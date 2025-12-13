// 添加嘉神慎之介被动
package game.role
{
   import feathers.data.ListCollection;
   import game.buff.AttributeChangeBuff;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   
   public class JS extends GameRole
   {

      private var _effectSuChuanTimer:int = 0; // SP紧锁之壁计时器

      private var _bdNumber:int = 0; // 被动吸收水晶次数

      private var _bdBuff:AttributeChangeBuff; // 被动魔力变化Buff
      
      public function JS(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         _bdBuff = new AttributeChangeBuff("bdBuff",this,-1,new RoleAttributeData());
         this.addBuff(_bdBuff);
         this.listData = new ListCollection([{
            "icon":"mofa.png",
            "msg":0
         }]);
      }

      override public function onFrame():void
      {
         super.onFrame();
         // SP紧锁之壁生成墙
         var effectSuChuan:EffectDisplay = this.world.getEffectFormName("SuChuan",this);
         if(effectSuChuan )
         {
            if(effectSuChuan.currentFrame == 0)
            {
               _effectSuChuanTimer = 250;
               // 不可推动
               effectSuChuan.body.allowMovement = false;
            }
            if(effectSuChuan.currentFrame == 2 && _effectSuChuanTimer > 0)
            {
               _effectSuChuanTimer -= 1;
               effectSuChuan.cardFrame = 2;
            }
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         // 被动吸收水晶逻辑
         var n:int = Math.random() * 100;
         if(n < 15)
         {
            if((enemy as GameRole).currentMp.value > 0)
            {
               (enemy as GameRole).currentMp.value -= 1;
               _bdNumber += 1;
               // 每次吸收水晶增加15点魔力
               _bdBuff.changeData.magic = 15 * _bdNumber;
               this.listData.getItemAt(0).msg = _bdBuff.changeData.magic;
               this.listData.updateItemAt(0);
            }
         }
         super.onHitEnemy(beData, enemy);
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         // 复制被动继承至下一局
         ob._bdNumber = _bdNumber;
         return ob;
      }
      
      override public function setData(value:Object) : void
      {
         super.setData(value);
         // 读取继承的被动
         _bdNumber = value._bdNumber || 0;
         _bdBuff.changeData.magic = 15 * _bdNumber;
         this.listData.getItemAt(0).msg = _bdBuff.changeData.magic;
         this.listData.updateItemAt(0);
      }
   }
}

