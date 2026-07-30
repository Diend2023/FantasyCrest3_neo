package game.server
{
   import game.role.GameRole;
   import game.skill.UDPSkill;
   import game.world.BaseGameWorld;
   import lzm.starling.swf.FPSUtil;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import zygame.core.GameCore;
   import zygame.display.BaseRole;
   import zygame.display.NumberFeedback;
   import zygame.display.RefRole;
   import zygame.display.World;
   import zygame.server.Service;
   
   public class HostRun2Model extends KeyRunModel
   {
      
      private var debug:FPSUtil = new FPSUtil(50);
      
      private static var _mergeFrameCount:int = 0; // P0优化：合并打包帧计数，用于全量同步周期
      private var _netLastCopyDataDict:Object = {}; // P0优化：按pid缓存角色上次全量数据
      
      public function HostRun2Model(roleTarget:String)
      {
         super(roleTarget);
         Service.client.messageFunc = onMessage;
         Service.client.udpFunc = onUDPMessage;
         Service.client.delayFunc = onDelay;
      }
      
      public function onDelay() : void
      {
         if(Starling.current.statsDisplay.fps < 30 || Service.client.delay > 200)
         {
            sendWifiLevel(0);
         }
         else if(Starling.current.statsDisplay.fps < 50 || Service.client.delay > 100)
         {
            sendWifiLevel(1);
         }
         else
         {
            sendWifiLevel(2);
         }
      }
      
      public function onUDPMessage(data:Object) : void
      {
         var funcRole:GameRole = null;
         var wifirole:BaseRole = null;
         var role:BaseRole = null;
         var newKeys:Array = null;
         var oldKeys:Array = null;
         switch(data.target)
         {
            case "func":
               funcRole = GameCore.currentWorld.getRoleFormName(data.role) as GameRole;
               if(funcRole)
               {
                  funcRole.doFunc(data.func,data.ret);
               }
               break;
            case "wifi":
               wifirole = GameCore.currentWorld.getRoleFormName(data.id);
               if(wifirole)
               {
                  (wifirole as GameRole).hpmpDisplay.wifi.updateLevel(data.level);
               }
               break;
            case "keys":
               if(!GameCore.currentWorld.auto)
               {
                  return;
               }
               role = GameCore.currentWorld.getRoleFormName(data.role);
               if(!role)
               {
                  break;
               }
               newKeys = data.key;
               oldKeys = role.getDownKeys();
               // for(var i in oldKeys)
               // {
               //    if(newKeys.indexOf(oldKeys[i]) == -1)
               //    {
               //       role.onUp(oldKeys[i]);
               //    }
               // }
               // var _loc12_:int = 0;
               // var _loc11_:* = newKeys;
               // while(§§hasnext(_loc11_,_loc12_))
               // {
               //    var i2:Object = §§nextname(_loc12_,_loc11_);
               //    if(oldKeys.indexOf(newKeys[i2]) == -1)
               //    {
               //       role.onDown(newKeys[i2]);
               //    }
               // }
               // 修复反编译错误，改为正常的for循环
               var i:int = 0; //
               for(i = 0; i < oldKeys.length; i++) //
               { //
                  if(newKeys.indexOf(oldKeys[i]) == -1) //
                  { //
                     role.onUp(oldKeys[i]); //
                  } //
               } //
               var j:int = 0; //
               for(j = 0; j < newKeys.length; j++) //
               { //
                  if(oldKeys.indexOf(newKeys[j]) == -1) //
                  { //
                     role.onDown(newKeys[j]); //
                  } //
               } //
               break;
            case "down":
               if(!GameCore.currentWorld.auto)
               {
                  return;
               }
               GameCore.currentWorld.getRoleFormName(data.role).onDown(data.key);
               break;
            case "up":
               if(!GameCore.currentWorld.auto)
               {
                  return;
               }
               GameCore.currentWorld.getRoleFormName(data.role).onUp(data.key);
         }
      }
      
      public function onMessage(data:Object) : void
      {
         var _loc2_:* = data.target;
         if("updateRunModel" === _loc2_)
         {
            GameCore.currentWorld.runModel = new AccessRun3Model(target);
         }
      }
      
      override public function onAddChild(child:DisplayObject) : void
      {
         if(child is NumberFeedback)
         {
            Service.radioUDP({
               "type":"radio",
               "data":{
                  "target":"hurt",
                  "num":(child as NumberFeedback).hurtNumber,
                  "crit":(child as NumberFeedback).crit,
                  "x":child.x,
                  "y":child.y
               }
            });
         }
      }
      
      override public function onCDChange(role:BaseRole, skillName:String) : void
      {
         Service.radioUDP({
            "type":"radio",
            "data":{
               "target":"cd",
               "role":role.name,
               "data":role.attribute.cdData
            }
         });
      }
      
      override public function onRoleFrame(role:RefRole) : Boolean
      {
         return false;
      }
      
      override public function onFrame() : Boolean
      {
         super.onFrame();
         sendWorldMessage();
         return false;
      }
      
      private function sendWorldMessage() : void
      {
         var num:int;
         var i:int;
         var skill:UDPSkill;
         var world:World = GameCore.currentWorld;
         var curFrame:int = (world as BaseGameWorld).frameCount;
         // 原始逐角色独立发送（注释保留）
         // world.getRoleList().forEach(function(role:BaseRole, index:int, v:Vector.<BaseRole>):void
         // {
         //    Service.radioUDP({
         //       "type":"radio",
         //       "data":{
         //          "type":"room_message",
         //          "target":"role",
         //          "frame":curFrame,
         //          "data":{
         //             "name":role.targetName,
         //             "id":role.pid,
         //             "data":(role as GameRole).copyData()
         //          }
         //       }
         //    });
         // });
         // P0优化：合并打包 + 差异编码
         _mergeFrameCount++; //
         var isFullFrame:Boolean = (_mergeFrameCount % 30 == 0); //
         var rolesData:Array = []; //
         var skillsData:Array = []; //
         var lastCopyDict:Object = _netLastCopyDataDict; //
         world.getRoleList().forEach(function(role:BaseRole, index:int, v:Vector.<BaseRole>):void //
         { //
            var fullData:Object = (role as GameRole).copyData(); //
            var lastData:Object = lastCopyDict[role.pid]; //
            var sendData:Object; //
            if(isFullFrame || lastData == null) //
            { //
               lastCopyDict[role.pid] = fullData; //
               fullData.full = true; //
               sendData = fullData; //
            } //
            else //
            { //
               var delta:Object = {full:false}; //
               for(var dk:String in fullData) //
               { //
                  if(!HostRun2Model._netIsSameValue(fullData[dk], lastData[dk])) //
                  { //
                     delta[dk] = fullData[dk]; //
                  } //
               } //
               lastCopyDict[role.pid] = fullData; //
               sendData = delta; //
            } //
            rolesData.push({ //
               "name":role.targetName, //
               "id":role.pid, //
               "data":sendData //
            }); //
         }); //
         num = world.map.roleLayer.numChildren;
         for(i = 0; i < num; )
         {
            skill = world.map.roleLayer.getChildAt(i) as UDPSkill;
            if(skill)
            {
               // Service.radioUDP({ // 原始逐技能独立发送
               //    "type":"radio",
               //    "data":{
               //       "type":"room_message",
               //       "target":"skill",
               //       "frame":curFrame,
               //       "data":skill.copyData()
               //    }
               // });
               skillsData.push(skill.copyData()); // P0优化：收集到技能数组中
            }
            i++;
         }
         Service.radioUDP({ //
            "type":"radio", //
            "data":{ //
               "type":"room_message", //
               "frame":curFrame, //
               "roles":rolesData, //
               "skills":skillsData //
            } //
         }); //
      }
      // P0优化：差异编码值比较
      private static function _netIsSameValue(a:*, b:*):Boolean //
      { //
         if(a is Array && b is Array) //
         { //
            var arrA:Array = a as Array; //
            var arrB:Array = b as Array; //
            if(arrA.length != arrB.length) return false; //
            for(var arrIdx:int = 0; arrIdx < arrA.length; arrIdx++) //
            { //
               if(arrA[arrIdx] != arrB[arrIdx]) return false; //
            } //
            return true; //
         } //
         return a == b; //
      }
   }
}

