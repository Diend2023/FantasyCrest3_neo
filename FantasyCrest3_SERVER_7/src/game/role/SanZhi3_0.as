package game.role
{
   import feathers.data.ListCollection;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.BaseRole;
   import zygame.display.World;
   
   public class SanZhi3_0 extends GameRole
   {
      
      public function SanZhi3_0(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.jumpTimeMax = 2;
         listData = new ListCollection([{
            "icon":"sudu.png",
            "msg":3
         }]);
      }
      
      override public function onFrame() : void
      {
         super.onFrame();
         listData.getItemAt(0).msg = this.jumpTime;
         listData.updateItemAt(0);
      }
      
      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         super.onHitEnemy(beData,enemy);
         this.goldenTime = 0.1;
      }
      
      override public function onSUpdate() : void
      {
         super.onSUpdate();
      }
      
      override public function jump(hv:int = -1, foc:Boolean = false, jumpEff:Boolean = false) : void
      {
         super.jump(hv,foc,jumpEff);
         if(hv == -1)
         {
            this.goldenTime = 0.25;
         }
      }
      
      override public function jumpOff() : void
      {
         super.jumpOff();
      }
   }
}

