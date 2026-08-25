// 新增原因：回放功能需要逐帧驱动录像数据还原战斗。
// 设计：配合原始世界类使用（回放世界即录像对应的模式世界类），返回false走完整帧循环，
// 使地图/动画/特效/胜负流程（overCheak->gameOver->end->reset/over）全部由原始世界自动驱动。
package game.server
{
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import zygame.core.SceneCore;
   import zygame.display.BaseRole;
   import zygame.display.EffectDisplay;
   import zygame.display.RefRole;
   import zygame.display.World;
   import zygame.run.IRunModel;
   import game.data.WorldRecordData;
   import game.role.GameRole;
   import game.skill.UDPSkill;
   import game.view.GameSettingsView;
   import game.view.GameStartMain;
   import game.view.ReplayListView;
   import game.world.AssistWorld; // 换人事件处理
   import game.world.BaseGameWorld;
   
   public class ReplayRunModel implements IRunModel
   {
      
      // 回放静态数据（ReplayListView播放时注入，BaseGameWorld据此挂载本模型）
      public static var recordData:WorldRecordData;
      
      public static var isReplay:Boolean = false;
      
      public static var oldDefaultClass:Class; // 进入回放前的世界类，结束还原
      
      private var _frames:Array;
      
      private var _index:int = 0;
      
      private var _world:BaseGameWorld;
      
      private var _isOver:Boolean = false;
      
      public function ReplayRunModel(record:WorldRecordData, world:BaseGameWorld)
      {
         _frames = record.worldDatas;
         _world = world;
      }
      
      public function message(param1:World, param2:Object) : void
      {
      }
      
      public function onDown(param1:int) : Boolean
      {
         // 返回true：拦截玩家按键（回放无操作权，角色由录像驱动）
         return true;
      }
      
      public function onUp(param1:int) : Boolean
      {
         return true;
      }
      
      public function onFrame() : Boolean
      {
         var frameArr:Array;
         var item:Object;
         var role:GameRole;
         var owner:GameRole;
         var eff:UDPSkill;
         if(_isOver)
         {
            return false;
         }
         if(_index >= _frames.length)
         {
            // 录像播放完毕（无over标记的模式如练习模式），结束回放
            _isOver = true;
            finishReplay();
            return false;
         }
         frameArr = _frames[_index];
         _index++;
         for each(item in frameArr)
         {
            if(item.target == "swap") // 换人事件（AssistWorld换人模式），重放换人流程
            {
               var asw:AssistWorld = _world as AssistWorld;
               if(asw)
               {
                  var outR:GameRole = asw.getRoleFormName(item.out) as GameRole;
                  var sarr:Array = outR ? asw["p" + (outR.troopid + 1) + "assist"] : null;
                  if(outR && sarr && sarr.length > 0)
                  {
                     var inR:GameRole = sarr[0] as GameRole;
                     inR.scaleX = outR.currentScaleX > 0 ? 1 : -1;
                     inR.clearDebuffMove();
                     asw.enterRole(inR);
                     inR.usePoint(1);
                     sarr.shift();
                     asw.outRole(outR);
                     outR.move("wait");
                     outR.usePoint(1);
                  }
               }
            }
            else if(item.target == "role")
            {
               role = _world.getRoleFormPid(item.id) as GameRole;
               if(role)
               {
                  role.setData(item.data);
                  // 非锁定状态下也用录像帧驱动动画帧（行走等动作正常播放，避免停在第一帧）
                  if(!item.data.isLock)
                  {
                     var _f:int = int(item.data.frame);
                     if(Math.abs(role.currentFrame - _f) > 1)
                     {
                        role.currentFrame = _f;
                        role.onShapeChange();
                     }
                  }
               }
            }
            else if(item.target == "skill")
            {
               owner = _world.getRoleFormPid(item.data.roleid) as GameRole;
               if(owner)
               {
                  eff = _world.getEffectFormName(item.data.name as String, owner) as UDPSkill;
                  if(eff)
                  {
                     eff.setData(item.data);
                  }
               }
            }
         }
         // 返回false走完整帧循环：moveMap/_gameBG/子对象onFrame/物理/胜负检测全部正常执行
         return false;
      }
      
      public function onFrameOver() : Boolean
      {
         return true;
      }
      
      public function onKillRole(param1:BaseRole) : Boolean
      {
         return false;
      }
      
      public function onAddChild(param1:DisplayObject) : void
      {
      }
      
      public function onRoleFrame(param1:RefRole) : Boolean
      {
         // 回放时每帧强制关闭角色AI（录像已含完整状态，AI决策会产生与录像不符的额外动作/特效；
         // 各模式initRole与换人流程会动态开ai，故必须在onRoleFrame每帧强制关，同帧aiFunc即因!ai跳过）
         (param1 as BaseRole).ai = false; //
         // 返回false：角色自身onFrame正常执行，动画帧自然推进
         return false;
      }
      
      public function onEffectPasing(param1:Array) : Boolean
      {
         return false;
      }
      
      public function onEffectFrame(param1:EffectDisplay) : Boolean
      {
         return false;
      }
      
      public function onMiss(param1:BaseRole) : Boolean
      {
         return false;
      }
      
      public function onHurt(param1:BaseRole, param2:int) : Boolean
      {
         return false;
      }
      
      public function onCDChange(param1:BaseRole, param2:String) : void
      {
      }
      
      // 结束回放，还原世界类并重建完整UI栈（主菜单+设置页+录像列表）
      public static function finishReplay() : void
      {
         Starling.juggler.delayCall(function():void
         {
            isReplay = false;
            World.defalutClass = ReplayRunModel.oldDefaultClass;
            SceneCore.replaceScene(new GameStartMain());
            SceneCore.pushView(new GameSettingsView());
            SceneCore.pushView(new ReplayListView());
         },0.1);
      }
   }
}
