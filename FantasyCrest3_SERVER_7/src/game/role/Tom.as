// 添加汤姆的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import feathers.data.ListCollection;
   import zygame.display.World;
   import starling.core.Starling;
   import zygame.data.BeHitData;
   import flash.geom.Point;
   import game.buff.AttributeChangeBuff;

   public class Tom extends GameRole
   {

      private var hasCounterAttack:Boolean = false;
      private var counterAttackTimer:int = 0;
      private var ms:Number = 0.0;

      public function Tom(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
         "icon":"liliang.png",
         "msg":"Off"
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
      }

      override public function onFrame() : void
      {
         super.onFrame();
         // if(counterAttackTimer > 0 && this.cardFrame <= 0 && !this.isOut)
         // {
         //    counterAttackTimer--;
         //    if(counterAttackTimer == 0)
         //    {
         //       listData.getItemAt(0).msg = "Over";
         //       listData.updateItemAt(0);
         //       attribute.power -= 200;
         //       ms = 0.0;
         //    }
         // }
         if(!hasCounterAttack)
         {
            listData.getItemAt(0).msg = "Off";
            listData.updateItemAt(0);
         }
         if(this.attribute.hp < this.attribute.hpmax * 0.3 && !hasCounterAttack)
         {
            hasCounterAttack = true;
            this.addBuff(new AttributeChangeBuff("counter_attack", this, 15, new RoleAttributeData(), null), 1, false);
            (this.attribute.hasBuff(AttributeChangeBuff, "counter_attack") as AttributeChangeBuff).changeData.power = 200;
            ms = 0.8;
            listData.getItemAt(0).msg = "On";
            listData.updateItemAt(0);
            // this.attribute.power += 200;
            // counterAttackTimer = 15 * 60; // 持续15秒
            // ms = 0.8;
            // Starling.juggler.delayCall(function():void
            // {
            //    listData.getItemAt(0).msg = "Over";
            //    listData.updateItemAt(0);
            //    attribute.power -= 200;
            //    ms = 0.0;
            // },15);
         }
         // if(this.attribute && this.attribute.hp > 0 && this.attribute.hasBuff(AttributeChangeBuff, "counter_attack"))
         // {
         //    listData.getItemAt(0).msg = "On";
         //    listData.updateItemAt(0);
         // }
         else if(this.attribute && this.attribute.hp > 0 && !this.attribute.hasBuff(AttributeChangeBuff, "counter_attack") && hasCounterAttack)
         {
            listData.getItemAt(0).msg = "Over";
            listData.updateItemAt(0);
            ms = 0.0;
         }
      }

      override public function hurtNumber(beHurt:int, beData:BeHitData, pos:Point) : void
      {
         super.hurtNumber(beHurt * (1 - ms),beData,pos);
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         // 复制被动使用状态
         ob.hasCounterAttack = hasCounterAttack;
         return ob;
      }

      override public function setData(value:Object) : void
      {
         super.setData(value);
         // 设置被动使用状态
         hasCounterAttack = value.hasCounterAttack;
      }

   }
}

