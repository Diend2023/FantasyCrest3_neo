// 添加剧情副本世界YuanSu01
package game.world.story.yuansu
{
   import game.role.GameRole;
   import zygame.ai.AiHeart;
   import zygame.core.DataCore;
   import zygame.core.PoltCore;
   import zygame.display.EffectDisplay;
   
   // public class YuanSu01 extends _1VStory
   public class YuanSu01 extends YuanSu // 改为添加的父类yuansu世界
   {
      
      public function YuanSu01(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function onInit() : void
      {
         var r:GameRole = null;
         super.onInit();
         // if(PoltCore.hasEvent("元素感染事件"))
         if(PoltCore.hasEvent("dnf_yuansu_1_刺客_元素感染事件")) // 触发事件
         {
            r = this.getRoleFormName("cike") as GameRole;
            r.discarded();
         }
         else
         {
            auto = false;
            this.role.move("right");
         }
      }
      
      public function Boom() : void
      {
         var r:GameRole = this.getRoleFormName("cike") as GameRole;
         r.discarded();
         var guangyuansu:GameRole = new GameRole("guangyuansu",r.posx,r.posy,this);
         this.addChild(guangyuansu);
         guangyuansu.name = "cike";
         guangyuansu.ai = true;
         guangyuansu.troopid = -1;
         guangyuansu.setAi(new AiHeart(guangyuansu,DataCore.getXml("ordinary")));
         // PoltCore.addEvent("元素感染事件");
         PoltCore.addEvent("dnf_yuansu_1_刺客_元素感染事件"); //
         var effect:EffectDisplay = new EffectDisplay("dianshan",null,guangyuansu,2,2);
         this.addChild(effect);
         effect.posx = guangyuansu.x - 150;
         effect.posy = guangyuansu.y - 600;
         auto = true;
      }

      // 重写检查游戏结束的方法，使得死亡会失败，胜利不结束
      override public function cheakGameOver() : int //
      { //
         var arr:Array = []; //
         for(var i in getRoleList()) //
         { //
            if(arr.indexOf(getRoleList()[i].troopid) == -1) //
            { //
               arr.push(getRoleList()[i].troopid); //
            } //
         } //
         if(arr.length > 1) //
         { //
            return -1; //
         } //
         if(arr.length == 1 && arr.indexOf(0) == -1) //
         { //
            return arr[0]; //
         } //
         return -1; //
      } //

   }
}

