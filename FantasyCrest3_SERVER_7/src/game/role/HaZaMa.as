// 添加哈扎吗被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import starling.display.Quad;
   import feathers.data.ListCollection;
   import zygame.buff.BuffRef;
   import zygame.display.BaseRole;
   import zygame.data.BeHitData;
   
   public class HaZaMa extends GameRole
   {

      private var _effectLX10Quad:Quad;

      private var _effectLX10Timer:int = 0;
      
      public function HaZaMa(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
         "icon":"shengcun.png",
         "msg":"Off"
         }]);
      }
      
      override public function onSUpdate() : void
      {
         super.onSUpdate();
         for each (var enemy:GameRole in this.world.getRoleList())
         {
            if (enemy != this && enemy.troopid != this.troopid)
            {
               if (enemy.attribute && enemy.attribute.hasBuff(BuffRef, "debuff_LX10"))
               {
                  enemy.attribute.hp -= enemy.attribute.hpmax * 0.02;
                  this.attribute.hp += enemy.attribute.hpmax * 0.02;
                  if(this.attribute.hp > this.attribute.hpmax)
                  {
                     this.attribute.hp = this.attribute.hpmax;
                  }
               }
            }
         }

      }

      override public function onFrame():void
      {
         super.onFrame();
         if (_effectLX10Timer > 0 && this.cardFrame <= 0)
         {
            _effectLX10Timer--;
            listData.getItemAt(0).msg = int(_effectLX10Timer / 60).toString();
            if (_effectLX10Timer <= 0)
            {
               listData.getItemAt(0).msg = "Off";
            }
            listData.updateItemAt(0);
         }
         if(inFrame("碧之魔导书·Jörmungandr（世界蛇）", 10))
         {
            _effectLX10Timer = 600;
         }
         var effectLX10:EffectDisplay = this.world.getEffectFormName("LX10",this);
         if (effectLX10)
         {
            if (!_effectLX10Quad)
            {
               _effectLX10Quad = new Quad(1, 1, 0xFF0000);
               _effectLX10Quad.alpha = 0.5;
               this.world.addChild(_effectLX10Quad);
               _effectLX10Quad.visible = false;
            }
            _effectLX10Quad.width = effectLX10.width / 1.5;
            _effectLX10Quad.height = effectLX10.height / 1.5;
            _effectLX10Quad.x = this.x - effectLX10.width / 3;
            _effectLX10Quad.y = this.y - effectLX10.height / 1.75;
            // _effectLX10Quad.visible = true;
            for each (var enemy:GameRole in this.world.getRoleList())
            {
               if (enemy != this && effectLX10 && enemy.troopid != this.troopid)
               {
                  if (Math.abs(enemy.x - _effectLX10Quad.x) < _effectLX10Quad.width && Math.abs(enemy.y - _effectLX10Quad.y) < _effectLX10Quad.height)
                  {
                     if (enemy.attribute && !enemy.attribute.hasBuff(BuffRef, "debuff_LX10"))
                     {
                        enemy.addBuff(new BuffRef("debuff_LX10",enemy,-1), 1, false);
                     }
                  }
                  else if (Math.abs(enemy.x - _effectLX10Quad.x) >= _effectLX10Quad.width || Math.abs(enemy.y - _effectLX10Quad.y) >= _effectLX10Quad.height)
                  {
                     if (enemy.attribute && enemy.attribute.hasBuff(BuffRef, "debuff_LX10"))
                     {
                        enemy.attribute.hasBuff(BuffRef, "debuff_LX10").currentTime = 0;
                     }
                  }
               }
            }
         }
         else if (_effectLX10Quad)
         {
            _effectLX10Quad.removeFromParent();
            _effectLX10Quad = null;
         }
         else if (!effectLX10)
         {
            for each (var enemy2:GameRole in this.world.getRoleList())
            {
               if (enemy2 != this && enemy2.troopid != this.troopid)
               {
                  if (enemy2.attribute && enemy2.attribute.hasBuff(BuffRef, "debuff_LX10"))
                  {
                     enemy2.attribute.hasBuff(BuffRef, "debuff_LX10").currentTime = 0;
                  }
               }
            }
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         // 命中时吸血20%
         if(enemy && enemy.attribute && enemy.attribute.hasBuff(BuffRef, "debuff_LX10"))
         {
            this.attribute.hp += beData.getHurt(this.attribute) * 0.2;
            if(this.attribute.hp > this.attribute.hpmax)
            {
               this.attribute.hp = this.attribute.hpmax;
            }
         }
         super.onHitEnemy(beData,enemy);
      }

      override public function hitDataBuff(beData:BeHitData):void
      {
         super.hitDataBuff(beData);
         // 10%概率破防
         for each (var enemy:BaseRole in this.world.getRoleList())
         {
            if (enemy != this && enemy.troopid != this.troopid)
            {
               if (enemy.attribute && enemy.attribute.hasBuff(BuffRef, "debuff_LX10"))
               {
                  if (Math.random() < 0.1)
                  {
                     beData.isBreakDam = true;
                  }
               }
            }
         }
      }

   }
}

