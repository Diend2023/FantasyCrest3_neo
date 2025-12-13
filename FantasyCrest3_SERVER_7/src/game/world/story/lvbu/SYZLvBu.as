// 添加szylb副本世界父类
package game.world.story.syzlvbu
{
   import game.world._1VStory;
   import zygame.core.PoltCore;
   
   public class SYZLvBu extends _1VStory
   {
      
      public function SYZLvBu(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function onInit() : void
      {
         super.onInit();
      }
      
      override public function over() : void
      {
         super.over();
         PoltCore.removeEvent("syzlb_0_吕布_击败事件");
         PoltCore.changePoltState("","","syzlb_0");
      }
   }
}

