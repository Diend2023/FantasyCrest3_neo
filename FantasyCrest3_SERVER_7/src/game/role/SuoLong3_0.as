package game.role
{
   import feathers.data.ListCollection;
   import game.buff.AttributeChangeBuff;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   
   public class SuoLong3_0 extends GameRole
   {
      
      private var _cd:int = 0;
      
      private var _buff:AttributeChangeBuff;
      
      public function SuoLong3_0(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
            "icon":"fangyu.png",
            "msg":"Auto"
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
         _buff = new AttributeChangeBuff("SuoLongBuff",this,-1,new RoleAttributeData());
         this.addBuff(_buff);
      }
      
      override public function onFrame() : void
      {
         super.onFrame();
         if(_cd <= 0)
         {
            _buff.changeData.dodgeRate = 25;
            listData.getItemAt(0).msg = "Auto";
         }
         else
         {
            _buff.changeData.dodgeRate = 0;
            _cd--;
            listData.getItemAt(0).msg = (_cd / 60).toFixed(1);
         }
         listData.updateAll();
      }
      
      override public function onMiss(beData:BeHitData) : void
      {
         super.onMiss(beData);
         _cd = 300;
         this.goldenTime = 0.3;
      }
   }
}

