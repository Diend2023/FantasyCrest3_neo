package zygame.server
{
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.events.TimerEvent;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import air.net.WebSocket;
   import flash.events.WebSocketEvent;
   import flash.events.EventDispatcher;
   
   /**
    * WebSocket客户端 - 基于AIR 51原生air.net.WebSocket
    * 数据事件名："websocketData"（WebSocketEvent.DATA常量）
    * 自动Ping/Pong + 额外PONG保活
    */
   public class SimpleWebSocket extends EventDispatcher
   {
      
      public static const CONNECTING:int = 0;
      public static const OPEN:int = 1;
      public static const CLOSING:int = 2;
      public static const CLOSED:int = 3;
      
      private var _ws:air.net.WebSocket;
      private var _readyState:int = CLOSED;
      private var _heartbeatTimer:Timer;
      
      public var onOpen:Function;
      public var onMessage:Function;
      public var onClose:Function;
      public var onError:Function;
      
      public function SimpleWebSocket(url:String)
      {
         _ws = new air.net.WebSocket();
         _ws.addEventListener(Event.CONNECT, onWsConnect);
         _ws.addEventListener(Event.CLOSE, onWsClose);
         _ws.addEventListener(IOErrorEvent.IO_ERROR, onWsError);
         // 关键：数据事件名是"websocketData"，不是"data"
         _ws.addEventListener("websocketData", onWsData);
         _ws.connect(url);
         _readyState = CONNECTING;
      }
      
      private function onWsConnect(e:Event) : void
      {
         _readyState = OPEN;
         startHeartbeat();
         if(onOpen != null) onOpen();
      }
      
      private function startHeartbeat() : void
      {
         stopHeartbeat();
         _heartbeatTimer = new Timer(25000);
         _heartbeatTimer.addEventListener(TimerEvent.TIMER, onHeartbeat);
         _heartbeatTimer.start();
      }
      
      private function stopHeartbeat() : void
      {
         if(_heartbeatTimer != null)
         {
            _heartbeatTimer.stop();
            _heartbeatTimer.removeEventListener(TimerEvent.TIMER, onHeartbeat);
            _heartbeatTimer = null;
         }
      }
      
      private function onHeartbeat(e:TimerEvent) : void
      {
         if(_readyState == OPEN)
         {
            try
            {
               // 发送PONG保活（opcode=10）
               _ws.sendMessage(10, "");
            }
            catch(err:Error) {}
         }
      }
      
      private function onWsClose(e:Event) : void
      {
         stopHeartbeat();
         _readyState = CLOSED;
         if(onClose != null) onClose();
      }
      
      private function onWsError(e:IOErrorEvent) : void
      {
         stopHeartbeat();
         _readyState = CLOSED;
         if(onError != null) onError(e.text);
      }
      
      private function onWsData(e:WebSocketEvent) : void
      {
         try
         {
            if(e.format == 1) // TEXT
            {
               if(onMessage != null) onMessage(e.stringData);
            }
            else if(e.format == 2) // BINARY
            {
               if(onMessage != null) onMessage(e.data);
            }
         }
         catch(err:Error) {}
      }
      
      public function send(message:String) : void
      {
         if(_readyState != OPEN) return;
         try
         {
            _ws.sendMessage(1, message);
         }
         catch(e:Error) {}
      }
      
      public function close() : void
      {
         stopHeartbeat();
         if(_readyState == OPEN || _readyState == CONNECTING)
         {
            _readyState = CLOSING;
            _ws.close(1000);
         }
         _readyState = CLOSED;
      }
      
      public function get readyState() : int
      {
         return _readyState;
      }
   }
}
