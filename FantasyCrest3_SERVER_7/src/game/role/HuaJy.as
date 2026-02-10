// 添加花京院典明被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.data.BeHitData;
   import zygame.display.BaseRole;
   import feathers.data.ListCollection;
   
   public class HuaJy extends GameRole
   {

      private var resetCDTimer:int = 0; // CD重置计时器
      
      public function HuaJy(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"mofa.png",
            "msg":0
         }]);
      }

      override public function onFrame() : void
      {
         super.onFrame();
         if (resetCDTimer > 0)
         {
            resetCDTimer--;
            this.listData.getItemAt(0).msg = (resetCDTimer / 60).toFixed(1); // 显示剩余时间，单位为秒
         }
         else
         {
            this.listData.getItemAt(0).msg = "Ready";
         }
         this.listData.updateItemAt(0);
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole):void
      {
         super.onHitEnemy(beData, enemy);
         if (this.hit % 10 == 0 && resetCDTimer <= 0 && this.attribute.getCD("绿宝石水花") > 0) // 每10次攻击触发一次被动效果
         {
            this.attribute.updateCD("绿宝石水花", 0); // 将绿宝石水花技能的CD重置为0
            resetCDTimer = 300; // 重置计时器
         }
      }
      
   }
}

