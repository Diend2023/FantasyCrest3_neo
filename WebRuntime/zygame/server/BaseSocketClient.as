package zygame.server
{
   import flash.events.DatagramSocketDataEvent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.net.DatagramSocket;
   import flash.net.Socket;
   import flash.utils.ByteArray;
   
   public class BaseSocketClient
   {
      
      public static var allSendPkgSize:int = 0;
      
      private var _socket:Socket;
      
      public var _udp:DatagramSocket;
      
      public var handFunc:Function;
      
      public var ioerrorFunc:Function;
      
      public var dataFunc:Function;
      
      public var closeFunc:Function;
      
      public var udpFunc:Function;
      
      public var userName:String;
      
      public var userCode:String;
      
      public var userData:Object;
      
      public var logFunc:Function;
      
      public var userId:String;
      
      public var udps:Array = [];
      
      private var _alldata:String = "";
      
      private var _cache:ByteArray;
      
      public function BaseSocketClient(param1:Socket)
      {
         super();
         socket = param1;
      }
      
      public static function code(param1:String) : String
      {
         return param1;
      }
      
      public static function uncode(param1:*) : String
      {
         return param1;
      }
      
      public function get udp() : DatagramSocket
      {
         return _udp;
      }
      
      public function pushUDP(param1:String, param2:int) : void
      {
         for(var _loc3_ in udps)
         {
            if(udps[_loc3_].ip == param1 && udps[_loc3_].port == param2)
            {
               return;
            }
         }
         udps.push({
            "ip":param1,
            "port":param2
         });
      }
      
      public function onUDPData(param1:DatagramSocketDataEvent) : void
      {
         var _loc2_:Object = toObject(param1.data);
         if(!_loc2_)
         {
            return;
         }
         if(logFunc != null)
         {
            logFunc("接收到数据UDP",userName,JSON.stringify(_loc2_),param1.data.length,"drc",param1.dstAddress,param1.dstPort,"src",param1.srcAddress,param1.srcPort);
         }
         switch(_loc2_.type)
         {
            case "back":
               return;
            case "acceated":
               return;
            case "acceat":
               Service.client.sendUDP({"type":"acceated"},param1.srcAddress,param1.srcPort);
               return;
            default:
               if(Boolean(udpFunc))
               {
                  udpFunc(_loc2_);
               }
               return;
         }
      }
      
      public function set socket(param1:Socket) : void
      {
         if(_socket)
         {
            _socket.removeEventListener("close",onSocketClose);
            _socket.removeEventListener("socketData",onSocketData);
            _socket.removeEventListener("connect",onConnect);
            _socket.removeEventListener("ioError",onError);
         }
         _socket = param1;
         if(!param1)
         {
            return;
         }
         _socket.addEventListener("close",onSocketClose);
         _socket.addEventListener("socketData",onSocketData);
         _socket.addEventListener("connect",onConnect);
         _socket.addEventListener("ioError",onError);
      }
      
      public function get socket() : Socket
      {
         return _socket;
      }
      
      protected function onError(param1:IOErrorEvent) : void
      {
         if(ioerrorFunc != null)
         {
            ioerrorFunc();
         }
      }
      
      protected function onSocketData(param1:ProgressEvent) : void
      {
         if(socket.bytesAvailable == 0)
         {
            return;
         }
         var _loc2_:ByteArray = new ByteArray();
         socket.readBytes(_loc2_,0,param1.bytesTotal);
         pushCache(_loc2_);
         parsingCache();
      }
      
      public function pushCache(param1:ByteArray) : void
      {
         if(_cache == null)
         {
            _cache = param1;
         }
         else
         {
            _cache.position = _cache.length;
            _cache.writeBytes(param1);
            param1.clear();
         }
      }
      
      public function parsingCache() : void
      {
         var _loc4_:* = 0;
         var _loc3_:ByteArray = null;
         var _loc2_:ByteArray = null;
         if(!_cache)
         {
            return;
         }
         var _loc1_:int = 0;
         _cache.position = _loc1_;
         while(_cache.bytesAvailable > 2)
         {
            _loc4_ = uint(_cache.readShort());
            if(_cache.bytesAvailable < _loc4_)
            {
               break;
            }
            _cache.position = _loc1_ + 2;
            _loc3_ = new ByteArray();
            _cache.readBytes(_loc3_,0,_loc4_);
            backData(_loc3_);
            _loc1_ += 2 + _loc4_;
            _cache.position = _loc1_;
         }
         if(_loc1_ != 0)
         {
            if(_cache.bytesAvailable > 0)
            {
               _loc2_ = new ByteArray();
               _cache.position = _loc1_;
               _cache.readBytes(_loc2_,0,_cache.bytesAvailable);
               _cache.clear();
               _cache = _loc2_;
            }
            else
            {
               _cache.clear();
               _cache = null;
            }
         }
      }
      
      private function backData(param1:ByteArray) : void
      {
         var _loc2_:Object = null;
         try
         {
            param1.position = 0;
            _loc2_ = param1.readObject();
            if(_loc2_)
            {
               if(dataFunc != null)
               {
                  dataFunc(_loc2_);
               }
            }
         }
         catch(e:Error)
         {
            trace("解析出现异常",param1,e.message);
         }
      }
      
      protected function onSocketClose(param1:Event) : void
      {
         if(closeFunc != null)
         {
            closeFunc();
         }
         socket.removeEventListener("close",onSocketClose);
         socket.removeEventListener("socketData",onSocketData);
      }
      
      public function sendUDP(param1:Object, param2:String = null, param3:int = 0) : void
      {
         trace("UDP发送：",param2,param3);
         try
         {
            _udp.send(toByte(param1),0,0,param2,param3);
         }
         catch(e:Error)
         {
            trace("UDP Error ",e.message);
         }
      }
      
      public function toByte(param1:Object) : ByteArray
      {
         var _loc2_:ByteArray = new ByteArray();
         _loc2_.writeObject(param1);
         return _loc2_;
      }
      
      public function toObject(param1:ByteArray) : Object
      {
         return param1.readObject();
      }
      
      public function send(param1:Object) : void
      {
         if(!socket || !socket.connected)
         {
            return;
         }
         var _loc4_:* = param1.type;
         if("hand" === _loc4_)
         {
            userName = param1.name;
            userId = param1.userid;
         }
         var _loc2_:ByteArray = toByte(param1);
         socket.writeShort(_loc2_.length);
         socket.writeBytes(_loc2_);
         var _loc3_:int = String(_loc2_.length).length + _loc2_.length;
         allSendPkgSize += _loc3_ + _loc2_.length;
         socket.flush();
      }
      
      public function openUDP() : void
      {
         if(Boolean(logFunc))
         {
            logFunc("开始打洞");
         }
         _udp.send(toByte({
            "type":"connect",
            "ip":socket.localAddress,
            "port":socket.localPort,
            "userName":userName
         }),0,0,socket.remoteAddress,socket.remotePort);
      }
      
      public function bindUDP(param1:String, param2:int) : void
      {
         if(_udp)
         {
            trace("开始绑定",param1,param2);
            _udp.bind(param2,param1);
            _udp.receive();
         }
      }
      
      protected function onConnect(param1:Event) : void
      {
         _udp = new DatagramSocket();
         bindUDP(socket.localAddress,socket.localPort);
         _udp.addEventListener("data",onUDPData);
         if(handFunc != null)
         {
            handFunc();
         }
      }
      
      public function get connected() : Boolean
      {
         if(!socket)
         {
            return false;
         }
         return socket.connected;
      }
      
      public function close() : void
      {
         if(socket && socket.connected)
         {
            socket.close();
         }
         socket = null;
      }
   }
}

