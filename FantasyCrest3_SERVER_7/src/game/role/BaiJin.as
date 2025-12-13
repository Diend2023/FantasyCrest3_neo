// 添加白金被动
package game.role
{
   import flash.utils.Dictionary;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.BaseRole;
   import zygame.display.World;
   import feathers.data.ListCollection;
   
   public class BaiJin extends GameRole
   {
      private var enemyBaseMagicDefense:Dictionary = new Dictionary();
      
      public function BaiJin(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"fangyu.png",
            "msg":0
         }]);
      }

      override public function onFrame() : void
      {
         super.onFrame();
         // 连击数为0时，重置敌人魔防
         for(var enemy:BaseRole in enemyBaseMagicDefense)
         {
            if(enemy && enemy.beHitCount == 0)
            {
               enemy.attribute.magicDefense = enemyBaseMagicDefense[enemy];
               this.listData.getItemAt(0).msg = enemy.attribute.magicDefense;
               this.listData.updateItemAt(0);
            }
         }
      }
      
      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         // 记录敌人初始魔防
         if(enemyBaseMagicDefense[enemy] == undefined)
         {
            enemyBaseMagicDefense[enemy] = enemy.attribute.magicDefense;
         }
         // 低于5连击数时，重置魔防
         if(enemy.beHitCount < 5 && enemyBaseMagicDefense[enemy] != undefined)
         {
            enemy.attribute.magicDefense = enemyBaseMagicDefense[enemy];
         }
         // 每5连击数，降低10%魔防
         if(enemy.beHitCount >= 5 && enemy.beHitCount % 5 == 0)
         {
            var fiveHitCount:int = enemy.beHitCount / 5;
            var newMagicDefense:int = enemyBaseMagicDefense[enemy];
            for(var i:int = 0; i < fiveHitCount; i++)
            {
               newMagicDefense = int(newMagicDefense * 0.9);
            }
            enemy.attribute.magicDefense = newMagicDefense;
         }
         super.onHitEnemy(beData,enemy);
         this.listData.getItemAt(0).msg = enemy.attribute.magicDefense;
         this.listData.updateItemAt(0);
      }
   }
}

