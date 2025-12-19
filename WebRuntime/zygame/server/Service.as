package zygame.server
{
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.Socket;
   import flash.system.Security;
   import flash.utils.setTimeout;
   import zygame.utils.SendDataUtils;
   
   public class Service extends BaseSocketClient
   {
      
      public static var client:Service;
      
      private var _type:String = "tourists";
      
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
      
      private var _heartbeat:Boolean = false;
      
      private var _oldtime:int = 0;
      
      private var _delays:Vector.<int>;
      
      private var _port:int = 0;
      
      private var _deady:Number;
      
      public var roomPlayerList:Array;
      
      private var _autoFind:Boolean = false;
      
      private var _findip:int = 1;
      
      private var _autoip:String;
      
      private var _timeout:uint = 3000;
      
      private var _findSockets:Vector.<Socket>;
      
      private var _errorCount:int = 0;
      
      public function Service(param1:String, param2:int, param3:Boolean = false)
      {
         var psocket:Socket;
         var ip:String = param1;
         var post:int = param2;
         var autoFind:Boolean = param3;
         _delays = new Vector.<int>();
         trace("Service ip:",ip,post,autoFind);
         _findSockets = new Vector.<Socket>();
         _port = post;
         _autoip = ip.substr(0,ip.lastIndexOf("."));
         _autoFind = autoFind;
         psocket = new Socket();
         psocket.timeout = _timeout;
         Security.loadPolicyFile("http://" + ip + ":4999/crossdomain.xml");
         psocket.connect(ip,post);
         super(psocket);
         this.dataFunc = function(param1:Object):void
         {
            var _loc3_:int = 0;
            try
            {
               switch(param1.type)
               {
                  case "bind_udp":
                     _loc3_ = 0;
                     while(_loc3_ < 15)
                     {
                        hitUDP(param1.ip,param1.port + _loc3_);
                        _loc3_++;
                     }
                     pushUDP(param1.ip,param1.port);
                     break;
                  case "handed":
                     userData = param1.userData;
                     if(userDataFunc != null)
                     {
                        userDataFunc(param1.userData);
                     }
                     break;
                  case "room_manages":
                     _type = "master";
                     if(createRoom != null)
                     {
                        createRoom(param1);
                     }
                     break;
                  case "room_accept":
                     _type = "player";
                     if(createRoom != null)
                     {
                        createRoom(param1);
                     }
                     break;
                  case "join_room":
                     if(joinFunc != null)
                     {
                        joinFunc(param1);
                     }
                     break;
                  case "exit_room":
                     if(exitFunc != null)
                     {
                        exitFunc(param1);
                     }
                     break;
                  case "room_message":
                  case "room_message_all":
                     if(messageFunc != null)
                     {
                        messageFunc(param1);
                     }
                     break;
                  case "heart":
                     _heartbeat = false;
                     var _loc2_:int = new Date().time;
                     _delays.push(0 - _oldtime);
                     if(_delays.length > 10)
                     {
                        _delays.shift();
                     }
                     heartbeat();
                     if(delayFunc != null)
                     {
                        delayFunc();
                     }
                     break;
                  case "room_list":
                     if(roomlistFunc != null)
                     {
                        roomlistFunc(param1);
                     }
                     break;
                  case "room_player_list":
                     roomPlayerList = param1.list;
                     if(rolelistFunc != null)
                     {
                        rolelistFunc(param1);
                     }
                     break;
                  case "get_room_player_data":
                     if(getroledataFunc != null)
                     {
                        getroledataFunc(param1);
                     }
                     break;
                  case "user_data":
                     userData = param1.userData;
                     if(userDataFunc != null)
                     {
                        userDataFunc(param1.data);
                     }
                     break;
                  case "push_udp":
                  case "room_refused":
               }
            }
            catch(e:Error)
            {
               trace("Service Error",e.message);
            }
         };
         client = this;
      }
      
      public static function startService(param1:String, param2:int, param3:Function, param4:Boolean = false) : void
      {
         var _loc5_:Service = null;
         if(!client || !client.connected)
         {
            _loc5_ = new Service(param1,param2,param4);
            _loc5_.ioerrorFunc = param3;
         }
      }
      
      public static function createRoom(param1:String, param2:String, param3:String) : void
      {
         var userName:String = param1;
         var userId:String = param2;
         var code:String = param3;
         client.handFunc = function():void
         {
            client.send(SendDataUtils.handData(userName,userId));
         };
      }
      
      public static function joinRoom(param1:String, param2:String, param3:int, param4:String) : void
      {
         var userName:String = param1;
         var userId:String = param2;
         var roomid:int = param3;
         var code:String = param4;
         client.handFunc = function():void
         {
            trace("登场成功");
            client.send(SendDataUtils.handData(userName,userName));
            client.send(SendDataUtils.joinRoom(roomid,code));
         };
      }
      
      public static function send(param1:Object) : void
      {
         if(client && client.connected)
         {
            client.send(param1);
         }
      }
      
      public static function sendUDP(param1:Object) : void
      {
         if(client && client.connected)
         {
            client.sendUDPAll(param1);
         }
      }
      
      public static function radioUDP(param1:Object) : void
      {
         param1.userName = client.userName;
         param1.id = client.userId;
         Service.client.sendUDP(param1,Service.client.socket.remoteAddress,Service.client.socket.remotePort);
      }
      
      public function hitUDP(param1:String, param2:int) : void
      {
         var ip:String = param1;
         var port:int = param2;
         var i:int = 0;
         while(i < 3)
         {
            setTimeout(function():void
            {
               Service.client.sendUDP({"type":"acceat"},ip,port);
            },2000 * i);
            i = i + 1;
         }
      }
      
      override protected function onError(param1:IOErrorEvent) : void
      {
         var i:int;
         var psocket:Socket;
         var e:IOErrorEvent = param1;
         if(_autoFind && _findip < 255)
         {
            _findip = 255;
            i = 1;
            while(i <= 255)
            {
               psocket = new Socket();
               psocket.timeout = _timeout;
               psocket.connect(_autoip + "." + i,_port);
               psocket.addEventListener("ioError",function(param1:IOErrorEvent):void
               {
                  _errorCount = _errorCount + 1;
                  if(progressFunc != null)
                  {
                     progressFunc(_errorCount / 255);
                  }
                  if(_errorCount == 255)
                  {
                     onError(param1);
                     _findSockets.splice(0,_findSockets.length);
                     _errorCount = 0;
                  }
               });
               psocket.addEventListener("connect",function(param1:Event):void
               {
                  socket = param1.target as Socket;
                  for(var _loc2_ in _findSockets)
                  {
                     try
                     {
                        if(_findSockets[_loc2_] != socket)
                        {
                           _findSockets[_loc2_].close();
                        }
                     }
                     catch(e:Error)
                     {
                     }
                  }
                  _findSockets.splice(0,_findSockets.length);
                  onConnect(param1);
               });
               _findSockets.push(psocket);
               i = i + 1;
            }
            if(progressFunc != null)
            {
               progressFunc(0);
            }
         }
         else
         {
            if(progressFunc != null)
            {
               progressFunc(1);
            }
            super.onError(e);
         }
      }
      
      override protected function onConnect(param1:Event) : void
      {
         super.onConnect(param1);
         _oldtime = new Date().time;
         heartbeat();
         if(progressFunc != null)
         {
            progressFunc(1);
         }
      }
      
      public function get type() : String
      {
         return _type;
      }
      
      public function set type(param1:String) : void
      {
         _type = param1;
      }
      
      public function get delay() : int
      {
         var _loc1_:int = 0;
         for(var _loc2_ in _delays)
         {
            _loc1_ += _delays[_loc2_];
         }
         return _loc1_ / _delays.length;
      }
      
      public function heartbeat() : void
      {
         if(!_heartbeat)
         {
            _heartbeat = true;
            setTimeout(function():void
            {
               _oldtime = new Date().time;
               send({"type":"heart"});
            },1000);
         }
      }
      
      public function waitLength() : int
      {
         return socket.bytesAvailable;
      }
      
      public function sendUDPAll(param1:Object) : void
      {
         for(var _loc2_ in udps)
         {
            sendUDP(param1,udps[_loc2_].ip,udps[_loc2_].port);
         }
      }
   }
}

