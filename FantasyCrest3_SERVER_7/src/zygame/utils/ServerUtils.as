package zygame.utils
{
   import flash.net.Socket;
   import flash.net.SharedObject; //
   import zygame.server.BaseSocketClient;
   import zygame.server.Service;
   
   public class ServerUtils
   {
      
      public static var ip:String = "";
      
      public static var sending:Boolean = false;
      
      public function ServerUtils()
      {
         super();
      }
      
      public static function updateRoleData(userName:String, userCode:String, userData:Object, onUpdate:Function) : void
      {
         if(userData.fight) // 更新游戏战力
         { //
            Service.userData.fight = userData.fight; //
         } //
         Service.userData.userData.fight = Service.userData.fight; //
         if(userData.fbs) //
         { //
            Service.userData.fbs = userData.fbs; //
         } //
         Service.userData.userData.fbs = Service.userData.fbs; //
         if(userData.ofigth) // 更新联机战力
         { //
            Service.userData.ofigth = userData.ofigth; // 
         } //
         Service.userData.userData.ofigth = Service.userData.ofigth; // 更新联机战力至真正的在线用户数据内
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; // 缓存用户数据
         SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
         onUpdate(Service.userData); // 游戏中更新用户数据
         // 原本的更新用户数据的代码
         // var clinet:BaseSocketClient;
         // if(sending)
         // {
         //    return;
         // }
         // sending = true;
         // clinet = createSocket(userName,userCode,onUpdate);
         // clinet.dataFunc = function(data:Object):void
         // {
         //    if(data.type == "handed")
         //    {
         //       clinet.send({
         //          "type":"update_user_data",
         //          "userData":userData
         //       });
         //    }
         //    else if(data.type == "user_data")
         //    {
         //       sending = false;
         //       onUpdate(data.data);
         //       clinet.close();
         //    }
         // };
      }
      
      public static function buyRole(userName:String, userCode:String, roleName:String, target:String, coin:int, type:int, onUpdate:Function, mail:String = null) : void
      {
         if(type) // 水晶购买
         { //
            // if(Service.userData.crystal + coin >= 0) //
            if(true) // 无论如何都能购买
            { //
               Service.userData.crystal += coin; //
               Service.userData.userData.buys.push(target) //
               onUpdate(Service.userData); //
            } //
            else //
            { //
               onUpdate(null); //
            } //
         } //
         else // 金币购买
         { //
            // if(Service.userData.coin + coin >= 0) //
            if(true) // 无论如何都能购买
            { //
               Service.userData.coin += coin; //
               Service.userData.userData.buys.push(target) //
               onUpdate(Service.userData); //
            } //
            else //
            { //
               onUpdate(null); //
            } //
         } //
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; //缓存userData
         SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
         // 原本的购买角色的代码
         // var clinet:BaseSocketClient;
         // if(sending)
         // {
         //    return;
         // }
         // sending = true;
         // clinet = createSocket(userName,userCode,onUpdate);
         // clinet.dataFunc = function(data:Object):void
         // {
         //    if(data.type == "handed")
         //    {
         //       clinet.send({
         //          "type":"buyRole",
         //          "coin":coin,
         //          "coinType":type,
         //          "roleTarget":target,
         //          "roleName":target,
         //          "mail":mail
         //       });
         //    }
         //    else if(data.type == "user_data")
         //    {
         //       sending = false;
         //       onUpdate(data.data);
         //       clinet.close();
         //    }
         // };
      }
      
      public static function transferMoney(userName:String, userCode:String, coin:int, coinType:int, mail:String, onUpdate:Function) : void
      {
         onUpdate(Service.userData); // 更新游戏中的用户数据
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; // 缓存用户数据
         SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
         // 原本的转账代码
         // var clinet:BaseSocketClient;
         // if(sending)
         // {
         //    return;
         // }
         // sending = true;
         // clinet = createSocket(userName,userCode,onUpdate);
         // clinet.dataFunc = function(data:Object):void
         // {
         //    if(data.type == "handed")
         //    {
         //       clinet.send({
         //          "type":"transferMoney",
         //          "coin":coin,
         //          "mail":mail,
         //          "coinType":coinType
         //       });
         //    }
         //    else if(data.type == "user_data")
         //    {
         //       sending = false;
         //       onUpdate(data.data);
         //       clinet.close();
         //    }
         // };
      }
      
      public static function addCoin(userName:String, userCode:String, coin:int, onUpdate:Function, codeType:String = "addCoin") : void
      {
         Service.userData.coin += coin; // 增加金币
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; //缓存用户数据
         SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
         onUpdate(Service.userData); // 更新游戏中的用户数据
         // 原本的增加金币的代码
         // var clinet:BaseSocketClient;
         // if(sending)
         // {
         //    return;
         // }
         // sending = true;
         // clinet = createSocket(userName,userCode,onUpdate);
         // clinet.dataFunc = function(data:Object):void
         // {
         //    if(data.type == "handed")
         //    {
         //       clinet.send({
         //          "type":codeType,
         //          "coin":coin
         //       });
         //    }
         //    else if(data.type == "user_data")
         //    {
         //       sending = false;
         //       onUpdate(data.data);
         //       clinet.close();
         //    }
         // };
      }
      
      private static function createSocket(userName:String, userCode:String, onUpdate:Function) : BaseSocketClient
      {
         onUpdate(Service.userData); //
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; //
         SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
         return null; //
         // 原本的创建Socket连接的代码
         // var socket:Socket = new Socket(ip,4888);
         // var clinet:BaseSocketClient = new BaseSocketClient(socket);
         // clinet.handFunc = function():void
         // {
         //    trace("握手");
         //    clinet.send(SendDataUtils.handData(userName,userCode));
         // };
         // clinet.ioerrorFunc = function():void
         // {
         //    trace("登录失败");
         //    sending = false;
         //    onUpdate(null);
         // };
         // clinet.closeFunc = function():void
         // {
         //    trace("登录失败");
         //    sending = false;
         //    onUpdate(null);
         // };
         // return clinet;
      }
   }
}

