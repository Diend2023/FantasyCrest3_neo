package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import game.buff.AttributeChangeBuff;
   import feathers.data.ListCollection;

   public class ZZX extends GameRole
   {

      private var p:Boolean = false;
      
      public function ZZX(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":"Off"
         }]);
      }
      
      override public function onFrame() : void
      {
         super.onFrame();
         if (this.hit > 5 && !this.attribute.hasBuff(AttributeChangeBuff, "fireBuff"))
         {
            var fireBuff:AttributeChangeBuff = new AttributeChangeBuff("fireBuff", this, -1, new RoleAttributeData());
            this.addBuff(fireBuff);
         }
         else if (this.hit <= 5 && this.attribute.hasBuff(AttributeChangeBuff, "fireBuff"))
         {
            this.attribute.hasBuff(AttributeChangeBuff, "fireBuff").currentTime = 0; // 清除buff持续时间
         }
         if (p)
         {
            listData.getItemAt(0).msg = "On";
         }
         else
         {
            listData.getItemAt(0).msg = "Off";
         }
         listData.updateItemAt(0);
      }

      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         super.runLockAction(str, canBreak);
         if(str == "我流·灼心燃魂")
         {
            p = !p;
         }
         // if(this.attribute.hasBuff(AttributeChangeBuff, "fireBuff"))
         if(p)
         {
            switch(str)
            {
               case "秘剑·鬼步（狱步）":
                  this.actionName = "EXSJ";
                  break;
               case "红莲腕（真·红莲腕）":
                  this.actionName = "EXWJ"
                  break;
               case "秘剑·圆（红牙飞燕）":
                  this.actionName = "EXU"
                  break;
               case "秘剑·走灼（锯刀行焰）":
                  this.actionName = "EXSU"
                  break;
               case "秘剑·背车刀（背车烛势）":
                  this.actionName = "EXWU"
                  break;
               case "秘剑·凌空（火烧云鸦）":
                  this.actionName = "EXKU"
                  break;
               case "秘剑·穿空（穿火灼心）":
                  this.actionName = "EXKSU"
                  break;
               case "秘剑·渡鸦（祸鸦三渡）":
                  this.actionName = "EXI"
                  break;
               case "秘剑·人屠（人屠炎灵）":
                  this.actionName = "EXSI"
                  break;
               case "秘剑·旋空（卷炎风旋）":
                  this.actionName = "EXWI"
                  break;
               case "秘剑·划空（凌云烟渡）":
                  this.actionName = "EXKI"
                  break;
               case "无限刃·炎鬼（终极秘剑·火产灵神）":
                  this.actionName = "EXO"
                  break;
               case "无限刃·旋空（无限刃·灼鬼旋空）":
                  this.actionName = "EXWO"
                  break;
            }
         }
      }

   }
}

