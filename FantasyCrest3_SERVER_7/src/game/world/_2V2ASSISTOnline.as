// 添加搭档对战联机模式
package game.world
{
   import game.data.Game;
   import game.data.OverTag;
   import game.server.AccessRun3Model;
   import game.server.HostRun2Model;
   import game.server.KeyRunModel;
   import game.view.GameChangeRoleTipsView;
   import game.view.GameOnlineRoomView;
   import game.view.GameOverView;
   import game.view.GameStateView;
   import starling.animation.Tween;
   import starling.core.Starling;
   import zygame.core.SceneCore;
   import zygame.display.BaseRole;
   import zygame.server.Service;
   import game.role.GameRole;
   
   public class _2V2ASSISTOnline extends _2V2ASSIST
   {
      
      private var _isInit:Boolean = false;
      
      // 记录本客户端控制的队伍ID（房主=0，客机=1）
      private var _myTroopId:int = 0;
      
      // 记录本客户端控制角色的标识名
      private var _myRoleTarget:String = "role0";
      
      public function _2V2ASSISTOnline(mapName:String, toName:String)
      {
         super(mapName,toName);
      }
      
      override public function initRole() : void
      {
         var roleTarget:String = null;
         var userData:Object = null;
         
         // 调用父类的initRole设置基本角色配置
         super.initRole();
         
         this.isDoublePlayer = false;
         
         // 根据客户端类型设置控制角色和运行模式
         // 角色分配：role0=p1(troopid=0), role1=p1assist, role2=p2(troopid=1), role3=p2assist
         if(Service.client.type == "player" || Service.client.type == "watching")
         {
            // 客机控制p2（troopid=1），对应role2
            _myTroopId = 1;
            _myRoleTarget = "role2";
            role = p2;
            founcDisplay = p2;
            this.runModel = new AccessRun3Model(_myRoleTarget);
            this.auto = false;
         }
         else
         {
            // 房主控制p1（troopid=0），对应role0
            _myTroopId = 0;
            _myRoleTarget = "role0";
            role = p1;
            founcDisplay = p1;
            this.runModel = new HostRun2Model(_myRoleTarget);
            this.auto = false;
         }
         
         // 初始化在线数据
         if(!_isInit)
         {
            _isInit = true;
            roleTarget = role.targetName;
            Game.onlineData.getData(roleTarget).addFightTimes();
            Game.onlineData.getData(roleTarget).isGetUp = true;
            userData = {"ofigth":Game.onlineData.toSaveData()};
            Service.client.send({
               "type":"update_user_data",
               "userData":userData
            });
         }
         
         // 为客机设置换人同步消息处理
         setupReplaceRoleSync();
         
         this.startInitCD();
      }
      
      // 设置换人同步处理
      private function setupReplaceRoleSync():void
      {
         if(Service.client.type == "player" || Service.client.type == "watching")
         {
            var self:_2V2ASSISTOnline = this;
            var originalUdpFunc:Function = Service.client.udpFunc;
            
            Service.client.udpFunc = function(data:Object):void
            {
               if(data.target == "replaceRole")
               {
                  // 客机收到换人同步消息，执行换人
                  // 使用 troopId 确定需要换人的队伍
                  var troopId:int = int(data.troopId);
                  var currentRole:GameRole = (troopId == 0 ? self.p1 : self.p2) as GameRole;
                  if(currentRole)
                  {
                     self.executeReplaceRole(currentRole);
                  }
               }
               else
               {
                  // 调用原始处理器
                  if(originalUdpFunc != null)
                  {
                     originalUdpFunc(data);
                  }
               }
            };
         }
      }
      
      // 执行换人逻辑（不发送网络消息，用于客机同步）
      public function executeReplaceRole(prole:GameRole):void
      {
         var arr:Array = this["p" + (prole.troopid + 1) + "assist"];
         // 检查前置条件：角色未锁定、有足够MP、不在换人动画中、有可用替补角色
         if(!prole.isLock && prole.currentMp.value > 0 && tween.indexOf(prole) == -1 && arr && arr.length > 0)
         {
            arr[0].scaleX = prole.currentScaleX > 0 ? 1 : -1;
            (arr[0] as BaseRole).clearDebuffMove();
            enterRole(arr[0]);
            arr.shift();
            outRole(prole);
            prole.move("wait");
            prole.usePoint(1);
            if(changeRoleView)
            {
               changeRoleView.update();
            }
         }
      }
      
      // 客机端只使用1P按键（WASD、HJKLUIOP），忽略2P按键（方向键、小键盘数字）
      // 这与 _1V1Online 的行为一致
      override public function onDown(key:int) : void
      {
         if(Service.client.type == "player")
         {
            // 客机：只允许1P按键，忽略2P按键
            if(is2PKey(key))
            {
               return; // 忽略2P按键
            }
         }
         super.onDown(key);
      }
      
      override public function onUp(key:int) : void
      {
         if(Service.client.type == "player")
         {
            // 客机：只允许1P按键，忽略2P按键
            if(is2PKey(key))
            {
               return; // 忽略2P按键
            }
         }
         super.onUp(key);
      }
      
      // 判断是否为2P按键（方向键、小键盘数字）
      private function is2PKey(key:int):Boolean
      {
         switch(key)
         {
            case 37: // 左
            case 39: // 右
            case 38: // 上
            case 40: // 下
            case 49: case 97:  // 1
            case 50: case 98:  // 2
            case 51: case 99:  // 3
            case 52: case 100: // 4
            case 53: case 101: // 5
            case 54: case 102: // 6
            case 55: case 103: // 7
            case 57: case 105: // 9
            case 48: case 96:  // 0
               return true;
            default:
               return false;
         }
      }
      
      override public function createChangeTipsView() : void
      {
         var self:_2V2ASSISTOnline = this;
         
         // 各端只显示自己控制的角色的切换按钮，隐藏对方的
         if(Service.client.type == "player")
         {
            // 客机：p2队伍显示在左边（自己），右边传空数组隐藏
            changeRoleView = new GameChangeRoleTipsView(p2assist, []);
         }
         else if(Service.client.type == "master")
         {
            // 房主：p1队伍显示在左边，右边传空数组隐藏
            changeRoleView = new GameChangeRoleTipsView(p1assist, []);
         }
         else
         {
            // 观战：正常显示双方
            changeRoleView = new GameChangeRoleTipsView(p1assist, p2assist);
         }
         changeRoleView.y = 120;
         
         // 根据客户端类型设置点击回调
         if(Service.client.type == "master")
         {
            // 房主只能点击左侧换人（控制p1队伍）
            changeRoleView.onLeftClick = function():void
            {
               if(p1 && p1.parent)
               {
                  p1.onDown(72);
                  p1.onUp(72); // 释放按键
               }
            };
            changeRoleView.onRightClick = null;
         }
         else if(Service.client.type == "player")
         {
            // 客机：左侧显示自己控制的角色（p2队伍）
            // 点击左侧换人（实际控制p2队伍）
            changeRoleView.onLeftClick = function():void
            {
               if(p2 && p2.parent)
               {
                  // 直接使用H键(72)触发网络发送
                  self.onDown(72);
                  self.onUp(72);
               }
            };
            changeRoleView.onRightClick = null; // 客机不能控制对方换人
         }
         else
         {
            // 观战模式不能操作
            changeRoleView.onLeftClick = null;
            changeRoleView.onRightClick = null;
         }
         
         state.addChild(changeRoleView);
      }
      
      override public function enterRole(prole:BaseRole) : void
      {
         var tw:Tween;
         var hrole:BaseRole;
         var oldRoleName:String;
         
         tween.push(prole);
         tw = new Tween(prole,0.5,"easeIn");
         hrole = null;
         
         if(prole.troopid == 0)
         {
            hrole = p1;
            // 交换name，让新角色继承原角色的网络标识
            oldRoleName = hrole.name;
            hrole.name = prole.name;
            prole.name = oldRoleName;
            p1 = prole;
         }
         else
         {
            hrole = p2;
            // 交换name，让新角色继承原角色的网络标识
            oldRoleName = hrole.name;
            hrole.name = prole.name;
            prole.name = oldRoleName;
            p2 = prole;
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
         
         // 联机模式下：只有当进入的角色是自己控制的队伍时，才更新role和runModel的target
         if(prole.troopid == _myTroopId)
         {
            role = prole;
            // 注意：不设置 founcDisplay = prole，保持聚焦在 _centerSprite
            // 更新 runModel 的 target
            if(runModel is KeyRunModel)
            {
               (runModel as KeyRunModel).target = prole.name;
            }
         }
      }
      
      override public function replaceRole(prole:GameRole) : void
      {
         // 观战模式阻止所有操作
         if(Service.client.type == "watching")
         {
            return;
         }
         
         // 客机不直接执行换人，等待房主同步
         if(Service.client.type == "player")
         {
            return;
         }
         
         // 保存 troopId（super.replaceRole 会调用 enterRole 交换 name）
         var troopId:int = prole.troopid;
         
         // 房主执行换人
         super.replaceRole(prole);
         
         // 发送换人同步消息给客机（使用 troopId 而不是 name，因为 name 已被交换）
         Service.radioUDP({
            "type":"radio",
            "data":{
               "target":"replaceRole",
               "troopId":troopId
            }
         });
      }
      
      override public function over() : void
      {
         var i:Object;
         var id:int;
         var tag:String;
         var over:GameOverView;
         
         // 重置房间内所有玩家的准备状态
         for(i in GameOnlineRoomView.roomdata.list)
         {
            GameOnlineRoomView.roomdata.list[i].isReady = false;
         }
         
         id = cheakGameOver();
         tag = OverTag.NONE;
         
         // 根据胜负和客户端类型确定结果标签
         // id=0 表示 troopid=1 的队伍全灭，troopid=0 获胜
         // id=1 表示 troopid=0 的队伍全灭，troopid=1 获胜
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