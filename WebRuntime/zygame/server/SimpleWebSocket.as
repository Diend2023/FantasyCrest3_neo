package zygame.server
{
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.events.SecurityErrorEvent;
   import flash.net.Socket;
   import flash.utils.ByteArray;
   import flash.utils.Endian;
   import flash.utils.Timer;
   import flash.events.TimerEvent;
   
   /**
    * 轻量级WebSocket客户端 - 替代hxonline中存在isNaN兼容问题的WebSocket实现
    * 直接使用Flash原生Socket实现WebSocket协议
    */
   public class SimpleWebSocket
   {
      
      public static const CONNECTING:int = 0;
      public static const OPEN:int = 1;
      public static const CLOSING:int = 2;
      public static const CLOSED:int = 3;
      
      private var _socket:Socket;
      private var _host:String;
      private var _port:int;
      private var _path:String;
      private var _readyState:int = CLOSED;
      private var _handshakeDone:Boolean = false;
      private var _buffer:ByteArray;
      private var _writeBuffer:ByteArray;
      private var _flushTimer:Timer;
      
      public var onOpen:Function;
      public var onMessage:Function;
      public var onClose:Function;
      public var onError:Function;
      
      public function SimpleWebSocket(url:String)
      {
         _buffer = new ByteArray();
         _buffer.endian = Endian.BIG_ENDIAN;
         _writeBuffer = new ByteArray();
         // 每16ms检查一次是否有待发送数据
         _flushTimer = new Timer(16);
         _flushTimer.addEventListener(TimerEvent.TIMER, onFlushTimer);
         _flushTimer.start();
         parseUrl(url);
      }
      
      private function onFlushTimer(e:TimerEvent) : void
      {
         flushWriteBuffer();
      }
      
      private function parseUrl(url:String) : void
      {
         var parts:Array = url.replace("ws://", "").replace("wss://", "").split("/");
         var hostPort:Array = parts[0].split(":");
         _host = hostPort[0];
         _port = hostPort.length > 1 ? int(hostPort[1]) : 80;
         _path = parts.length > 1 ? "/" + parts.slice(1).join("/") : "/";
      }
      
      public function connect() : void
      {
         _readyState = CONNECTING;
         _handshakeDone = false;
         _socket = new Socket();
         _socket.addEventListener(Event.CONNECT, onSocketConnect);
         _socket.addEventListener(Event.CLOSE, onSocketClose);
         _socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
         _socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketSecurityError);
         _socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
         _socket.connect(_host, _port);
      }
      
      private function onSocketConnect(e:Event) : void
      {
         sendHandshake();
      }
      
      private function sendHandshake() : void
      {
         // 生成随机的Sec-WebSocket-Key
         var keyBytes:ByteArray = new ByteArray();
         for(var i:int = 0; i < 16; i++)
         {
            keyBytes.writeByte(int(Math.random() * 256));
         }
         keyBytes.position = 0;
         var key:String = base64Encode(keyBytes);
         
         var request:String = "GET " + _path + " HTTP/1.1\r\n" +
            "Host: " + _host + ":" + _port + "\r\n" +
            "Upgrade: websocket\r\n" +
            "Connection: Upgrade\r\n" +
            "Sec-WebSocket-Key: " + key + "\r\n" +
            "Sec-WebSocket-Version: 13\r\n" +
            "\r\n";
         
         _socket.writeUTFBytes(request);
         _socket.flush();
      }
      
      private function onSocketData(e:ProgressEvent) : void
      {
         if(!_handshakeDone)
         {
            readHandshakeResponse();
         }
         else
         {
            readFrames();
         }
      }
      
      private function readHandshakeResponse() : void
      {
         // 将新数据追加到持久缓冲区
         _socket.readBytes(_buffer, _buffer.length, _socket.bytesAvailable);
         _buffer.position = 0;
         var response:String = _buffer.readUTFBytes(_buffer.length);
         
         if(response.indexOf("101") != -1 && response.indexOf("\r\n\r\n") != -1)
         {
            _handshakeDone = true;
            _readyState = OPEN;
            if(onOpen != null)
            {
               onOpen();
            }
            
            // 检查是否有剩余数据（帧数据紧跟在握手之后）
            var headerEnd:int = response.indexOf("\r\n\r\n");
            var headerBytes:int = headerEnd + 4;
            if(_buffer.length > headerBytes)
            {
               // 保留握手之后的帧数据
               var remaining:ByteArray = new ByteArray();
               _buffer.position = headerBytes;
               _buffer.readBytes(remaining, 0, _buffer.length - headerBytes);
               _buffer.clear();
               remaining.position = 0;
               _buffer = remaining;
               processFrameData(_buffer);
            }
            else
            {
               _buffer.clear();
            }
         }
      }
      
      private function readFrames() : void
      {
         // 将新数据追加到持久缓冲区
         _socket.readBytes(_buffer, _buffer.length, _socket.bytesAvailable);
         _buffer.position = 0;
         processFrameData(_buffer);
         // 帧处理完成后立即flush（处理期间send/sendPong写入_writeBuffer）
         flushWriteBuffer();
      }
      
      private function processFrameData(data:ByteArray) : void
      {
         var startPos:int = data.position;
         while(data.bytesAvailable >= 2)
         {
            startPos = data.position;
            var firstByte:int = data.readUnsignedByte();
            var secondByte:int = data.readUnsignedByte();
            
            var opcode:int = firstByte & 0x0F;
            var fin:Boolean = (firstByte & 0x80) != 0;
            var isMasked:Boolean = (secondByte & 0x80) != 0;
            var payloadLength:int = secondByte & 0x7F;
            
            if(payloadLength == 126)
            {
               if(data.bytesAvailable < 2)
               {
                  data.position = startPos;
                  compactBuffer(data);
                  return;
               }
               payloadLength = data.readUnsignedShort();
            }
            else if(payloadLength == 127)
            {
               if(data.bytesAvailable < 8)
               {
                  data.position = startPos;
                  compactBuffer(data);
                  return;
               }
               data.readUnsignedInt();
               payloadLength = data.readUnsignedInt();
            }
            
            var maskKey:ByteArray = null;
            if(isMasked)
            {
               if(data.bytesAvailable < 4)
               {
                  data.position = startPos;
                  compactBuffer(data);
                  return;
               }
               maskKey = new ByteArray();
               data.readBytes(maskKey, 0, 4);
            }
            
            if(data.bytesAvailable < payloadLength)
            {
               // 帧不完整，回退位置并保留未完成数据
               data.position = startPos;
               compactBuffer(data);
               return;
            }
            
            var payload:ByteArray = new ByteArray();
            data.readBytes(payload, 0, payloadLength);
            
            if(isMasked && maskKey != null)
            {
               unmask(payload, maskKey);
            }
            
            // 处理不同的opcode
            switch(opcode)
            {
               case 0x01: // 文本帧
                  payload.position = 0;
                  var text:String = payload.readUTFBytes(payloadLength);
                  trace("[WS:RECV] " + text);
                  if(onMessage != null)
                  {
                     onMessage(text);
                  }
                  break;
               case 0x02: // 二进制帧
                  payload.position = 0;
                  if(onMessage != null)
                  {
                     onMessage(payload);
                  }
                  break;
               case 0x08: // 关闭帧
                  _readyState = CLOSED;
                  if(onClose != null)
                  {
                     onClose();
                  }
                  return;
               case 0x09: // Ping
                  sendPong(payload);
                  break;
               case 0x0A: // Pong
                  // 忽略
                  break;
            }
         }
         // 所有完整帧处理完毕，清除已处理数据
         compactBuffer(data);
      }
      
      /**
       * 将缓冲区中已处理的数据清除，保留未处理的数据
       */
      private function compactBuffer(data:ByteArray) : void
      {
         var remaining:int = data.bytesAvailable;
         if(remaining > 0)
         {
            var newData:ByteArray = new ByteArray();
            data.readBytes(newData, 0, remaining);
            newData.position = 0;
            _buffer = newData;
         }
         else
         {
            data.clear();
         }
      }
      
      /**
       * 将写缓冲区数据发送到socket
       */
      private function flushWriteBuffer() : void
      {
         if(_writeBuffer.length > 0 && _socket != null && _socket.connected)
         {
            _writeBuffer.position = 0;
            _socket.writeBytes(_writeBuffer);
            _socket.flush();
            _writeBuffer.clear();
         }
      }
      
      /**
       * 发送文本消息
       */
      public function send(message:String) : void
      {
         if(_readyState != OPEN)
         {
            return;
         }
         
         var payload:ByteArray = new ByteArray();
         payload.writeUTFBytes(message);
         payload.position = 0;
         
         var frame:ByteArray = new ByteArray();
         
         // 第一个字节：FIN + opcode (文本帧 = 0x01)
         frame.writeByte(0x81);
         
         // 第二个字节：mask位 + 长度
         var len:int = payload.length;
         if(len < 126)
         {
            frame.writeByte(0x80 | len); // 客户端必须设置mask位
         }
         else if(len < 65536)
         {
            frame.writeByte(0x80 | 126);
            frame.writeShort(len);
         }
         else
         {
            frame.writeByte(0x80 | 127);
            frame.writeUnsignedInt(0);
            frame.writeUnsignedInt(len);
         }
         
         // 4字节mask key
         var maskKey:ByteArray = new ByteArray();
         for(var i:int = 0; i < 4; i++)
         {
            maskKey.writeByte(int(Math.random() * 256));
         }
         maskKey.position = 0;
         frame.writeBytes(maskKey);
         
         // 掩码后的payload
         var maskedPayload:ByteArray = new ByteArray();
         payload.position = 0;
         payload.readBytes(maskedPayload, 0, payload.length);
         maskedPayload.position = 0;
         maskKey.position = 0;
         for(var j:int = 0; j < maskedPayload.length; j++)
         {
            maskedPayload[j] = maskedPayload[j] ^ maskKey[j % 4];
         }
         
         frame.writeBytes(maskedPayload);
         
         // 所有写入统一走_writeBuffer
         frame.position = 0;
         _writeBuffer.writeBytes(frame);
      }
      
      private function sendPong(payload:ByteArray) : void
      {
         var frame:ByteArray = new ByteArray();
         frame.writeByte(0x8A); // FIN + Pong
         frame.writeByte(0x80 | payload.length); // mask + length
         
         var maskKey:ByteArray = new ByteArray();
         for(var i:int = 0; i < 4; i++)
         {
            maskKey.writeByte(int(Math.random() * 256));
         }
         frame.writeBytes(maskKey);
         
         payload.position = 0;
         for(var j:int = 0; j < payload.length; j++)
         {
            frame.writeByte(payload[j] ^ maskKey[j % 4]);
         }
         
         frame.position = 0;
         _writeBuffer.writeBytes(frame);
      }
      
      
      private function unmask(data:ByteArray, maskKey:ByteArray) : void
      {
         data.position = 0;
         for(var i:int = 0; i < data.length; i++)
         {
            data[i] = data[i] ^ maskKey[i % 4];
         }
         data.position = 0;
      }
      
      public function close() : void
      {
         if(_flushTimer)
         {
            _flushTimer.stop();
            _flushTimer.removeEventListener(TimerEvent.TIMER, onFlushTimer);
            _flushTimer = null;
         }
         if(_readyState == OPEN)
         {
            _readyState = CLOSING;
            var frame:ByteArray = new ByteArray();
            frame.writeByte(0x88); // FIN + Close
            frame.writeByte(0x80 | 0); // mask + 0 length
            var maskKey:ByteArray = new ByteArray();
            for(var i:int = 0; i < 4; i++)
            {
               maskKey.writeByte(int(Math.random() * 256));
            }
            frame.writeBytes(maskKey);
            frame.position = 0;
            _socket.writeBytes(frame);
            _socket.flush();
         }
         _socket.close();
         _readyState = CLOSED;
      }
      
      public function get readyState() : int
      {
         return _readyState;
      }
      
      private function onSocketClose(e:Event) : void
      {
         _readyState = CLOSED;
         if(onClose != null)
         {
            onClose();
         }
      }
      
      private function onSocketError(e:IOErrorEvent) : void
      {
         _readyState = CLOSED;
         if(onError != null)
         {
            onError(e.text);
         }
      }
      
      private function onSocketSecurityError(e:SecurityErrorEvent) : void
      {
         _readyState = CLOSED;
         if(onError != null)
         {
            onError(e.text);
         }
      }
      
      /**
       * Base64编码
       */
      private static const BASE64_CHARS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      
      private function base64Encode(data:ByteArray) : String
      {
         var output:String = "";
         data.position = 0;
         var remaining:int = data.length;
         
         while(remaining >= 3)
         {
            var b0:int = data.readUnsignedByte();
            var b1:int = data.readUnsignedByte();
            var b2:int = data.readUnsignedByte();
            output += BASE64_CHARS.charAt((b0 >> 2) & 0x3F);
            output += BASE64_CHARS.charAt(((b0 << 4) | (b1 >> 4)) & 0x3F);
            output += BASE64_CHARS.charAt(((b1 << 2) | (b2 >> 6)) & 0x3F);
            output += BASE64_CHARS.charAt(b2 & 0x3F);
            remaining -= 3;
         }
         
         if(remaining == 2)
         {
            var r0:int = data.readUnsignedByte();
            var r1:int = data.readUnsignedByte();
            output += BASE64_CHARS.charAt((r0 >> 2) & 0x3F);
            output += BASE64_CHARS.charAt(((r0 << 4) | (r1 >> 4)) & 0x3F);
            output += BASE64_CHARS.charAt((r1 << 2) & 0x3F);
            output += "=";
         }
         else if(remaining == 1)
         {
            var s0:int = data.readUnsignedByte();
            output += BASE64_CHARS.charAt((s0 >> 2) & 0x3F);
            output += BASE64_CHARS.charAt((s0 << 4) & 0x3F);
            output += "==";
         }
         
         return output;
      }
   }
}
