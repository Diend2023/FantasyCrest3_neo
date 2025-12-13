// 添加ServiceHold
package game.data
{
   import flash.net.SharedObject;
   import zygame.server.Service;
   import zygame.core.DataCore;
   import game.data.Game;
   import flash.utils.ByteArray;
   import flash.utils.CompressionAlgorithm;
   import zygame.utils.Base64;

   public class ServiceHold
   {
      
      public var isLog:Object;
      public var rankdata:XMLList;
      private var _rankDataArray:Array;
      
      public function ServiceHold()
      {
         super();
         if(!SharedObject.getLocal("net.zygame.hxwz.air").data.userData)
         {
            SharedObject.getLocal("net.zygame.hxwz.air").data.userData = {"_4399userData":[]};
         }
         isLog = SharedObject.getLocal("net.zygame.hxwz.air").data.userData._4399userData;
      }
      
      private function decodeExtraField(extraString:String):Object
      {
          try {
              // 使用 Base64 解码
              var bytes:ByteArray = Base64.decodeToByteArray(extraString);
              
              // zlib 解压缩
              bytes.uncompress(CompressionAlgorithm.ZLIB);
              
              // 读取解压后的数据
              bytes.position = 0;
              var text:String = bytes.readUTFBytes(bytes.length);
              
              // 查找角色名
              var highrolePos:int = text.indexOf("highRole");
              if (highrolePos >= 0) {
                  // 跳过 "highRole" 和控制字符，提取角色名
                  var afterHighrole:String = text.substring(highrolePos + 8);
                  var roleName:String = "";
                  
                  // 提取字母字符作为角色名
                  for (var j:int = 0; j < afterHighrole.length; j++) {
                      var char:String = afterHighrole.charAt(j);
                      var charCode:int = char.charCodeAt(0);
                      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
                          // A-Z 或 a-z
                          roleName += char;
                      } else if (roleName.length > 0) {
                          // 遇到非字母且已有角色名，停止
                          break;
                      }
                  }
                  
                  if (roleName.length > 0) {
                      return {highRole: roleName};
                  }
              }
              
              return {highRole: "unknown"};
              
          } catch(e:Error) {
              return {highRole: "error"};
          }
      }

      private function parseRankData():void
      {
         var xml:XML = DataCore.getXml("rankdata");
         if(xml)
         {
            rankdata = xml.children();
            _rankDataArray = [];
            if(rankdata)
            {
               var content:String = rankdata.toString();
               var lines:Array = content.split("\n");
               
               // 跳过第一行表头
               for(var i:int = 1; i < lines.length; i++)
               {
                  var line:String = lines[i];
                  if(line && line.length > 0)
                  {
                     var parts:Array = line.split(",");
                     if(parts.length >= 5)
                     {
                        _rankDataArray.push({
                           rank: parseInt(parts[0]),
                           userId: parts[1],
                           userName: parts[2],
                           saveIndex: parseInt(parts[3]),
                           score: parseInt(parts[4]),
                           extra: decodeExtraField(parts[5]),
                           area: "无地区数据"
                        });
                     }
                  }
               }
            }
         }
         else
         {
            _rankDataArray = [];
         }
      }
      
      public function getData(bul:Boolean, index:int) : Object
      {
         isLog = Service.userData._4399userData;
         if(isLog)
         {
            return isLog[index];
         }
         return {};
      }
      
      public function saveData(name:String, data:Object, bul:Boolean, index:int) : void
      {
         if(name == "幻想纹章存档")
         {
            isLog = Service.userData._4399userData;
            isLog[index].allFight = data.allFight;
            Service.userData.userData.allFight = data.allFight;
            isLog[index].fight = data.fight;
            Service.userData.userData.fight = data.fight;
            isLog[index].vip = data.vip;
            Service.userData.userData.vip = data.vip;
            isLog[index].version = data.version;
            Service.userData.userData.version = data.version;
            isLog[index].fbs = data.fbs;
            Service.userData.userData.fbs = data.fbs;
            Service.userData._4399userData[index] = isLog[index];
            SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData;
            SharedObject.getLocal("net.zygame.hxwz.air").flush();
         }
      }
      
      public function submitScoreToRankLists(index:int, scores:Array) : void
      {
         if(!scores || scores.length == 0)
         {
         return;
         }
      
         // 确保排行榜数据已加载
         if(!_rankDataArray)
         {
            parseRankData();
         }
         if(!_rankDataArray)
         {
            _rankDataArray = [];
         }
         
         var scoreData:Object = scores[0]; // 取第一个分数数据
         var newScore:int = scoreData.score;
         var rankId:int = scoreData.rId;
         var extraData:Object = scoreData.extra;
         
         // 获取当前用户信息
         var currentUser:Object = Game.game4399Tools.logInfo;
         if(!currentUser) 
         {
            return;
         }
         
         var userId:String = currentUser.uid || "unknown";
         var userName:String = currentUser.nickName || currentUser.name || "未知用户";
         
         // 查找用户是否已在排行榜中
         var existingIndex:int = -1;
         for(var i:int = 0; i < _rankDataArray.length; i++) 
         {
            if(_rankDataArray[i].userId == userId) 
            {
                  existingIndex = i;
                  break;
            }
         }
         
         var oldRank:int = existingIndex >= 0 ? _rankDataArray[existingIndex].rank : -1;
         var oldScore:int = existingIndex >= 0 ? _rankDataArray[existingIndex].score : 0;
         
         // 如果用户已存在且新分数不高于旧分数，不更新
         if(existingIndex >= 0 && newScore <= oldScore) 
         {
            return;
         }
         
         // 移除旧记录（如果存在）
         if(existingIndex >= 0) 
         {
            _rankDataArray.splice(existingIndex, 1);
         }
         
         // 编码扩展数据
         // var encodedExtra:String = "";
         // if(extraData && extraData.highRole) 
         // {
         //    encodedExtra = encodeExtraField(extraData.highRole);
         // }
         
         // 创建新记录
         var newRecord:Object = {
            rank: 1, // 临时排名，稍后重新计算
            userId: userId,
            userName: userName,
            saveIndex: index,
            score: newScore,
            extra: extraData || {highRole: "unknown"},
            area: "无地区数据"
         };
         
         // 插入新记录到正确位置（按分数降序）
         var insertIndex:int = 0;
         for(var j:int = 0; j < _rankDataArray.length; j++) 
         {
            if(newScore > _rankDataArray[j].score) 
            {
                  insertIndex = j;
                  break;
            }
            insertIndex = j + 1;
         }
         
         _rankDataArray.splice(insertIndex, 0, newRecord);
         
         // 重新计算所有排名
         for(var k:int = 0; k < _rankDataArray.length; k++) 
         {
            _rankDataArray[k].rank = k + 1;
         }
      }
      
      public function getRankListsData(rankid:int, pageSize:int, page:int) : void
      {
         pageSize = 100;
         if(!_rankDataArray)
         {
            parseRankData();
         }
         var startIndex:int = (page - 1) * pageSize;
         var endIndex:int = Math.min(startIndex + pageSize, _rankDataArray ? _rankDataArray.length : 0);
         var resultData:Array = [];
         
         if(_rankDataArray && rankid == 1941)
         {
            for(var i:int = startIndex; i < endIndex; i++)
            {
               if(i < _rankDataArray.length)
               {
                  resultData.push(_rankDataArray[i]);
               }
            }
         }

         // 直接返回数据，不使用事件
         if(Game.game4399Tools && Game.game4399Tools.onRankList)
         {
            Game.game4399Tools.onRankList(resultData);
         }
      }

      public function getOneRankInfo(rankid:int, userName:String) : void
      {
         if(!_rankDataArray)
         {
            parseRankData();
         }

         var userRankData:Object = null;
         var currentUser:Object = Game.game4399Tools.logInfo;

         if(currentUser && _rankDataArray && rankid == 1941)
         {
            var userId:String = currentUser.uid;
            for each (var item:Object in _rankDataArray)
            {
               if(item.userId == userId)
               {
                  userRankData = item;
                  break;
               }
            }
         }

         var result:Array = [];
         if(userRankData)
         {
            result.push(userRankData);
         }

         if(Game.game4399Tools && Game.game4399Tools.onRankSelf)
         {
            Game.game4399Tools.onRankSelf(result);
         }
      }
   }
}