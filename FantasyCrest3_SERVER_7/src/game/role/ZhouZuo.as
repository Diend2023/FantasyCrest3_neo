// 添加咒印佐助被动
package game.role
{
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.BaseRole;
   import zygame.display.World;
   import feathers.data.ListCollection;
   
   public class ZhouZuo extends GameRole
   {

      public function ZhouZuo(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }
      
      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         if(enemy.hasBuff(ganDianBuff))
         {
            if(beData.armorScale == 0 && beData.magicScale == 0)
            {
               beData.armorScale = 1;
               beData.magicScale = 1;
            }
            beData.magicScale = 1.6;
         }
         if(actionName == "恸哭的千鸟" && !enemy.hasBuff(ganDianBuff))
         {
            enemy.addBuff(new ganDianBuff("gandian",enemy,10,"pj"));
         }
         super.onHitEnemy(beData,enemy);
      }
   }
}

import zygame.buff.BuffRef;
import zygame.display.BaseRole;

class ganDianBuff extends BuffRef
{
   public function ganDianBuff(buffName:String, role:BaseRole, time:int, effectName:String = null)
   {
      super(buffName,role,time,effectName);
   }
}