// 添加朽木白哉
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.buff.BuffRef;
   import zygame.display.EffectDisplay;

   
   public class BaiZai extends GameRole
   {

      private var _effectQiangTimer:int = 0; // P断空墙持续时间计时器
      
      public function BaiZai(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }

      override public function onFrame():void
      {
         super.onFrame();
         if(this.inFrame("卍解         千 本 樱            景严",18))
         {
            this.addBuff(new BuffRef("buff_Yinghua",this,10), 1, false);
         }
         var effectYinghua:EffectDisplay = this.world.getEffectFormName("yinghua",this)
         if(effectYinghua)
         {
            if (effectYinghua.currentFrame == 6)
            {
               effectYinghua.go(0);
            }
         }
         var effectQiang:EffectDisplay = this.world.getEffectFormName("qiang",this);
         if(effectQiang)
         {
            var effectQiangScaleX:int = effectQiang.scaleX > 0 ? 1 : -1;
            if(effectQiang.currentFrame == 0)
            {
               _effectQiangTimer = 600;
               // 不可推动
               effectQiang.body.allowMovement = false;
            }
            if(effectQiang.currentFrame == 1 && _effectQiangTimer > 0)
            {
               _effectQiangTimer -= 1;
               effectQiang.cardFrame = 2;
            }
         }
         // 碰到其它特效时，使特效速度为0
         var effects:Vector.<EffectDisplay> = this.world.getEffects();
         for each(var effect:EffectDisplay in effects)
         {
            if(effectQiang && effect.role.troopid != this.troopid && Math.abs(effect.x - effectQiang.x) < 150 && Math.abs(effect.y + 100 - effectQiang.y) < 200)
            {
               effect.speedScale = 0;
            }
            else
            {
               effect.speedScale = 1;
            }
         }
      }
   }
}

