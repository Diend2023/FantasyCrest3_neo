// 添加搭档对战联机模式
package game.world
{
   import game.data.Game;
   import game.data.OverTag;
   import game.server.AccessRun3Model;
   import game.server.HostRun2Model;
   import game.view.GameChangeRoleTipsView;
   import game.view.GameOnlineRoomView;
   import game.view.GameOverView;
   import game.view.GameStateView;
   import starling.animation.Tween;
   import starling.core.Starling;
   import zygame.core.SceneCore;
   import zygame.display.BaseRole;
   import zygame.server.Service;
   
   public class _2V2ASSISTOnline extends _2V2ASSIST
   {
      
      private var _isInit:Boolean = false;
      
      public function _2V2ASSISTOnline(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function initRole() : void
      {
         var p3:BaseRole = null;
         var roleTarget:String = null;
         var userData:Object = null;
         super.initRole();
         this.isDoublePlayer = false;
         if(Service.client.type == "player" || Service.client.type == "watching")
         {
            // 交换主控角色，使本地玩家始终控制 p1
            p3 = p1;
            p1 = p2;
            p2 = p3;
            role = p1;
            this.runModel = new AccessRun3Model("role1");
            this.auto = false;
         }
         else
         {
            this.runModel = new HostRun2Model("role0");
            this.auto = false;
         }
         founcDisplay = p1;
         if(!_isInit)
         {
            _isInit = true;
            roleTarget = p1.targetName;
            if(Game.onlineData.getData(roleTarget))
            {
               Game.onlineData.getData(roleTarget).addFightTimes();
               Game.onlineData.getData(roleTarget).isGetUp = true;
               userData = {"ofigth":Game.onlineData.toSaveData()};
               Service.client.send({
                  "type":"update_user_data",
                  "userData":userData
               });
            }
         }
         this.startInitCD();
      }
      
      override public function createChangeTipsView() : void
      {
         if(Service.client.type == "player" || Service.client.type == "watching")
         {
            // 客机模式下，p1 是 Troop 1，p2 是 Troop 0
            // Troop 1 的援助角色在 p2assist 中（因为 outRole 逻辑是固定的）
            // 所以左侧 UI (p1位置) 应该显示 p2assist
            changeRoleView = new GameChangeRoleTipsView(p2assist,p1assist);
            changeRoleView.y = 120;
            changeRoleView.onLeftClick = function():void
            {
               if(p1 && p1.parent)
               {
                  p1.onDown(72); // 触发换人按键
               }
            };
            changeRoleView.onRightClick = function():void
            {
               if(p2 && p2.parent)
               {
                  p2.onDown(conversionKey(96));
               }
            };
            state.addChild(changeRoleView);
         }
         else
         {
            super.createChangeTipsView();
         }
      }
      
      override public function enterRole(prole:BaseRole) : void
      {
         var tw:Tween = null;
         var hrole:BaseRole = null;
         // 如果是客机，需要处理 p1/p2 交换后的逻辑
         if(Service.client.type == "player" || Service.client.type == "watching")
         {
            tween.push(prole);
            tw = new Tween(prole,0.5,"easeIn");
            hrole = null;
            // 客机视角：p1 是 Troop 1, p2 是 Troop 0
            if(prole.troopid == 0)
            {
               hrole = p2;
               p2 = prole;
            }
            else
            {
               hrole = p1;
               p1 = prole;
            }
            prole.display.alpha = 1;
            prole.posx = hrole.x - 200 * prole.scaleX;
            prole.posy = hrole.y - stage.stageHeight;
            if(prole.posx < 60)
            {
               prole.posx = 60;
            }
            else if(prole.posx > map.getWidth() - 60)
            {
               prole.posx = map.getWidth() - 60;
            }
            tw.animate("posx",hrole.x);
            tw.animate("posy",hrole.y);
            tw.onComplete = function():void
            {
               prole.body.space = nape;
               prole.hitBody.space = nape;
               tween.removeAt(tween.indexOf(prole));
            };
            Starling.juggler.add(tw);
            roles.push(prole);
            (state as GameStateView).bind(prole.troopid,prole);
            // 如果进场的是 Troop 1 (客机己方)，则绑定控制权
            if(prole.troopid == 1)
            {
               role = prole;
            }
         }
         else
         {
            super.enterRole(prole);
         }
      }
      
      override public function over() : void
      {
         var i:Object = null;
         var id:int = 0;
         var tag:String = null;
         var over:GameOverView = null;
         for(i in GameOnlineRoomView.roomdata.list)
         {
            GameOnlineRoomView.roomdata.list[i].isReady = false;
         }
         id = cheakGameOver();
         tag = OverTag.NONE;
         if(id == 0 && Service.client.type == "master")
         {
            tag = OverTag.GAME_WIN;
         }
         else if(id == 1 && Service.client.type == "player")
         {
            tag = OverTag.GAME_WIN;
         }
         else if(id == 0 && Service.client.type == "player")
         {
            tag = OverTag.GAME_OVER;
         }
         else if(id == 1 && Service.client.type == "master")
         {
            tag = OverTag.GAME_OVER;
         }
         over = new GameOverView(fightData.data1,fightData.data2,tag);
         over.callBack = function():void
         {
            SceneCore.replaceScene(new GameOnlineRoomView(GameOnlineRoomView.roomdata));
         };
         SceneCore.replaceScene(over);
      }
   }
}