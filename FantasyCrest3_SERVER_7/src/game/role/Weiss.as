package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.BaseRole;
   import zygame.display.EffectDisplay;
   
   public class Weiss extends GameRole
   {
      private var _suFrameCunter:int = 0; // su帧数计数器
      
      public function Weiss(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }

      override public function onFrame():void
      {
         super.onFrame();
         if (this.actionName == "Yellow Glyphs")
         {
            if(_suFrameCunter == 1 || (_suFrameCunter >= 9 && _suFrameCunter % 9 != 0) && _suFrameCunter <= 100)
            {
               declareSpeed(); // 每9帧降低一次敌方速度
            }
            _suFrameCunter++;
         }
         else
         {
            _suFrameCunter = 0; // 重置计数器
         }
         if(this.inFrame("白银骑士", 20))
         {
            var roles:Vector.<BaseRole> = this.world.getRoleList()
            for each (var role:BaseRole in roles)
            {
               if (role != this && role.troopid != this.troopid && role.attribute && Math.abs(this.x - role.x) < 300)
               {
                  this.posx = role.x;
                  break;
               }
            }
         }
      }

      private function declareSpeed():void
      {
         var roles:Vector.<BaseRole> = this.world.getRoleList()
         for each (var role:BaseRole in roles)
         {
            if (role != this && role.troopid != this.troopid && role.attribute)
            {
               role.cardFrame = 2; // 
            }
         }
         var effects:Vector.<EffectDisplay> = this.world.getEffects();
         for each (var effect:EffectDisplay in effects)
         {
            if (effect.role && effect.role.troopid != this.troopid)
            {
               effect.cardFrame = 1; // 
            }
         }
      }
      
   }
}

