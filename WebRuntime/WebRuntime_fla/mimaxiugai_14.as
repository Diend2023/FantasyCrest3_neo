package WebRuntime_fla
{
   import adobe.utils.*;
   import flash.accessibility.*;
   import flash.desktop.*;
   import flash.display.*;
   import flash.errors.*;
   import flash.events.*;
   import flash.external.*;
   import flash.filters.*;
   import flash.geom.*;
   import flash.globalization.*;
   import flash.media.*;
   import flash.net.*;
   import flash.net.drm.*;
   import flash.printing.*;
   import flash.profiler.*;
   import flash.sampler.*;
   import flash.sensors.*;
   import flash.system.*;
   import flash.text.*;
   import flash.text.engine.*;
   import flash.text.ime.*;
   import flash.ui.*;
   import flash.utils.*;
   import flash.xml.*;
   import zygame.server.BaseSocketClient;
   import zygame.utils.SendDataUtils;
   
   public dynamic class mimaxiugai_14 extends MovieClip
   {
      
      public var back:SimpleButton;
      
      public var code:TextField;
      
      public var dengji:SimpleButton;
      
      public var getcode:SimpleButton;
      
      public var mail:TextField;
      
      public var userCode:TextField;
      
      public var userCode2:TextField;
      
      public function mimaxiugai_14()
      {
         super();
      }
      
      public function onClick(param1:MouseEvent) : void
      {
         if(param1.target == this.getcode)
         {
            this.getCode();
         }
         else if(param1.target == this.back)
         {
            this.visible = false;
         }
         else if(param1.target == this.dengji)
         {
            this.ZC();
         }
      }
      
      public function getCode() : void
      {
         var socket:Socket = null;
         var clinet:BaseSocketClient = null;
         if(this.mail.text != "")
         {
            this.getcode.visible = false;
            socket = new Socket("120.79.155.18",4888);
            clinet = new BaseSocketClient(socket);
            clinet.handFunc = function():void
            {
               trace("握手");
               clinet.send(SendDataUtils.handData("tourists","tourists"));
            };
            clinet.ioerrorFunc = function():void
            {
               trace("登录失败");
               loginShow();
            };
            clinet.closeFunc = function():void
            {
               trace("登录失败");
               loginShow();
            };
            clinet.dataFunc = function(param1:Object):void
            {
               trace(JSON.stringify(param1));
               if(param1.type == "handed")
               {
                  trace("getCode登录成功");
                  clinet.send({
                     "type":"getCode",
                     "mail":mail.text
                  });
               }
               else if(param1.type == "getCode")
               {
                  clinet.close();
                  loginShow();
                  trace("获取验证码：",param1.code);
               }
            };
         }
      }
      
      public function ZC() : void
      {
         var socket:Socket = null;
         var clinet:BaseSocketClient = null;
         if(this.mail.text != "" && this.userCode.text != "" && this.userCode2.text != "" && this.code.text != "")
         {
            if(this.userCode.text != this.userCode2.text)
            {
               return;
            }
            socket = new Socket("120.79.155.18",4888);
            clinet = new BaseSocketClient(socket);
            clinet.handFunc = function():void
            {
               trace("握手");
               clinet.send(SendDataUtils.handData("tourists","tourists"));
            };
            clinet.ioerrorFunc = function():void
            {
               trace("登录失败");
               loginShow();
            };
            clinet.closeFunc = function():void
            {
               trace("登录失败");
               loginShow();
            };
            clinet.dataFunc = function(param1:Object):void
            {
               trace(JSON.stringify(param1));
               if(param1.type == "handed")
               {
                  trace("登录成功");
                  clinet.send({
                     "type":"modificationUserCode",
                     "mail":mail.text,
                     "userCode":userCode.text,
                     "code":code.text
                  });
               }
               else if(param1.type == "modificationUserCode")
               {
                  clinet.close();
                  if(param1.isOk)
                  {
                     visible = false;
                  }
               }
            };
         }
      }
      
      public function loginShow() : void
      {
         this.getcode.visible = true;
      }
   }
}

