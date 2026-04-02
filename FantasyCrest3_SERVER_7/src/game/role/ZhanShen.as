// 添加斩神白面被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import zygame.data.BeHitData;
   import game.world.BaseGameWorld;
   import zygame.data.RoleFrameGroup;
   
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
         var effectYuanQiDan:EffectDisplay = this.world.getEffectFormName("YuanQiDan", this);
         if(effectYuanQiDan && this.actionName != "刻杀·雪风" && this.actionName != "刻杀·悪滅")
         {
            effectYuanQiDan.discarded();
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
         if(this.actionName == "虚空阵 刻杀·雪风")
         {
            if(this.frameAt(2,8))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.playSkillPainting("刻杀·雪风");
               this.runLockAction("刻杀·雪风");
            }
         }
      }

      override public function runLockAction(str:String, canBreak:Boolean = false) : void
      {
         // 防反技能释放时取消播放大招动画，重写runLockAction
         var group:RoleFrameGroup = this.roleXmlData.getGroupAt(str);
         if(group && group.key && group.key.indexOf("O") != -1 && actionName != str && str =="虚空阵 刻杀·雪风" || str =="虚空阵 刻杀·悪滅")
         {
            if(group && group["mp"])
            {
               usePoint(int(group["mp"]));
            }
            if(!isLock)
            {
               if(isKeyDown(65))
               {
                  this.scaleX = -1;
               }
               else if(isKeyDown(68))
               {
                  this.scaleX = 1;
               }
            }
            this.action = str;
            this.isLock = true;
            this.canBreakAction = canBreak;
            return;
         }
         super.runLockAction(str,canBreak);
      }

      // 播放大招动画
      public function playSkillPainting(actionName:String):void
      {
         var effect:EffectDisplay = new EffectDisplay("bisha",null,this,1.5,1.5);
         effect.x = this.x;
         effect.y = this.y;
         this.world.addChild(effect);
         effect.fps = 24;
         for(var i in this.world.getRoleList())
         {
            this.world.getRoleList()[i].cardFrame = 40;
         }
         (this.world as BaseGameWorld).showSkillPainting(targetName,actionName,troopid);
      }

   }
}

