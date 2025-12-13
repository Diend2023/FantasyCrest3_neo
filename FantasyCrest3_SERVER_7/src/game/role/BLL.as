// 添加布罗利(纹4)
package game.role
{
   import game.buff.AttributeChangeBuff;
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.display.EffectDisplay;
   import feathers.data.ListCollection;
   import game.world.BaseGameWorld;
   import zygame.data.BeHitData;
   import zygame.display.BaseRole;
   import flash.geom.Rectangle;
   import zygame.core.GameCore;
   
   public class BLL extends GameRole
   {
      private var _timeBuff:AttributeChangeBuff;
      private var _hitBuff:AttributeChangeBuff;
      private var _timecount:int = 0;
      private var _beHitNum:int = 0;
      private var _hitNum:int = 0;
      private var _groundY:int;

      public function BLL(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         _timeBuff = new AttributeChangeBuff("BLL_timeBuff",this,-1,new RoleAttributeData());
         this.addBuff(_timeBuff);
         _hitBuff = new AttributeChangeBuff("BLL_hitBuff",this,-1,new RoleAttributeData());
         this.addBuff(_hitBuff);
         this.listData = new ListCollection([{
            "icon":"liliang.png",
            "msg":0
         },
         {
            "icon":"mofa.png",
            "msg":0
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
      }

      override public function onSUpdate() : void
      {
         super.onSUpdate();
         // 被动代码随时间加伤和防御代码实现
         _timeBuff.changeData.power = int(_timecount * 0.00232);
         _timeBuff.changeData.magic = int(_timecount * 0.00286);
         _timeBuff.changeData.armorDefense = int(_timecount * 0.00002);
         _timeBuff.changeData.magicDefense = int(_timecount * 0.00002);
         listData.getItemAt(0).msg = this.attribute.power;
         listData.updateItemAt(0);
         listData.getItemAt(1).msg = this.attribute.magic;
         listData.updateItemAt(1);
      }

	   override public function onFrame():void
      {
         super.onFrame();
         _timecount++;
         var isHand:Boolean = false;
         var role:BaseRole = null;
         // 普通攻击后续
         if (actionName == "普通攻击" && frameAt(8,14))
         {
            if (isKeyDown(74))
            {
               mandatorySkill = 1;
               playSkill("[隐藏]普通攻击后续");
               mandatorySkill = 1;
            }
         }
         if (actionName == "[隐藏]普通攻击后续" && frameAt(15,20))
         {
            if (isKeyDown(74))
            {
               mandatorySkill = 1;
               playSkill("[隐藏]普通攻击后续2");
            }
         }
         // 普通攻击后续2抓取实现
         if (actionName == "[隐藏]普通攻击后续2")
         {
            if (frameAt(5, 17))
            {
               isHand = hand(200, 100, 100, 200, 100, 0);
               if (!isHand && currentFrame == 16)
               {
                  breakAction();
               }
            }
            else if (currentFrame == 22)
            {
               hand(200, 100, 100, 200, 0, 200);
            }
         }

         // I套索传送后续
         if (actionName == "套索传送" && frameAt(18, 51))
         {
            if (isKeyDown(73))
            {
               mandatorySkill = 1;
               playSkill("[隐藏]套索后续");
               mandatorySkill = 1;
            }
         }

         // SU巨爪击抓取后续
         if (actionName == "[隐藏][抓取]抓取后续" && frameAt(-1, 9))
         {
            hand(150, 150, 150, 150, 100, 25);
         }

         // KI浩瀚重击取后续
         if (actionName == "[隐藏][抓取]浩瀚重击后续" && frameAt(-1, 5))
         {
            hand(150, 150, 150, 150, 75, 50);
         }

         // WL超级冲击实现
         if (isKeyDown(87) && isKeyDown(76))
         {
            playSkill("超级冲击");
         }

         // SJ龙冲击抓取以及跳转实现
         if (actionName == "[无十二刀]龙冲击" && frameAt(3, 9))
         {
            isHand = hand(100, 100, 200, 200, 90, 10);
            if (isHand)
            {
               mandatorySkill = 1;
               playSkill("[抓取][无十二刀][隐藏]龙冲击后续");
               mandatorySkill = 1;
            }
         }

         // SJ龙冲击后续
         if (actionName == "[抓取][无十二刀][隐藏]龙冲击后续" && frameAt(-1, 29))
         {
            hand(100, 100, 200, 200, 90, 10);
         }

         // P抹杀风暴抓取
         if (actionName == "[抓取][无十二刀]抹杀风暴")
         {
            if (currentFrame == 14)
            {
               isHand = hand(200, 200, 200, 250, 100, 0);
               if (!isHand)
               {
                  breakAction();
               }
            }
            else if (frameAt(14, 34))
            {
               hand(200, 200, 200, 200, 100, 100);
            }
            else if (frameAt(52, 64))
            {
               hand(200, 200, 200, 200, 100, 25);
            }
         }

         // KSU重砸抓取
         if (actionName == "[抓取]重砸")
         {
            if (currentFrame == 20)
            {
               isHand = hand(200, 300, 200, 300, 100, 50);
               if (!isHand)
               {
                  breakAction();
               }
            }
            else if (frameAt(23, 31))
            {
               hand(200, 200, 200, 200, 100, 0);
            }
         }

         // SL消失移动实现
         if (isKeyDown(83) && isKeyDown(76))
         {
            playSkill("消失移动");
         }

         // 消失移动时停瞬移实现
         if (actionName == "消失移动")
         {
            role = this.findRole(new Rectangle(0,0,world.map.getWidth(),world.map.getHeight()));
            if(role)
            {
               if(frameAt(3, 19) && role.isJump())
               {
                  shiting(3, role);
               }
               if (currentFrame == 11)
               {
                  this.posx = role.x - 100 * role.scaleX;
                  this.posy = role.y;
                  this.scaleX = role.scaleX > 0 ? 1 : -1;
               }
            }
         }

         // O抹杀加农炮镜头锁定实现
         if (actionName == "抹杀加农炮")
         {
            if (currentFrame == 1)
            {
               for(var i in this.world.getRoleList())
               {
                  if (this.world.getRoleList()[i] != this)
                  {
                     shiting(90, this.world.getRoleList()[i]);
                  }
               }
               (world as BaseGameWorld).founcDisplay = this;
            }
            if (currentFrame == 31)
            {
               (world as BaseGameWorld).founcDisplay = (world as BaseGameWorld).centerSprite;
            }
            // O命中后续实现
            var effectW:EffectDisplay = this.world.getEffectFormName("W",this);
            if (effectW && effectW.name == "Obaozha")
            {
               role = this.findRole(new Rectangle(0,0,world.map.getWidth(),world.map.getHeight()));
               if(role)
               {
                  if (Math.abs(role.x - effectW.x) < 100 && Math.abs(role.y - 100 - effectW.y) < 150)
                  {
                     var effectTxjs125:EffectDisplay = new EffectDisplay("txjs125",{blendMode:"changeColor",addColor:"0x66FF33"},this,1,1);
                     effectTxjs125.name = "txjs125";
                     effectTxjs125.scaleX = 2;
                     effectTxjs125.scaleY = 2;
                     effectTxjs125.fps = 16;
                     (world as BaseGameWorld).addChild(effectTxjs125);
                     effectTxjs125.x = role.x;
                     effectTxjs125.y = role.y - 70;

                     var effectBaozhaR:EffectDisplay = new EffectDisplay("baozhaR",{blendMode:"changeColor",addColor:"0x66FF33"},this,1,1);
                     effectBaozhaR.name = "baozhaR";
                     effectBaozhaR.scaleX = 2;
                     effectBaozhaR.scaleY = 2;
                     effectBaozhaR.fps = 16;
                     effectBaozhaR.unhit = true;
                     (world as BaseGameWorld).addChild(effectBaozhaR);
                     effectBaozhaR.x = role.x;
                     effectBaozhaR.y = role.y;

                     var effectLongZhanEr:EffectDisplay = new EffectDisplay("LongZhanEr",{blendMode:"changeColor2",addColor:"0x66FF33"},this,1,1);
                     effectLongZhanEr.name = "LongZhanEr";
                     effectLongZhanEr.scaleX = 2;
                     effectLongZhanEr.scaleY = 2;
                     effectLongZhanEr.fps = 18;
                     effectLongZhanEr.unhit = true;
                     (world as BaseGameWorld).addChild(effectLongZhanEr);
                     effectLongZhanEr.x = role.x;
                     effectLongZhanEr.y = role.y - 70;

                     var effectTxjs77R:EffectDisplay = new EffectDisplay("txjs77R",{blendMode:"changeColor",addColor:"0x66FF33"},this,1,1);
                     effectTxjs77R.name = "txjs77R";
                     effectTxjs77R.scaleX = 2;
                     effectTxjs77R.scaleY = 2;
                     effectTxjs77R.fps = 24;
                     effectTxjs77R.unhit = true;
                     (world as BaseGameWorld).addChild(effectTxjs77R);
                     effectTxjs77R.x = role.x;
                     effectTxjs77R.y = role.y - 70;

                     var effectP:EffectDisplay = new EffectDisplay("P",{findName:"P",blendMode:"changeColor2",addColor:"0x000000",cardFrame:15,hitVibrationSize:35,stiff:60,mFight:1750},this,1,1);
                     effectP.name = "P";
                     effectP.scaleX = 1;
                     effectP.scaleY = 2;
                     effectP.hitY = 40;
                     (world as BaseGameWorld).addChild(effectP);
                     (world as BaseGameWorld).vibrationSize = 35;
                     (world as BaseGameWorld).mapVibrationTime = 18;
                     effectP.x = role.x;
                     effectP.y = role.y;
                     effectP.posx = role.x;
                     effectP.posy = role.y;
                     effectW.removeFromParent();
                  }
               }
            }
         }

         if(actionName == "待机")
         {
            _groundY = this.y - 70;
         }

         // KO巨量流星时停和cg实现
         if (actionName == "巨量流星")
         {
            if (currentFrame == 0)
            {
               for(var j in this.world.getRoleList())
               {
                  if (this.world.getRoleList()[j] != this && this.world.getRoleList()[j].isJump())
                  {
                     shiting(30, this.world.getRoleList()[j]);
                  }
               }
            }
            if (currentFrame == 4)
            {
               for(var k in this.world.getRoleList())
               {
                  shiting(150, this.world.getRoleList()[k]);
               }
               currentFrame = 5;
            }
            if (currentFrame == 5)
            {
               var effectBLL13:EffectDisplay = new EffectDisplay("BLL13",{blendMode:"normal"},this,2,2);
               effectBLL13.fps = 15;
               effectBLL13.unhit = true;
               (world as BaseGameWorld).addChild(effectBLL13);
               GameCore.soundCore.playEffect("BLL1");
               if((world as BaseGameWorld).founcDisplay == this)
               {
                  effectBLL13.posx = this.x - 640;
                  effectBLL13.posy = this.y - 360;
               }
               else
               {
                  effectBLL13.posx = (world as BaseGameWorld).centerSprite.x - 640;
                  effectBLL13.posy = (world as BaseGameWorld).centerSprite.y - 360;
               }
               currentFrame = 6;
            }
         }

         var effectBLL22:EffectDisplay = this.world.getEffectFormName("BLL22",this);
         if (effectBLL22 && effectBLL22.name == "BLL22")
         {
            if (effectBLL22.currentFrame == 25)
            {
               effectBLL22.go(0);
               effectBLL22.rotation += 1;
            }

            role = this.findRole(new Rectangle(0,0,world.map.getWidth(),world.map.getHeight()));
            if(role)
            {
               if (Math.abs(role.x - effectBLL22.x) < 100 && Math.abs(role.y - effectBLL22.y) < 100)
               {
                  role.x = effectBLL22.x;
                  role.y = effectBLL22.y;
                  effectBLL22.scaleX = Math.max(-4, Math.min(effectBLL22.scaleX * 1.05, 4));
                  effectBLL22.scaleY = Math.max(-4, Math.min(effectBLL22.scaleY * 1.05, 4));
               }
            }

            if(effectBLL22.y >= _groundY)
            {
               effectBLL22.removeFromParent();

               var effectBLL25:EffectDisplay = new EffectDisplay("BLL25",{blendMode:"changeColor",addColor:0x66FF33,cardFrame:15,hitVibrationSize:20,stiff:50,mFight:100},this,1,1);
               effectBLL25.scaleX = 2;
               effectBLL25.scaleY = 2;
               effectBLL25.fps = 60;
               effectBLL25.hitY = 10;
               (world as BaseGameWorld).addChild(effectBLL25);
               (world as BaseGameWorld).vibrationSize = 20;
               (world as BaseGameWorld).mapVibrationTime = 10;
               effectBLL25.posx = effectBLL22.x;
               effectBLL25.posy = effectBLL22.y - 770;

               var effectBLL23:EffectDisplay = new EffectDisplay("BLL23",{blendMode:"changeColor",addColor:0x66FF33,cardFrame:50,hitVibrationSize:35,stiff:60,mFight:500},this,1,1);
               effectBLL23.scaleX = 1.5;
               effectBLL23.scaleY = 1.5;
               effectBLL23.fps = 35;
               effectBLL23.hitY = 10;
               (world as BaseGameWorld).addChild(effectBLL23);
               (world as BaseGameWorld).vibrationSize = 35;
               (world as BaseGameWorld).mapVibrationTime = 18;
               effectBLL23.posx = effectBLL22.x;
               effectBLL23.posy = effectBLL22.y + 30;
               
               var effectRose1:EffectDisplay = new EffectDisplay("rose1",{blendMode:"changeColor2",addColor:0x66FF33},this,1,1);
               effectRose1.scaleX = 2;
               effectRose1.scaleY = 2;
               (world as BaseGameWorld).addChild(effectRose1);
               effectRose1.x = effectBLL22.x;
               effectRose1.y = effectBLL22.y + 80;
            }
         }

         // WP霸体实现
         var effectTxjs107:EffectDisplay = this.world.getEffectFormName("txjs107",this);
         if (effectTxjs107)
         {
            this.golden = 10;
         }
      }

      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         var isHand:Boolean = false;
         // 被动当攻击敌人1hit后增加攻击代码实现
         _hitBuff.changeData.power = int(++_hitNum * 0.464);
         _hitBuff.changeData.magic = int(++_hitNum * 0.572);
         listData.getItemAt(0).msg = this.attribute.power;
         listData.updateItemAt(0);
         listData.getItemAt(1).msg = this.attribute.magic;
         listData.updateItemAt(1);
         super.onHitEnemy(beData,enemy);

         // SU巨爪击破防和跳转后续和调整敌方位置实现
         if (actionName == "[抓取]巨抓击" && frameAt(8,16))
         {
            isHand = hand(300, 300, 200, 200, 100, 0);
            if (isHand)
            {
               mandatorySkill = 1;
               playSkill("[隐藏][抓取]抓取后续");
               mandatorySkill = 1;
            }
         }

         // KI浩瀚重击抓取以及跳转实现
         if (actionName == "[抓取]浩瀚重击")
         {
            isHand = hand(400, 400, 400, 400, 100, 100);
            if (isHand)
            {
               mandatorySkill = 1;
               playSkill("[隐藏][抓取]浩瀚重击后续");
               mandatorySkill = 1;
            }
         }

         // WL超级冲击停止
         if (actionName == "超级冲击" && frameAt(6, 23))
         {
            currentFrame = 23;
         }
      }

      override public function onBeHit(beData:BeHitData) : void
      {
         // 被动当收到一hit攻击后增加防御代码实现
         _hitBuff.changeData.armorDefense = int(++_beHitNum * 0.05);
         _hitBuff.changeData.magicDefense = int(++_beHitNum * 0.05);
         listData.getItemAt(0).msg = this.attribute.power;
         listData.updateItemAt(0);
         listData.getItemAt(1).msg = this.attribute.magic;
         listData.updateItemAt(1);
         super.onBeHit(beData);
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         // 复制被击和命中次数继承至下一局
         ob._timecount = this._timecount;
         ob._beHitNum = this._beHitNum;
         ob._hitNum = this._hitNum;
         return ob;
      }
      
      override public function setData(value:Object) : void
      {
         super.setData(value);
         // 读取继承的被击和命中次数
         _timecount = value._timecount;
         _beHitNum = value._beHitNum;
         _hitNum = value._hitNum;
         _timeBuff.changeData.power = int(_timecount * 0.00232);
         _timeBuff.changeData.magic = int(_timecount * 0.00286);
         _timeBuff.changeData.armorDefense = int(_timecount * 0.00002);
         _timeBuff.changeData.magicDefense = int(_timecount * 0.00002);
         _hitBuff.changeData.power = int(_hitNum * 0.464);
         _hitBuff.changeData.magic = int(_hitNum * 0.572);
         _hitBuff.changeData.armorDefense = int(_beHitNum * 0.05);
         _hitBuff.changeData.magicDefense = int(_beHitNum * 0.05);
         listData.getItemAt(0).msg = this.attribute.power;
         listData.updateItemAt(0);
         listData.getItemAt(1).msg = this.attribute.magic;
         listData.updateItemAt(1);
      }

      public function hand(topRange:int = 200, bottomRange:int = 200, backRange:int = 100, frontRange:int = 200,  toX:int = 0, toY:int = 0):Boolean
      {
          var rect:Rectangle = this.body.bounds.toRect();
          // 横向判定
          if(this.scaleX > 0)
          {
              rect.width += frontRange;
              rect.x -= backRange;
              rect.width += backRange;
          }
          else
          {
              rect.x -= frontRange;
              rect.width += frontRange;
              rect.width += backRange;
          }
          // 纵向判定
          rect.y -= topRange;
          rect.height += topRange;
          rect.height += bottomRange;
      
          // 修正左边界
          if(rect.x < 0)
          {
              rect.width += rect.x; // 把溢出的部分减掉
              rect.x = 0;
              toX = 0;
          }
          // 修正右边界
          if(rect.x + rect.width > world.map.getWidth())
          {
              rect.width = world.map.getWidth() - rect.x;
              toX = 0;
          }
      
          if(rect.width > 0 && rect.height > 0)
          {
              var role:BaseRole = findRole(rect);
              if(role)
              {
                  role.clearDebuffMove();
                  role.straight = 30;
                  role.setX(this.x + toX * this.scaleX);
                  role.setY(this.y - toY);
                  return true;
              }
          }
          return false;
      }

      public function shiting(cardFrame:int, role:BaseRole):void
      {
         for(var i in this.world.getRoleList())
         {
            if(this.world.getRoleList()[i] == role)
            {
               this.world.getRoleList()[i].cardFrame = cardFrame;
            }
         }
      }

   }
}