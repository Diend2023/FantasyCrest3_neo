// 新增录像列表项（显示角色头像/时间/模式/地图信息，以及播放/导出/删除按钮）。
// 说明：改为纯starling Sprite，不继承feathers BaseItem——feathers List的touchGroup拦截会导致内部starling按钮收不到触摸；
// 角色以头像展示（参考RankItem），未找到头像时使用role_head图集的none，队伍之间以select_role图集的vs分隔；
// 数据与回调直接由构造注入，避免容器无显式尺寸时height为0导致的按钮重叠问题。
package game.view.item
{
   import game.display.CommonButton;
   import game.uilts.GameFont;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.text.TextField;
   import starling.text.TextFormat;
   import starling.textures.Texture;
   import zygame.core.DataCore;
   
   public class ReplayItem extends Sprite
   {
      
      public function ReplayItem(value:Object, onPlay:Function, onExport:Function, onDelete:Function)
      {
         super();
         var bg:Quad = new Quad(590,90,0x1a1a1a);
         bg.alpha = 0.75;
         this.addChild(bg);
         this.width = bg.width;
         this.height = bg.height;
         // 信息区（时间/模式，居左上）
         var msg:TextField = new TextField(280,40,"",new TextFormat(GameFont.FONT_NAME,12,16777215,"left"));
         this.addChild(msg);
         msg.x = 10;
         msg.y = 4;
         if(value)
         {
            msg.text = "[" + value.timeText + "] [" + value.durationText + "]\n" + value.modeLabel + " | " + value.mode + " | " + value.situation;
         }
         // 地图显示（MapItem结构原样放入缩放容器：背景框原始尺寸+遮罩内缩5+图片按(框宽-10)缩放+40高18号白字；
         // 容器整体缩放到高72，显示选中效果alpha=1；y=8使底部(8+72=80)与角色头像底部对齐）
         var mapX:Number = 250;
         var mapY:Number = 12;
         try
         {
            var mapCont:Sprite = new Sprite();
            // 背景框（原始尺寸不缩放，与MapItem一致）
            var mapBg:Image = new Image(DataCore.getTextureAtlas("select_role").getTexture("map_bg_frame"));
            mapCont.addChild(mapBg);
            var mapW:Number = mapBg.width;
            var mapH:Number = mapBg.height;
            // 遮罩（内缩5px，与MapItem一致）
            var mapMask:Quad = new Quad(mapW - 10,mapH - 10,0);
            mapMask.x = 5;
            mapMask.y = 5;
            mapCont.addChild(mapMask);
            // 地图图片（map_image图集，存在才显示，scale=(框宽-10)/图宽，x=5，与MapItem一致）
            try
            {
               var mapImg:Image = new Image(DataCore.getTextureAtlas("map_image").getTextures(value ? value.mapName : "")[0]);
               mapImg.scale = (mapW - 10) / mapImg.width;
               mapImg.x = 5;
               mapImg.mask = mapMask;
               mapCont.addChildAt(mapImg,0);
            }
            catch(e:Error)
            {
               // 无地图图片时仅显示背景框（与MapItem一致）
            }
            // 地图中文名（40高18号白字，宽=框宽，与MapItem一致）
            var mapText:TextField = new TextField(mapW,40,value ? getMapName(value.mapName) : "",new TextFormat(GameFont.FONT_NAME,18,16777215));
            mapCont.addChild(mapText);
            // 整体缩放到高72并定位到右上，选中效果全亮
            mapCont.scaleX = mapCont.scaleY = 72 / mapH;
            mapCont.x = mapX;
            mapCont.y = mapY;
            mapCont.alpha = 1;
            this.addChild(mapCont);
         }
         catch(e:Error)
         {
            // 图集缺失时兜底显示中文名文本
            var mapText2:TextField = new TextField(140,22,value ? getMapName(value.mapName) : "",new TextFormat(GameFont.FONT_NAME,18,16777215));
            this.addChild(mapText2);
            mapText2.x = mapX;
            mapText2.y = mapY;
         }
         // 角色头像区（时间/模式下方，队伍1头像 + VS + 队伍2头像）
         var ax:Number = 10;
         if(value && value.team1)
         {
            for each(var n1:String in value.team1)
            {
               addHeadImage(n1,ax,46);
               ax += 40;
            }
         }
         // VS分隔图（select_role图集，与头像同尺寸，水平居中于头像区）
         try
         {
            var vsImg:Image = new Image(DataCore.getTextureAtlas("select_role").getTexture("vs"));
            vsImg.x = ax + 1; // 左移（原+3，居中修正）
            vsImg.y = 46;
            vsImg.width = 34; // 与头像同尺寸（放大一倍）
            vsImg.height = 34; // 与头像同尺寸（放大一倍）
            this.addChild(vsImg);
            ax += 40;
         }
         catch(e:Error)
         {
            ax += 40;
         }
         if(value && value.team2)
         {
            for each(var n2:String in value.team2)
            {
               addHeadImage(n2,ax,46);
               ax += 40;
            }
         }
         // 操作列：播放/导出/删除（放大至scale=0.55，三个按钮整体垂直居中于90高item）
         var _btnScale:Number = 0.55; // 放大按钮 //
         var playBtn:CommonButton = new CommonButton("btn_style_1","start_main","播放");
         this.addChild(playBtn);
         playBtn.scale = _btnScale;
         playBtn.x = 455;
         var _btnH:Number = playBtn.imageDisplay.height * _btnScale;
         var _step:Number = _btnH + 4;
         var _startY:Number = (90 - (_btnH * 3 + 8)) / 2 + 12; // 垂直居中后整体下移10px（按钮过高视觉修正）
         playBtn.y = _startY;
         playBtn.callBack = function():void
         {
            if(onPlay != null)
            {
               onPlay();
            }
         };
         var exportBtn:CommonButton = new CommonButton("btn_style_1","start_main","导出");
         this.addChild(exportBtn);
         exportBtn.scale = _btnScale;
         exportBtn.x = 455;
         exportBtn.y = _startY + _step;
         exportBtn.callBack = function():void
         {
            if(onExport != null)
            {
               onExport();
            }
         };
         var deleteBtn:CommonButton = new CommonButton("btn_style_1","start_main","删除");
         this.addChild(deleteBtn);
         deleteBtn.scale = _btnScale;
         deleteBtn.x = 455;
         deleteBtn.y = _startY + _step * 2;
         deleteBtn.callBack = function():void
         {
            if(onDelete != null)
            {
               onDelete();
            }
         };
      }
      
      // 根据地图target名查maps.xml得到地图中文名（参考Game.getMapData的name来源）
      private function getMapName(target:String) : String
      {
         try
         {
            var xml:XMLList = DataCore.getXml("maps").children();
            for each(var map:XML in xml)
            {
               if(String(map.@target) == target)
               {
                  return String(map.@name);
               }
            }
         }
         catch(e:Error)
         {
         }
         return target;
      }
      
      // 添加角色头像（加载方式与RoleSelectItem一致：getTextures+try-catch，无头像时用role_head的none），尺寸对齐RoleSelectItem的65
      private function addHeadImage(roleName:String, px:Number, py:Number) : void
      {
         var tex:Texture = null;
         try
         {
            tex = DataCore.getTextureAtlas("role_head").getTextures(roleName)[0];
         }
         catch(e:Error)
         {
            tex = null;
         }
         if(!tex)
         {
            try
            {
               tex = DataCore.getTextureAtlas("role_head").getTextures("none")[0];
            }
            catch(e2:Error)
            {
               return;
            }
         }
         var img:Image = new Image(tex);
         img.x = px;
         img.y = py;
         img.width = 34; // 头像放大一倍
         img.height = 34; // 头像放大一倍
         this.addChild(img);
         // 头像框（与RoleSelectItem一致：role_head图集frame纹理覆盖在头像上，同尺寸）
         try
         {
            var frameTex:Texture = DataCore.getTextureAtlas("role_head").getTexture("frame");
            var frameImg:Image = new Image(frameTex);
            frameImg.x = px -2;
            frameImg.y = py -2;
            frameImg.width = 38;
            frameImg.height = 38;
            this.addChild(frameImg);
         }
         catch(e:Error)
         {
         }
      }
   }
}
