package zygame.server
{
   import flash.utils.Timer;
   import flash.events.TimerEvent;
   import zygame.utils.SendDataUtils;
   
   /**
    * 联机服务客户端 - 基于HxOnlineClient + go-websocket-server
    * 使用原生Socket实现WebSocket协议，避免hxonline.swc的isNaN兼容问题
    */
   public class Service
   {
      
      public static var userData:Object;
      
      public static var client:Service;
      
      private var _hxClient:HxOnlineClient;
      
      private var _type:String = "tourists";
      
      private var _userName:String = "";
      
      private var _userCode:String = "";
      
      private var _processTimer:Timer;
      
      // === 回调函数（保持与旧API兼容） ===
      
      public var joinFunc:Function;
      
      public var exitFunc:Function;
      
      public var createRoom:Function;
      
      public var messageFunc:Function;
      
      public var delayFunc:Function;
      
      public var progressFunc:Function;
      
      public var roomlistFunc:Function;
      
      public var rolelistFunc:Function;
      
      public var getroledataFunc:Function;
      
      public var userDataFunc:Function;
      
      public var udpFunc:Function;
      
      public var handFunc:Function;
      
      public var closeFunc:Function;
      
      public var ioerrorFunc:Function;
      
      public var roomPlayerList:Array;
      
      public function Service()
      {
         _hxClient = HxOnlineClient.getInstance();
         client = this;
         _processTimer = new Timer(16);
         _processTimer.addEventListener(TimerEvent.TIMER, onProcessTimer);
         _processTimer.start();
      }
      
      private function onProcessTimer(e:TimerEvent) : void
      {
         if(_hxClient != null)
         {
            _hxClient.process();
         }
      }
      
      public function get connected() : Boolean
      {
         return _hxClient != null && _hxClient.connected();
      }
      
      public function get type() : String
      {
         return _type;
      }
      
      public function set type(str:String) : void
      {
         _type = str;
      }
      
      public function get userName() : String
      {
         return _userName;
      }
      
      public function set userName(value:String) : void
      {
         _userName = value;
      }
      
      public function get userCode() : String
      {
         return _userCode;
      }
      
      public function set userCode(value:String) : void
      {
         _userCode = value;
      }
      
      public function get delay() : int
      {
         return 0;
      }
      
      public static function startService(ip:String, port:int, ioFunc:Function, autoFind:Boolean = false) : void
      {
         if(!client)
         {
            client = new Service();
         }
         var hxClient:HxOnlineClient = client._hxClient;
         HxOnlineClient.debug = false;
         hxClient.init("ws://" + ip + ":" + port, "fantasycrest3");
         
         hxClient.onClose = function():void
         {
            trace("[Service]连接断开");
            if(client.closeFunc != null)
            {
               client.closeFunc();
            }
         };
         hxClient.onOpMessage = function(op:int, data:Object):void
         {
            client.onHxMessage(op, data);
         };
         
         client.ioerrorFunc = ioFunc;
      }
      
      public function login(puserName:String, puserId:String, cb:Function = null) : void
      {
         _userName = puserName;
         _userCode = puserId;
         _hxClient.login(puserId, puserName, function(data:Object):void
         {
            if(data.code == 0)
            {
               trace("[Service]登录成功, uid:", _hxClient.uid);
               if(handFunc != null)
               {
                  handFunc();
               }
               if(cb != null)
               {
                  cb(true);
               }
            }
            else
            {
               trace("[Service]登录失败");
               if(ioerrorFunc != null)
               {
                  ioerrorFunc();
               }
               if(cb != null)
               {
                  cb(false);
               }
            }
         });
      }
      
      /**
       * 静态发送方法 - 供外部直接调用 Service.send(data)
       */
      public static function send(data:Object) : void
      {
         if(client && client.connected)
         {
            client.send(data);
         }
      }
      
      public function send(data:Object) : void
      {
         if(!connected)
         {
            return;
         }
         
         switch(data.type)
         {
            case "hand":
               break;
               
            case "room_list":
               _hxClient.getRoomList(1, 50, function(result:Object):void
               {
                  if(result.code == 0 && roomlistFunc != null)
                  {
                     var list:Array = [];
                     var respData:Object = result.data;
                     var rooms:Array = respData ? respData.list as Array : null;
                     var onlineCount:int = respData ? (respData.onlineCounts || 0) : 0;
                     if(rooms != null)
                     {
                        for(var ri:int = 0; ri < rooms.length; ri++)
                        {
                           var room:Object = rooms[ri];
                           var roomCustomData:Object = room.data || {};
                           list.push({
                              "id": room.id,
                              "master": room.master || "",
                              "code": roomCustomData.code ? 1 : (room.password ? 1 : 0),
                              "num": room.counts || 0,
                              "maxCount": room.maxCounts || 4,
                              "lock": room.lock || false,
                              "mode": roomCustomData.mode || "普通模式"
                           });
                        }
                     }
                     roomlistFunc({"list": list, "count": onlineCount});
                  }
               });
               break;
               
            case "create_room":
               var roomMode:String = data.mode || "普通模式";
               var roomCount:int = data.count || 4;
               var roomCode:String = data.code || "";
               trace("[send] create_room mode=" + roomMode + " count=" + roomCount + " code=" + roomCode + " rawData=" + JSON.stringify(data));
               createRoomInternal(roomMode, roomCount, roomCode);
               break;
               
            case "join_room":
               var joinId:int = data.id;
               var joinCode:String = data.code || "";
               _hxClient.joinRoom(joinId, function(result:Object):void
               {
                  if(result.code == 0)
                  {
                     trace("[Service]加入房间成功");
                     _hxClient.setClientState({"type": "player", "isReady": false}, function(stateResult:Object):void
                     {
                        refreshAndNotifyRoom();
                     });
                  }
                  else
                  {
                     trace("[Service]加入房间失败");
                  }
               }, joinCode);
               break;
               
            case "exit_room":
               _hxClient.exitRoom(function(result:Object):void
               {
                  trace("[Service]退出房间");
               });
               break;
               
            case "room_message":
            case "room_message_all":
               var roomMsg:Object = {};
               for(var rk:String in data)
               {
                  if(rk != "type")
                  {
                     roomMsg[rk] = data[rk];
                  }
               }
               _hxClient.sendRoomMessage(roomMsg);
               break;
               
            case "lock":
               _hxClient.lockRoom(function(result:Object):void
               {
                  trace("[Service]房间已锁定");
               });
               break;
               
            case "unlock":
               _hxClient.unlockRoom(function(result:Object):void
               {
                  trace("[Service]房间已解锁");
               });
               break;
               
            case "ready":
               _hxClient.setClientState({"isReady": true}, function(r:Object):void
               {
                  refreshRoomPlayerList();
               });
               break;
               
            case "cannel":
               _hxClient.setClientState({"isReady": false}, function(r:Object):void
               {
                  refreshRoomPlayerList();
               });
               break;
               
            case "change_role":
               _hxClient.setClientState({"type": data.change}, function(r:Object):void
               {
                  _type = data.change;
                  refreshRoomPlayerList();
               });
               break;
               
            case "heart":
               if(delayFunc != null)
               {
                  delayFunc();
               }
               break;
               
            default:
               _hxClient.sendRoomMessage(data);
               break;
         }
      }
      
      private function createRoomInternal(mode:String, count:int, code:String) : void
      {
         trace("[createRoomInternal] mode=" + mode + " count=" + count + " code=" + code);
         _hxClient.createRoom(function(result:Object):void
         {
            trace("[createRoomInternal] createRoom result=" + JSON.stringify(result));
            if(result.code == 0)
            {
               trace("[Service]创建房间成功, 设置状态为master");
               _hxClient.setClientState({"type": "master", "isReady": false}, function(stateResult:Object):void
               {
                  trace("[createRoomInternal] setClientState result=" + JSON.stringify(stateResult));
                  _hxClient.updateRoomOption({
                     "maxCounts": count,
                     "password": code
                  }, function(optResult:Object):void
                  {
                     trace("[createRoomInternal] updateRoomOption result=" + JSON.stringify(optResult));
                     _hxClient.updateRoomCustomData({
                        "mode": mode,
                        "code": code,
                        "count": count
                     }, function(cusResult:Object):void
                     {
                        trace("[createRoomInternal] updateRoomCustomData result=" + JSON.stringify(cusResult));
                        refreshAndNotifyRoom();
                     });
                  });
               });
            }
            else
            {
               trace("[Service]创建房间失败");
            }
         });
      }
      
      private function refreshAndNotifyRoom() : void
      {
         _hxClient.getRoomData(function(result:Object):void
         {
            trace("[refreshAndNotifyRoom] result=" + JSON.stringify(result));
            if(result.code == 0)
            {
               var roomData:Object = result.data;
               var roomInfo:Object = convertRoomData(roomData);
               
               _type = roomInfo.selfType;
               roomPlayerList = roomInfo.list;
               
               if(createRoom != null)
               {
                  var notifyData:Object = {
                     "id": roomData.id,
                     "code": roomData.data ? (roomData.data.code || "") : "",
                     "mode": roomData.data ? (roomData.data.mode || "普通模式") : "普通模式",
                     "count": roomData.max,
                     "list": roomInfo.list
                  };
                  trace("[refreshAndNotifyRoom] notify=" + JSON.stringify(notifyData));
                  createRoom(notifyData);
               }
            }
         });
      }
      
      private function refreshRoomPlayerList() : void
      {
         _hxClient.getRoomData(function(result:Object):void
         {
            if(result.code == 0)
            {
               var roomData:Object = result.data;
               var roomInfo:Object = convertRoomData(roomData);
               
               _type = roomInfo.selfType;
               roomPlayerList = roomInfo.list;
               
               if(rolelistFunc != null)
               {
                  rolelistFunc({
                     "id": roomData.id,
                     "code": roomData.data ? (roomData.data.code || "") : "",
                     "mode": roomData.data ? (roomData.data.mode || "普通模式") : "普通模式",
                     "count": roomData.max,
                     "list": roomInfo.list
                  });
               }
            }
         });
      }
      
      private function convertRoomData(roomData:Object) : Object
      {
         var list:Array = [];
         var users:Array = roomData.users as Array;
         var usersState:Object = roomData.usersState || {};
         var selfType:String = "player";
         var myUid:int = _hxClient.uid;
         
         trace("[convertRoomData] myUid=" + myUid + " master=" + JSON.stringify(roomData.master));
         trace("[convertRoomData] usersState=" + JSON.stringify(usersState));
         trace("[convertData] customData=" + JSON.stringify(roomData.data));
         
         if(users != null)
         {
            for(var ui:int = 0; ui < users.length; ui++)
            {
               var user:Object = users[ui];
               var isMaster:Boolean = roomData.master != null && user.uid == roomData.master.uid;
               var userState:Object = usersState[String(user.uid)] || user.state || {};
               var userType:String = "player";
               
               trace("[convertRoomData] user[" + ui + "] uid=" + user.uid + " name=" + user.name + " userState=" + JSON.stringify(userState));
               
               if(userState.type)
               {
                  userType = userState.type;
               }
               else if(isMaster)
               {
                  userType = "master";
               }
               else
               {
                  userType = ui <= 1 ? "player" : "watching";
               }
               
               var isReady:Boolean = userState.isReady == true;
               
               list.push({
                  "name": user.name,
                  "type": userType,
                  "nickName": user.data ? (user.data.nickName || user.name) : user.name,
                  "isReady": isReady,
                  "master": isMaster ? 1 : 0
               });
               
               if(user.uid == myUid)
               {
                  selfType = userType;
               }
            }
         }
         
         trace("[convertRoomData] result selfType=" + selfType + " list=" + JSON.stringify(list));
         return {"list": list, "selfType": selfType};
      }
      
      private function onHxMessage(op:int, data:Object) : void
      {
         try
         {
            if(op == 10)
            {
               if(data != null)
               {
                  var msgData:Object = (data.data != null && data.uid != null) ? data.data : data;
                  if(msgData.__game == true)
                  {
                     if(udpFunc != null)
                     {
                        udpFunc(msgData);
                     }
                  }
                  else
                  {
                     if(messageFunc != null)
                     {
                        messageFunc(msgData);
                     }
                  }
               }
            }
            else if(op == 11)
            {
               trace("[Service]玩家加入:", data.name);
               if(joinFunc != null)
               {
                  joinFunc(data);
               }
               refreshRoomPlayerList();
            }
            else if(op == 12)
            {
               trace("[Service]玩家退出:", data.name);
               if(exitFunc != null)
               {
                  exitFunc(data);
               }
               refreshRoomPlayerList();
            }
            else if(op == 3)
            {
               refreshRoomPlayerList();
            }
            else if(op == 26)
            {
               refreshRoomPlayerList();
            }
            else if(op == 9)
            {
               if(udpFunc != null)
               {
                  udpFunc(data);
               }
            }
            else if(op == 34)
            {
               refreshRoomPlayerList();
            }
         }
         catch(e:Error)
         {
            trace("[Service]消息处理错误:", e.message);
         }
      }
      
      public static function radioUDP(data:Object) : void
      {
         if(client && client.connected)
         {
            var gameData:Object = data.data || data;
            var sendObj:Object = {};
            for(var key:String in gameData)
            {
               sendObj[key] = gameData[key];
            }
            sendObj.__game = true;
            client._hxClient.sendRoomMessage(sendObj);
         }
      }
      
      public static function sendUDP(data:Object) : void
      {
      }
      
      /**
       * 实例UDP发送方法（保留接口兼容，WebSocket模式下为空操作）
       */
      public function sendUDP(data:Object, ip:String = null, port:int = 0) : void
      {
      }
      
      public function sendUDPAll(data:Object) : void
      {
      }
      
      public function openUDP() : void
      {
         trace("[Service]openUDP - 已由WebSocket替代，无需操作");
      }
      
      public function waitLength() : int
      {
         return 0;
      }
      
      public function close() : void
      {
         if(_hxClient != null)
         {
            _hxClient.close();
         }
         if(_processTimer != null)
         {
            _processTimer.stop();
            _processTimer = null;
         }
      }
   }
}

