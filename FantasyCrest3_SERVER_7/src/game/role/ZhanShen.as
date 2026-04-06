// 添加斩神白面被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import zygame.data.BeHitData;
   import game.world.BaseGameWorld;
   import zygame.data.RoleFrameGroup;
   import zygame.display.BaseRole
   
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
         if(this.actionName == "虚空阵 素" || this.actionName == "虚空阵 盈" || this.actionName == "虚空阵 鸣" || this.actionName == "虚空阵 尊")
         {
            if(this.frameAt(3,10))
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
         if(this.actionName == "虚空阵 刻杀·雪风")
         {
            if(this.frameAt(3,10))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.runLockAction("刻杀·雪风");
               beData.cardFrame = 120;
            }
         }
         if(this.actionName == "刻杀·雪风" && this.frameAt(-1,16))
         {
            for each(var i:BaseRole in this.world.getRoleList())
            {
               if (i != this)
               {
                  shitingRole(120, i);
                  shitingEffect(120, i);
               }
            }
         }
         if(this.actionName == "虚空阵 刻杀·悪滅")
         {
            if(this.frameAt(5,16))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.runLockAction("刻杀·悪滅");
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
         for each(var i:BaseRole in this.world.getRoleList())
         {
            i.cardFrame = 40;
         }
         (this.world as BaseGameWorld).showSkillPainting(targetName,actionName,troopid);
      }

      // 时停角色
      public function shitingRole(cardFrame:int, role:BaseRole):void
      {
         for each(var i:BaseRole in this.world.getRoleList())
         {
            if(i == role)
            {
               i.cardFrame = cardFrame;
            }
         }
      }

      // 时停特效
      public function shitingEffect(cardFrame:int, role:BaseRole):void
      {
         for each(var i:BaseRole in this.world.getRoleList())
         {
            if(i == role)
            {
               var effect:EffectDisplay = null;
               var num:int = this.world.map.roleLayer.numChildren;
               for(var j:int = 0; j < num; j++)
               {
                  effect = this.world.map.roleLayer.getChildAt(j) as EffectDisplay;
                  if(effect && effect.role == role)
                  {
                     effect.cardFrame = cardFrame;
                  }
               }
            }
         }
      }

   }
}

