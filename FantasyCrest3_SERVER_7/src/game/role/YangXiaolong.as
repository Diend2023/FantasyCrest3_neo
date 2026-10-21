package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import feathers.data.ListCollection;
   import zygame.data.BeHitData;
   import game.buff.AttributeChangeBuff;
   import game.server.AccessRun3Model;
   import game.server.ReplayRunModel;
   import zygame.display.BaseRole;
   
   public class YangXiaolong extends GameRole
   {

      protected var hairNum:int = 0;

      // 力量buff剩余秒数，> 0 表示 buff 生效中
      protected var liliangTime:int = 0;

      // 冷却剩余秒数，> 0 表示冷却中
      protected var liliangCD:int = 0;
      
      // 力量buff持续秒数（BuffRef.time 的单位是秒）
      private static const LILIANG_BUFF_TIME:int = 7;
      
      // buff结束后的冷却秒数（原逻辑 900 帧 ÷ 60 = 15 秒）
      private static const LILIANG_CD_TIME:int = 15;
      
      public function YangXiaolong(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"mofa.png",
            "msg":0
         },
         {
            "icon":"liliang.png",
            "msg":"Ready"
         }]);
      }
      
      // 只读镜像端：客机与回放的数据由主机/录像驱动，不本地推进状态机
      private function get isMirror() : Boolean
      {
         var rm:Object = this.world ? this.world.runModel : null;
         return rm is AccessRun3Model || rm is ReplayRunModel;
      }
      
      // 同步给客机/录像：状态由两个计数隐式表示（都为0即Ready）
      override public function copyData() : Object
      {
         var data:Object = super.copyData();
         data.liliangTime = this.liliangTime;
         data.liliangCD = this.liliangCD;
         return data;
      }
      
      override public function setData(value:Object) : void
      {
         super.setData(value);
         // 注意：必须在 super.setData 之后取，差分包缺失的字段此时已被合并回 value
         var t:int = this.liliangTime;
         var cd:int = this.liliangCD;
         if(value.liliangTime != undefined)
         {
            t = int(value.liliangTime);
         }
         if(value.liliangCD != undefined)
         {
            cd = int(value.liliangCD);
         }
         if(t != this.liliangTime || cd != this.liliangCD)
         {
            this.liliangTime = t;
            this.liliangCD = cd;
            this.updateLiliangMsg();
         }
      }
      
      // 秒级状态机：onSUpdate 由 World._sfps(1Hz) 每秒触发一次，与逻辑时间同步
      // Ready(liliangTime=0 && liliangCD=0) → On(liliangTime>0) → CD(liliangCD>0) → Ready
      override public function onSUpdate() : void
      {
         super.onSUpdate();
         if(!this.isMirror)
         {
            var buff:AttributeChangeBuff = this.attribute.hasBuff(AttributeChangeBuff, "addAttack") as AttributeChangeBuff;
            if(buff)
            {
               // On：同步buff剩余秒数
               this.liliangTime = buff.currentTime;
            }
            else if(this.liliangTime > 0)
            {
               // On → CD：buff刚刚结束，只在这里赋一次值，避免每帧重置
               this.liliangTime = 0;
               this.liliangCD = LILIANG_CD_TIME;
            }
            else if(this.liliangCD > 0)
            {
               // CD递减
               this.liliangCD--;
            }
         }
         this.updateLiliangMsg();
      }
      
      // 三态msg刷新
      private function updateLiliangMsg() : void
      {
         var msg:Object = null;
         if(this.liliangTime > 0)
         {
            msg ="On " + this.liliangTime;
         }
         else if(this.liliangCD > 0)
         {
            msg ="Wait " + this.liliangCD;
         }
         else
         {
            msg = "Ready";
         }
         this.listData.getItemAt(1).msg = msg;
         this.listData.updateItemAt(1);
      }
      
      override public function onBeHit(beData:BeHitData) : void
      {
         super.onBeHit(beData);
         if(hairNum < 10)
         {
            var randomNum:Number = Math.random();
            if(randomNum < 0.1)
            {
               hairNum += 1;
               this.listData.getItemAt(0).msg = hairNum;
               this.listData.updateItemAt(0);
            }
         }
         // 客机不跑本地结算，回放以录像数据为准，只有权威端才触发buff
         if(!this.isMirror && this.liliangCD <= 0 && this.liliangTime <= 0 && this.straight >= 75 && !this.attribute.hasBuff(AttributeChangeBuff, "addAttack"))
         {
            this.addBuff(new AttributeChangeBuff("addAttack", this, LILIANG_BUFF_TIME, new RoleAttributeData()));
            (this.attribute.hasBuff(AttributeChangeBuff, "addAttack") as AttributeChangeBuff).changeData.power = hairNum * 10;
            this.liliangTime = LILIANG_BUFF_TIME;
            this.updateLiliangMsg();
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         if(isOSkill())
         {
            if(beData.armorScale == 0 && beData.magicScale == 0)
            {
               beData.armorScale = 1;
            }
            beData.armorScale += 0.08 * hairNum;
         }
         else
         {
            if(beData.armorScale == 0 && beData.magicScale == 0)
            {
               beData.armorScale = 1;
            }
            beData.armorScale += 0.05 * hairNum;
         }
         super.onHitEnemy(beData,enemy);
      }

   }
}
