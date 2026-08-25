package game.data
{
   import flash.utils.ByteArray;
   import flash.utils.getQualifiedClassName; // 用于录像记录世界类名
   import game.role.GameRole;
   import game.skill.UDPSkill;
   import game.view.GameStartMain; // 读取录像元数据（模式label/mode/situation）
   import game.world.BaseGameWorld;
   import zygame.display.BaseRole;
   
   public class WorldRecordData
   {
      
      public var worldDatas:Array;
      
      private var _stop:Boolean = false;
      
      public var worldClass:String;
      
      // 录像元数据（v2格式），供录像列表与回放重建使用
      public var worldClassName:String; // 世界类名（getQualifiedClassName取末段，如"_1V1"）

      public var mapName:String; // 地图名

      public var team1Roles:Array; // 队伍1角色名列表（troopid=0）

      public var team2Roles:Array; // 队伍2角色名列表（troopid=1）

      public var gameModeLabel:String; // 主菜单模式label

      public var gameMode:String; // 模式mode

      public var situation:String; // 对局模式

      public var createTime:Number; // 录像时间戳

      public var totalFrames:int; // 总帧数
      
      public function WorldRecordData(byte:ByteArray = null)
      {
         super();
         if(byte)
         {
            // worldDatas = byte.readObject();
            // byte.clear();
            // _stop = true;
            // 读取v2头部元数据
            worldClassName = byte.readUTF(); //
            mapName = byte.readUTF(); //
            team1Roles = byte.readObject() as Array; //
            team2Roles = byte.readObject() as Array; //
            gameModeLabel = byte.readUTF(); //
            gameMode = byte.readUTF(); //
            situation = byte.readUTF(); //
            createTime = byte.readDouble(); //
            totalFrames = byte.readInt(); //
            worldDatas = byte.readObject(); //
            byte.clear(); //
            _stop = true; //
         }
         else
         {
            worldDatas = [];
         }
      }
      
      public function initWorld(world:BaseGameWorld) : void
      {
         worldClass = String(world);
         // 采集回放所需元数据（worldClassName存完整限定名，回放用getDefinitionByName还原世界类）
         worldClassName = getQualifiedClassName(world); //
         mapName = world.targetName; //
         team1Roles = []; //
         team2Roles = []; //
         var _roles:Vector.<BaseRole> = world.getRoleList(); //
         for(var _i:int = 0; _i < _roles.length; _i++) //
         { //
            if(_roles[_i].troopid == 0) //
            { //
               team1Roles.push(_roles[_i].targetName); //
            } //
            else if(_roles[_i].troopid == 1) //
            { //
               team2Roles.push(_roles[_i].targetName); //
            } //
         } //
         gameModeLabel = (GameStartMain.recordModeLabel == null ? "" : GameStartMain.recordModeLabel); //
         gameMode = (GameStartMain.recordMode == null ? "" : GameStartMain.recordMode); //
         situation = (GameStartMain.recordSituation == null || GameStartMain.recordSituation == "" ? "普通局" : GameStartMain.recordSituation); //
         createTime = new Date().time; //
      }
      
      public function pushWorld(world:BaseGameWorld) : void
      {
         var arr:Array;
         var curFrame:int;
         var num:int;
         var i:int;
         var skill:UDPSkill;
         if(_stop)
         {
            return;
         }
         arr = [];
         curFrame = (world as BaseGameWorld).frameCount;
         world.getRoleList().forEach(function(role:BaseRole, index:int, v:Vector.<BaseRole>):void
         {
            arr.push({
               "frame":curFrame,
               "target":"role",
               "name":role.targetName,
               "id":role.pid,
               "data":(role as GameRole).copyData()
            });
         });
         num = world.map.roleLayer.numChildren;
         for(i = 0; i < num; )
         {
            skill = world.map.roleLayer.getChildAt(i) as UDPSkill;
            if(skill)
            {
               arr.push({
                  "target":"skill",
                  "frame":curFrame,
                  "data":skill.copyData()
               });
            }
            i++;
         }
         worldDatas.push(arr);
         totalFrames = worldDatas.length; // 记录总帧数
      }
      
      public function playWorld(world:BaseGameWorld) : void
      {
      }
      
      public function get bytes() : ByteArray
      {
         var byte:ByteArray = new ByteArray();
         // byte.writeUTFBytes(worldClass);
         // byte.writeObject(worldDatas);
         // 写入v2头部元数据（writeUTF遇到null会抛Error #2007，统一兜底）
         byte.writeUTF(worldClassName == null ? "" : worldClassName); //
         byte.writeUTF(mapName == null ? "" : mapName); //
         byte.writeObject(team1Roles == null ? [] : team1Roles); //
         byte.writeObject(team2Roles == null ? [] : team2Roles); //
         byte.writeUTF(gameModeLabel == null ? "" : gameModeLabel); //
         byte.writeUTF(gameMode == null ? "" : gameMode); //
         byte.writeUTF(situation == null ? "" : situation); //
         byte.writeDouble(createTime); //
         byte.writeInt(totalFrames); //
         byte.writeObject(worldDatas); //
         return byte;
      }
      
      public function stop() : void
      {
         _stop = true;
      }
      
      // 录像换人事件标记（AssistWorld.replaceRole成功换人时调用，回放端据此重放换人流程）
      public function pushSwap(outName:String, enterName:String) : void //
      { //
         if(!_stop) //
         { //
            worldDatas.push([{target:"swap",out:outName,"in":enterName}]); //
            totalFrames = worldDatas.length; //
         } //
      } //
   }
}

