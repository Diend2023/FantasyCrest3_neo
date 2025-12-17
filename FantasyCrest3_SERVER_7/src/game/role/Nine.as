// 添加奈茵被动
package game.role
{
   import feathers.data.ListCollection;
   import game.world.BaseGameWorld;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   
   public class Nine extends GameRole
   {
      
      public function Nine(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":"0%"
         },
         {
            "icon":"mofa.png",
            "msg":"0%"
         }]);
      }
      
      // 计算每秒伤害
      public function get timeHurt() : int
      {
         return hurt / ((world as BaseGameWorld).frameCount / 60);
      }
      
      override public function onFrame() : void
      {
         super.onFrame();
         // 更新每秒伤害显示
         var hurt:int = timeHurt;
         if(hurt < 200)
         {
            this.listData.getItemAt(0).msg = "25%";
            this.listData.getItemAt(1).msg = "25%";
         }
         else
         {
            this.listData.getItemAt(0).msg = "0%";
            this.listData.getItemAt(1).msg = "0%";
         }
         this.listData.updateAll();
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         // 根据每秒伤害增加伤害比例
         var hurt:int = timeHurt;
         if(hurt < 200)
         {
            if(beData.armorScale == 0)
            {
               beData.armorScale = 1;
            }
            if(beData.magicScale == 0)
            {
               beData.magicScale = 1;
            }
            beData.armorScale += 0.25;
            beData.magicScale += 0.25;
         }
         super.onHitEnemy(beData,enemy);
      }
   }
}

