// 添加朽木白哉
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   import feathers.data.ListCollection;

   
   public class BaiZai extends GameRole
   {

      private const _yinghuaSkills:Array = ["樱汇", "千本樱", "千痕"];
      private var _effectQiangTimer:int = 0; // P断空墙持续时间计时器
      private var _willLockRole:BaseRole = null; // 即将被锁定的角色
      private var _yinghuaTimer:int = 0; // 樱花持续时间计时器
      
      public function BaiZai(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"mofa.png",
            "msg":"Off"
         }]);
      }

      override public function onFrame():void
      {
         super.onFrame();
         if(_yinghuaTimer > 0)
         {
            _yinghuaTimer -= 1;
            this.listData.getItemAt(0).msg = Number(_yinghuaTimer / 60).toFixed(1).toString(); // 显示樱花持续时间，单位为秒
         }
         else
         {
            this.listData.getItemAt(0).msg = "Off";
         }
         this.listData.updateItemAt(0);
         if(this.inFrame("卍解         千 本 樱            景严",28))
         {
            for each(var skillName:String in _yinghuaSkills)
            {
               this.attribute.updateCD(skillName, 0);
               _yinghuaTimer = 600; // 樱花持续时间
            }
         }
         var effectYinghua:EffectDisplay = this.world.getEffectFormName("yinghua",this)
         if(effectYinghua)
         {
            if (effectYinghua.currentFrame == 6)
            {
               effectYinghua.go(0);
            }
         }
         var effectQiang:EffectDisplay = this.world.getEffectFormName("qiang",this);
         if(effectQiang)
         {
            var effectQiangScaleX:int = effectQiang.scaleX > 0 ? 1 : -1;
            if(effectQiang.currentFrame == 0)
            {
               _effectQiangTimer = 600;
               // 不可推动
               effectQiang.body.allowMovement = false;
            }
            if(effectQiang.currentFrame == 1 && _effectQiangTimer > 0)
            {
               _effectQiangTimer -= 1;
               effectQiang.cardFrame = 2;
            }
         }
         // 碰到其它特效时，使特效速度为0
         var effects:Vector.<EffectDisplay> = this.world.getEffects();
         for each(var effect:EffectDisplay in effects)
         {
            if(effectQiang && effect.role.troopid != this.troopid && Math.abs(effect.x - effectQiang.x) < 150 && Math.abs(effect.y + 100 - effectQiang.y) < 200)
            {
               effect.speedScale = 0;
            }
            else
            {
               effect.speedScale = 1;
            }
         }
         var effectMlsXing:EffectDisplay = this.world.getEffectFormName("mlsXing",this);
         if(effectMlsXing && this.actionName == "六杖光牢" && _willLockRole && _willLockRole.attribute)
         {
            effectMlsXing.cardFrame = 180; // 锁定持续时间
            effectMlsXing.posx = _willLockRole.x;
            effectMlsXing.posy = _willLockRole.y - 100;
            _willLockRole.breakAction();
            _willLockRole.clearDebuffMove();
            _willLockRole.straight = 180;
            _willLockRole = null;
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole):void
      {
         var effectXbao:EffectDisplay = this.world.getEffectFormName("Xbao",this);
         if(this.actionName == "六杖光牢" && effectXbao)
         {
            _willLockRole = enemy;
         }
         super.onHitEnemy(beData, enemy);
      }

      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         var effectYinghua:EffectDisplay = this.world.getEffectFormName("yinghua",this)
         if(_yinghuaSkills.indexOf(str) != -1 && effectYinghua)
         {
            this.attribute.updateCD(str, 3);
         }
         super.runLockAction(str, canBreak);
      }
   }
}

