package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   import game.server.AccessRun3Model;
   import game.server.ReplayRunModel;
   
   public class ZiWan extends GameRole
   {
      
      // 冷却缩减量：60帧 = 1秒（cdData 以逻辑帧为单位，由 BaseRole.onFrame 里的 updateAllCD 每帧减 1）
      private static const CD_REDUCE_FRAME:int = 60;
      
      // cdData 中 >= 该值的项视为封印/未解锁（updateAllCD 同样会跳过），不参与随机缩减
      private static const CD_SEALED:int = 50000;
      
      public function ZiWan(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }
      
      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         super.onHitEnemy(beData,enemy);
         // 客机/回放不做本地结算，避免随机结果与主机不一致
         if(world.runModel is AccessRun3Model || world.runModel is ReplayRunModel)
         {
            return;
         }
         this.reduceRandomCD(CD_REDUCE_FRAME);
      }
      
      // 随机挑一个正在冷却中的技能，缩短指定帧数
      private function reduceRandomCD(frames:int) : void
      {
         var cds:Object = this.attribute.cdData;
         if(!cds)
         {
            return;
         }
         var names:Array = [];
         var value:int = 0;
         for(var name:String in cds)
         {
            value = int(cds[name]);
            if(value > 0 && value < CD_SEALED)
            {
               names.push(name);
            }
         }
         if(names.length == 0)
         {
            return;
         }
         var key:String = names[int(Math.random() * names.length)] as String;
         cds[key] = int(cds[key]) - frames;
         if(cds[key] <= 0)
         {
            // 与 updateAllCD 的清理规则保持一致
            delete cds[key];
         }
         // 主机端把新的 cdData 整包同步给客机（沿用技能释放时的同步通道）
         if(world.runModel)
         {
            world.runModel.onCDChange(this,key);
         }
      }

   }
}
