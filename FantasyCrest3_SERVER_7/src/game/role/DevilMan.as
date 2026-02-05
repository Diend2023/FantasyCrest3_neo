// 添加恶魔人被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import game.buff.AttributeChangeBuff;
   import zygame.data.BeHitData;
   import feathers.data.ListCollection;

   
   public class DevilMan extends GameRole
   {

      private var hasGolden:Boolean = false;
      
      public function DevilMan(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":0
         },
         {
            "icon":"fangyu.png",
            "msg":"Off"
         }]);
      }

      override public function onInit():void
      {
         super.onInit();
         this.addBuff(new AttributeChangeBuff("add_power", this, -1, new RoleAttributeData(), null), 1, false);
         this.listData.getItemAt(0).msg = this.attribute.power;
         this.listData.updateItemAt(0);
      }

      override public function onFrame():void
      {
         super.onFrame();
         // 每损失20%血量，增加40点力量
         if (this.attribute && this.attribute.hp > 0)
         {
            if(!this.attribute.hasBuff(AttributeChangeBuff, "add_power"))
            {
               // 如果没有该buff，重新添加
               this.addBuff(new AttributeChangeBuff("add_power", this, -1, new RoleAttributeData(), null), 1, false);
            }
            var lostHpPercent:Number = (this.attribute.hpmax - this.attribute.hp) / this.attribute.hpmax;
            trace("lostHpPercent: " + lostHpPercent);
            var addPower:int = int(lostHpPercent / 0.2) * 40;
            (this.attribute.hasBuff(AttributeChangeBuff, "add_power") as AttributeChangeBuff).changeData.power = addPower;
            this.listData.getItemAt(0).msg = this.attribute.power;
            this.listData.updateItemAt(0);
         }
         if(hasGolden)
         {
            this.listData.getItemAt(1).msg = "Over";
            this.listData.updateItemAt(1);
         }
      }

      override public function onBeHit(beData:BeHitData):void
      {
         super.onBeHit(beData);
         if (this.attribute && this.attribute.hp < this.attribute.hpmax * 0.15 && !hasGolden)
         {
            this.golden += 180;
            hasGolden = true;
         }
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         // 复制被动使用状态
         ob.hasGolden = hasGolden;
         return ob;
      }

      override public function setData(value:Object) : void
      {
         super.setData(value);
         // 设置被动使用状态
         hasGolden = value.hasGolden;
      }

   }
}

