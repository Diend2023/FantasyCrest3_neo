// 添加疾风传佐助的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import feathers.data.ListCollection;
   import zygame.display.World;
   
   public class JiFengZuo extends GameRole
   {
      
      public function JiFengZuo(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
            "icon":"cd_O.png",
            "msg":0
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
         this.attribute.updateCD("麒麟", 60)

      }

      override public function onFrame() : void
      {
         super.onFrame();
         if(inFrame("千鸟锐枪",1) || inFrame("电火之牙",1))
         {
            if(Number(this.attribute.getCD("麒麟") / 60) <= 5)
            {
                this.attribute.updateCD("麒麟", 0);
            }
            else
            {
                this.attribute.updateCD("麒麟", Number(this.attribute.getCD("麒麟") / 60) - 5);
            }
         }
         else if (inFrame("豪龙火",1))
         {
            if(Number(this.attribute.getCD("麒麟") / 60) <= 10)
            {
                this.attribute.updateCD("麒麟", 0);
            }
            else
            {
                this.attribute.updateCD("麒麟", Number(this.attribute.getCD("麒麟") / 60) - 10);
            }
         }

         if(this.attribute.getCD("麒麟") == 0)
         {
            listData.getItemAt(0).msg = "Ready";
         }
         else
         {
            listData.getItemAt(0).msg = int(this.attribute.getCD("麒麟") / 60);
         }
         listData.updateItemAt(0);
      }

      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         if(str == "千鸟流·地走" || str == "电火之牙")
         {
            this.attribute.updateCD("千鸟流·地走", 8);
            this.attribute.updateCD("电火之牙", 8);
         }
         if(str == "千鸟锐枪" || str == "千鸟锐枪·穿透")
         {
            this.attribute.updateCD("千鸟锐枪", 8);
            this.attribute.updateCD("千鸟锐枪·穿透", 8);
         }
         if(str == "豪龙火" || str == "豪龙火·焚尽")
         {
            this.attribute.updateCD("豪龙火", 8);
            this.attribute.updateCD("豪龙火·焚尽", 8);
         }
         super.runLockAction(str, canBreak);
      }
   }
}

