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
            effectKuwu1.posx = (world.state as GameStateView)._tips[enemy.pid - 1].x - effectKuwu1.width / 1.75;
            effectKuwu1.posy = enemy.y + enemy.display.y * (enemy.getRawScaleY() * (enemy.contentScale + (1 - enemy.contentScale)));
            var listObj:Object = {"icon":"sudu.png","msg":String(enemy.pid) + "P"};
            this.listData.addItem(listObj);
            this.listData.updateItemAt(i);
            i++;
            }
            else
            {
               effectKuwu1.discarded();
               effectKuwu1.dispose();
               delete roleKuwu1Dic[enemy];
            }
         }
         if(this.inFrame("飞雷神2",9))
         {
            tpRole(0, 0, false);
         }
         else if(this.inFrame("WJ",7))
         {
            tpRole(-150, 0, false);
         }
         else if(this.inFrame("飞雷神WU",1))
         {
            tpRole(150, 0, true);
         }
         else if(this.inFrame("飞雷神U",1))
         {
            tpRole(-150, 0, false);
         }
         else if(this.inFrame("丸子",1))
         {
            tpRole(150, 50, true);
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
            effect8.discarded();
         }
         else if((this.actionName == "SI" || this.actionName == "飞雷神WI") && effectC)
         {
            createKuwu1(enemy);
            effectC.discarded();
         }
      }

      private function tpRole(toX:Number, toY:Number, isBehind:Boolean):void
      {
         for(var enemy:Object in roleKuwu1Dic)
         {
            var targetEnemy:BaseRole = enemy as BaseRole;
            var effectKuwu1:EffectDisplay = roleKuwu1Dic[targetEnemy];
            if(effectKuwu1 && targetEnemy)
            {
               var enemyDir:int = targetEnemy.scaleX > 0 ? 1 : -1;
               var directionMultiplier:int = isBehind ? -1 : 1;
               this.posx = targetEnemy.x + (toX * directionMultiplier * enemyDir);
               this.posy = targetEnemy.y - toY;
               this.scaleX = (isBehind ? enemyDir : -enemyDir);
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
         effectKuwu1.posx = (world.state as GameStateView)._tips[enemy.pid - 1].x - effectKuwu1.width / 1.75;
         effectKuwu1.posy = enemy.y - enemy.height;
         effectKuwu1.scaleX = 1;
         effectKuwu1.scaleY = 1;
         (world as BaseGameWorld).addChild(effectKuwu1);
      }

   }
}

