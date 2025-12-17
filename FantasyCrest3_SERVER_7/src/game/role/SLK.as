// 添加赛莉卡被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.BaseRole;
   
   public class SLK extends GameRole
   {

      private var sCount:int = 3;
      
      public function SLK(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }
      
      override public function onSUpdate() : void
      {
         super.onSUpdate();
         if(sCount % 2 != 0)
         {
            for each(var r:BaseRole in this.world.getRoleList())
            {
               if(r && (r as GameRole).troopid != this.troopid && r.attribute && (r as GameRole).mpPoint.value > -1)
               {
                  if(r.targetName == "Es")
                  {
                     (r as GameRole).mpPoint.value -= 1;
                  }
               }
            }
         }
         else if(sCount % 2 == 0)
         {
            for each(var r2:BaseRole in this.world.getRoleList())
            {
               if(r2 && (r2 as GameRole).troopid != this.troopid && r2.attribute && (r2 as GameRole).mpPoint.value > -1)
               {
                  (r2 as GameRole).mpPoint.value -= 1;
               }
            }
         }
         sCount++;
      }
   }
}

