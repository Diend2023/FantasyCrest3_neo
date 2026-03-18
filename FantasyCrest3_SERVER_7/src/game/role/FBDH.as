package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.data.BeHitData;
   import zygame.display.BaseRole;
   import flash.geom.Point;
   import feathers.data.ListCollection;
   
   public class FBDH extends GameRole
   {
      
      public function FBDH(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
         "icon":"liliang.png",
         "msg":0
         }]);
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole):void
      {
         super.onHitEnemy(beData, enemy);
         if(this.actionName == "虎虎生威")
         {
            // 额外造成敌人当前生命值的6%伤害
            enemy.hurtNumber(enemy.attribute.hp * 0.06,null,new Point(enemy.x,enemy.y));
         }
      }

      override public function onFrame():void
      {
         super.onFrame();
         if(this.attribute.getCD("虎虎生威") <= 0)
         {
            this.listData.getItemAt(0).msg = "Ready";
         }
         else
         {
            this.listData.getItemAt(0).msg = (this.attribute.getCD("虎虎生威") / 60).toFixed(1);
         }
         this.listData.updateItemAt(0);
      }
   }
}

