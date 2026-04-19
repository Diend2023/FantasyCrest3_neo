// 添加斩神白面被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import zygame.data.BeHitData;
   import game.world.BaseGameWorld;
   import zygame.data.RoleFrameGroup;
   import zygame.display.BaseRole
   import feathers.data.ListCollection;
   import flash.geom.Rectangle;
   import zygame.core.GameCore;
   
   public class ZhanShen extends GameRole
   {

      private var _keyQueue:Array = [];

      private const _keyObj:Object = {65:"←",68:"→",87:"↑",83:"↓",74:"J",75:"K",76:"L",85:"U",73:"I",79:"O",80:"P"};

      private var _hasChangeStateList:Boolean = false;
      
      public function ZhanShen(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"cd_I_mp.png",
            "msg":""
         }]);
      }

      override public function onDown(key:int):void
      {
         super.onDown(key);
         if(key == 85 && (this.actionName == "虚空阵 素" || this.actionName == "虚空阵 盈" || this.actionName == "虚空阵 鸣" || this.actionName == "虚空阵 尊"))
         {
            if(this.currentFrame > 10 && this.currentMp.value >= 1)
            {
               this.breakAction();
               this.clearDebuffMove();
               this.playSkill(this.actionName + " 攻击");
               this.currentMp.value -= 1;
            }
         }
         if(_keyObj.hasOwnProperty(key))
         {
            _keyQueue.push(_keyObj[key]);
         }
         if(_keyQueue.length > 5)
         {
            _keyQueue.shift();
         }
         if(key == 73)
         {
            if(_keyQueue.join("").indexOf("→→I") != -1 || _keyQueue.join("").indexOf("←←I") != -1)
            {
               this.playSkill("红莲");
            }
            if(_keyQueue.join("").indexOf("↓→↓→I") != -1 || _keyQueue.join("").indexOf("↓←↓←I") != -1)
            {
               this.playSkill("残铁");
            }
            if(_keyQueue.join("").indexOf("→→↑I") != -1 || _keyQueue.join("").indexOf("←←↑I") != -1)
            {
               this.playSkill("鬼蹴·阍魔");
            }
            _keyQueue = [];
         }
         this.listData.getItemAt(0).msg = _keyQueue.join("");
         this.listData.updateItemAt(0);
      }
      
      override public function onFrame():void
      {
         super.onFrame();
         if(!_hasChangeStateList)
         {
            // 强制穿透修改：List -> ViewPort -> RoleStateItem -> BG/Label
            if(this.hpmpDisplay.stateList.numChildren > 0)
            {
               var viewPort:Object = this.hpmpDisplay.stateList.getChildAt(0);
               if(viewPort && "numChildren" in viewPort && viewPort.numChildren > 0)
               {
                  var item:Object = viewPort.getChildAt(0);
                  if(item)
                  {
                     item.width = 130;
                     if("numChildren" in item && item.numChildren >= 2)
                     {
                        var bg:Object = item.getChildAt(0);
                        var label:Object = item.getChildAt(1);
                        if(bg) bg.width = 110;
                        if(label) label.width = 80;
                        _hasChangeStateList = true;
                     }
                  }
               }
            }
         }
         if(this.actionName != "待机")
         {
            var effectNingjujuju:EffectDisplay = this.world.getEffectFormName("ningjujuju", this);
            if (effectNingjujuju)
            {
               effectNingjujuju.continuousTime = 0;
               effectNingjujuju.go(999);
            }
         }
         var effectYuanQiDan:EffectDisplay = this.world.getEffectFormName("YuanQiDan", this);
         if(effectYuanQiDan && this.actionName != "刻杀·雪风" && this.actionName != "刻杀·悪滅")
         {
            effectYuanQiDan.continuousTime = 0;
            effectYuanQiDan.go(999);
         }
         var effectZs1:EffectDisplay = this.world.getEffectFormName("zs1", this);
         if(effectZs1 && effectZs1.scaleX < 0)
         {
            effectZs1.scaleX *= this.scaleX > 0 ? 1 : -1;
            effectZs1.x -= effectZs1.width * effectZs1.scaleX;
         }
         var effectZs2:EffectDisplay = this.world.getEffectFormName("zs2", this);
         if(effectZs2 && effectZs2.scaleX < 0)
         {
            effectZs2.scaleX *= this.scaleX > 0 ? 1 : -1;
            effectZs2.x -= effectZs2.width * effectZs2.scaleX;
         }
         var effectZs3:EffectDisplay = this.world.getEffectFormName("zs3", this);
         if(effectZs3 && effectZs3.scaleX < 0)
         {
            effectZs3.scaleX *= this.scaleX > 0 ? 1 : -1;
            effectZs3.x -= effectZs3.width * effectZs3.scaleX;
         }
         if(this.actionName.indexOf("攻击") != -1 && this.actionName != "虚空阵 鸣 攻击")
         {
            if(this.isKeyDown(83) && this.isKeyDown(79) && this.currentMp.value >=4)
            {
               this.breakAction();
               this.clearDebuffMove();
               this.golden += 45;
               this.playSkill("雪风·刻");
               this.currentMp.value -= 4;
            }
         }
         if (this.currentMp.value == this.mpMax)
         {
            this.mpPoint.value = 0;
         }
         var getRole:BaseRole = null;
         if(this.actionName == "虚空阵 鸣 攻击" && this.frameAt(0, 5))
         {
            hand(200, 200, 100, 200, 0, -25);
         }
         if(this.actionName == "虚空阵 尊 攻击")
         {
            if(this.currentFrame == 2)
            {
               getRole = hand(200, 200, 100, 300, 200, 10);
            }
            if(this.currentFrame == 3)
            {
               getRole = hand(200, 200, 100, 300, 100, 10);
               if(!getRole)
               {
                  this.breakAction();
               }
            }
         }
      }

      override public function onSUpdate() : void
      {
         if (this.currentMp.value == this.mpMax)
         {
            return;
         }
         super.onSUpdate();
         if(this.actionName == "待机")
         {
            addMpPoint(1);
         }
      }

      override public function onBeHit(beData:BeHitData) : void
      {
         super.onBeHit(beData);
         if(this.actionName == "虚空阵 素" || this.actionName == "虚空阵 盈" || this.actionName == "虚空阵 鸣" || this.actionName == "虚空阵 尊")
         {
            if(this.frameAt(3,10))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.playSkill(this.actionName + " 攻击");
               this.golden += 45;
               if (this.currentMp.value < this.mpMax)
               {
                  this.currentMp.value += 1;
               }
            }
         }
         if(this.actionName == "虚空阵 刻杀·雪风")
         {
            if(this.frameAt(3,10))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.runLockAction("刻杀·雪风");
               beData.cardFrame = 90;
            }
         }
         if(this.actionName == "刻杀·雪风" && this.frameAt(-1,16))
         {
            for each(var i:BaseRole in this.world.getRoleList())
            {
               if (i != this)
               {
                  shitingRole(90, i);
                  shitingEffect(90, i);
               }
            }
         }
         if(this.actionName == "虚空阵 刻杀·悪滅")
         {
            if(this.frameAt(5,16))
            {
               this.breakAction();
               this.clearDebuffMove();
               this.runLockAction("刻杀·悪滅");
               // GameCore.soundCore.playBGSound("astralfinish");
               beData.cardFrame = 45;
               for each(var j:BaseRole in this.world.getRoleList())
               {
                  if (j != this)
                  {
                     shitingEffect(45, j);
                  }
               }
            }
         }
      }

      override public function runLockAction(str:String, canBreak:Boolean = false) : void
      {
         // 防反技能释放时取消播放大招动画，重写runLockAction
         var group:RoleFrameGroup = this.roleXmlData.getGroupAt(str);
         if(group && group.key && group.key.indexOf("O") != -1 && actionName != str && str =="虚空阵 刻杀·雪风" || str =="虚空阵 刻杀·悪滅")
         {
            if(group && group["mp"])
            {
               usePoint(int(group["mp"]));
            }
            if(!isLock)
            {
               if(isKeyDown(65))
               {
                  this.scaleX = -1;
               }
               else if(isKeyDown(68))
               {
                  this.scaleX = 1;
               }
            }
            this.action = str;
            this.isLock = true;
            this.canBreakAction = canBreak;
            return;
         }
         super.runLockAction(str,canBreak);
      }

      // 播放大招动画
      public function playSkillPainting(actionName:String):void
      {
         var effect:EffectDisplay = new EffectDisplay("bisha",null,this,1.5,1.5);
         effect.x = this.x;
         effect.y = this.y;
         this.world.addChild(effect);
         effect.fps = 24;
         for each(var i:BaseRole in this.world.getRoleList())
         {
            i.cardFrame = 40;
         }
         (this.world as BaseGameWorld).showSkillPainting(targetName,actionName,troopid);
      }

      // 时停角色
      public function shitingRole(cardFrame:int, role:BaseRole):void
      {
         for each(var i:BaseRole in this.world.getRoleList())
         {
            if(i == role)
            {
               i.cardFrame = cardFrame;
            }
         }
      }

      // 时停特效
      public function shitingEffect(cardFrame:int, role:BaseRole):void
      {
         for each(var i:BaseRole in this.world.getRoleList())
         {
            if(i == role)
            {
               var effect:EffectDisplay = null;
               var num:int = this.world.map.roleLayer.numChildren;
               for(var j:int = 0; j < num; j++)
               {
                  effect = this.world.map.roleLayer.getChildAt(j) as EffectDisplay;
                  if(effect && effect.role == role)
                  {
                     effect.cardFrame = cardFrame;
                  }
               }
            }
         }
      }

      public function hand(topRange:int = 200, bottomRange:int = 200, backRange:int = 100, frontRange:int = 200,  toX:int = 0, toY:int = 0):BaseRole
      {
         var rect:Rectangle = this.body.bounds.toRect();
         // 横向判定
         if(this.scaleX > 0)
         {
            rect.width += frontRange;
            rect.x -= backRange;
            rect.width += backRange;
         }
         else
         {
            rect.x -= frontRange;
            rect.width += frontRange;
            rect.width += backRange;
         }
         // 纵向判定
         rect.y -= topRange;
         rect.height += topRange;
         rect.height += bottomRange;

         // 修正左边界
         if(rect.x < 0)
         {
            rect.width += rect.x; // 把溢出的部分减掉
            rect.x = 0;
            toX = 0;
         }
         // 修正右边界
         if(rect.x + rect.width > world.map.getWidth())
         {
            rect.width = world.map.getWidth() - rect.x;
            toX = 0;
         }

         if(rect.width > 0 && rect.height > 0)
         {
            var role:BaseRole = findRole(rect);
            if(role)
            {
               role.clearDebuffMove();
               role.straight = 30;
               role.setX(this.x + toX * this.scaleX);
               role.setY(this.y - toY);
               return role;
            }
         }
         return null;
      }

   }
}

