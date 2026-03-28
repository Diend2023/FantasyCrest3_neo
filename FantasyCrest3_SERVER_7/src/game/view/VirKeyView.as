package game.view
{
   import flash.geom.Point;
   import game.display.CommonButton;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.events.Touch;
   import starling.textures.TextureAtlas;
   import starling.utils.rad2deg;
   import zygame.core.DataCore;
   import zygame.display.TouchDisplayObject;
   
   public class VirKeyView extends TouchDisplayObject
   {
      
      private var _moveKey:Image;
      
      private var _moveBottom:Image;
      
      private var _touchTime:int = 0;

      private var _touchStartY:Number = 0; //

      private var _slideType:int = 0; // 0: 无滑动, 1: 上滑, 2: 下滑

      private var _delayTriggerKey:String = null; // 当前正在等待判定的按键
      private var _delayTriggerCount:int = 0;     // 判定计数（帧数）
      private const MAX_DELAY_FRAMES:int = 6;      // 判定阈值，在这个时间内滑动则触发组合键，否则触发单键。
      
      public function VirKeyView()
      {
         super();
      }
      
      override public function onInit() : void
      {
         super.onInit();
         var textures:TextureAtlas = DataCore.getTextureAtlas("hpmp");
         var moveKey:Image = new Image(textures.getTexture("key_bottom.png"));
         this.addChild(moveKey);
         moveKey.alignPivot();
         moveKey.x = 150;
         moveKey.y = stage.stageHeight - 100;
         _moveBottom = moveKey;
         _moveKey = new Image(textures.getTexture("key_move.png"));
         this.addChild(_moveKey);
         _moveKey.pivotX = 16;
         _moveKey.pivotY = 16;
         _moveKey.x = 150;
         _moveKey.y = moveKey.y;
         _moveKey.visible = false;
         var q:Quad = new Quad(300,200,16711680);
         q.alpha = 0;
         this.addChild(q);
         q.name = "move";
         q.x = 0;
         q.y = stage.stageHeight - q.height;
         var J:CommonButton = new CommonButton("j_key.png","hpmp");
         this.addChild(J);
         J.x = stage.stageWidth - 150;
         J.y = stage.stageHeight - 75;
         J.name = "j";
         J.callBack = onTag;
         var K:CommonButton = new CommonButton("k_key.png","hpmp");
         this.addChild(K);
         K.x = stage.stageWidth - 80;
         K.y = stage.stageHeight - 165;
         K.callBack = onTag;
         K.name = "k";
         var U:CommonButton = new CommonButton("u_key.png","hpmp");
         this.addChild(U);
         U.x = stage.stageWidth - 255;
         U.y = stage.stageHeight - 75;
         U.callBack = onTag;
         U.name = "u";
         var I:CommonButton = new CommonButton("i_key.png","hpmp");
         this.addChild(I);
         I.x = stage.stageWidth - 220;
         I.y = stage.stageHeight - 155;
         I.callBack = onTag;
         I.name = "i";
         var O:CommonButton = new CommonButton("o_key.png","hpmp");
         this.addChild(O);
         O.x = stage.stageWidth - 160;
         O.y = stage.stageHeight - 230;
         O.callBack = onTag;
         O.name = "o";
         var P:CommonButton = new CommonButton("p_key.png","hpmp");
         this.addChild(P);
         P.x = stage.stageWidth - 70;
         P.y = stage.stageHeight - 270;
         P.callBack = onTag;
         P.name = "p";
         world.addUpdateList(this);
         isTouch = true;
         var L:CommonButton = new CommonButton("l_key.png","hpmp"); //添加虚拟按键L
         this.addChild(L); //
         L.x = stage.stageWidth - 55; //
         L.y = stage.stageHeight - 75; //
         L.callBack = onTag; //
         L.name = "l"; //
      }
      
      override public function onFrame() : void
      {
         if(_touchTime > 0)
         {
            _touchTime--;
         }
         if (_delayTriggerKey != null) //
         { //
            _delayTriggerCount++; //
            if (_delayTriggerCount >= MAX_DELAY_FRAMES) // 缓冲结束：玩家没有滑动，视为普通点击处理按下
            { //
               realOnTag(_delayTriggerKey, true); //
               _delayTriggerKey = null; //
               _delayTriggerCount = 0; //
            } //
         } //
      }
      
      // public function onTag(target:String) : void
         public function onTag(target:String, isDown:Boolean = true) : void //
      {
         if (isDown) // 所有按键按下时先放入缓冲区，等待 onFrame 或 onTouchMove 判定
         { //
            _delayTriggerKey = target; //
            _delayTriggerCount = 0; //
            return; //
         } //
         
         realOnTag(target, false); // 弹起事件不受影响，直接由 realOnTag 处理

         // switch(target)
         // {
            // case "j_key.png":
            //    world.onDown(74);
            //    break;
            // case "k_key.png":
            //    world.onDown(75);
            //    break;
            // case "u_key.png":
            //    world.onDown(85);
            //    break;
            // case "i_key.png":
            //    world.onDown(73);
            //    break;
            // case "o_key.png":
            //    world.onDown(79);
            //    break;
            // case "p_key.png":
            //    world.onDown(80);
         // }
      }

      private function realOnTag(target:String, isDown:Boolean) : void //
      { //
         var keyCode:int = 0; //
         switch(target) //
         { //
            case "j_key.png": case "j": keyCode = 74; break; //
            case "k_key.png": case "k": keyCode = 75; break; //
            case "u_key.png": case "u": keyCode = 85; break; //
            case "i_key.png": case "i": keyCode = 73; break; //
            case "o_key.png": case "o": keyCode = 79; break; //
            case "p_key.png": case "p": keyCode = 80; break; //
            case "l_key.png": case "l": keyCode = 76; break; //
         } //

         if(keyCode != 0) //
         { //
            if(isDown) world.onDown(keyCode); //
            else world.onUp(keyCode); //
         } //
      } //
      
      override public function onTouchBegin(touch:Touch) : void
      {
         if(!touch.target)
         {
            return;
         }
         var touchName:String = touch.target.name;
         var _loc3_:* = touchName;
         if("move" === _loc3_)
         {
            _moveKey.x = touch.globalX;
            _moveKey.y = touch.globalY;
            moveKey();
            _moveKey.visible = true;
            if(_touchTime > 1)
            {
               world.onDown(76);
            }
            _touchTime = 12;
         }
         else //
         { //
            _touchStartY = touch.globalY; //
            _slideType = 0; // 重置滑动状态
         } //
      }
      
      override public function onTouchMove(touch:Touch) : void
      {
         if(!touch.target)
         {
            return;
         }
         var touchName:String = touch.target.name;
         var _loc3_:* = touchName;
         if("move" === _loc3_)
         {
            _moveKey.x = touch.globalX;
            _moveKey.y = touch.globalY;
            moveKey();
            _moveKey.visible = true;
         }
         else if(touchName == "u" || touchName == "i" || touchName == "o" || touchName == "p" || touchName == "j" || touchName == "k" || touchName == "l") //
         { //
            var diffY:Number = touch.globalY - _touchStartY; //
            if(Math.abs(diffY) > 30) //
            { //
               if(diffY < 0) //
               { //
                  _slideType = 1; // 标记为上滑，暂不触发 world.onDown
               } //
               else //
               { //
                  _slideType = 2; // 标记为下滑，暂不触发 world.onDown
               } //
               if (_delayTriggerKey != null) //
               { //
                  var dirCode:int = (_slideType == 1) ? 87 : 83; // W 或 S
                  world.onDown(dirCode); // 先按方向
                  realOnTag(_delayTriggerKey, true); // 再按功能键
                  _delayTriggerKey = null; // 清除延迟，防止 onFrame 重复发送
               } //
            } //
            else // 回到中心范围
            { //
               _slideType = 0; //
            } //
         } //
      }
      
      override public function onTouchEnd(touch:Touch) : void
      {
         if(!touch.target)
         {
            return;
         }
         var touchName:String = touch.target.name;
         
         if (_delayTriggerKey != null) // 如果玩家点击速度极快，在 MAX_DELAY_FRAMES 到达前就松手了，这里需要立即触发
         { //
            realOnTag(_delayTriggerKey, true); // 补发按下
            realOnTag(_delayTriggerKey, false); // 补发抬起
            _delayTriggerKey = null; // 清除延迟，防止 onFrame 重复发送
            _delayTriggerCount = 0; // 重置延迟计数
         } //

         if(_slideType != 0) //
         { //
            world.onUp(87); // 释放可能按住的 W
            world.onUp(83); // 释放可能按住的 S
            _slideType = 0; // 重置滑动状态
         } //

         switch(touchName)
         {
            case "move":
               _moveKey.visible = false;
               world.onUp(68);
               world.onUp(87);
               world.onUp(83);
               world.onUp(65);
               world.onUp(76);
               break;
            case "j":
               world.onUp(74);
               break;
            case "k":
               world.onUp(75);
               break;
            case "u":
               world.onUp(85);
               break;
            case "i":
               world.onUp(73);
               break;
            case "o":
               world.onUp(79);
               break;
            case "p":
               world.onUp(80);
               break; //
            case "l": //
               world.onUp(76); //
         }
      }
      
      public function moveKey() : void
      {
         var c:Number = NaN;
         var s:Number = NaN;
         var r:Number = Math.atan2(_moveKey.y - _moveBottom.y,_moveKey.x - _moveBottom.x);
         _moveKey.rotation = r;
         var point1:Point = new Point(_moveKey.x,_moveKey.y);
         var point2:Point = new Point(_moveBottom.x,_moveBottom.y);
         var len:Number = Point.distance(point1,point2);
         if(len > _moveBottom.width * 0.3)
         {
            c = Math.cos(r);
            s = Math.sin(r);
            _moveKey.x = _moveBottom.x + _moveBottom.width * 0.3 * c;
            _moveKey.y = _moveBottom.y + _moveBottom.width * 0.3 * s;
         }
         r = rad2deg(r);
         if(Math.abs(Math.abs(r) - 90) < 30)
         {
            if(r < 0)
            {
               world.onUp(83);
               world.onDown(87);
            }
            else
            {
               world.onUp(87);
               world.onDown(83);
            }
         }
         else if(_moveKey.x > 150)
         {
            world.onUp(83);
            world.onUp(87);
            world.onUp(65);
            world.onDown(68);
         }
         else
         {
            world.onUp(83);
            world.onUp(87);
            world.onUp(68);
            world.onDown(65);
         }
      }
   }
}

