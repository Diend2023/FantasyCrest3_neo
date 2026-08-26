// 添加空条承太郎被动
package game.role
{
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.filters.ColorMatrixFilter;
   import zygame.core.GameCore;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;
   import game.server.AccessRun3Model;
   import game.server.HostRun2Model;
   import game.server.ReplayRunModel;
   import game.world.BaseGameWorld;
   
   public class JO extends GameRole
   {

      private var theWorldTimer:int = 0; // 时停计时器

      private var _worldFilter:ColorMatrixFilter; // 用于地面层

      private var _backgroundFilter:ColorMatrixFilter;  // 用于背景

      private var _filterTargets:Array = []; // 时停滤镜目标层

      private var _filterInstances:Array = []; // 各目标层独立的滤镜实例

      // private var baseBgVolume:Number = 0.4;

      public var hasPassive:Boolean = false;
      
      public var passiveWillDie:Boolean = false;
      
      public function JO(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         startTheWorldVisualEffect();
         stopTheWorldVisualEffect();
         // GameCore.soundCore.bgvolume = this.baseBgVolume;
      }

      override public function onInit():void
      {
         super.onInit();
         if(theWorldTimer <= 0 && !isNaN(GameCore.soundCore.bgPausePosition))
         {
            GameCore.soundCore.resumeBGSound();
         }
      }

	   override public function onFrame():void
      {
         super.onFrame();
         if (this.actionName == "the world")
         {
            if (this.currentFrame == 16)
            {
               theWorld();
            }
         }
         // 时停被动计时
         if (this.theWorldTimer > 0)
         {
            shitingRoleAll(2);
            shitingEffectAll(2);
            this.theWorldTimer -= 1;

            if(this.theWorldTimer == 45)
            {
               if(this.passiveWillDie)
               {
                  this.attribute.hp = 0;
                  this.theWorldTimer = 0;
                  // GameCore.soundCore.bgvolume = this.baseBgVolume;
                  GameCore.soundCore.resumeBGSound();
                  stopTheWorldVisualEffect();
                  return;
               }
               this.playSkill("时间开始流动");
            }

            // 计时结束，移除效果
            if(this.theWorldTimer <= 0)
            {
               // GameCore.soundCore.bgvolume = this.baseBgVolume;
               GameCore.soundCore.resumeBGSound();
               stopTheWorldVisualEffect();
            }
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         if(beData.armorScale == 0)
         {
            beData.armorScale = 1;
         }
         if(this.attribute.hp > 0 && this.attribute.hp < 50 && (this.actionName == "欧拉？" || this.actionName == "隔空杀妈"))
         {
            beData.armorScale += 0.7; // 增加70%伤害
         }
         super.onHitEnemy(beData,enemy);
      }

      override public function onBeHit(beData:BeHitData) : void
      {
         super.onBeHit(beData);
         if(this.attribute.hp <= 0 && !this.hasPassive && this.currentMp.value >= 5 && this.theWorldTimer <= 0)
         {
            this.attribute.hp = 1; // 保持1点生命值
            passiveTheWorld(beData.role);
            this.passiveWillDie = true;
         }
         if(this.attribute.hp > 0 && this.attribute.hp < 50 && !this.hasPassive && this.currentMp.value >= 5 && this.theWorldTimer <= 0)
         {
            passiveTheWorld(beData.role);
         }
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         ob.hasPassive = this.hasPassive;
         return ob;
      }
      
      override public function setData(value:Object) : void
      {
         super.setData(value);
         this.hasPassive = value.hasPassive;
      }

      override public function win() : void
      {
         super.win();
         if(!isNaN(GameCore.soundCore.bgPausePosition))
         {
            GameCore.soundCore.resumeBGSound();
         }
      }

      override public function over():void
      {
         super.over();
         if(!isNaN(GameCore.soundCore.bgPausePosition))
         {
            GameCore.soundCore.resumeBGSound();
         }
      }

      public function theWorld():void
      {
         this.theWorldTimer = 345; // 5秒钟
         // GameCore.soundCore.bgvolume = 0.0;
         GameCore.soundCore.pauseBGSound();
         GameCore.soundCore.playEffect("ctl39");
         // Starling.juggler.delayCall(function():void
         // {
         //    GameCore.soundCore.bgvolume = baseBgVolume;
         // },5);
         if(world.runModel is AccessRun3Model || world.runModel is ReplayRunModel)
         {
            return;
         }
         startTheWorldVisualEffect();
      }

      public function passiveTheWorld(enemy:BaseRole):void
      {
         GameCore.soundCore.playEffect("ctl29");
         this.hasPassive = true;
         theWorld();
         this.currentMp.value = 0;
         this.mpPoint.value = 0;
         this.posx = enemy.x - 150 * enemy.scaleX;
         this.posy = enemy.y;
         this.scaleX = enemy.scaleX > 0 ? 1 : -1;
         this.golden = 60;
         this.cardFrame = 0;
         this.clearDebuffMove();
         this.actionName = "降落";
      }

      // 时停所有角色除了自己
      public function shitingRoleAll(cardFrame:int):void
      {
         var i:int = 0;
         for(i = 0; i < this.world.getRoleList().length; i++)
         {
            if (this.world.getRoleList()[i] == this)
            {
               continue;
            }
            this.world.getRoleList()[i].cardFrame = cardFrame;
         }
      }

      // 时停所有攻击特效包括自己
      public function shitingEffectAll(cardFrame:int):void
      {
         var j:int = 0;
         var effect:EffectDisplay = null;
         var num:int = this.world.map.roleLayer.numChildren;
         for(j = 0; j < num; j++)
         {
            effect = this.world.map.roleLayer.getChildAt(j) as EffectDisplay;
            if(effect == null || (effect.role == this as BaseRole && effect.objectData.unhit == true))
            {
               continue;
            }
            else
            {
               effect.cardFrame = cardFrame;
            }
         }
      }


      public function startTheWorldVisualEffect():void
      {
         // if(this.world.targetName != "map1" && this.world.targetName != "map1_3.0")
         // {
         //    return;
         // }
         // 1. 收集目标渲染层（跳过角色互动层）
         _filterTargets.length = 0;
         _filterInstances.length = 0;
         if (this.world.map && this.world.map.numChildren > 0)
         {
            var roleLayerParent:DisplayObjectContainer = this.world.map.roleLayer ? this.world.map.roleLayer.parent : null;
            for (var i:int = 0; i < this.world.map.numChildren; i++)
            {
               var child:DisplayObject = this.world.map.getChildAt(i);
               if (child == roleLayerParent)
               {
                  continue;
               }
               _filterTargets.push(child);
            }
         }
         // 2. 背景精灵也作为目标层
         if (this.world.backgroundContent)
         {
            _filterTargets.push(this.world.backgroundContent);
         }
         if (_filterTargets.length == 0)
         {
            return;
         }
         // 3. 为每个目标层创建独立的滤镜实例（避免共享实例导致滤镜失效）
         var invertMatrix:Vector.<Number> = Vector.<Number>([
            -1,  0,  0,  1,  0,
             0, -1,  0,  1,  0,
             0,  0, -1,  1,  0,
             0,  0,  0,  1,  0 
         ]);
         for (i = 0; i < _filterTargets.length; i++)
         {
            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.matrix = invertMatrix;
            (_filterTargets[i] as DisplayObject).filter = filter;
            _filterInstances.push(filter);
         }
         // 保留引用，便于 stop 时清理
         _worldFilter = _filterInstances[0] as ColorMatrixFilter;
         _backgroundFilter = this.world.backgroundContent ? (_filterInstances[_filterInstances.length - 1] as ColorMatrixFilter) : null;
         // 4. 缓动 0.2 秒后切换到"时停"高亮灰度状态
         var tw:Tween = new Tween({}, 0.2);
         tw.onComplete = function():void
         {
            var s:Number = 1.5;
            var r:Number = 0.3 * s;
            var g:Number = 0.59 * s;
            var b:Number = 0.11 * s;
            var brightGrayMatrix:Vector.<Number> = Vector.<Number>([
               r, g, b, 0, 0,
               r, g, b, 0, 0,
               r, g, b, 0, 0,
               0, 0, 0, 1, 0
            ]);
            for (var j:int = 0; j < _filterInstances.length; j++)
            {
               (_filterInstances[j] as ColorMatrixFilter).matrix = brightGrayMatrix;
            }
         };
         Starling.juggler.add(tw);
         if(world.runModel is HostRun2Model)
         {
            (world.runModel as HostRun2Model).doFunc(this.name,"startTheWorldVisualEffect");
         }
         if(world is BaseGameWorld && (world as BaseGameWorld).worldData)
         {
            (world as BaseGameWorld).worldData.pushFunc(this.name,"startTheWorldVisualEffect");
         }
      }

      // 结束时停视觉效果
      public function stopTheWorldVisualEffect():void
      {
         // if(this.world.targetName != "map1" && this.world.targetName != "map1_3.0")
         // {
         //    return;
         // }
         // 1. 移除所有目标层的滤镜
         for (var i:int = 0; i < _filterTargets.length; i++)
         {
            var target:DisplayObject = _filterTargets[i] as DisplayObject;
            if (target)
            {
               target.filter = null;
            }
         }
         _filterTargets.length = 0;
         _filterInstances.length = 0;
         _worldFilter = null;
         _backgroundFilter = null;
         if(world.runModel is HostRun2Model)
         {
            (world.runModel as HostRun2Model).doFunc(this.name,"stopTheWorldVisualEffect");
         }
         if(world is BaseGameWorld && (world as BaseGameWorld).worldData)
         {
            (world as BaseGameWorld).worldData.pushFunc(this.name,"stopTheWorldVisualEffect");
         }
      }
   }
}

