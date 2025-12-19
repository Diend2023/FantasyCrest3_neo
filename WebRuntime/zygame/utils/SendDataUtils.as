package zygame.utils
{
   import zygame.server.Service;
   
   public class SendDataUtils
   {
      
      public function SendDataUtils()
      {
         super();
      }
      
      public static function handData(param1:String, param2:String) : Object
      {
         return {
            "type":"hand",
            "userName":param1,
            "userCode":param2
         };
      }
      
      public static function userData(param1:Object) : Object
      {
         return {
            "type":"user_data",
            "data":param1
         };
      }
      
      public static function messageData(param1:String, param2:String) : Object
      {
         return {
            "type":"message",
            "msg":param1,
            "target":param2
         };
      }
      
      public static function roomList(param1:Array) : Object
      {
         return {
            "type":"room_list",
            "list":param1
         };
      }
      
      public static function createRoom(param1:String, param2:int, param3:String) : Object
      {
         return {
            "type":"create_room",
            "mode":param1,
            "count":param2,
            "code":param3
         };
      }
      
      public static function joinRoom(param1:int, param2:String) : Object
      {
         return {
            "type":"join_room",
            "id":param1,
            "code":param2
         };
      }
      
      public static function exitRoom(param1:int) : Object
      {
         return {
            "type":"exit_room",
            "id":param1
         };
      }
      
      public static function setRoleData(param1:Object) : Object
      {
         return {
            "type":"set_room_player_data",
            "data":param1
         };
      }
      
      public static function getRoleData() : Object
      {
         return {"type":"get_room_player_data"};
      }
      
      public static function changeRole(param1:String) : Object
      {
         Service.client.type = param1;
         return {
            "type":"change_role",
            "change":param1
         };
      }
   }
}

