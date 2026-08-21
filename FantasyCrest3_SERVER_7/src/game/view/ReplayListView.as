// 新增原因：回放功能需要录像列表界面（列出video目录下的.zyvideo录像，支持播放/导出/删除）。
// 说明：列表用feathers LayoutGroup + 自定义ReplayItem（纯starling Sprite），不使用feathers List——
// List(Scroller)默认touchGroup=true会拦截itemRenderer内starling原生按钮触摸，导致按钮无法点击。
package game.view
{
   import feathers.controls.LayoutGroup;
   import feathers.layout.VerticalLayout;
   import flash.filesystem.File;
   import flash.net.FileReference;
   import flash.utils.ByteArray;
   import game.data.WorldRecordData;
   import game.display.CommonButton;
   import game.uilts.GameFont;
   import game.view.item.ReplayItem;
   import game.world.ReplayWorld;
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
         title.y = panel.y - panel.height / 2 + 30;
         title.alignPivot();
         group = new LayoutGroup();
         this.addChild(group);
         layout = new VerticalLayout();
         layout.gap = 5;
         group.layout = layout;
         group.x = panel.x - 295;
         group.y = panel.y - panel.height / 2 + 55;
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
         refreshList();
      }
      
      public function refreshList() : void
      {
         var arr:Array = [];
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
                     arr.push(item);
                  }
               }
            }
         }
         _group.removeChildren();
         for each(var itemData:Object in arr)
         {
            var itemView:ReplayItem = new ReplayItem(itemData,itemData.onPlay,itemData.onExport,itemData.onDelete);
            _group.addChild(itemView);
         }
         _group.validate();
         _emptyTips.visible = arr.length == 0;
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
               rolesText:rolesText,
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
      
      // 回放世界白名单校验（排除剧情/副本/联机模式）
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
         if(className == "_1VStory" || className == "_1VFB")
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
               // 注入回放数据并切换世界类，走GameVSView过渡（VS动画+资源加载进度）
               ReplayWorld.recordData = record;
               ReplayWorld.oldDefaultClass = World.defalutClass;
               World.defalutClass = ReplayWorld;
               SceneCore.replaceScene(new GameVSView(record.mapName, record.team1Roles, record.team2Roles));
            }
            catch(e:Error)
            {
               trace("回放失败",e);
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
               }
            }
            catch(e:Error)
            {
               trace("导出录像失败",e);
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
               }
               refreshList();
            }
            catch(e:Error)
            {
               trace("删除录像失败",e);
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
   }
}
