package game.server
{
   /**
    * 游戏服务器配置 - 已改为hxonline+go-websocket-server架构
    * 不再需要本地启动GameServer，直接连接到go-websocket-server
    */
   public class GameServerScoket
   {
      private static var _ip:String = "127.0.0.1";
      
      private static var _port:int = 8888;
      
      public function GameServerScoket()
      {
         super();
      }
      
      /**
       * 不再需要初始化本地服务器，go-websocket-server已替代
       */
      public static function init(inIp:String = null, inPort:int = 8888) : void
      {
         if(inIp != null)
         {
            _ip = inIp;
         }
         _port = inPort;
         trace("[GameServerScoket]已切换为hxonline+go-websocket-server架构，无需本地服务器");
      }

      public static function get ip() : String
      {
         return _ip;
      }

      public static function get port() : int
      {
         return _port;
      }
   }
}

