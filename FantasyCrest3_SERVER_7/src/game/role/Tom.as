// 添加汤姆的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import feathers.data.ListCollection;
   import zygame.display.World;
   import starling.core.Starling;
   import zygame.data.BeHitData;
   import flash.geom.Point;

   public class Tom extends GameRole
   {

      public var hasCounterAttack:Boolean = false;
      var ms:Number = 0.0;

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
         if(this.attribute.hp < this.attribute.hpmax * 0.3 && !this.hasCounterAttack)
         {
            this.hasCounterAttack = true;
            listData.getItemAt(0).msg = "On";
            listData.updateItemAt(0);
            this.attribute.power += 200;
            ms = 0.8;
            Starling.juggler.delayCall(function():void
            {
               listData.getItemAt(0).msg = "Over";
               listData.updateItemAt(0);
               attribute.power -= 200;
               ms = 0.0;
            },15);
         }
      }

      override public function hurtNumber(beHurt:int, beData:BeHitData, pos:Point) : void
      {
         super.hurtNumber(beHurt * (1 - ms),beData,pos);
      }

   }
}

