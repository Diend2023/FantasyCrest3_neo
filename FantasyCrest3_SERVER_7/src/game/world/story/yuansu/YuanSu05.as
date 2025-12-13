// 添加剧情副本世界YuanSu06
package game.world.story.yuansu
{
   import game.role.GameRole;
   import zygame.core.PoltCore;

   public class YuanSu05 extends YuanSu
   {
      
      public function YuanSu05(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function onInit() : void
      {
         var huolongaisi:GameRole = null;
         super.onInit();
         if(PoltCore.hasEvent("dnf_yuansu_5_艾斯库尔_击败事件"))
         {
            huolongaisi = this.getRoleFormName("huolongaisi") as GameRole;
            huolongaisi.discarded();
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
         if(arr.length > 1)
         {
            return -1;
         }
         if(arr.length == 1 && arr.indexOf(0) == -1)
         {
            return arr[0];
         }
         return -1;
      }

      override public function onFrame() : void
      {
         super.onFrame();
         if(this.getRoleFormName("huolongaisi") && !PoltCore.hasEvent("dnf_yuansu_5_艾斯库尔_击败事件"))
         {
            var huolongaisi:GameRole = this.getRoleFormName("huolongaisi") as GameRole;
            if(huolongaisi.attribute.hp <= 0)
            {
               PoltCore.addEvent("dnf_yuansu_5_艾斯库尔_击败事件");
            }
         }
      }
   }
}

