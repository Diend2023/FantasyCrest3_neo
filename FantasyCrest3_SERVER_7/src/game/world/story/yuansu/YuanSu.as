// 添加yuansu副本世界父类
package game.world.story.yuansu
{
   import game.world._1VStory;
   import zygame.core.PoltCore;
   
   public class YuanSu extends _1VStory
   {
      
      public function YuanSu(mapName:String, toName:String)
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
         PoltCore.removeEvent("dnf_yuansu_1_刺客_元素感染事件");
         PoltCore.changePoltState("","","dnf_yuansu_1");
         PoltCore.changePoltState("event2","","dnf_yuansu_1");
         PoltCore.removeEvent("dnf_yuansu_6_暗黑魔龙_击败事件");
         PoltCore.removeEvent("dnf_yuansu_5_艾斯库尔_击败事件");
         PoltCore.changePoltState("","","dnf_yuansu_5");
         PoltCore.changePoltState("","","dnf_yuansu_6");
         PoltCore.changePoltState("","","dnf_yuansu_0");
      }
   }
}

