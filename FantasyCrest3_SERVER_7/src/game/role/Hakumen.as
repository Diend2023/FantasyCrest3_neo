package game.role
{
   import flash.geom.Point;
   import game.world._FBBaseWorld;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.BaseRole;
   import zygame.display.World;
   import feathers.data.ListCollection;

   public class Hakumen extends GameRole
   {
      
      private var hasDefense:Boolean = false;

      private var KLMoveFrameCount:int = 0

      private var KWLMoveFrameCount:int = 0

      private var _keyQueue:Array = [];

      private const _keyObj:Object = {65:"←",68:"→",87:"↑",83:"↓",74:"J",75:"K",76:"L",85:"U",73:"I",79:"O",80:"P"};
      
      public function Hakumen(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"cd_I_mp.png",
            "msg":"",
            "len":110
         }]);
      }

      override public function onFrame():void
      {
        if(this.inFrame("防御",8) && this.isDefense())
        {
            this.hasDefense = true;
            this.go(3);
        }
        super.onFrame();
        if(this.actionName == "待机")
        {
            if(this.currentFrame == 36)
            {
                var randomNum:Number = Math.random();
                if(randomNum < 0.4)
                {
                    this.go(0);
                }
                else if(0.5 <= randomNum < 0.825)
                {
                    this.go(37);
                }
                else if(0.825 <= randomNum < 0.875)
                {
                    this.go(48);
                }
                else if(0.875 <= randomNum < 0.925)
                {
                    this.go(62);
                }
                else if(0.925 <= randomNum < 0.95)
                {
                    this.go(87);
                }
                else if(0.95 <= randomNum < 0.975)
                {
                    this.go(107);
                }
                else if(0.975 <= randomNum < 1.0)
                {
                    this.go(123);
                }
            }
            switch (this.currentFrame)
            {
                case 47:
                case 61:
                case 86:
                    this.go(0);
                    break;
                case 106:
                    this.go(this.currentFrame - 6);
                    break;
                case 122:
                    this.go(this.currentFrame - 3);
                    break;
                case 133:
                    this.go(this.currentFrame - 4);
                    break;
            }
        }
        if(this.inFrame("降落", this.roleXmlData.getActionLength("降落") - 1))
        {
            this.currentFrame -= 2;
        }
        if(this.actionName == "受伤")
        {
            if(this.currentFrame == 0)
            {
                randomNum = Math.random();
                if(randomNum >= 0.5)
                {
                    this.go(4);
                }
            }
            if(this.currentFrame == 3)
            {
                this.currentFrame -= 1;
            }
        }
        if(KLMoveFrameCount > 0)
        {
            if(this.cardFrame <= 0)
            {
                this.xMove(10 * (this.scaleX > 0 ? 1 : -1));
                KLMoveFrameCount -= 1;
            }
        }
        if(!this.isJump())
        {
            this.attribute.clearCD("突进")
        }
        if(actionName == "斩神JD" || actionName == "空投")
        {
            KLMoveFrameCount = 0;
        }
        if(KWLMoveFrameCount > 0)
        {
            if(this.cardFrame <= 0)
            {
                this.xMove(10 * (this.scaleX > 0 ? -1 : 1));
                KWLMoveFrameCount -= 1;
            }
        }
        if(actionName == "斩神JD" || actionName == "空投")
        {
            KWLMoveFrameCount = 0;
        }
      }

      override public function onDown(key:int):void
      {
         super.onDown(key);
        //  if(key == 85 && (this.actionName == "虚空阵 素" || this.actionName == "虚空阵 盈" || this.actionName == "虚空阵 鸣" || this.actionName == "虚空阵 尊"))
        //  {
        //     if(this.currentFrame > 10 && this.currentMp.value >= 1)
        //     {
        //        this.breakAction();
        //        this.clearDebuffMove();
        //        this.playSkill(this.actionName + " 攻击");
        //        this.currentMp.value -= 1;
        //     }
        //  }
         if(_keyObj.hasOwnProperty(key))
         {
            _keyQueue.push(_keyObj[key]);
         }
         if(_keyQueue.length > 5)
         {
            _keyQueue.shift();
         }
         if(key == 73)
         {
            if(_keyQueue.join("").indexOf("→→I") != -1 || _keyQueue.join("").indexOf("←←I") != -1)
            {
               this.playSkill("红莲214A");
            }
            if(_keyQueue.join("").indexOf("↓→I") != -1 || _keyQueue.join("").indexOf("↓←I") != -1)
            {
               this.playSkill("残铁41236C");
            }
            if(_keyQueue.join("").indexOf("→→↑I") != -1 || _keyQueue.join("").indexOf("←←↑I") != -1)
            {
               this.playSkill("鬼蹴·阍魔623A");
            }
            if(_keyQueue.join("").indexOf("→→↓I") != -1 || _keyQueue.join("").indexOf("←←↓I") != -1)
            {
               this.playSkill("鵺柳214D");
            }
            if(_keyQueue.join("").indexOf("→↑I") != -1 || _keyQueue.join("").indexOf("←↑I") != -1)
            {
               this.playSkill("莲华236B");
            }
            _keyQueue = [];
         }
         this.listData.getItemAt(0).msg = _keyQueue.join("");
         this.listData.updateItemAt(0);
      }

      override public function playSkill(target:String):void
      {
        if(target == "瞬步" && this.isJump())
        {
            if(this.attribute.getCD("突进") <= 0)
            {
                target = "突进";
                KLMoveFrameCount = 40;
            }
            else
            {
                return;
            }
        }
        if(target == "空中后撤" && this.attribute.getCD("空中后撤") <= 0)
        {
            KWLMoveFrameCount = 20;
        }
        super.playSkill(target);
      }

   }
}

