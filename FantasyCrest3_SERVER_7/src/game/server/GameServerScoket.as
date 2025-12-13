package game.server
{
   import zygame.server.GameServer;
   import zygame.utils.IPUtils;
   
   public class GameServerScoket
   {
      private static var _server:GameServer; // 定义本地联机服务器
      
      public function GameServerScoket()
      {
         super();
      }
      
      public static function init() : void
      {
         //原本的创建本地连接服务器代码
         // var server:GameServer = new GameServer(ip,4888);
         if (!_server) // 修复尝试重复创建本地联机服务器的问题
         { //
            _server = new GameServer(ip, 4888); //
         } //
      }

      public static function get ip() : String
      {
         // 原本的获取本地IP地址代码
         // return IPUtils.currentIP;
         return "127.0.0.1"; // 默认使用本地回环地址
      }

      public static function get server():GameServer // 获取本地联机服务器实例
      { //
         return _server; //
      } //
   }
}

