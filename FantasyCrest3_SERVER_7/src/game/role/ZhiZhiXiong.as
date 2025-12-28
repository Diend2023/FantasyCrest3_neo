// 添加志志雄真实(纹4)的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import feathers.data.ListCollection;
   import zygame.data.BeHitData;
   import game.buff.AttributeChangeBuff;

   public class ZhiZhiXiong extends GameRole
   {

      private var _bdTimeer:int = 0; // 自爆计时器

      private var _addAttactBuffTimer:int = 0; // 增加攻击力buff计时器
      
      public function ZhiZhiXiong(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"shengcun.png",
            "msg":0
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
         _bdTimeer = 3000; // 初始化倒计时为3000帧（约50秒）
      }

      override public function onFrame() : void
      {
         super.onFrame();
         if(_bdTimeer > 0 && this.cardFrame <= 0)
         {
            _bdTimeer--;
         }
         else if(_bdTimeer <= 0 && this.attribute && this.attribute.hp > 0)
         {
            this.breakAction();
            this.playSkill("自爆");
         }
         if(this.actionName == "自爆")
         {
            if(this.attribute.hp <= 0)
            {
               this.breakAction();
            }
            else if(this.inFrame("自爆", 11))
            {
               if(this.listData.getItemAt(1))
               {
                  this.listData.removeItemAt(1);
               }
               this.attribute.hp = 0; // 在自爆动作的特定帧将HP设为0
               return;
            }
         }
         if(_addAttactBuffTimer > 0 && this.cardFrame <= 0)
         {
            _addAttactBuffTimer--;
         }
         else if(_addAttactBuffTimer <= 0 && this.attribute.hasBuff(AttributeChangeBuff, "addAttack"))
         {
            this.attribute.hasBuff(AttributeChangeBuff, "addAttack").currentTime = 0;
         }
         if(this.attribute.hasBuff(AttributeChangeBuff, "addAttack") && !this.listData.getItemAt(1) && _addAttactBuffTimer > 0)
         {
            var addAttackBuff:AttributeChangeBuff = this.attribute.hasBuff(AttributeChangeBuff, "addAttack") as AttributeChangeBuff;
            var buffObj:Object = {
               "icon":"liliang.png",
               "msg":0
            };
            this.listData.addItemAt(buffObj, 1);
            buffObj.msg = (_addAttactBuffTimer / 60).toFixed(1); // 显示buff剩余时间
         }
         else if(this.listData.getItemAt(1))
         {
            this.listData.removeItemAt(1);
         }
         this.listData.getItemAt(0).msg = int(_bdTimeer / 60); // 显示剩余时间
         this.listData.updateItemAt(0);
         this.listData.updateItemAt(1);
      }

      override public function onBeHit(beData:BeHitData):void
      {
         if(this.actionName == "秘剑·鬼步（狱步）" && this.frameAt(0, 5) && !this.attribute.hasBuff(AttributeChangeBuff, "addAttack"))
         {
            this.clearDebuffMove();
            var addAttackBuff:AttributeChangeBuff = new AttributeChangeBuff("addAttack", this, -1, new RoleAttributeData());
            var basePower:int = this.attribute.power;
            var baseMagic:int = this.attribute.magic;
            addAttackBuff.changeData.power = basePower;
            addAttackBuff.changeData.magic = baseMagic;
            this.addBuff(addAttackBuff);
            _addAttactBuffTimer = 600;
            this.golden = 12;
            return
         }
         else if(this.attribute.hasBuff(AttributeChangeBuff, "addAttack"))
         {
            _addAttactBuffTimer = 600;
            this.golden = 12;
         }
         super.onBeHit(beData);
      }
   }
}

