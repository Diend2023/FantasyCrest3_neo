package game.world
{
   import game.role.GameRole;
   import game.view.GameTipsView;
   import starling.display.Image;
   import zygame.core.DataCore;
   import zygame.core.SceneCore;
   import zygame.display.WorldState;
   import starling.display.Quad; //
   import starling.events.TouchEvent; //
   import starling.events.TouchPhase; //
   
   public class _1VSB extends BaseGameWorld
   {
      
      public function _1VSB(mapName:String, toName:String)
      {
         super(mapName,toName);
         this.isDoublePlayer = true;
      }
      
      override public function initRole() : void
      {
         super.initRole();
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
         return arr.length <= 1 ? 3 : -1;
      }
      
      override public function addStateContent(pstate:WorldState) : void
      {
         var tips:Image = null;
         super.addStateContent(pstate);
         if(pstate)
         {
            tips = new Image(DataCore.getTextureAtlas("hpmp").getTexture("sb_tips.png"));
            pstate.addChild(tips);
            tips.x = 10;
            tips.scale = 0.8;
            tips.y = stage.stageHeight - tips.height - 10;
            // 添加快捷键点击域
            addQuad(pstate, "回血", 0x00FF00, 90, 95, tips.y, 70, tips.height); // 回血
            addQuad(pstate, "满蓝", 0x0000FF, 88, 180, tips.y, 70, tips.height); // 回蓝
            addQuad(pstate, "清理CD", 0xFFFF00, 67, 265, tips.y, 100, tips.height); // 清理CD
            addQuad(pstate, "启用/禁用AI", 0xFF00FF, 86, 380, tips.y, 135, tips.height); // 启用/禁用AI
         }
      }
      
      // 私有函数：添加一个Quad作为点击域
      private function addQuad(pstate:WorldState, target:String, color:uint, key:int, x:Number, y:Number, width:Number, height:Number):void //
      { //
         var quad:Quad = new Quad(width, height, color); //
         quad.y = y; //
         quad.x = x; //
         quad.alpha = 0; //
         pstate.addChild(quad); //
         // 添加触摸事件，模拟onDown
         quad.addEventListener(TouchEvent.TOUCH, function(event:TouchEvent):void //
         { //
            var touch = event.getTouch(quad); //
            if(touch && touch.phase == TouchPhase.ENDED) //
            { //
               onDown(key); //
            } //
         }); //
      } //

      override public function onDown(key:int) : void
      {
         super.onDown(key);
         switch(key)
         {
            case 90:
               SceneCore.pushView(new GameTipsView("启动回血指令"));
               // var _loc6_:int = 0;
               // var _loc5_:* = this.getRoleList();
               // while(§§hasnext(_loc5_,_loc6_))
               // {
               //    var hp:Object = §§nextname(_loc6_,_loc5_);
               //    this.getRoleList()[hp].attribute.hp = this.getRoleList()[hp].attribute.hpmax;
               // }
               var hp:int = 0; // 修复反编译错误，改为正常的for循环
               for(hp = 0; hp < this.getRoleList().length; hp++) //
               { //
                  this.getRoleList()[hp].attribute.hp = this.getRoleList()[hp].attribute.hpmax; //
               } //
               break;
            case 88:
               SceneCore.pushView(new GameTipsView("启动回蓝指令"));
               // var _loc8_:int = 0;
               // var _loc7_:* = this.getRoleList();
               // while(§§hasnext(_loc7_,_loc8_))
               // {
               //    var mp:Object = §§nextname(_loc8_,_loc7_);
               //    (this.getRoleList()[mp] as GameRole).currentMp.value = (this.getRoleList()[mp] as GameRole).mpMax;
               // }
               var mp:int = 0; // 修复反编译错误，改为正常的for循环
               for(mp = 0; mp < this.getRoleList().length; mp++) //
               { //
                  (this.getRoleList()[mp] as GameRole).currentMp.value = (this.getRoleList()[mp] as GameRole).mpMax; //
               } //
               break;
            case 67:
               SceneCore.pushView(new GameTipsView("启动清理CD指令"));
               // var _loc10_:int = 0;
               // var _loc9_:* = this.getRoleList();
               // while(§§hasnext(_loc9_,_loc10_))
               // {
               //    var cd:Object = §§nextname(_loc10_,_loc9_);
               //    this.getRoleList()[cd].attribute.clearCD();
               // }
               var cd:int = 0; // 修复反编译错误，改为正常的for循环
               for(cd = 0; cd < this.getRoleList().length; cd++) //
               { //
                  this.getRoleList()[cd].attribute.clearCD(); //
               } //
               break;
            case 86:
               if(this.getRoleList().length == 2)
               {
                  this.getRoleList()[1].ai = !this.getRoleList()[1].ai;
                  this.getRoleList()[1].stopAllKey();
                  this.getRoleList()[1].move("wait");
                  SceneCore.pushView(new GameTipsView(this.getRoleList()[1].ai ? "启动敌人AI" : "关闭敌人AI"));
               }
         }
      }
   }
}

