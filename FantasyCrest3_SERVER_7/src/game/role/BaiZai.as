// 添加朽木白哉
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.buff.BuffRef;
   
   public class BaiZai extends GameRole
   {
      
      public function BaiZai(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }

      override public function onFrame():void
      {
         super.onFrame();
         if(this.inFrame("卍解         千 本 樱            景严",18))
         {
            this.addBuff(new BuffRef("buff_Yinghua",this,10,"yinghua"), 1, false);
         }
      }
   }
}

