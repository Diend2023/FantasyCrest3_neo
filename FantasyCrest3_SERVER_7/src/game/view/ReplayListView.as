// 新增回放功能需要录像列表界面（列出video目录下的.zyvideo录像，支持播放/导出/删除）。
// 说明：列表用feathers LayoutGroup + 自定义ReplayItem（纯starling Sprite），不使用feathers List——
// List(Scroller)默认touchGroup=true会拦截itemRenderer内starling原生按钮触摸，导致按钮无法点击。
package game.view
{
   import feathers.controls.LayoutGroup;
   import feathers.layout.VerticalLayout;
   import flash.events.Event; // FileReference导入事件
   import flash.filesystem.File;
   import flash.filesystem.FileMode; // 导入写文件
   import flash.filesystem.FileStream; // 导入写文件
   import flash.net.FileFilter; // 导入文件过滤
   import flash.net.FileReference;
   import flash.utils.ByteArray;
   import flash.utils.getDefinitionByName; // 回放时还原录像对应的原始世界类
   import game.data.WorldRecordData;
   import game.display.CommonButton;
   import game.server.ReplayRunModel; // 回放静态数据注入
   import game.uilts.GameFont;
   import game.view.item.ReplayItem;
   import starling.display.Quad;
   import starling.text.TextField;
   import starling.text.TextFormat;
   import zygame.core.SceneCore;
   import zygame.display.DisplayObjectContainer;
   import zygame.display.World;
   import zygame.utils.RTools;
   
   public class ReplayListView extends DisplayObjectContainer
   {
      
      private var _group:LayoutGroup;
      
      private var _emptyTips:TextField;
      
      // 分页相关
      private var _allItems:Array = []; // 全部录像数据（时间倒序）
      
      private var _page:int = 0; // 当前页（0起）
      
      private var _pageCount:int = 0; // 总页数
      
      private var _pageText:TextField; // 页码显示
      
      private var _prevBtn:CommonButton; // 上一页
      
      private var _nextBtn:CommonButton; // 下一页
      
      private var _importRef:FileReference; // 导入录像文件引用
      
      private static const PAGE_SIZE:int = 4; // 每页最多4个
      
      public function ReplayListView()
      {
         super();
      }
      
      override public function onInit() : void
      {
         var bg:Quad;
         var panel:Quad;
         var group:LayoutGroup;
         var layout:VerticalLayout;
         var title:TextField;
         var close:CommonButton;
         super.onInit();
         // 全屏半透明遮罩（不使用排行榜背景图）
         bg = new Quad(stage.stageWidth,stage.stageHeight,0x000000);
         bg.alpha = 0.7;
         this.addChild(bg);
         panel = new Quad(620,480,0x111111);
         panel.alpha = 0.85;
         this.addChild(panel);
         panel.x = stage.stageWidth / 2;
         panel.y = stage.stageHeight / 2;
         panel.alignPivot();
         title = new TextField(300,40,"录像列表",new TextFormat(GameFont.FONT_NAME,24,16777215,"center"));
         this.addChild(title);
         title.x = panel.x;
         title.y = panel.y - panel.height / 2 + 20;
         title.alignPivot();
         group = new LayoutGroup();
         this.addChild(group);
         layout = new VerticalLayout();
         layout.gap = 5;
         group.layout = layout;
         group.x = panel.x - 295;
         group.y = panel.y - panel.height / 2 + 65;
         _group = group;
         _emptyTips = new TextField(400,40,"暂无录像",new TextFormat(GameFont.FONT_NAME,18,11184810,"center"));
         this.addChild(_emptyTips);
         _emptyTips.x = panel.x;
         _emptyTips.y = panel.y;
         _emptyTips.alignPivot();
         close = new CommonButton("关闭");
         this.addChild(close);
         close.x = panel.x + panel.width / 2 - close.width / 2;
         close.y = panel.y - panel.height / 2 + close.height / 2;
         close.callBack = function():void
         {
            removeFromParent();
         };
         // 导入按钮（位于"录像列表"标题与"关闭"按钮之间，大小与录像item按钮一致scale=0.55且顶部对齐）
         var importBtn:CommonButton = new CommonButton("btn_style_1","start_main","导入");
         this.addChild(importBtn);
         importBtn.scale = 0.55;
         importBtn.x = group.x + importBtn.imageDisplay.width / 4 + 5;
         importBtn.y = group.y - importBtn.imageDisplay.height / 4;
         importBtn.callBack = function():void
         {
            importReplay();
         };
         // 分页控件（上一页/页码/下一页，位于列表下方）
         _prevBtn = new CommonButton("next_last","start_main",null);
         this.addChild(_prevBtn);
         _prevBtn.scale = 0.75;
         _prevBtn.scaleX = -0.75;
         _prevBtn.x = panel.x - 70;
         _prevBtn.y = panel.y + 215;
         _prevBtn.callBack = function():void
         {
            if(_page > 0)
            {
               _page--;
               updateList();
            }
         };
         _nextBtn = new CommonButton("next_last","start_main",null);
         this.addChild(_nextBtn);
         _nextBtn.scale = 0.75;
         _nextBtn.x = panel.x + 70;
         _nextBtn.y = panel.y + 215;
         _nextBtn.callBack = function():void
         {
            if(_page < _pageCount - 1)
            {
               _page++;
               updateList();
            }
         };
         _pageText = new TextField(120,40,"",new TextFormat(GameFont.FONT_NAME,24,16777215,"center"));
         this.addChild(_pageText);
         _pageText.x = panel.x;
         _pageText.y = panel.y + 215;
         _pageText.alignPivot();
         refreshList();
      }
      
      public function refreshList() : void
      {
         _allItems = [];
         var videoDir:File = File.applicationStorageDirectory.resolvePath("video");
         if(videoDir.exists && videoDir.isDirectory)
         {
            var files:Array = videoDir.getDirectoryListing();
            files.sortOn("modificationDate",Array.DESCENDING);
            for each(var file:File in files)
            {
               if(!file.isDirectory && file.extension == "zyvideo")
               {
                  var item:Object = readHeader(file);
                  if(item)
                  {
                     item.file = file;
                     item.onPlay = buildPlay(item);
                     item.onExport = buildExport(item);
                     item.onDelete = buildDelete(item);
                     _allItems.push(item);
                  }
               }
            }
         }
         // 删除后页码越界回退
         _pageCount = Math.ceil(_allItems.length / PAGE_SIZE);
         if(_pageCount == 0)
         {
            _page = 0;
         }
         else if(_page >= _pageCount)
         {
            _page = _pageCount - 1;
         }
         updateList();
      }
      
      // 按当前页渲染列表（每页最多PAGE_SIZE个）
      private function updateList() : void
      {
         var start:int = _page * PAGE_SIZE;
         var end:int = Math.min(start + PAGE_SIZE,_allItems.length);
         _group.removeChildren();
         for(var i:int = start; i < end; i++)
         {
            var itemData:Object = _allItems[i];
            var itemView:ReplayItem = new ReplayItem(itemData,itemData.onPlay,itemData.onExport,itemData.onDelete);
            _group.addChild(itemView);
         }
         _group.validate();
         _emptyTips.visible = _allItems.length == 0;
         _pageText.text = (_pageCount == 0 ? 0 : _page + 1) + "/" + _pageCount;
         _prevBtn.visible = _page > 0;
         _nextBtn.visible = _page < _pageCount - 1;
      }
      
      // 只读录像文件头部元数据（不解析帧数据，性能友好）
      private function readHeader(file:File) : Object
      {
         try
         {
            var byte:ByteArray = RTools.readByteArray(file);
            if(!byte)
            {
               return null;
            }
            byte.uncompress();
            byte.position = 0;
            var worldClassName:String = byte.readUTF();
            var mapName:String = byte.readUTF();
            var t1:Array = byte.readObject() as Array;
            var t2:Array = byte.readObject() as Array;
            var modeLabel:String = byte.readUTF();
            var mode:String = byte.readUTF();
            var situation:String = byte.readUTF();
            var createTime:Number = byte.readDouble();
            var totalFrames:int = byte.readInt();
            var rolesText:String = "";
            if(t1 && t1.length > 0)
            {
               rolesText += t1.join("、");
            }
            rolesText += " VS ";
            if(t2 && t2.length > 0)
            {
               rolesText += t2.join("、");
            }
            return {
               worldClassName:worldClassName,
               mapName:mapName,
               modeLabel:modeLabel,
               mode:mode,
               situation:situation,
               timeText:formatTime(createTime),
               durationText:formatDuration(totalFrames), // 游戏时长[时:分:秒]
               rolesText:rolesText,
               team1:t1, // 队伍1角色名数组（头像展示用）
               team2:t2, // 队伍2角色名数组（头像展示用）
               totalFrames:totalFrames
            };
         }
         catch(e:Error)
         {
            // 损坏的录像文件直接跳过
            trace("读取录像头部失败：",file.name,e.message);
            return null;
         }
      }
      
      // 回放世界白名单校验（排除剧情/副本/联机模式，className为完整限定名如"game.world::_1V1"）
      private function cheakSupport(className:String) : Boolean
      {
         if(className == null || className == "")
         {
            return false;
         }
         if(className.indexOf("Online") != -1)
         {
            return false;
         }
         if(className.indexOf("::_1VStory") != -1 || className.indexOf("::_1VFB") != -1)
         {
            return false;
         }
         return true;
      }
      
      private function buildPlay(item:Object) : Function
      {
         return function():void
         {
            try
            {
               if(!cheakSupport(item.worldClassName))
               {
                  SceneCore.pushView(new GameTipsView("该模式暂不支持回放"));
                  return;
               }
               var byte:ByteArray = RTools.readByteArray(item.file);
               if(!byte)
               {
                  return;
               }
               byte.uncompress();
               byte.position = 0;
               var record:WorldRecordData = new WorldRecordData(byte);
               // 注入回放数据，用录像对应的原始世界类走GameVSView过渡（VS动画+资源加载进度）
               // 原始世界类复用其全部模式逻辑（血条映射/出场/换人/胜负流程），实现完美兼容
               var _cls:Class = getDefinitionByName(record.worldClassName) as Class;
               if(_cls == null)
               {
                  SceneCore.pushView(new GameTipsView("回放失败：未知的世界类型"));
                  return;
               }
               ReplayRunModel.recordData = record;
               ReplayRunModel.isReplay = true;
               ReplayRunModel.oldDefaultClass = World.defalutClass;
               World.defalutClass = _cls;
               SceneCore.replaceScene(new GameVSView(record.mapName, record.team1Roles, record.team2Roles));
            }
            catch(e:Error)
            {
               trace("回放失败",e);
               ReplayRunModel.isReplay = false;
               SceneCore.pushView(new GameTipsView("回放失败：" + e.message));
            }
         };
      }
      
      private function buildExport(item:Object) : Function
      {
         return function():void
         {
            try
            {
               var byte:ByteArray = RTools.readByteArray(item.file);
               if(byte)
               {
                  var fr:FileReference = new FileReference();
                  fr.save(byte,"录像_" + String(item.timeText).replace(/[: ]/g,"_") + ".zyvideo");
                  SceneCore.pushView(new GameTipsView("导出成功"));
               }
            }
            catch(e:Error)
            {
               trace("导出录像失败",e);
               SceneCore.pushView(new GameTipsView("导出失败"));
            }
         };
      }
      
      private function buildDelete(item:Object) : Function
      {
         return function():void
         {
            try
            {
               if(item.file && item.file.exists)
               {
                  item.file.deleteFile();
                  SceneCore.pushView(new GameTipsView("删除成功"));
               }
               refreshList();
            }
            catch(e:Error)
            {
               trace("删除录像失败",e);
               SceneCore.pushView(new GameTipsView("删除失败"));
            }
         };
      }
      
      private function formatTime(t:Number) : String
      {
         var d:Date = new Date(t);
         return d.fullYear + "-" + pad(d.month + 1) + "-" + pad(d.date) + " " + pad(d.hours) + ":" + pad(d.minutes) + ":" + pad(d.seconds);
      }
      
      private function pad(n:int) : String
      {
         return n < 10 ? "0" + n : String(n);
      }
      
      // 录像游戏时长（由总帧数换算，60fps，格式[时:分:秒]）
      private function formatDuration(totalFrames:int) : String
      {
         var totalSec:int = totalFrames / 60;
         var h:int = totalSec / 3600;
         var m:int = (totalSec % 3600) / 60;
         var s:int = totalSec % 60;
         return pad(h) + ":" + pad(m) + ":" + pad(s);
      }
      
      // 导入外部录像（FileReference浏览*.zyvideo -> 验证头部 -> 写入video目录 -> 刷新列表）
      private function importReplay() : void
      {
         try
         {
            _importRef = new FileReference();
            _importRef.addEventListener(Event.SELECT,onImportSelected);
            _importRef.browse([new FileFilter("录像文件","*.zyvideo")]);
         }
         catch(e:Error)
         {
            trace("打开导入对话框失败",e);
         }
      }
      
      private function onImportSelected(e:Event) : void
      {
         try
         {
            _importRef.addEventListener(Event.COMPLETE,onImportComplete);
            _importRef.load();
         }
         catch(e:Error)
         {
            trace("加载导入录像失败",e);
         }
      }
      
      private function onImportComplete(e:Event) : void
      {
         try
         {
            var bytes:ByteArray = _importRef.data;
            if(!bytes || bytes.length == 0)
            {
               SceneCore.pushView(new GameTipsView("导入失败：空文件"));
               return;
            }
            // 验证v2录像头部（录像文件为压缩态，需先解压副本验证；能完整读出头部+帧数据才视为有效录像）
            var verify:ByteArray = new ByteArray();
            verify.writeBytes(bytes,0,bytes.length);
            verify.position = 0;
            verify.uncompress();
            verify.position = 0;
            verify.readUTF(); // worldClassName
            verify.readUTF(); // mapName
            verify.readObject(); // team1Roles
            verify.readObject(); // team2Roles
            verify.readUTF(); // gameModeLabel
            verify.readUTF(); // gameMode
            verify.readUTF(); // situation
            verify.readDouble(); // createTime
            verify.readInt(); // totalFrames
            verify.readObject(); // worldDatas
            // 写入video目录（保存原始压缩字节，与dispose落盘格式一致）
            var videoDir:File = File.applicationStorageDirectory.resolvePath("video");
            if(!videoDir.exists)
            {
               videoDir.createDirectory();
            }
            var outFile:File = videoDir.resolvePath(_importRef.name);
            var fs:FileStream = new FileStream();
            fs.open(outFile,FileMode.WRITE);
            fs.writeBytes(bytes,0,bytes.length);
            fs.close();
            refreshList();
            SceneCore.pushView(new GameTipsView("导入成功"));
         }
         catch(e:Error)
         {
            trace("导入录像失败",e);
            SceneCore.pushView(new GameTipsView("导入失败"));
         }
      }
   }
}
