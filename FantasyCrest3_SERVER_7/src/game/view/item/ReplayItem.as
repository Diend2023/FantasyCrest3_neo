// 新增原因：录像列表项（显示时间/模式/地图/角色信息，以及播放/导出/删除按钮）。
// 说明：改为纯starling Sprite，不继承feathers BaseItem——feathers List的touchGroup拦截会导致内部starling按钮收不到触摸；
// 数据与回调直接由构造注入，避免容器无显式尺寸时height为0导致的按钮重叠问题。
package game.view.item
{
   import game.display.CommonButton;
   import game.uilts.GameFont;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.text.TextField;
   import starling.text.TextFormat;
   
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
         var msg:TextField = new TextField(340,84,"",new TextFormat(GameFont.FONT_NAME,12,16777215,"left"));
         this.addChild(msg);
         msg.x = 10;
         msg.y = 4;
         // 地图名称列
         var mapField:TextField = new TextField(95,90,"",new TextFormat(GameFont.FONT_NAME,12,16776960,"center"));
         this.addChild(mapField);
         mapField.x = 345;
         mapField.y = 0;
         if(value)
         {
            msg.text = "[" + value.timeText + "]\n" + value.modeLabel + " | " + value.mode + " | " + value.situation + "\n" + value.rolesText;
            mapField.text = value.mapName;
         }
         // 操作列：播放/导出/删除（用imageDisplay实际高度计算间距，避免容器height为0导致按钮重叠）
         var playBtn:CommonButton = new CommonButton("btn_style_1","start_main","播放");
         this.addChild(playBtn);
         playBtn.scale = 0.4;
         playBtn.x = 455;
         playBtn.y = 8;
         playBtn.callBack = function():void
         {
            if(onPlay != null)
            {
               onPlay();
            }
         };
         var _step:Number = playBtn.imageDisplay.height * playBtn.scale + 4;
         var exportBtn:CommonButton = new CommonButton("btn_style_1","start_main","导出");
         this.addChild(exportBtn);
         exportBtn.scale = 0.4;
         exportBtn.x = 455;
         exportBtn.y = 8 + _step;
         exportBtn.callBack = function():void
         {
            if(onExport != null)
            {
               onExport();
            }
         };
         var deleteBtn:CommonButton = new CommonButton("btn_style_1","start_main","删除");
         this.addChild(deleteBtn);
         deleteBtn.scale = 0.4;
         deleteBtn.x = 455;
         deleteBtn.y = 8 + _step * 2;
         deleteBtn.callBack = function():void
         {
            if(onDelete != null)
            {
               onDelete();
            }
         };
      }
   }
}
