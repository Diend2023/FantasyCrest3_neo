// 添加双月让叶
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.data.BeHitData;
   import zygame.display.BaseRole;
   import feathers.data.ListCollection;
   import game.world.BaseGameWorld;
   
   public class SYRY extends GameRole
   {

      private static var _baDao:Array = ["居合斩·上段", "居合斩·中段", "居合斩·下段", "拔刀斩·笑 下段", "拔刀斩·笑 中段", "拔刀斩·笑 上段", "空中拔刀术·下段", "空中拔刀术·中段", "空中拔刀术·上段", "空中居合斩·下段", "空中居合斩·中段", "空中居合斩·上段"];
      private var _baDaoHitCount:int = 0;
      private var _baoFaCount:int = 0;
      private var _cameraTimer:int = 0; // 镜头缩放计时器
      
      public function SYRY(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":0
         }]);
      }

      override public function onInit() : void
      {
         super.onInit();
         _baDaoHitCount = 0;
      }

      override public function onFrame() : void
      {
         super.onFrame();
         if(_cameraTimer > 0)
         {
            (this.world as BaseGameWorld).founcDisplay = this;
            (this.world as BaseGameWorld).cameraScale = 1.015;
            _cameraTimer--;
            if(_cameraTimer == 0)
            {
               (this.world as BaseGameWorld).founcDisplay = (this.world as BaseGameWorld).centerSprite;
               (this.world as BaseGameWorld).cameraScale = 1;
            }
         }
         if(this.actionName == "双月一刀流         华   生" && this.currentFrame <= 28)
         {
            _cameraTimer = 2; // 设置镜头缩放持续时间，单位为帧
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole):void
      {
         if((this.actionName == "双月一刀流         华   生" && this.frameAt(43, 47)) || (this.actionName == "双月一刀流·散华" && this.frameAt(46, 50)))
         {
            beData.armorScale *= 1 + (Number(_baoFaCount) / 100);
            beData.addCrit = _baoFaCount; // 增加暴击率，数值等于暴发次数
            _baoFaCount = 0; // 重置暴发次数
            this.listData.getItemAt(0).msg = _baoFaCount;
            this.listData.updateItemAt(0);
         }
         else
         {
            beData.addCrit = 0; // 非特定动作时不增加暴击率
         }
         super.onHitEnemy(beData, enemy);
         trace("armorScale:", beData.armorScale, "addCrit:", beData.addCrit);
      }

      override public function hitDataBuff(beData:BeHitData):void
      {
         super.hitDataBuff(beData);
         if(_baDao.indexOf(this.actionName) != -1)
         {
            if(beData.armorScale != 0)
            {
               beData.armorScale *= 0.7;
            }
               if(this.attribute && this.attribute.hp > 0)
            if (_baoFaCount < 30)
            {
               _baoFaCount++;
               this.listData.getItemAt(0).msg = _baoFaCount;
               this.listData.updateItemAt(0);
            }
            if(_baDaoHitCount >= 2)
            {
               beData.isBreakDam = true;
               _baDaoHitCount = 0;
            }
            else
            {
               beData.isBreakDam = false;
               _baDaoHitCount++;
            }
         }
         else
         {
           beData.isBreakDam = false;
         }
         switch (_baDaoHitCount)
         {
            case 0:
               if(this.listData.getItemAt(1))
               {
                  this.listData.removeItemAt(1);
               }
               break;
            case 1:
               if(this.listData.getItemAt(1))
               {
                  this.listData.getItemAt(1).msg = "start";
               }
               else
               {
                  this.listData.addItemAt({
                     "icon":"mingzhong.png",
                     "msg":"start"
                  }, 1);
               }
               break;
            case 2:
               if(this.listData.getItemAt(1))
               {
                  this.listData.getItemAt(1).msg = "ready";
               }
               else
               {
                  this.listData.addItemAt({
                     "icon":"mingzhong.png",
                     "msg":"ready"
                  }, 1);
               }
               break;
         }
         if(this.listData.getItemAt(1))
         {
            this.listData.updateItemAt(1);
         }
      }
      
      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         ob._baoFaCount = _baoFaCount;
         return ob;
      }

      override public function setData(value:Object) : void
      {
         super.setData(value);
         _baoFaCount = value._baoFaCount || 0;
         this.listData.getItemAt(0).msg = _baoFaCount;
         this.listData.updateItemAt(0);
      }

   }
}

