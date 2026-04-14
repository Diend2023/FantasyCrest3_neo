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
         if(_keyObj.hasOwnProperty(key))
         {
            _keyQueue.push(_keyObj[key]);
         }
         if(_keyQueue.length > 5)
         {
            _keyQueue.shift();
         }
         var keyQueue:Array = _keyQueue.reverse();
         _keyQueue.reverse();
         this.listData.getItemAt(0).msg = keyQueue.join("");
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
                        if(bg) bg.width = 130;
                        if(label) label.width = 100;
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
         if(this.actionName.indexOf("攻击") != -1 && this.actionName != "虚空阵 鸣")
         {
            if(this.isKeyDown(83) && this.isKeyDown(79) && this.currentMp.value >=4)
            {
               this.breakAction();
               this.clearDebuffMove();
               this.playSkill("雪风·刻");
               this.currentMp.value -= 4;
            }
         }
         if (this.currentMp.value == this.mpMax)
         {
            this.mpPoint.value = 0;
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

   }
}

