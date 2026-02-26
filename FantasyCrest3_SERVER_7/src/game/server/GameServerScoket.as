package game.server
{
   import zygame.server.GameServer;
   import zygame.utils.IPUtils;
   
   public class GameServerScoket
   {
      private static var _server:GameServer; // 定义本地联机服务器

      private static var _ip:String; // 定义本地联机服务器的IP地址

      private static var _port:int; // 定义本地联机服务器的端口
      
      public function GameServerScoket()
      {
         super();
      }
      
      // public static function init() : void
      public static function init(inIp:String, inPort:int) : void //
      {
         //原本的创建本地连接服务器代码
         // var server:GameServer = new GameServer(ip,4888);
         if (!_server) // 修复尝试重复创建本地联机服务器的问题
         { //
            _ip = inIp; //
            _port = inPort; //
            _server = new GameServer(_ip, _port); //
         } //
      }

      public static function get ip() : String
      {
         // 原本的获取本地IP地址代码
         // return IPUtils.currentIP;
         return _ip //
      }

      public static function get port() : int //
      { //
         return _port //
      } //

      public static function get server():GameServer // 获取本地联机服务器实例
      { //
         return _server; //
      } //
   }
}

