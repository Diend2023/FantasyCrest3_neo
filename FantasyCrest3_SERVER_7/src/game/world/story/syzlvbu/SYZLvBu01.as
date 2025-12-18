// 添加剧情副本世界SYZLvBu01
package game.world.story.syzlvbu
{
   import zygame.core.PoltCore;
   import game.role.GameRole;
   
   public class SYZLvBu01 extends SYZLvBu
   {
      
      public function SYZLvBu01(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function onInit() : void
      {
         super.onInit();
         var lvbu:GameRole = null;
         lvbu = this.getRoleFormName("lvbu") as GameRole;
         super.changeNpcPower(lvbu,3,1.1); // 三倍属性，1.1倍大小
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

   }
}

