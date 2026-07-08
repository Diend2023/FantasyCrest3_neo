package game.role
{
   import game.buff.AttributeChangeBuff;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   
   public class TeLanKeSi3_0 extends FlyRole
   {
      
      private var buff:RoleAttributeData;
      
      public function TeLanKeSi3_0(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         buff = new RoleAttributeData();
         var buff2:AttributeChangeBuff = new AttributeChangeBuff("TeLanKeSi",this,-1,buff);
         this.addBuff(buff2);
      }
      
      override public function onFrame() : void
      {
         super.onFrame();
         if(actionName == "行走" && (isKeyDown(87) || isKeyDown(83)))
         {
            this.isFly = true;
            buff.speed = 3;
         }
         else if(!isJump())
         {
            this.isFly = false;
            buff.speed = 0;
         }
      }
      
      override public function set action(str:String) : void
      {
         if(this.isFly && (str == "跳跃" || str == "降落"))
         {
            this.actionName = "降落";
            return;
         }
         super.action = str;
      }
   }
}

