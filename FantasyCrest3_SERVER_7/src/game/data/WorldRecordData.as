package game.data
{
   import flash.utils.ByteArray;
   import game.role.GameRole;
   import game.skill.UDPSkill;
   import game.world.BaseGameWorld;
   import zygame.display.BaseRole;
   import flash.utils.Dictionary; //

   
   public class WorldRecordData
   {
      
      public var worldDatas:Array;
      
      private var _stop:Boolean = false;
      
      public var worldClass:String;

      private var _playback:Boolean = false; //
      private var _skillCache:Dictionary = new Dictionary(); //
      
      public function WorldRecordData(byte:ByteArray = null)
      {
         super();
         if(byte)
         {
            // worldDatas = byte.readObject();
            _playback = true; //
            try { byte.uncompress(); } catch(e:Error) {} //
            worldDatas = readWorldDatas(byte); //
            byte.clear();
            _stop = true;
         }
         else
         {
            worldDatas = [];
         }
      }
      
      public function get isPlayback():Boolean //
      { //
         return _playback; //
      } //
      
      private function readWorldDatas(byte:ByteArray):Array //
      { //
         var data:Object; //
         try //
         { //
            byte.position = 0; //
            worldClass = byte.readUTF(); //
            data = byte.readObject(); //
            if(data is Array) return data as Array; //
         } //
         catch(e:Error) //
         { //
         } //
         try //
         { //
            byte.position = 0; //
            data = byte.readObject(); //
            if(data is Array) return data as Array; //
         } //
         catch(e2:Error) //
         { //
         } //
         try //
         { //
            for(var i:int = 0; i < byte.length; i++) //
            { //
               var b:int = byte[i]; //
               if(b == 9 || b == 10) //
               { //
                  byte.position = i; //
                  data = byte.readObject(); //
                  if(data is Array) return data as Array; //
               } //
            } //
         } //
         catch(e3:Error) //
         { //
         } //
         return []; //
      } //

      public function initWorld(world:BaseGameWorld) : void
      {
         worldClass = String(world);
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
      }
      
      public function playWorld(world:BaseGameWorld) : void
      {
         if(!worldDatas || worldDatas.length == 0) //
         { //
            return; //
         } //
         var index:int = world.frameCount; //
         if(index >= worldDatas.length) //
         { //
            _stop = true; //
            return; //
         } //
         var frameArr:Array = worldDatas[index] as Array; //
         if(!frameArr) //
         { //
            return; //
         } //
         
         var keep:Dictionary = new Dictionary(); //
         var roles:Vector.<BaseRole> = world.getRoleList(); //
         
         for each(var item:Object in frameArr) //
         { //
            if(item.target == "role") //
            { //
               var rid:int = int(item.id); //
               for each(var r:BaseRole in roles) //
               { //
                  if(r && r.pid == rid && r is GameRole) //
                  { //
                     (r as GameRole).setData(item.data); //
                     break; //
                  } //
               } //
            } //
            else if(item.target == "skill") //
            { //
               var sd:Object = item.data; //
               if(!sd) continue; //
               var key:String = sd.roleid + ":" + sd.name; //
               var sk:UDPSkill = _skillCache[key]; //
               if(!sk || sk.parent == null) //
               { //
                  var owner:BaseRole = null; //
                  for each(var rr:BaseRole in roles) //
                  { //
                     if(rr && rr.pid == int(sd.roleid)) //
                     { //
                        owner = rr; //
                        break; //
                     } //
                  } //
                  if(owner) //
                  { //
                     sk = new UDPSkill(sd.name, {}, owner); //
                     world.map.roleLayer.addChild(sk); //
                     _skillCache[key] = sk; //
                  } //
               } //
               if(sk) //
               { //
                  sk.setData(sd); //
                  keep[key] = true; //
               } //
            } //
         } //
         
         for(var k:String in _skillCache) //
         { //
            if(!keep[k]) //
            { //
               var oldSkill:UDPSkill = _skillCache[k]; //
               if(oldSkill) //
               { //
                  if("discarded" in oldSkill) //
                  { //
                     oldSkill["discarded"](); //
                  } //
                  else //
                  { //
                     oldSkill.removeFromParent(true); //
                  } //
               } //
               delete _skillCache[k]; //
            } //
         } //
      }
      
      public function get bytes() : ByteArray
      {
         var byte:ByteArray = new ByteArray();
         // byte.writeUTFBytes(worldClass);
         byte.writeUTF(worldClass ? worldClass : "");
         byte.writeObject(worldDatas);
         return byte;
      }
      
      public function stop() : void
      {
         _stop = true;
      }
   }
}

