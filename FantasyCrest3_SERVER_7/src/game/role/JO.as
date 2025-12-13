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
   
   public class JO extends GameRole
   {

      private var theWorldTimer:int = 0; // 时停计时器

      private var _worldFilter:ColorMatrixFilter; // 用于地面层

      private var _backgroundFilter:ColorMatrixFilter;  // 用于背景

      private var baseBgVolume:Number = 0.4;

      public var hasPassive:Boolean = false;
      
      public var passiveWillDie:Boolean = false;
      
      public function JO(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         startTheWorldVisualEffect();
         stopTheWorldVisualEffect();
         GameCore.soundCore.bgvolume = this.baseBgVolume;
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
                  GameCore.soundCore.bgvolume = this.baseBgVolume;
                  stopTheWorldVisualEffect();
                  return;
               }
               this.playSkill("时间开始流动");
            }

            // 计时结束，移除效果
            if(this.theWorldTimer <= 0)
            {
               GameCore.soundCore.bgvolume = this.baseBgVolume;
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

      public function theWorld():void
      {
         this.theWorldTimer = 345; // 5秒钟
         GameCore.soundCore.bgvolume = 0.0;
         GameCore.soundCore.playEffect("ctl39");
         startTheWorldVisualEffect();
         Starling.juggler.delayCall(function():void
         {
            GameCore.soundCore.bgvolume = baseBgVolume;
         },5);
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
         for(var j = 0; j < num; j++)
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
         if(this.world.targetName != "map1")
         {
            return;
         }
         // 1. 创建独立的滤镜实例
         _worldFilter = new ColorMatrixFilter();
         _backgroundFilter = new ColorMatrixFilter();
         
         // 2. 反色矩阵 (瞬间冲击)
         var invertMatrix:Vector.<Number> = Vector.<Number>([
            -1,  0,  0,  1,  0,
             0, -1,  0,  1,  0,
             0,  0, -1,  1,  0,
             0,  0,  0,  1,  0 
         ]);
         
         _worldFilter.matrix = invertMatrix;
         _backgroundFilter.matrix = invertMatrix;  // 同步初始矩阵
         
         // 3. 给地图的地面层加滤镜
         if (this.world.map && this.world.map.numChildren > 0)
         {
            this.world.map.getChildAt(0).filter = _worldFilter;
         }
         
         // 4. 给背景精灵加滤镜
         if (this.world.backgroundContent)
         {
            this.world.backgroundContent.filter = _backgroundFilter;
         }
         
         // 5. 缓动过渡到“时停”状态，使用 onUpdate 同步背景滤镜的矩阵
         var tw:Tween = new Tween(_worldFilter, 0.2);
         
         tw.onUpdate = function():void
         {
            // 同步背景滤镜的矩阵到地图滤镜
            if (_backgroundFilter)
            {
               _backgroundFilter.matrix = _worldFilter.matrix;
            }
         };
         
         tw.onComplete = function():void
         {
            if(_worldFilter)
            {
               // 高亮灰度矩阵
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
               
               _worldFilter.matrix = brightGrayMatrix;
               // 同步到背景
               if (_backgroundFilter)
               {
                  _backgroundFilter.matrix = brightGrayMatrix;
               }
            }
         };
         
         Starling.juggler.add(tw);
      }

      // 结束时停视觉效果
      public function stopTheWorldVisualEffect():void
      {
         if(this.world.targetName != "map1")
         {
            return;
         }
         // 1. 移除地图地面层的滤镜
         if (this.world.map && this.world.map.numChildren > 0)
         {
            if (this.world.map.getChildAt(0).filter == _worldFilter)
            {
               this.world.map.getChildAt(0).filter = null;
            }
         }
         
         // 2. 移除背景精灵的滤镜
         if (this.world.backgroundContent && this.world.backgroundContent.filter == _backgroundFilter)
         {
            this.world.backgroundContent.filter = null;
         }
         
         _worldFilter = null;
         _backgroundFilter = null;
      }
   }
}

