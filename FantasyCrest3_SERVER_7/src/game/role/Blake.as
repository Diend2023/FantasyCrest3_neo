// 新增Blake被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.data.BeHitData;
   import flash.geom.Point;
   import feathers.data.ListCollection;
   
   public class Blake extends GameRole
   {

      private var _PTimer:int = 0;

      private var _blakeFS:GameRole = null;
      
      public function Blake(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }

      override public function onInit() : void
      {
         super.onInit();
         this.listData = new ListCollection([{
            "icon":"mofa.png",
            "msg":"Ready"
         }]);
      }

      override public function onFrame():void
      {
         if(_PTimer > 0 && this.cardFrame <= 0)
         {
            _PTimer -= 1;
            if(!_blakeFS)
            {
               _PTimer = 0
               this.hurtNumber(int(this.attribute.hpmax * 0.33), null, new Point(this.x, this.y));
            }
            else
            {
               _blakeFS.attribute.updateCD("分身",99999);
            }
         }
         if(_PTimer <= 0)
         {
            if(_blakeFS)
            {
               discardFS();
            }
         }
         if(_blakeFS && _blakeFS.inFrame("分身结束",_blakeFS.roleXmlData.getActionLength("分身结束") - 1))
         {
            this.hurtNumber(int((_blakeFS.attribute.hpmax - _blakeFS.attribute.hp) * 0.33), null, new Point(this.x, this.y));
            this.detachFS();
         }
         super.onFrame();
         if(_PTimer > 0)
         {
            if(_blakeFS)
            {
               if(_blakeFS.attribute.hp <= 0)
               {
                  this.detachFS();
               }
               this.playSkill("防御");
               if(this.isOut)
               {
                  discardFS();
               }
            }
            this.listData.getItemAt(0).msg = (_PTimer / 60).toFixed(1);
         }
         else if(this.attribute.getCD("分身") > 0)
         {
            this.listData.getItemAt(0).msg = "Wait";
         }
         else
         {
            this.listData.getItemAt(0).msg = "Ready";
         }
         this.listData.updateItemAt(0);
      }
      
      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         super.runLockAction(str, canBreak);
         if(str == "分身" && !_blakeFS && this.name != "blakeFS")
         {
            var blakeFS:GameRole = new GameRole("Blake",this.x,this.y,this.world);
            this.world.addChild(blakeFS);
            blakeFS.name = "blakeFS";
            blakeFS.ai = false;
            blakeFS.troopid = this.troopid;
            blakeFS.attribute.hpmax = this.attribute.hpmax;
            blakeFS.attribute.hp = blakeFS.attribute.hpmax;
            _blakeFS = blakeFS;
            _PTimer = 600;
            blakeFS.runLockAction("分身");
            this.overDown();
         }
      }

      override public function hurtNumber(beHurt:int, beData:BeHitData, pos:Point) : void
      {
         super.hurtNumber(beHurt,beData,pos);
         if(_blakeFS)
         {
            discardFS();
         }
      }

      override public function onDown(key:int):void
      {
         if(_blakeFS)
         {
            if(key != 72)
            {
               _blakeFS.onDown(key);
               this.pushKey(key);
            }
            return;
         }
         super.onDown(key);
      }

      override public function onUp(key:int):void
      {
         if(_blakeFS)
         {
            _blakeFS.onUp(key);
            this.removeKey(key);
            return;
         }
         super.onUp(key);
      }

      override public function isKeyDown(key:int) : Boolean
      {
         if(_blakeFS)
         {
            return false;
         }
         return super.isKeyDown(key);
      }

      override protected function onDie(beData:BeHitData) : void
      {
         if(_blakeFS)
         {
            this.detachFS();
         }
         super.onDie(beData);
      }

      private function discardFS():void
      {
         if(_blakeFS && _blakeFS.attribute.hp > 0)
         {
            _blakeFS.breakAction();
            _blakeFS.goldenTime = 30;
            _blakeFS.runLockAction("分身结束");
            this.overDown();
         }
      }

      private function detachFS() : void
      {
         if(!_blakeFS)
         {
            return;
         }
         _blakeFS.stopAllKey(); // 分身侧彻底松手（含双击缓存）
         _blakeFS.discarded();
         _blakeFS = null;
         this.overDown();
      }
   }
}

