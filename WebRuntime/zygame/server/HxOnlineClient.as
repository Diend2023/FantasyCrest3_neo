package zygame.server
{
   import flash.utils.ByteArray;
   
   /**
    * hxonline兼容客户端 - 使用SimpleWebSocket替代hxonline中存在isNaN问题的WebSocket
    * 实现与go-websocket-server的通信协议
    */
   public class HxOnlineClient
   {
      
      // OpCode常量（与go-websocket-server协议一致）
      public static const OP_ERROR:int = -1;
      public static const OP_MESSAGE:int = 0;
      public static const OP_CREATE_ROOM:int = 1;
      public static const OP_JOIN_ROOM:int = 2;
      public static const OP_CHANGED_ROOM:int = 3;
      public static const OP_GET_ROOM_DATA:int = 4;
      public static const OP_START_FRAME_SYNC:int = 5;
      public static const OP_STOP_FRAME_SYNC:int = 6;
      public static const OP_UPLOAD_FRAME:int = 7;
      public static const OP_LOGIN:int = 8;
      public static const OP_FDATA:int = 9;
      public static const OP_ROOM_MESSAGE:int = 10;
      public static const OP_JOIN_ROOM_CLIENT:int = 11;
      public static const OP_EXIT_ROOM_CLIENT:int = 12;
      public static const OP_EXIT_ROOM:int = 14;
      public static const OP_UPDATE_USER_DATA:int = 16;
      public static const OP_UPDATE_ROOM_CUSTOM_DATA:int = 18;
      public static const OP_UPDATE_ROOM_OPTION:int = 19;
      public static const OP_KICK_OUT:int = 20;
      public static const OP_SET_CLIENT_STATE:int = 25;
      public static const OP_CLIENT_STATE_UPDATE:int = 26;
      public static const OP_LOCK_ROOM:int = 30;
      public static const OP_UNLOCK_ROOM:int = 31;
      public static const OP_GET_ROOM_LIST:int = 35;
      public static const OP_EXTENDS_CALL:int = 42;
      
      private static var _instance:HxOnlineClient;
      
      public static function getInstance() : HxOnlineClient
      {
         if(_instance == null)
         {
            _instance = new HxOnlineClient();
         }
         return _instance;
      }
      
      private var _socket:SimpleWebSocket;
      private var _serverUrl:String;
      private var _appId:String;
      private var _uid:int = 0;
      private var _userId:String = "";
      private var _name:String = "";
      private var _connected:Boolean = false;
      private var _pendingCallbacks:Object = {};
      private var _callbackId:int = 0;
      
      /** 调试模式 */
      public static var debug:Boolean = false;
      
      /** 当前房间数据 */
      public static var roomData:Object = null;
      
      /** 连接成功回调 */
      public var onConnected:Function;
      
      /** 连接关闭回调 */
      public var onClose:Function;
      
      /** 操作消息回调 (op:int, data:Object) */
      public var onOpMessage:Function;
      
      public function HxOnlineClient()
      {
      }
      
      public function get uid() : int { return _uid; }
      public function get userId() : String { return _userId; }
      public function get name() : String { return _name; }
      
      /**
       * 初始化服务器地址
       */
      public function init(url:String, appid:String) : void
      {
         _serverUrl = url;
         _appId = appid;
         if(debug) trace("[HxOnline]init url:" + url, appid);
      }
      
      /**
       * 是否已连接
       */
      public function connected() : Boolean
      {
         return _connected;
      }
      
      /**
       * 连接并登录
       */
      public function login(userId:String, userName:String, cb:Function = null) : void
      {
         _userId = userId;
         _name = userName;
         
         if(_connected)
         {
            // 已连接，直接发送登录
            sendLoginOp(userId, userName, cb);
            return;
         }
         
         _socket = new SimpleWebSocket(_serverUrl);
         _socket.onOpen = function():void
         {
            _connected = true;
            if(onConnected != null) onConnected();
            sendLoginOp(userId, userName, cb);
         };
         _socket.onMessage = function(data:*):void
         {
            if(data is String)
            {
               handleMessage(String(data));
            }
         };
         _socket.onClose = function():void
         {
            _connected = false;
            roomData = null;
            if(onClose != null) onClose();
         };
         _socket.onError = function(msg:String):void
         {
            trace("[HxOnline]连接错误:", msg);
            _connected = false;
            if(cb != null) cb({"code": -1, "op": OP_LOGIN, "data": "无法连接服务器"});
         };
         _socket.connect();
      }
      
      private function sendLoginOp(userId:String, userName:String, cb:Function) : void
      {
         sendOp(OP_LOGIN, {"openid": userId, "username": userName, "appid": _appId}, function(data:Object):void
         {
            if(data.code == 0)
            {
               _uid = data.data.uid;
            }
            if(cb != null) cb(data);
         });
      }
      
      /**
       * 处理收到的消息
       */
      private function handleMessage(text:String) : void
      {
         try
         {
            var msg:Object = JSON.parse(text);
            var op:int = msg.op;
            var data:Object = msg.data;
            var isError:Boolean = false;
            
            if(op == OP_ERROR)
            {
               isError = true;
               trace("[HxOnline]服务器错误:", JSON.stringify(data));
               op = data.op;
            }
            
            trace("[HxOnline]收到 op=" + op + " data=" + JSON.stringify(data).substr(0, 200));
            
            // 处理回调
            var cbKey:String = "op_" + op;
            if(_pendingCallbacks[cbKey] != null && _pendingCallbacks[cbKey].length > 0)
            {
               var cb:Function = _pendingCallbacks[cbKey].shift();
               if(cb != null)
               {
                  cb({"code": isError ? 1 : 0, "op": op, "data": data});
               }
            }
            
            // 处理房间数据更新
            handleRoomDataUpdate(op, data, isError);
            
            // 触发通用回调
            if(onOpMessage != null)
            {
               onOpMessage(op, data);
            }
         }
         catch(e:Error)
         {
            trace("[HxOnline]消息解析错误:", e.message, text);
         }
      }
      
      /**
       * 处理房间数据的自动更新
       */
      private function handleRoomDataUpdate(op:int, data:Object, isError:Boolean) : void
      {
         if(isError) return;
         
         switch(op)
         {
            case OP_JOIN_ROOM_CLIENT:
               if(roomData != null && roomData.users != null)
               {
                  var exists:Boolean = false;
                  for each(var u:Object in roomData.users)
                  {
                     if(u.uid == data.uid)
                     {
                        exists = true;
                        break;
                     }
                  }
                  if(!exists) roomData.users.push(data);
               }
               break;
            case OP_EXIT_ROOM_CLIENT:
               if(roomData != null && roomData.users != null)
               {
                  for(var i:int = 0; i < roomData.users.length; i++)
                  {
                     if(roomData.users[i].uid == data.uid)
                     {
                        roomData.users.splice(i, 1);
                        break;
                     }
                  }
                  if(roomData.master != null && roomData.master.uid == data.uid)
                  {
                     getRoomData(null);
                  }
               }
               break;
            case OP_EXIT_ROOM:
               roomData = null;
               break;
            case OP_CLIENT_STATE_UPDATE:
               if(roomData != null && roomData.users != null)
               {
                  for each(var user:Object in roomData.users)
                  {
                     if(user.uid == data.uid)
                     {
                        if(user.state == null) user.state = {};
                        updateData(user.state, data.data);
                        break;
                     }
                  }
               }
               break;
         }
      }
      
      /**
       * 发送操作消息
       */
      private function sendOp(op:int, data:Object = null, cb:Function = null) : void
      {
         if(!_connected) return;
         
         var msg:Object = {"op": op, "data": data};
         var json:String = JSON.stringify(msg);
         
         if(debug) trace("[HxOnline]发送 op=" + op + ":", json);
         _socket.send(json);
         
         if(cb != null)
         {
            var cbKey:String = "op_" + op;
            if(_pendingCallbacks[cbKey] == null)
            {
               _pendingCallbacks[cbKey] = [];
            }
            _pendingCallbacks[cbKey].push(cb);
         }
      }
      
      // ===== 公共API =====
      
      /**
       * 创建房间
       */
      public function createRoom(cb:Function = null) : void
      {
         sendOp(OP_CREATE_ROOM, null, cb);
      }
      
      /**
       * 加入房间
       */
      public function joinRoom(roomid:int, cb:Function = null, password:String = null) : void
      {
         sendOp(OP_JOIN_ROOM, {"id": roomid, "password": password}, cb);
      }
      
      /**
       * 退出房间
       */
      public function exitRoom(cb:Function = null) : void
      {
         sendOp(OP_EXIT_ROOM, null, cb);
      }
      
      /**
       * 发送房间消息
       */
      public function sendRoomMessage(data:Object, cb:Function = null) : void
      {
         sendOp(OP_ROOM_MESSAGE, data, cb);
      }
      
      /**
       * 获取房间列表
       */
      public function getRoomList(page:int, counts:int, cb:Function = null) : void
      {
         sendOp(OP_GET_ROOM_LIST, {"page": page, "counts": counts}, cb);
      }
      
      /**
       * 获取房间数据
       */
      public function getRoomData(cb:Function = null) : void
      {
         sendOp(OP_GET_ROOM_DATA, null, function(data:Object):void
         {
            if(data.code == 0)
            {
               roomData = data.data;
               if(roomData != null && roomData.users != null)
               {
                  for each(var user:Object in roomData.users)
                  {
                     var state:Object = roomData.usersState ? roomData.usersState[user.uid] : null;
                     user.state = state == null ? {} : state;
                  }
               }
            }
            if(cb != null) cb(data);
         });
      }
      
      /**
       * 更新房间选项
       */
      public function updateRoomOption(data:Object, cb:Function = null) : void
      {
         sendOp(OP_UPDATE_ROOM_OPTION, data, cb);
      }
      
      /**
       * 更新房间自定义数据
       */
      public function updateRoomCustomData(data:Object, cb:Function = null) : void
      {
         sendOp(OP_UPDATE_ROOM_CUSTOM_DATA, data, cb);
      }
      
      /**
       * 锁定房间
       */
      public function lockRoom(cb:Function = null) : void
      {
         sendOp(OP_LOCK_ROOM, null, cb);
      }
      
      /**
       * 解锁房间
       */
      public function unlockRoom(cb:Function = null) : void
      {
         sendOp(OP_UNLOCK_ROOM, null, cb);
      }
      
      /**
       * 设置客户端状态
       */
      public function setClientState(data:Object, cb:Function = null) : void
      {
         sendOp(OP_SET_CLIENT_STATE, data, cb);
      }
      
      /**
       * 上传帧数据
       */
      public function uploadFrame(data:Object) : void
      {
         sendOp(OP_UPLOAD_FRAME, data);
      }
      
      /**
       * 开始帧同步
       */
      public function startFrameSync(cb:Function = null) : void
      {
         sendOp(OP_START_FRAME_SYNC, null, cb);
      }
      
      /**
       * 停止帧同步
       */
      public function stopFrameSync(cb:Function = null) : void
      {
         sendOp(OP_STOP_FRAME_SYNC, null, cb);
      }
      
      /**
       * 更新用户数据
       */
      public function updateUserData(data:Object, cb:Function = null) : void
      {
         sendOp(OP_UPDATE_USER_DATA, data, cb);
      }
      
      /**
       * 是否房主
       */
      public function isMaster() : Boolean
      {
         if(roomData != null && roomData.self != null)
         {
            return roomData.master.uid == roomData.self.uid;
         }
         return false;
      }
      
      /**
       * 处理WebSocket事件（Flash需要定期调用）
       */
      public function process() : void
      {
         // SimpleWebSocket基于事件驱动，无需轮询
      }
      
      /**
       * 关闭连接
       */
      public function close() : void
      {
         if(_socket != null)
         {
            _socket.close();
            _socket = null;
         }
         _connected = false;
         _pendingCallbacks = {};
         roomData = null;
      }
      
      /**
       * 合并数据
       */
      private function updateData(target:Object, source:Object) : void
      {
         if(target == null || source == null) return;
         for(var key:String in source)
         {
            target[key] = source[key];
         }
      }
   }
}
