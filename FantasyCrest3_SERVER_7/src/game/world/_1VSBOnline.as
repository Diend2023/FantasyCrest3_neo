// 添加联机练习模式
package game.world
{
   import game.role.GameRole;
   import zygame.core.SceneCore;
   import zygame.display.WorldState;
   import game.view.GameStateView;
   import game.data.Game;
   import game.data.OverTag;
   import game.server.AccessRun3Model;
   import game.server.HostRun2Model;
   import game.view.GameOnlineRoomView;
   import game.view.GameOverView;
   import game.view.GameTipsView;
   import zygame.core.SceneCore;
   import zygame.core.GameCore;
   import zygame.display.BaseRole;
   import zygame.server.Service;

   public class _1VSBOnline extends _1VSB
   {

      private var _isInit:Boolean = false;
      
      public function _1VSBOnline(mapName:String, toName:String)
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
            Game.onlineData.getData(roleTarget).addFightTimes();
            Game.onlineData.getData(roleTarget).isGetUp = true;
            userData = {"ofigth":Game.onlineData.toSaveData()};
            Service.client.send({
               "type":"update_user_data",
               "userData":userData
            });
         }
         setupSandboxCmdSync();
         this.startInitCD();
      }

      // 拦截 UDP 消息，处理联机练习模式快捷键同步 //
      private function setupSandboxCmdSync() : void
      {
         var self:_1VSBOnline = this;
         var originalUdpFunc:Function = Service.client.udpFunc;

         Service.client.udpFunc = function(data:Object) : void
         {
            if(data.target == "sandboxCmd")
            {
               // toggleAi 客机只显示 tips，不执行（避免双端重复切换）//
               if(data.cmd == "toggleAi" && Service.client.type != "master")
               {
                  SceneCore.pushView(new GameTipsView(self.getRoleList()[data.idx].ai ? "启动敌人AI" : "关闭敌人AI"));
               }
               else
               {
                  self.executeSandboxCmd(data.cmd, data.idx);
               }
            }
            else
            {
               if(originalUdpFunc != null)
                  originalUdpFunc(data);
            }
         };
      }

      // 房主执行快捷键指令，逻辑参考 _1VSB.onDown //
      private function executeSandboxCmd(cmd:String, idx:int = 1) : void
      {
         var hp:int = 0;
         var mp:int = 0;
         var cd:int = 0;
         switch(cmd)
         {
            case "heal":
               SceneCore.pushView(new GameTipsView("启动回血指令"));
               for(hp = 0; hp < this.getRoleList().length; hp++)
               {
                  this.getRoleList()[hp].attribute.hp = this.getRoleList()[hp].attribute.hpmax;
               }
               break;
            case "mp":
               SceneCore.pushView(new GameTipsView("启动回蓝指令"));
               for(mp = 0; mp < this.getRoleList().length; mp++)
               {
                  (this.getRoleList()[mp] as GameRole).currentMp.value = (this.getRoleList()[mp] as GameRole).mpMax;
               }
               break;
            case "clearCd":
               SceneCore.pushView(new GameTipsView("启动清理CD指令"));
               for(cd = 0; cd < this.getRoleList().length; cd++)
               {
                  this.getRoleList()[cd].attribute.clearAllCD();
               }
               break;
            case "toggleAi":
               if(this.getRoleList().length == 2)
               {
                  this.getRoleList()[idx].ai = !this.getRoleList()[idx].ai;
                  this.getRoleList()[idx].stopAllKey();
                  this.getRoleList()[idx].move("wait");
                  SceneCore.pushView(new GameTipsView(this.getRoleList()[idx].ai ? "启动敌人AI" : "关闭敌人AI"));
               }
               break;
            case "reset":
               this.reset();
               break;
            case "endGame":
               ((this.state as GameStateView)).pushWin(0);
               ((this.state as GameStateView)).pushWin(0);
               this.gameOver();
               break;
         }
      }
      
      override public function onDown(key:int) : void
      {
         var cmd:String = null;
         switch(key)
         {
            case 90:
               cmd = "heal"; // 回血
               SceneCore.pushView(new GameTipsView("启动回血指令"));
               break;
            case 88:
               cmd = "mp"; // 回蓝
               SceneCore.pushView(new GameTipsView("启动回蓝指令"));
               break;
            case 67:
               cmd = "clearCd"; // 清理CD
               SceneCore.pushView(new GameTipsView("启动清理CD指令"));
               break;
            case 86:
               cmd = "toggleAi"; // 切换AI
               var aiTipIdx:int = (Service.client.type == "master" ? 1 : 0);
               SceneCore.pushView(new GameTipsView(this.getRoleList()[aiTipIdx].ai ? "启动敌人AI" : "关闭敌人AI"));
               break;
            case 8:
               cmd = "reset"; // 重置练习
               break;
            case 82:
               cmd = "endGame"; // 结束练习
               break;
         }
         if(cmd)
         {
            var data:Object = {"target":"sandboxCmd","cmd":cmd};
            if(cmd == "toggleAi")
               data.idx = (Service.client.type == "master" ? 1 : 0);
            Service.radioUDP({"type":"radio","data":data});
            // sender 也执行一次 //
            this.executeSandboxCmd(cmd);
            return;
         }
         if(key == 13)
         {
            if(!GamePauseView1VSBOnline.isOpen)
            {
               SceneCore.pushView(new GamePauseView1VSBOnline());
            }
            return;
         }
         super.onDown(key);
      }
      override public function over() : void
      {
         var i:Object;
         var id:int;
         var tag:String;
         var over:GameOverView;
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

// 联机练习暂停菜单，继承 GamePauseView 仅保留 3 个按钮
import game.display.CommonButton;
import game.view.GameOnlineRoomView;
import game.view.GamePauseView;
import game.view.GameSettingsView;
import starling.display.Quad;
import zygame.core.GameCore;
import zygame.core.SceneCore;
import game.view.GameStateView;

class GamePauseView1VSBOnline extends GamePauseView
{
   internal static var isOpen:Boolean = false; // 供 _1VSBOnline 查询 //
   private var _justCreated:Boolean = true; // 防同帧 key 穿透关闭 //

   override public function onInit() : void
   {
      _justCreated = true;
      isOpen = true;
      var bg:Quad = new Quad(stage.stageWidth, stage.stageHeight, 0);
      this.addChild(bg);
      bg.alpha = 0.5;

      createBtn("结束练习", stage.stageHeight / 2 - 84,  82);
      createBtn("继续游戏", stage.stageHeight / 2 - 42,  13);
      createBtn("设置",stage.stageHeight / 2 + 0,        83);
      createBtn("重置练习", stage.stageHeight / 2 + 42,   8);
      this.openKey();
   }

   override public function createBtn(target:String, y:int, key:int) : void
   {
      var exit:CommonButton = new CommonButton("btn_style_1","start_main",target);
      this.addChild(exit);
      exit.scale = 100 / exit.width;
      exit.x = stage.stageWidth / 2;
      exit.y = y;
      exit.callBack = function():void
      {
         onDown(key);
      };
   }

   override public function onDown(key:int) : void
   {
      if(_justCreated)
      {
         _justCreated = false;
         return;
      }
      switch(key)
      {
         case 13: // 继续游戏 → 仅关闭菜单
            this.clearKey();
            this.removeFromParent(true);
            isOpen = false;
            return;
         case 8:  // 重置练习 → 走 sandboxCmd 同步双方
         case 82: // 结束练习 → 走 sandboxCmd 同步双方
            this.clearKey();
            this.removeFromParent(true);
            isOpen = false;
            GameCore.currentWorld.onDown(key);
            return;
         case 83: // 设置 → 不注销键盘，保持监听 //
            SceneCore.pushView(new GameSettingsView());
            return;
         case 69:
            return;
         case 81:
            return;
         case 88:
            return;
         default:
            super.onDown(key);
      }
   }
}
