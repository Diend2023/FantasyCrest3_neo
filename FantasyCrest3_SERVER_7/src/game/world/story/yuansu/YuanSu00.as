// 添加剧情副本世界YuanSu00
package game.world.story.yuansu
{

   public class YuanSu00 extends YuanSu
   {
      
      public function YuanSu00(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function onInit() : void
      {
         super.onInit();
      }

      // 重写检查游戏结束的方法，使得死亡会失败，胜利不结束
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

   }
}

