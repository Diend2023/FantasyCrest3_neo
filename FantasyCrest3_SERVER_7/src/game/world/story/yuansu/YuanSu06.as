// 添加剧情副本世界YuanSu05
package game.world.story.yuansu
{
   import game.role.GameRole;
   import zygame.core.PoltCore;

   public class YuanSu06 extends YuanSu
   {
      
      public function YuanSu06(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function onInit() : void
      {
         var anheimolong:GameRole = null;
         var guanggong:GameRole = null;
         super.onInit();
         super.changeNpcPower(this.getRoleFormName("guanggong") as GameRole,2.0,2.0); //
         super.changeNpcPower(this.getRoleFormName("anheimolong") as GameRole,0.75,NaN); //
         if(PoltCore.hasEvent("dnf_yuansu_6_暗黑魔龙_击败事件"))
         {
            anheimolong = this.getRoleFormName("anheimolong") as GameRole;
            anheimolong.discarded();
         }
         if(PoltCore.getPoltState("",this.targetName) && PoltCore.getPoltState("",this.targetName) == "EventOver")
         {
            auto = true;
         }
         else
         {
            auto = false;
            this.role.move("right");
         }
      }
      
      override public function cheakGameOver() : int
      {
         var arr:Array = [];
         for(var i in getRoleList())
         {
            if(arr.indexOf(getRoleList()[i].troopid) == -1)
            {
               arr.push(getRoleList()[i].troopid);
            }
         }
         if(arr.indexOf(0) == -1)
         {
            return arr[0];
         }
         return arr.length <= 1 ? arr[0] : -1;
      }

      override public function onFrame() : void
      {
         super.onFrame();
         var anheimolong:GameRole = null;
         if(this.getRoleFormName("anheimolong") && !PoltCore.hasEvent("dnf_yuansu_6_暗黑魔龙_击败事件"))
         {
            anheimolong = this.getRoleFormName("anheimolong") as GameRole;
            if(anheimolong.attribute.hp <= 0)
            {
               PoltCore.addEvent("dnf_yuansu_6_暗黑魔龙_击败事件");
            }
         }
      }

   }
}

