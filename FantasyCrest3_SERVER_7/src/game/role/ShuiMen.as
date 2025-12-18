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
   
   public class ShuiMen extends GameRole
   {

      private var roleKuwu1Dic:Dictionary = new Dictionary();
      
      public function ShuiMen(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }

      override public function onFrame():void
      {
         super.onFrame();
         for(var enemy:Object in roleKuwu1Dic)
         {
            var effectKuwu1:EffectDisplay = roleKuwu1Dic[enemy];
            if(effectKuwu1)
            {
               effectKuwu1.posx = enemy.x - 50;
               effectKuwu1.posy = enemy.y - 200;
            }
         }
         if(this.inFrame("飞雷神2",9))
         {
            tp();
            this.currentFrame == 10;
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole):void
      {
         super.onHitEnemy(beData,enemy);
         var effect8:EffectDisplay = this.world.getEffectFormName("8",this);
         var effectZhan:EffectDisplay = this.world.getEffectFormName("zhan",this);
         if(effect8 || effectZhan)
         {
            var effectKuwu1:EffectDisplay = new EffectDisplay("kuwu1",{blendMode:"normal",rotation:335,time:999},this,1,1);
            effectKuwu1.name = "kuwu1_" + enemy.targetName;
            roleKuwu1Dic[enemy] = effectKuwu1;
            effectKuwu1.posx = enemy.x - 50;
            effectKuwu1.posy = enemy.y - 200;
            effectKuwu1.scaleX = 1;
            effectKuwu1.scaleY = 1;
            (world as BaseGameWorld).addChild(effectKuwu1);
         }
         effect8.removeFromParent();
         effectZhan.removeFromParent();
      }

      private function tp():void
      {
         for(var enemy:Object in roleKuwu1Dic)
         {
            var effectKuwu1:EffectDisplay = roleKuwu1Dic[enemy];
            if(effectKuwu1)
            {
               this.posx = enemy.x - 50 * enemy.scaleX;
               this.posy = enemy.y;
               this.scaleX = enemy.scaleX > 0 ? 1 : -1;
               effectKuwu1.removeFromParent();
               delete roleKuwu1Dic[enemy];
               return;
            }
         }
      }

   }
}

