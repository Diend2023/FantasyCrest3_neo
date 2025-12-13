// 添加由岐照美被动
package game.role
{
   import flash.utils.Dictionary;
   import feathers.data.ListCollection;
   import game.buff.AttributeChangeBuff;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   
   public class ZhaoMei extends GameRole
   {

      // 额外水晶
      private var _otherMP:int = 0;

      // 技能表以及能否计数
      private var _skillCanCountObj:Object = {"我不知道":false,"叫什么":false,"技能":false,"蛇缚封焉尘":false,"神帰来・大蛇斩头烈封饿":false,"???":false,"轰牙双天刃·滅":false,"SI":false,"boom":false,"蛇麟炼翔牙":false,"蛇境灭闪牙":false,"SJ":false,"轰牙双天刃":false,"永生蛇·拆尼斯冲冲冲":false};

      // 大招表以及水晶消耗数量
      private var _oSkillCrystalObj:Object = {"蛇缚封焉尘":3,"神帰来・大蛇斩头烈封饿":3,"蛇麟炼翔牙":3,"蛇境灭闪牙":3,"轰牙双天刃":2,"永生蛇·拆尼斯冲冲冲":2};

      // 攻击计数
      private var _Count:int = 0;

      // O使用时水晶数
      private var _OUsePoint:int = 0;
      
      public function ZhaoMei(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         // 额外水晶显示
         this.listData = new ListCollection([{
            "icon":"shuijing.png",
            "msg":_otherMP
         }]);
      }

      override public function onFrame():void
      {
         super.onFrame();
         // 检测技能冷却，恢复计数状态
         var skillName:String;
         for(skillName in _skillCanCountObj)
         {
            if(this.attribute.getCD(skillName) == 0)
            {
               _skillCanCountObj[skillName] = true;
               // 大招恢复时，重置O使用水晶数
               if(skillName == "神帰来・大蛇斩头烈封饿")
               {
                  _OUsePoint = 0;
               }
            }
         }
         // 维护水晶数与显示（被其它方法扣减水晶时）
         if(_otherMP > this.currentMp.value)
         {
            _otherMP = this.currentMp.value;
            this.attribute.setValue("crystal",6 + _otherMP);
            this.listData.getItemAt(0).msg = _otherMP;
            this.listData.updateItemAt(0);
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         // O消耗全部水晶增加伤害
         if(this.actionName == "神帰来・大蛇斩头烈封饿" && beData.getHurt(enemy.attribute) > 1000)
         {
            var effectBOOM11:EffectDisplay = this.world.getEffectFormName("BOOM11",this);
            if(effectBOOM11 && effectBOOM11.currentFrame == 0)
            {
               if(beData.armorScale == 0)
               {
                  beData.armorScale = 1;
               }
               beData.armorScale *= 1 + _OUsePoint * 0.05;
               beData.armorScale -= 20;
               _OUsePoint = 0;
            }
         }
         super.onHitEnemy(beData,enemy);
         // 技能攻击计数
         if(_skillCanCountObj[this.actionName])
         {
            _Count += 1;
            _skillCanCountObj[this.actionName] = false;
         }
         // 计数达到3次，扣除敌人水晶并增加自身水晶
         if(_Count >= 3)
         {
            if((enemy as GameRole).currentMp.value > 0)
            {
               (enemy as GameRole).currentMp.value -= 1;
               if(_otherMP < 6)
               {
                  _otherMP += 1;
                  this.currentMp.value += 1;
               }
            }
            _Count = 0;
         }
         this.attribute.setValue("crystal",6 + _otherMP);
         this.listData.getItemAt(0).msg = _otherMP;
         this.listData.updateItemAt(0);
      }

      override public function runLockAction(str:String, canBreak:Boolean = false) : void
      {
         // 大招扣除水晶
         if(_oSkillCrystalObj[str])
         {
            _otherMP -= _oSkillCrystalObj[str];
            if(_otherMP < 0)
            {
               _otherMP = 0;
            }
            // O技能消耗全部水晶并记录
            if(str == "神帰来・大蛇斩头烈封饿")
            {
               _OUsePoint = this.currentMp.value;
               usePoint(this.currentMp.value);
               _otherMP = 0;
            }
            this.attribute.setValue("crystal",6 + _otherMP);
            this.listData.getItemAt(0).msg = _otherMP;
            this.listData.updateItemAt(0);
         }
         super.runLockAction(str, canBreak);
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         // 复制额外水晶计数至下一局
         ob._otherMP = _otherMP;
         return ob;
      }
      
      override public function setData(value:Object) : void
      {
         super.setData(value);
         // 读取继承的额外水晶计数
         _otherMP = value._otherMP || 0;
         this.attribute.setValue("crystal",6 + _otherMP);
         this.listData.getItemAt(0).msg = _otherMP;
         this.listData.updateItemAt(0);
      }
   }
}

