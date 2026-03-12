package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import game.buff.AttributeChangeBuff;
   import feathers.data.ListCollection;
   import zygame.display.EffectDisplay;

   public class ZZX extends GameRole
   {

      private const EFFECT_MH17_DATA:Object = {"blow":false,"hitVibrationSize":0,"addColor":13395456,"intensity":0,"time":0,"srcColor":-1,"name":"mh17","rotation":89,"isBreak":false,"isLaunch":false,"cardFrame":0,"isLockActionShow":false,"hitX":0,"scaleX":1,"isLockAction":true,"blendMode":"addColor","scaleY":1,"isABlow":false,"findName":"selfmh17","mFight":0,"stiff":30,"wFight":0,"atbottom":false,"isFollow":true,"hitY":0,"overrideClass":"","gox":0,"canHit":false,"hitMap":false,"unhit":true,"through":false,"x":-25,"goy":0,"y":-35,"fadeIn":false,"fadeOut":false,"color":[],"hitEffectName":""};

      private var _pFireTimer:int = 0; // P火焰buff计时器

      public function ZZX(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":0
         }]);
      }
      
      override public function onFrame() : void
      {
         super.onFrame();
         trace("hit: " + this.hit, "_pFireTimer: " + _pFireTimer, this.attribute.hasBuff(AttributeChangeBuff, "fireBuff") == null ? "no fireBuff" : "has fireBuff");
         if(this.actionName == "我流·灼心燃魂" && this.currentFrame >= 2)
         {
            _pFireTimer = 300;
         }
         if(_pFireTimer > 0 && this.cardFrame <= 0)
         {
            _pFireTimer--;
         }
         if ((this.hit > 5 || _pFireTimer > 0) && !this.attribute.hasBuff(AttributeChangeBuff, "fireBuff"))
         {
            var fireBuff:AttributeChangeBuff = new AttributeChangeBuff("fireBuff", this, -1, new RoleAttributeData());
            this.addBuff(fireBuff);
         }
         else if (this.hit <= 5 && this.attribute.hasBuff(AttributeChangeBuff, "fireBuff") && _pFireTimer <= 0)
         {
            this.attribute.hasBuff(AttributeChangeBuff, "fireBuff").currentTime = 0; // 清除buff
         }
         var effects:Vector.<EffectDisplay> = this.world.getEffects();
         for each(var effect:EffectDisplay in effects)
         {
            if(effect.objectData.findName == "selfmh17" && effect.role == this)
            {
               var effectMh17:EffectDisplay = effect;
            }
         }
         if(this.attribute.hasBuff(AttributeChangeBuff, "fireBuff"))
         {
            (this.attribute.hasBuff(AttributeChangeBuff, "fireBuff") as AttributeChangeBuff).changeData.power = 200 * (1 - this.attribute.hp / this.attribute.hpmax); // 根据当前HP百分比增加攻击力
            if(this.cardFrame <= 0)
            {
               this.attribute.hp -= 10; // 每帧扣除10点HP
            }
            if(!effectMh17)
            {
               effectMh17 = new EffectDisplay("mh17", EFFECT_MH17_DATA, this);
               this.world.addChild(effectMh17);
            }
         }
         else
         {
            if(effectMh17)
            {
               effectMh17.removeFromParent(true);
            }
         }
         listData.getItemAt(0).msg = this.attribute.power; // 更新攻击力显示
         listData.updateItemAt(0);
      }

      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         super.runLockAction(str, canBreak);
         if(this.attribute.hasBuff(AttributeChangeBuff, "fireBuff"))
         {
            switch(str)
            {
               case "秘剑·鬼步（狱步）":
                  this.actionName = "EXSJ";
                  break;
               case "红莲腕（真·红莲腕）":
                  this.actionName = "EXWJ"
                  break;
               case "秘剑·圆（红牙飞燕）":
                  this.actionName = "EXU"
                  break;
               case "秘剑·走灼（锯刀行焰）":
                  this.actionName = "EXSU"
                  break;
               case "秘剑·背车刀（背车烛势）":
                  this.actionName = "EXWU"
                  break;
               case "秘剑·凌空（火烧云鸦）":
                  this.actionName = "EXKU"
                  break;
               case "秘剑·穿空（穿火灼心）":
                  this.actionName = "EXKSU"
                  break;
               case "秘剑·渡鸦（祸鸦三渡）":
                  this.actionName = "EXI"
                  break;
               case "秘剑·人屠（人屠炎灵）":
                  this.actionName = "EXSI"
                  break;
               case "秘剑·旋空（卷炎风旋）":
                  this.actionName = "EXWI"
                  break;
               case "秘剑·划空（凌云烟渡）":
                  this.actionName = "EXKI"
                  break;
               case "无限刃·炎鬼（终极秘剑·火产灵神）":
                  this.actionName = "EXO"
                  break;
               case "无限刃·旋空（无限刃·灼鬼旋空）":
                  this.actionName = "EXWO"
                  break;
            }
            if (this.actionName.startsWith("EX"))
            {
               this.golden = 60; // 释放EX技能获得60帧霸体
            }
         }
      }

   }
}

