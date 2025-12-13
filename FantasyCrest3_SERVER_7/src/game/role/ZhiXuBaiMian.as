// 添加秩序白面被动
package game.role
{
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import feathers.data.ListCollection;
   import game.world.BaseGameWorld;
   import zygame.display.EffectDisplay;
   import zygame.data.RoleFrameGroup;
   
   public class ZhiXuBaiMian extends GameRole
   {

      private var breakDamTimer:int = 0;
      
      public function ZhiXuBaiMian(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"fangyu.png",
            "msg":"Ready"
         }]);
      }

	   override public function onFrame():void
      {
         super.onFrame();
         // 聚能回水晶实现
         if (inFrame("聚能",11) || inFrame("入场动作",11))
         {
            if (this.currentMp.value < this.mpMax)
            {
               this.currentMp.value += 1;
            }
         }
         if (this.actionName == "聚能" || this.actionName == "入场动作")
         {
            if (this.frameAt(2,12))
            {
               this.addMpPoint(1);
            }
         }
         // 反破防被动计时
         if (this.breakDamTimer > 0)
         {
            this.breakDamTimer -= 1;
            this.listData.getItemAt(0).msg = (this.breakDamTimer / 60).toFixed(1);
         }
         else
         {
            this.listData.getItemAt(0).msg = "Ready";
         }
         this.listData.updateItemAt(0);
      }

      override public function onBeHit(beData:BeHitData) : void
      {
         super.onBeHit(beData);
         // 被破防时获得1s霸体
         if (this.breakDamTimer <= 0)
         {
            if(beData.isBreakDam || (this.actionName == "防御" && !this.isRightInFront(beData.role)))
               {
                  this.clearDebuffMove();
                  this.golden = 60;
                  this.breakDamTimer = 900;
               }
         }
         // 每次被攻击时，增加1点水晶
         if (this.currentMp.value < this.mpMax)
         {
            this.currentMp.value += 1;
         }
         // 防反
         var enemy = beData.role as GameRole;
         if (this.actionName == "虛空陣 悪滅" && this.frameAt(3,20))
         {
            this.clearDebuffMove();
            this.currentFrame = 21;
            if (!enemy.isOSkill())
            {
               enemy.breakAction();
               enemy.straight = 180;
            }
            playSkillPainting("虛空陣 悪滅");
         }
         if (this.actionName == "虚空阵 雪风" && this.frameAt(4,21))
         {
            this.clearDebuffMove();
            this.currentFrame = 22;
            playSkillPainting("虚空阵 雪风");
            this.golden = 60;
            beData.cardFrame = 120;
            for(var i in this.world.getRoleList())
            {
               if (this.world.getRoleList()[i] != this)
               {
                  shitingRole(120, this.world.getRoleList()[i]);
                  shitingEffect(120, this.world.getRoleList()[i]);
               }
            }
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         super.onHitEnemy(beData,enemy);
         if (this.actionName == "聚能")
         {
            if (breakDamTimer >= 720 && this.currentMp.value >= 3 && isKeyDown(80))
            {
               this.playSkill("虚空阵 疾风");
               this.currentMp.value -= 3;
               enemy.breakAction();
               enemy.straight = 120;
            }
         }
      }

      override public function runLockAction(str:String, canBreak:Boolean = false) : void
      {
         // 防反技能释放时取消播放大招动画，重写runLockAction
         var group:RoleFrameGroup = this.roleXmlData.getGroupAt(str);
         if(group && group.key && group.key.indexOf("O") != -1 && actionName != str && str =="虛空陣 悪滅" || str =="虚空阵 雪风")
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
      public function  playSkillPainting(actionName:String):void
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

      // 时停角色
      public function shitingRole(cardFrame:int, role:BaseRole):void
      {
         for(var i in this.world.getRoleList())
         {
            if(this.world.getRoleList()[i] == role)
            {
               this.world.getRoleList()[i].cardFrame = cardFrame;
            }
         }
      }

      // 时停特效
      public function shitingEffect(cardFrame:int, role:BaseRole):void
      {
         for(var i in this.world.getRoleList())
         {
            if(this.world.getRoleList()[i] == role)
            {
               var j:int = 0;
               var effect:EffectDisplay = null;
               var num:int = this.world.map.roleLayer.numChildren;
               for(var j = 0; j < num; j++)
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

