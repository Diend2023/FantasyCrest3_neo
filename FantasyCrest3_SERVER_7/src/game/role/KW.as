// 添加假面骑士空我的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import feathers.data.ListCollection;
   import zygame.display.World;
   import zygame.core.GameCore;
   import zygame.data.BeHitData;
   import zygame.display.BaseRole;
   import flash.geom.Rectangle; // 抓取用
   
   public class KW extends GameRole
   {
      private var forms:Array = ["Dragon","Pegasus","Titan"]; // 形态数组
      private var currentForm:String; // 当前形态
      private var formTimer:int; // 形态计时器
      private var formMightyUI:Object = {"icon":"liliang.png","msg":"Mighty"}; // 全能形态UI显示
      private var formDragonUI:Object = {"icon":"shuijing.png","msg":"Dragon"}; // 青龙形态UI显示
      private var formPegasusUI:Object = {"icon":"shengcun.png","msg":"Pegasus"}; // 天马形态UI显示
      private var formTitanUI:Object = {"icon":"mofa.png","msg":"Titan"}; // 泰坦形态UI显示
      private var baseCrit:int; // 基础暴击率
      private var baseJumpTimeMax:int; // 基础跳跃次数最大值
      private var haveShiting:Boolean; // 是否拥有一次时停
      // 可以触发时停的技能
      private var shitingSkills:Array = ["瞬步","猛力连打","急速突击","旋空上踢","抓取膝顶","极限冲撞","勇士连击","骑士炎踢","天马I","天马SI","天马WI","形态更换"];
      private var shitingSkill:String; // 已触发时停的技能
      private var hurtMultipleAdd:Number; // 伤害倍数增加
      private var _prevActionName:String = null;
      private var _playedFrameSounds:Object = {};

      public function KW(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.jumpTimeMax = 1; // 初始化跳跃次数最大值
         baseJumpTimeMax = 1; // 初始化基础跳跃次数最大值
         listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":"Mighty"
         }]);
      }

      override public function onInit() : void
      {
         super.onInit();
         // 初始化
         formTimer = 0;
         currentForm = "Mighty";
         baseCrit = this.attribute.crit;
         haveShiting = false;
         shitingSkill = null;
         hurtMultipleAdd = 0;
         this.attribute.crit = baseCrit + 5;
      }

	   override public function onFrame():void
      {
         super.onFrame();

         // 调试用
         // if (actionName == "普通攻击")
         // {
         //    trace("baseCrit: " + baseCrit);
         //    trace("baseJumpTimeMax: " + baseJumpTimeMax);
         //    trace("haveShiting: " + haveShiting);
         //    trace("hurtMultipleAdd: " + hurtMultipleAdd);
         //    trace("this.attribute.crit: " + this.attribute.crit);
         // }

         // 去除重复帧需要播放的音效
         if(_prevActionName != actionName)
         {
            _prevActionName = actionName;
            try
            {
               _playedFrameSounds[actionName] = {};
            }
            catch(e:Error)
            {

            }
         }
         if(actionName == "形态更换")
         {
            // 形态更换音效强制播放
            if (currentFrame == 1)
            {
               var playedMap:Object = _playedFrameSounds[actionName] || (_playedFrameSounds[actionName] = {});
               if(!playedMap[currentFrame])
               {
                  GameCore.soundCore.playEffect("jmqsKW45");
                  playedMap[currentFrame] = true;
               }
            }

            // 形态更换逻辑实现
            if (currentFrame == 5)
            {
               currentForm = forms[Math.floor(Math.random() * forms.length)];
               formTimer = 600;
               switch(currentForm)
               {
                  case "Dragon":
                     playSkill("青龙形态");
                     listData.getItemAt(0).icon = formDragonUI.icon;
                     listData.getItemAt(0).msg = formDragonUI.msg;
                     this.attribute.crit = baseCrit;
                     this.jumpTimeMax = baseJumpTimeMax + 1;
                     haveShiting = false;
                     hurtMultipleAdd = 0;
                     break;
                  case "Pegasus":
                     playSkill("天马形态");
                     listData.getItemAt(0).icon = formPegasusUI.icon;
                     listData.getItemAt(0).msg = formPegasusUI.msg;
                     this.attribute.crit = baseCrit;
                     this.jumpTimeMax = baseJumpTimeMax;
                     haveShiting = true;
                     hurtMultipleAdd = 0;
                     break;
                  case "Titan":
                     playSkill("泰坦形态");
                     listData.getItemAt(0).icon = formTitanUI.icon;
                     listData.getItemAt(0).msg = formTitanUI.msg;
                     this.attribute.crit = baseCrit;
                     this.jumpTimeMax = baseJumpTimeMax;
                     haveShiting = false;
                     hurtMultipleAdd = 0.2;
               }
            }
         }

         // 天马形态首次技能时停逻辑实现
         if (currentForm == "Pegasus" && haveShiting)
         {
            // 时停技能第一帧记录该技能
            if (!shitingSkill && shitingSkills.indexOf(this.actionName) != -1)
            {
               shitingSkill = this.actionName;
               for(var j in this.world.getRoleList())
               {
                  if (this.world.getRoleList()[j] != this)
                  {
                     shiting(2, this.world.getRoleList()[j]);
                  }
               }
            }
            // 时停技能后续帧保持时停
            else if (this.actionName == shitingSkill && shitingSkill != null)
            {
               for(var k in this.world.getRoleList())
               {
                  if (this.world.getRoleList()[k] != this)
                  {
                     shiting(2, this.world.getRoleList()[k]);
                  }
               }
            }
            // 时停技能结束
            else if (this.actionName != shitingSkill && shitingSkill != null)
            {
               shitingSkill = null;
               haveShiting = false;
            }
         }

         // 形态更换倒计时逻辑实现
         if(formTimer > 0)
         {
            formTimer--;
            if (formTimer > 0)
            {
               this.listData.getItemAt(0).msg = int(formTimer / 60) + "s";
            }
            // 形态更换倒计时结束，切换为全能形态
            else
            {
               currentForm = "Mighty";
               listData.getItemAt(0).icon = formMightyUI.icon;
               listData.getItemAt(0).msg = formMightyUI.msg;
               this.attribute.crit = baseCrit + 5;
               this.jumpTimeMax = baseJumpTimeMax;
               haveShiting = false;
               hurtMultipleAdd = 0;
            }
         }

         // EX技能抓取逻辑实现
         if(actionName == "【EX】Ultimate Smash")
         {
            // 抓取判定
            if (currentFrame == 1)
            {
               var isHand:Boolean;
               isHand = hand(100,100,100,200,0,0);
            }
            // 抓取效果
            if (frameAt(3,10) && isHand)
            {
               hand(100,100,100,200,30,75);
            }
         }


         this.listData.updateItemAt(0);
      }

	   override public function runLockAction(str:String, canBreak:Boolean = false) : void
      {
         super.runLockAction(str, canBreak);
         // 生命值低于30%时SO替换为EX技能逻辑实现
         if (str == "Ultimate Smash" && this.attribute.hp <= this.attribute.hpmax * 0.3)
         {
            this.actionName = "【EX】Ultimate Smash";
            return;
         }

         // 不同形态的技能替换逻辑实现
         if (currentForm == "Mighty")
         {
            return;
         }
         if (currentForm == "Dragon")
         {
            switch(str)
            {
               case "燃烧突击":
                  this.actionName = "青龙I";
                  break;
               case "火焰闪打":
                  this.actionName = "青龙SI";
                  break;
               case "爆裂拳击":
                  this.actionName = "青龙WI";
            }
            return;
         }
         if (currentForm == "Pegasus")
         {
            switch(str)
            {
               case "燃烧突击":
                  this.actionName = "天马I";
                  break;
               case "火焰闪打":
                  this.actionName = "天马SI";
                  break;
               case "爆裂拳击":
                  this.actionName = "天马WI";
            }
            return;
         }
         if (currentForm == "Titan")
         {
            switch(str)
            {
               case "燃烧突击":
                  this.actionName = "泰坦I";
                  break;
               case "火焰闪打":
                  this.actionName = "泰坦SI";
                  break;
               case "爆裂拳击":
                  this.actionName = "泰坦WI";
            }
            return;
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         if(beData.armorScale == 0)
         {
            beData.armorScale = 1;
         }
         // 泰坦形态伤害加成逻辑实现
         beData.armorScale += hurtMultipleAdd;
         super.onHitEnemy(beData,enemy);
      }

      // 时停效果实现
      public function shiting(cardFrame:int, role:BaseRole):void
      {
         for(var i in this.world.getRoleList())
         {
            if(this.world.getRoleList()[i] == role)
            {
               this.world.getRoleList()[i].cardFrame = cardFrame;
            }
         }
      }

      // 抓取逻辑实现
      public function hand(topRange:int = 200, bottomRange:int = 200, backRange:int = 100, frontRange:int = 200,  toX:int = 0, toY:int = 0):Boolean
      {
          var rect:Rectangle = this.body.bounds.toRect();
          // 横向判定
          if(this.scaleX > 0)
          {
              rect.width += frontRange;
              rect.x -= backRange;
              rect.width += backRange;
          }
          else
          {
              rect.x -= frontRange;
              rect.width += frontRange;
              rect.width += backRange;
          }
          // 纵向判定
          rect.y -= topRange;
          rect.height += topRange;
          rect.height += bottomRange;
      
          // 修正左边界
          if(rect.x < 0)
          {
              rect.width += rect.x; // 把溢出的部分减掉
              rect.x = 0;
              toX = 0;
          }
          // 修正右边界
          if(rect.x + rect.width > world.map.getWidth())
          {
              rect.width = world.map.getWidth() - rect.x;
              toX = 0;
          }
      
          if(rect.width > 0 && rect.height > 0)
          {
              var role:BaseRole = findRole(rect);
              if(role)
              {
                  role.clearDebuffMove();
                  role.straight = 30;
                  role.setX(this.x + toX * this.scaleX);
                  role.setY(this.y - toY);
                  return true;
              }
          }
          return false;
      }

   }
}

