// 添加波风水门
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import zygame.data.BeHitData;
   import zygame.display.BaseRole;
   import flash.utils.Dictionary;
   import game.world.BaseGameWorld;
   import game.view.GameStateView;
   import feathers.data.ListCollection;
   import game.world._FBBaseWorld;
   import flash.geom.Rectangle;
   
   public class ShuiMen extends GameRole
   {

      private var roleKuwu1Dic:Dictionary = new Dictionary();
      
      public function ShuiMen(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([]);
      }

      override public function onFrame():void
      {
         super.onFrame();
         var i:int = 0;
         this.listData.removeAll();
         for(var enemy:BaseRole in roleKuwu1Dic)
         {
            var effectKuwu1:EffectDisplay = roleKuwu1Dic[enemy];
            if(effectKuwu1 && enemy && enemy.attribute)
            {
               effectKuwu1.posx = enemy.x - effectKuwu1.width / 1.75;
               effectKuwu1.posy = enemy.y;
               if(!(this.world is _FBBaseWorld) && this.world.roles.indexOf(enemy) != -1)
               {
                  var listObj:Object = {"icon":"sudu.png","msg":String(enemy.pid) + "P"};
                  this.listData.addItem(listObj);
                  this.listData.updateItemAt(i);
               }
               if(this.world.roles.indexOf(enemy) != -1)
               {
                  effectKuwu1.visible = true;
               }
               else
               {
                  effectKuwu1.visible = false;
               }
               i++;
            }
            else
            {
               effectKuwu1.discarded();
               effectKuwu1.dispose();
               delete roleKuwu1Dic[enemy];
            }
         }
         var j:int = 0;
         for each(var effect:EffectDisplay in this.world.getEffects())
         {
            if(effect.name && effect.name == "kuwu1_land" && effect.role == this)
            {
               this.attribute.updateCD("飞雷神·闪",999);
               j++;
            }
         }
         if(this.inFrame("飞雷神2",9))
         {
            tpRole(0, 0, false, false);
         }
         else if(this.inFrame("WJ",7))
         {
            tpRole(-150, 0, false, true);
         }
         else if(this.inFrame("时空间·螺旋丸",33))
         {
            tpRole(200, 250, true, false);
         }
         else if(this.inFrame("疾风连段·神速真空斩！",9) || this.inFrame("疾风连段·神速真空斩！",38))
         {
            tpRole(0, 0, false, false);
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole):void
      {
         super.onHitEnemy(beData,enemy);
         var effect8:EffectDisplay = this.world.getEffectFormName("8",this);
         var effectZhan:EffectDisplay = this.world.getEffectFormName("zhan",this);
         var effectMy6:EffectDisplay = this.world.getEffectFormName("my6",this);
         var effectC:EffectDisplay = this.world.getEffectFormName("C",this);
         if(this.actionName == "飞雷神2" && effectZhan && effectMy6)
         {
            createKuwu1(enemy);
            effectZhan.discarded();
            effectMy6.discarded();
         }
         else if((this.actionName == "WJ" || this.actionName == "WU" || this.actionName == "龙椎闪") && effectZhan)
         {
            createKuwu1(enemy);
            effectZhan.discarded();
         }
         else if(this.actionName == "飞雷神" && effect8)
         {
            createKuwu1(enemy);
         }
         else if((this.actionName == "SI" || this.actionName == "飞雷神WI") && effectC)
         {
            createKuwu1(enemy);
            effectC.discarded();
         }
         else if(this.actionName == "疾风连段·神速真空斩！" && effectC)
         {
            createKuwu1(enemy);
            effectC.discarded();
         }
      }

      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         super.runLockAction(str,canBreak);
         if(str == "神速")
         {
            var rect:Rectangle = this.body.bounds.toRect();
            rect.width = 800;
            rect.height = 400;
            rect.x = this.x - rect.width / 2;
            rect.y = this.y - 300;
            var role:BaseRole = this.findRole(rect);
            for(var roleKuwu1DicLength:int = 0 in roleKuwu1Dic)
            {
               roleKuwu1DicLength++;
            }
            if(role)
            {
               this.scaleX = this.x < role.x ? 1 : -1;
               this.posx = role.x + 150 * (this.scaleX > 0 ? -1 : 1);
               this.posy = role.y;
            }
            else if(roleKuwu1DicLength > 0)
            {
               tpRole(150, 0, false, false);
            }
            else
            {
               this.playSkill("我tm跑路");
            }
         }
         else if(str == "龙椎闪")
         {
            tpRole(150, 200, true, false);
         }
         else if(str == "飞雷神WU")
         {
            tpRole(150, 0, true, false);
         }
         else if(str == "飞雷神U")
         {
            tpRole(-150, 0, false, false);
         }
         else if(str == "丸子")
         {
            tpRole(150, 50, true, false);
         }
         else if(str == "飞雷神WI")
         {
            tpRole(150, 100, true, false);
         }
         else if(str == "飞雷神I")
         {
            tpRole(100, 0, true, false);
         }
         else if(str == "斩")
         {
            tpRole(150, 100, true, false);

         }
         else if(str == "战略性认怂")
         {
            for each(var effect:EffectDisplay in this.world.getEffects())
            {
               if(effect.name && effect.name == "kuwu1_land" && effect.role == this)
               {
                  tpKuwu1(effect);
                  return;
               }
            }
            tpRole(-150, 0, false, false);
            this.attribute.updateCD("战略性勇敢",6);
         }
         else if(str == "战略性勇敢")
         {
            var i:int = 0;
            for(var enemy:Object in roleKuwu1Dic)
            {
               i++;
            }
            if(i)
            {
               tpRole(-150, 0, false, false);
            }
            else
            {
               for each(var effect:EffectDisplay in this.world.getEffects())
               {
                  if(effect.name && effect.name == "kuwu1_land" && effect.role == this)
                  {
                     tpKuwu1(effect);
                  }
               }
            }
            this.attribute.updateCD("战略性认怂",6);
         }
      }

      private function tpRole(toX:Number, toY:Number, isBehind:Boolean, reverse:Boolean):void
      {
         for(var enemy:Object in roleKuwu1Dic)
         {
            var targetEnemy:BaseRole = enemy as BaseRole;
            var effectKuwu1:EffectDisplay = roleKuwu1Dic[targetEnemy];
            if(effectKuwu1 && targetEnemy && this.world.roles.indexOf(targetEnemy) != -1)
            {
               var enemyDir:int = targetEnemy.scaleX > 0 ? 1 : -1;
               var directionMultiplier:int = isBehind ? -1 : 1;
               this.posx = targetEnemy.x + (toX * directionMultiplier * enemyDir);
               this.posy = targetEnemy.y - toY;
               this.scaleX = (this.x < targetEnemy.x ? 1 : -1) * ((reverse && enemyDir) ? -1 : 1);
               effectKuwu1.discarded();
               effectKuwu1.dispose();
               delete roleKuwu1Dic[targetEnemy];
               return;
            }
         }
      }

      private function createKuwu1(enemy:BaseRole):void
      {
         var effectKuwu1:EffectDisplay = new EffectDisplay("kuwu1",{blendMode:"normal",rotation:335,time:999999},this,1,1);
         effectKuwu1.name = "kuwu1_" + enemy.targetName;
         if(roleKuwu1Dic[enemy])
         {
            var oldEffectKuwu1:EffectDisplay = roleKuwu1Dic[enemy];
            oldEffectKuwu1.discarded();
            oldEffectKuwu1.dispose();
            delete roleKuwu1Dic[enemy];
         }
         roleKuwu1Dic[enemy] = effectKuwu1;
         effectKuwu1.posx = enemy.x - effectKuwu1.width / 1.75;
         effectKuwu1.posy = enemy.y - enemy.height;
         effectKuwu1.scaleX = 1;
         effectKuwu1.scaleY = 1;
         (world as BaseGameWorld).addChild(effectKuwu1);
      }

      private function tpKuwu1(kuwu1Effect:EffectDisplay):void
      {
         this.posx = kuwu1Effect.posx;
         this.posy = kuwu1Effect.posy;
         kuwu1Effect.discarded();
         this.attribute.updateCD("飞雷神·闪",3);
         this.attribute.updateCD("战略性勇敢",6);
         this.attribute.updateCD("战略性认怂",6);
      }

   }
}

