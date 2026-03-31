// 添加斩神白面被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import zygame.data.BeHitData;
   
   public class ZhanShen extends GameRole
   {
      
      public function ZhanShen(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }
      
      override public function onFrame():void
      {
         super.onFrame();
         if(this.actionName != "待机")
         {
            var effectNingjujuju:EffectDisplay = this.world.getEffectFormName("ningjujuju", this);
            if (effectNingjujuju)
            {
               effectNingjujuju.discarded();
            }
         }
      }

      override public function onSUpdate() : void
      {
         super.onSUpdate();
         if(this.actionName == "待机")
         {
            addMpPoint(1);
         }
         if (this.currentMp.value == this.mpMax)
         {
            this.mpPoint.value = 0;
         }
      }

      override public function onBeHit(beData:BeHitData) : void
      {
         super.onBeHit(beData);
         if(this.actionName == "虚空阵 素" || this.actionName == "虚空阵 盈" || this.actionName == "虚空阵 尊")
         {
            if(this.frameAt(2,8))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.playSkill(this.actionName + " 攻击");
               this.golden = 30;
               if (this.currentMp.value < this.mpMax)
               {
                  this.currentMp.value += 1;
               }
            }
         }
         if(this.actionName == "虚空阵 鸣")
         {
            if(this.frameAt(1,7))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.playSkill("虚空阵 鸣 攻击");
               this.golden = 30;
               if (this.currentMp.value < this.mpMax)
               {
                  this.currentMp.value += 1;
               }
            }
         }
      }

   }
}

