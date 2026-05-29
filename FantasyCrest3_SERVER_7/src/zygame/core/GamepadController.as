// 添加GamepadController用于支持手柄
package zygame.core
{
   import flash.display.Stage;
   import flash.events.Event;
   import flash.ui.GameInput;
   import flash.ui.GameInputControl;
   import flash.ui.GameInputDevice;
   import flash.events.GameInputEvent;
   import zygame.core.SceneCore;
   import game.view.GameTipsView;
   
   /**
    * 手柄输入控制器，将GameInput手柄按键/摇杆映射为键盘keyCode，
    * 通过KeyCore的onDown/onUp注入游戏输入系统。
    * 
    * 1P模式（默认）：
    *   左摇杆/D-Pad → WASD方向
    *   BUTTON_4  → J (74) 普通攻击
    *   BUTTON_5  → K (75) 跳跃
    *   BUTTON_6  → U (85) 技能U
    *   BUTTON_7  → I (73) 技能I
    *   BUTTON_8  → O (79) 技能O
    *   BUTTON_9  → L (76) 闪避/冲刺
    *   BUTTON_11 → P (80) 技能P
    *   右摇杆下拉 (AXIS_3 < -0.25) → H (72)
    *   BUTTON_13 → 13 (Enter)
    *
    * 2P模式（按住BUTTON_10时）：
    *   左摇杆/D-Pad → 方向键 ↑↓←→
    *   BUTTON_4  → 1 (49)
    *   BUTTON_5  → 2 (50)
    *   BUTTON_9  → 3 (51) L→3
    *   BUTTON_6  → 4 (52) U→4
    *   BUTTON_7  → 5 (53) I→5
    *   BUTTON_8  → 6 (54) O→6
    *   BUTTON_11 → 9 (57)
    *   右摇杆下拉 → 0 (48)
    */
   public class GamepadController
   {
      /** 设为true时每帧打印所有control的实时值，用于手柄按键分配调试 */
      public static var debugMode:Boolean = false;
      
      /** 游戏是否已初始化完成，控制是否允许弹出UI提示 */
      private static var _gameReady:Boolean = false;
      
      /**
       * 游戏初始化完成后调用，之后手柄插拔才会弹出UI提示。
       * 启动时已连接的手柄不会弹提示。
       */
      public static function setGameReady():void
      {
         _gameReady = true;
      }
      
      /** 延迟提示队列：在游戏未就绪时缓存消息，就绪后一次性弹出 */
      private static var _pendingTips:Vector.<String> = new Vector.<String>();
      
      /**
       * 游戏初始化完成后，弹出缓存的提示（如启动时已插着手柄）
       */
      public static function flushPendingTips():void
      {
         _gameReady = true;
         for(var i:int = 0; i < _pendingTips.length; i++)
         {
            showTip(_pendingTips[i]);
         }
         _pendingTips.splice(0, _pendingTips.length);
      }
      
      private static function showTip(msg:String):void
      {
         if(!_gameReady) 
         {
            _pendingTips.push(msg);
            return;
         }
         try
         {
            SceneCore.pushView(new GameTipsView(msg));
         }
         catch(err:Error)
         {
            trace("[GamepadController] 提示显示失败:", err.message);
         }
      }
      
      private static const STICK_DEADZONE:Number = 0.25;
      
      // ===== 1P 键盘映射常量 =====
      private static const KEY_LEFT:int    = 65;  // A
      private static const KEY_RIGHT:int   = 68;  // D
      private static const KEY_UP:int      = 87;  // W
      private static const KEY_DOWN:int    = 83;  // S
      private static const KEY_ATTACK:int  = 74;  // J
      private static const KEY_JUMP:int    = 75;  // K
      private static const KEY_SKILL_U:int = 85;  // U
      private static const KEY_SKILL_I:int = 73;  // I
      private static const KEY_SKILL_O:int = 79;  // O
      private static const KEY_DASH:int    = 76;  // L
      private static const KEY_SKILL_P:int = 80;  // P
      private static const KEY_H:int      = 72;  // H
      
      // ===== 2P 键盘映射常量（按住BUTTON_10时） =====
      private static const KEY2_LEFT:int    = 37;  // ←
      private static const KEY2_RIGHT:int   = 39;  // →
      private static const KEY2_UP:int      = 38;  // ↑
      private static const KEY2_DOWN:int    = 40;  // ↓
      private static const KEY2_ATTACK:int  = 49;  // 1
      private static const KEY2_JUMP:int    = 50;  // 2
      private static const KEY2_DASH:int    = 51;  // 3 (L→3)
      private static const KEY2_SKILL_U:int = 52;  // 4 (U→4)
      private static const KEY2_SKILL_I:int = 53;  // 5 (I→5)
      private static const KEY2_SKILL_O:int = 54;  // 6 (O→6)
      private static const KEY2_SKILL_P:int = 57;  // 9
      private static const KEY2_H:int      = 48;  // 0
      
      // ===== 通用（不区分1P/2P） =====
      private static const KEY_ENTER:int   = 13;  // Enter
      
      private var _keyCore:KeyCore;
      private var _stage:Stage;
      private var _gameInput:GameInput;
      private var _device:GameInputDevice;
      
      // BUTTON_0 ~ BUTTON_19 的边缘检测状态
      private static const MAX_BUTTONS:int = 20;
      private var _prevButtons:Vector.<Boolean>;
      private var _currButtons:Vector.<Boolean>;
      
      // 方向键当前状态（摇杆+D-Pad合并）
      private var _dirLeft:Boolean = false;
      private var _dirRight:Boolean = false;
      private var _dirUp:Boolean = false;
      private var _dirDown:Boolean = false;
      
      // 上一帧方向键状态
      private var _prevDirLeft:Boolean = false;
      private var _prevDirRight:Boolean = false;
      private var _prevDirUp:Boolean = false;
      private var _prevDirDown:Boolean = false;
      
      // 2P模式切换键（BUTTON_10）
      private var _modDown:Boolean = false;
      private var _prevModDown:Boolean = false;
      
      // 右摇杆下拉状态
      private var _rstickDown:Boolean = false;
      private var _prevRstickDown:Boolean = false;
      
      // Control名称到索引的映射表
      private var _controlMap:Object;
      
      public function GamepadController(keyCore:KeyCore, stage:Stage)
      {
         _keyCore = keyCore;
         _stage = stage;
         
         _controlMap = {};
         _prevButtons = new Vector.<Boolean>(MAX_BUTTONS, true);
         _currButtons = new Vector.<Boolean>(MAX_BUTTONS, true);
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            _prevButtons[i] = false;
            _currButtons[i] = false;
         }
         
         try
         {
            _gameInput = new GameInput();
            _gameInput.addEventListener(GameInputEvent.DEVICE_ADDED, onDeviceAdded);
            _gameInput.addEventListener(GameInputEvent.DEVICE_REMOVED, onDeviceRemoved);
            
            for(var d:int = 0; d < GameInput.numDevices; d++)
            {
               var dev:GameInputDevice = GameInput.getDeviceAt(d);
               if(dev)
               {
                  selectDevice(dev);
                  break;
               }
            }
         }
         catch(e:Error)
         {
            trace("[GamepadController] GameInput不可用:", e.message);
         }
      }
      
      private function onDeviceAdded(e:GameInputEvent):void
      {
         trace("[GamepadController] 手柄已连接:", e.device.name);
         showTip("手柄已连接");
         if(!_device)
         {
            selectDevice(e.device);
         }
      }
      
      private function onDeviceRemoved(e:GameInputEvent):void
      {
         trace("[GamepadController] 手柄已断开:", e.device.name);
         showTip("手柄已断开");
         if(_device == e.device)
         {
            releaseAllKeys();
            _device = null;
            _stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            _controlMap = {};
            
            for(var d:int = 0; d < GameInput.numDevices; d++)
            {
               var dev:GameInputDevice = GameInput.getDeviceAt(d);
               if(dev && dev != e.device)
               {
                  selectDevice(dev);
                  break;
               }
            }
         }
      }
      
      private function selectDevice(device:GameInputDevice):void
      {
         _device = device;
         _device.enabled = true;
         
         _controlMap = {};
         for(var c:int = 0; c < _device.numControls; c++)
         {
            var control:GameInputControl = _device.getControlAt(c);
            _controlMap[control.id] = c;
            trace("[GamepadController] Control:", control.id, "index:", c, "min:", control.minValue, "max:", control.maxValue);
         }
         
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            _prevButtons[i] = false;
            _currButtons[i] = false;
         }
         _dirLeft = _dirRight = _dirUp = _dirDown = false;
         _prevDirLeft = _prevDirRight = _prevDirUp = _prevDirDown = false;
         _modDown = false;
         _prevModDown = false;
         _rstickDown = false;
         _prevRstickDown = false;
         
         _stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
         
         trace("[GamepadController] 已选择设备:", device.name, "Controls数量:", device.numControls);
         if(debugMode)
         {
            trace("[GamepadController] === 所有Control列表 ===");
            for(var d:int = 0; d < _device.numControls; d++)
            {
               var ctrl:GameInputControl = _device.getControlAt(d);
               trace("  [" + d + "] id=" + ctrl.id + "  value=" + ctrl.value.toFixed(3) + "  min=" + ctrl.minValue + "  max=" + ctrl.maxValue);
            }
            trace("[GamepadController] =====================");
         }
      }
      
      /**
       * 获取指定control的当前值
       */
      private function getControlValue(controlId:String):Number
      {
         if(!_device) return 0;
         var index:int = _controlMap[controlId] != null ? int(_controlMap[controlId]) : -1;
         if(index == -1) return 0;
         var control:GameInputControl = _device.getControlAt(index);
         if(!control) return 0;
         return control.value;
      }
      
      /**
       * 检测指定button control是否被按下
       */
      private function isButtonPressed(controlId:String):Boolean
      {
         return getControlValue(controlId) > 0.5;
      }
      
      /**
       * 读取指定BUTTON_N的当前状态
       */
      private function readButton(buttonIndex:int):Boolean
      {
         return isButtonPressed("BUTTON_" + buttonIndex);
      }
      
      /**
       * 每帧轮询手柄状态
       */
      private function onEnterFrame(e:Event):void
      {
         if(!_device) return;
         
         // 调试模式
         if(debugMode)
         {
            var debugStr:String = "[Gamepad] ";
            for(var di:int = 0; di < _device.numControls; di++)
            {
               var dc:GameInputControl = _device.getControlAt(di);
               var dv:Number = dc.value;
               if(Math.abs(dv) > 0.01)
               {
                  debugStr += dc.id + "=" + dv.toFixed(2) + "  ";
               }
            }
            if(debugStr != "[Gamepad] ")
            {
               trace(debugStr);
            }
         }
         
         // 读取2P切换键状态
         _modDown = readButton(10);
         
         // 读取摇杆+D-Pad方向
         readAxes();
         
         // 读取所有按钮
         readButtons();
         
         // 发送方向键事件
         sendDirectionEvents();
         
         // 发送按钮事件
         sendButtonEvents();
         
         // 右摇杆下拉 → H(1P) / 0(2P)
         _rstickDown = getControlValue("AXIS_3") < -STICK_DEADZONE;
         sendRightStickEvent();
         
         // BUTTON_13 → Enter（不受modifier影响）
         checkButtonSingle(13, KEY_ENTER);
         
         // 保存当前状态为上一帧
         savePrevState();
      }
      
      /**
       * 读取摇杆轴 + D-Pad，合并方向状态
       * AXIS_0: 负值=左, 正值=右
       * AXIS_1: 正值=上(W), 负值=下(S)（用户自定义方向）
       */
      private function readAxes():void
      {
         var leftX:Number = getControlValue("AXIS_0");
         var leftY:Number = getControlValue("AXIS_1");
         
         var dpadUp:Boolean    = readButton(16);
         var dpadDown:Boolean  = readButton(17);
         var dpadLeft:Boolean  = readButton(18);
         var dpadRight:Boolean = readButton(19);
         
         _dirLeft  = (leftX < -STICK_DEADZONE) || dpadLeft;
         _dirRight = (leftX > STICK_DEADZONE) || dpadRight;
         _dirUp    = (leftY > STICK_DEADZONE) || dpadUp;
         _dirDown  = (leftY < -STICK_DEADZONE) || dpadDown;
      }
      
      /**
       * 读取所有按钮当前状态
       */
      private function readButtons():void
      {
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            _currButtons[i] = readButton(i);
         }
      }
      
      /**
       * 发送方向键事件，支持1P/2P模式切换
       */
      private function sendDirectionEvents():void
      {
         // 根据modifier选择keycode
         var kLeft:int  = _modDown ? KEY2_LEFT  : KEY_LEFT;
         var kRight:int = _modDown ? KEY2_RIGHT : KEY_RIGHT;
         var kUp:int    = _modDown ? KEY2_UP    : KEY_UP;
         var kDown:int  = _modDown ? KEY2_DOWN  : KEY_DOWN;
         
         // modifier状态发生变化：释放旧keycode，按下新keycode
         if(_modDown != _prevModDown)
         {
            var oldLeft:int  = _modDown ? KEY_LEFT  : KEY2_LEFT;
            var oldRight:int = _modDown ? KEY_RIGHT : KEY2_RIGHT;
            var oldUp:int    = _modDown ? KEY_UP    : KEY2_UP;
            var oldDown:int  = _modDown ? KEY_DOWN  : KEY2_DOWN;
            
            // 释放旧方向键
            if(_prevDirLeft)  _keyCore.onUp(oldLeft);
            if(_prevDirRight) _keyCore.onUp(oldRight);
            if(_prevDirUp)    _keyCore.onUp(oldUp);
            if(_prevDirDown)  _keyCore.onUp(oldDown);
            
            // 按下新方向键（如果当前正在按）
            if(_dirLeft)  _keyCore.onDown(kLeft);
            if(_dirRight) _keyCore.onDown(kRight);
            if(_dirUp)    _keyCore.onDown(kUp);
            if(_dirDown)  _keyCore.onDown(kDown);
         }
         else
         {
            // 正常边缘检测
            if(_dirLeft && !_prevDirLeft)
               _keyCore.onDown(kLeft);
            else if(!_dirLeft && _prevDirLeft)
               _keyCore.onUp(kLeft);
            
            if(_dirRight && !_prevDirRight)
               _keyCore.onDown(kRight);
            else if(!_dirRight && _prevDirRight)
               _keyCore.onUp(kRight);
            
            if(_dirUp && !_prevDirUp)
               _keyCore.onDown(kUp);
            else if(!_dirUp && _prevDirUp)
               _keyCore.onUp(kUp);
            
            if(_dirDown && !_prevDirDown)
               _keyCore.onDown(kDown);
            else if(!_dirDown && _prevDirDown)
               _keyCore.onUp(kDown);
         }
      }
      
      /**
       * 发送右摇杆下拉事件，支持1P/2P模式切换
       */
      private function sendRightStickEvent():void
      {
         var activeKey:int = _modDown ? KEY2_H : KEY_H;
         
         if(_modDown != _prevModDown)
         {
            var oldKey:int = _modDown ? KEY_H : KEY2_H;
            if(_prevRstickDown)
            {
               _keyCore.onUp(oldKey);
               _keyCore.onDown(activeKey);
            }
         }
         else
         {
            if(_rstickDown && !_prevRstickDown)
               _keyCore.onDown(activeKey);
            else if(!_rstickDown && _prevRstickDown)
               _keyCore.onUp(activeKey);
         }
      }
      
      /**
       * 发送按钮事件，支持1P/2P模式切换
       * 1P: BUTTON_4→J, BUTTON_5→K, BUTTON_6→U, BUTTON_7→I, BUTTON_8→O, BUTTON_9→L, BUTTON_11→P
       * 2P: BUTTON_4→1, BUTTON_5→2, BUTTON_9→3, BUTTON_6→4, BUTTON_7→5, BUTTON_8→6, BUTTON_11→9
       */
      private function sendButtonEvents():void
      {
         // 每个按钮对应的1P和2P keycode
         checkButtonDual(4,  KEY_ATTACK,  KEY2_ATTACK);
         checkButtonDual(5,  KEY_JUMP,    KEY2_JUMP);
         checkButtonDual(9,  KEY_DASH,    KEY2_DASH);    // L→3
         checkButtonDual(6,  KEY_SKILL_U, KEY2_SKILL_U); // U→4
         checkButtonDual(7,  KEY_SKILL_I, KEY2_SKILL_I); // I→5
         checkButtonDual(8,  KEY_SKILL_O, KEY2_SKILL_O); // O→6
         checkButtonDual(11, KEY_SKILL_P, KEY2_SKILL_P);
      }
      
      /**
       * 检测单个按钮的边缘变化，根据modifier选择1P或2P keycode
       */
      private function checkButtonDual(buttonIndex:int, key1P:int, key2P:int):void
      {
         var activeKey:int = _modDown ? key2P : key1P;
         
         if(_modDown != _prevModDown)
         {
            var oldKey:int = _modDown ? key1P : key2P;
            // modifier切换：释放旧keycode，按下新keycode
            if(_prevButtons[buttonIndex])
            {
               _keyCore.onUp(oldKey);
               _keyCore.onDown(activeKey);
            }
         }
         else
         {
            // 正常边缘检测
            if(_currButtons[buttonIndex] && !_prevButtons[buttonIndex])
               _keyCore.onDown(activeKey);
            else if(!_currButtons[buttonIndex] && _prevButtons[buttonIndex])
               _keyCore.onUp(activeKey);
         }
      }
      
      /**
       * 检测单个按钮的边缘变化（不受modifier影响）
       */
      private function checkButtonSingle(buttonIndex:int, keyCode:int):void
      {
         if(_currButtons[buttonIndex] && !_prevButtons[buttonIndex])
            _keyCore.onDown(keyCode);
         else if(!_currButtons[buttonIndex] && _prevButtons[buttonIndex])
            _keyCore.onUp(keyCode);
      }
      
      /**
       * 保存当前状态为上一帧
       */
      private function savePrevState():void
      {
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            _prevButtons[i] = _currButtons[i];
         }
         _prevDirLeft = _dirLeft;
         _prevDirRight = _dirRight;
         _prevDirUp = _dirUp;
         _prevDirDown = _dirDown;
         _prevModDown = _modDown;
         _prevRstickDown = _rstickDown;
      }
      
      /**
       * 释放所有按下的键（手柄断开时调用）
       */
      private function releaseAllKeys():void
      {
         // 释放1P方向键
         if(_dirLeft)  { _keyCore.onUp(KEY_LEFT); _keyCore.onUp(KEY2_LEFT); }
         if(_dirRight) { _keyCore.onUp(KEY_RIGHT); _keyCore.onUp(KEY2_RIGHT); }
         if(_dirUp)    { _keyCore.onUp(KEY_UP); _keyCore.onUp(KEY2_UP); }
         if(_dirDown)  { _keyCore.onUp(KEY_DOWN); _keyCore.onUp(KEY2_DOWN); }
         
         // 释放所有按钮（同时释放1P和2P keycode以确保干净）
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            if(_currButtons[i])
            {
               switch(i)
               {
                  case 4:  _keyCore.onUp(KEY_ATTACK); _keyCore.onUp(KEY2_ATTACK); break;
                  case 5:  _keyCore.onUp(KEY_JUMP); _keyCore.onUp(KEY2_JUMP); break;
                  case 6:  _keyCore.onUp(KEY_SKILL_U); _keyCore.onUp(KEY2_SKILL_U); break;
                  case 7:  _keyCore.onUp(KEY_SKILL_I); _keyCore.onUp(KEY2_SKILL_I); break;
                  case 8:  _keyCore.onUp(KEY_SKILL_O); _keyCore.onUp(KEY2_SKILL_O); break;
                  case 9:  _keyCore.onUp(KEY_DASH); _keyCore.onUp(KEY2_DASH); break;
                  case 11: _keyCore.onUp(KEY_SKILL_P); _keyCore.onUp(KEY2_SKILL_P); break;
                  case 13: _keyCore.onUp(KEY_ENTER); break;
               }
            }
            _currButtons[i] = false;
            _prevButtons[i] = false;
         }
         _dirLeft = _dirRight = _dirUp = _dirDown = false;
         _prevDirLeft = _prevDirRight = _prevDirUp = _prevDirDown = false;
         _modDown = false;
         _prevModDown = false;
         // 释放右摇杆下拉
         _keyCore.onUp(KEY_H);
         _keyCore.onUp(KEY2_H);
         _rstickDown = false;
         _prevRstickDown = false;
      }
      
      /**
       * 释放资源
       */
      public function dispose():void
      {
         releaseAllKeys();
         if(_stage)
         {
            _stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
         }
         if(_gameInput)
         {
            _gameInput.removeEventListener(GameInputEvent.DEVICE_ADDED, onDeviceAdded);
            _gameInput.removeEventListener(GameInputEvent.DEVICE_REMOVED, onDeviceRemoved);
         }
         _device = null;
         _gameInput = null;
         _keyCore = null;
         _stage = null;
         _controlMap = null;
      }
   }
}