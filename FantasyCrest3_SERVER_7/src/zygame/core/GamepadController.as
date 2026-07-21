// 添加GamepadController用于支持手柄
package zygame.core
{
   import flash.display.Stage;
   import flash.events.Event;
   import flash.ui.GameInput;
   import flash.ui.GameInputControl;
   import flash.ui.GameInputDevice;
   import flash.events.GameInputEvent;
   import flash.net.SharedObject; //
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
      /** 全局单例引用 */
      public static var instance:GamepadController; //

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
      
      // ===== 原静态常量（已注释，替换为可配置静态变量） ===== //
      // private static const STICK_DEADZONE:Number = 0.25; //
      private static var STICK_DEADZONE:Number = 0.25; //
      
      // ===== 1P 摇杆方向映射 ===== //
      // private static const KEY_LEFT:int    = 65;  // A //
      // private static const KEY_RIGHT:int   = 68;  // D //
      // private static const KEY_UP:int      = 87;  // W //
      // private static const KEY_DOWN:int    = 83;  // S //
      private static var KEY_LEFT:int    = 65;  // A //
      private static var KEY_RIGHT:int   = 68;  // D //
      private static var KEY_UP:int      = 87;  // W //
      private static var KEY_DOWN:int    = 83;  // S //
      
      // ===== D-Pad十字键方向映射（默认与摇杆一致，2P由EX切换） ===== //
      private static var KEY_DPAD_UP:int    = 87;  // W //
      private static var KEY_DPAD_DOWN:int  = 83;  // S //
      private static var KEY_DPAD_LEFT:int  = 65;  // A //
      private static var KEY_DPAD_RIGHT:int = 68;  // D //
      
      // ===== 动作按钮映射 ===== //
      // private static const KEY_ATTACK:int  = 74;  // J //
      // private static const KEY_JUMP:int    = 75;  // K //
      // private static const KEY_SKILL_U:int = 85;  // U //
      // private static const KEY_SKILL_I:int = 73;  // I //
      // private static const KEY_SKILL_O:int = 79;  // O //
      // private static const KEY_DASH:int    = 76;  // L //
      // private static const KEY_SKILL_P:int = 80;  // P //
      // private static const KEY_H:int      = 72;  // H //
      private static var KEY_ATTACK:int  = 74;  // J //
      private static var KEY_JUMP:int    = 75;  // K //
      private static var KEY_SKILL_U:int = 85;  // U //
      private static var KEY_SKILL_I:int = 73;  // I //
      private static var KEY_SKILL_O:int = 79;  // O //
      private static var KEY_DASH:int    = 76;  // L //
      private static var KEY_SKILL_P:int = 80;  // P //
      private static var KEY_H:int      = 72;  // H //
      
      // ===== 2P 键盘映射（固定不可配置） ===== //
      // private static const KEY2_LEFT:int    = 37;  // ← //
      // private static const KEY2_RIGHT:int   = 39;  // → //
      // private static const KEY2_UP:int      = 38;  // ↑ //
      // private static const KEY2_DOWN:int    = 40;  // ↓ //
      private static var KEY2_LEFT:int    = 37;  // ← //
      private static var KEY2_RIGHT:int   = 39;  // → //
      private static var KEY2_UP:int      = 38;  // ↑ //
      private static var KEY2_DOWN:int    = 40;  // ↓ //
      // private static const KEY2_ATTACK:int  = 49;  // 1 //
      // private static const KEY2_JUMP:int    = 50;  // 2 //
      // private static const KEY2_DASH:int    = 51;  // 3 (L→3) //
      // private static const KEY2_SKILL_U:int = 52;  // 4 (U→4) //
      // private static const KEY2_SKILL_I:int = 53;  // 5 (I→5) //
      // private static const KEY2_SKILL_O:int = 54;  // 6 (O→6) //
      // private static const KEY2_SKILL_P:int = 57;  // 9 //
      // private static const KEY2_H:int      = 48;  // 0 //
      private static var KEY2_ATTACK:int  = 49;  // 1 //
      private static var KEY2_JUMP:int    = 50;  // 2 //
      private static var KEY2_DASH:int    = 51;  // 3 (L→3) //
      private static var KEY2_SKILL_U:int = 52;  // 4 (U→4) //
      private static var KEY2_SKILL_I:int = 53;  // 5 (I→5) //
      private static var KEY2_SKILL_O:int = 54;  // 6 (O→6) //
      private static var KEY2_SKILL_P:int = 57;  // 9 //
      private static var KEY2_H:int      = 48;  // 0 //
      
      // ===== 通用 ===== //
      // private static const KEY_ENTER:int   = 13;  // Enter //
      private static var KEY_ENTER:int   = 13;  // Enter //

      // ===== 练习模式按键映射 ===== //
      private static var KEY_PRACTICE_HP:int = 90;  // Z //
      private static var KEY_PRACTICE_MP:int = 88;  // X //
      private static var KEY_PRACTICE_CD:int = 67;  // C //
      private static var KEY_PRACTICE_AI:int = 86; // V //
      
      private var _keyCore:KeyCore;
      private var _stage:Stage;
      private var _gameInput:GameInput;
      private var _device:GameInputDevice;
      
      // BUTTON_0 ~ BUTTON_19 的边缘检测状态
      private static const MAX_BUTTONS:int = 20;
      private var _prevButtons:Vector.<Boolean>;
      private var _currButtons:Vector.<Boolean>;
      
      // ===== 原方向状态（已注释，替换为分离的摇杆/D-Pad状态） ===== //
      // 方向键当前状态（摇杆+D-Pad合并）
      // private var _dirLeft:Boolean = false; //
      // private var _dirRight:Boolean = false; //
      // private var _dirUp:Boolean = false; //
      // private var _dirDown:Boolean = false; //
      // 上一帧方向键状态
      // private var _prevDirLeft:Boolean = false; //
      // private var _prevDirRight:Boolean = false; //
      // private var _prevDirUp:Boolean = false; //
      // private var _prevDirDown:Boolean = false; //
      // 2P模式切换键（BUTTON_10）
      // private var _modDown:Boolean = false; //
      // private var _prevModDown:Boolean = false; //

      // 摇杆方向当前状态
      private var _stickLeft:Boolean = false; //
      private var _stickRight:Boolean = false; //
      private var _stickUp:Boolean = false; //
      private var _stickDown:Boolean = false; //
      // 摇杆方向上一帧状态
      private var _prevStickLeft:Boolean = false; //
      private var _prevStickRight:Boolean = false; //
      private var _prevStickUp:Boolean = false; //
      private var _prevStickDown:Boolean = false; //
      // D-Pad方向当前状态
      private var _dpadLeft:Boolean = false; //
      private var _dpadRight:Boolean = false; //
      private var _dpadUp:Boolean = false; //
      private var _dpadDown:Boolean = false; //
      // D-Pad方向上一帧状态
      private var _prevDpadLeft:Boolean = false; //
      private var _prevDpadRight:Boolean = false; //
      private var _prevDpadUp:Boolean = false; //
      private var _prevDpadDown:Boolean = false; //

      // EX切换2P模式（BUTTON_10 改为切换模式）
      private var _exToggle:Boolean = false; //
      private var _prevExButton:Boolean = false; //
      
      // 右摇杆下拉状态
      private var _rstickDown:Boolean = false;
      private var _prevRstickDown:Boolean = false;
      
      // Control名称到索引的映射表
      private var _controlMap:Object;

      // 可配置输入映射：functionId → 控件ID（如 "J"→"BUTTON_4"）
      private static var _inputMapping:Object = {}; //

      // 控件上一帧激活状态（用于数据驱动的边缘检测）
      private var _prevControlActive:Object = {}; //

      // 手柄输入捕获相关
      private static var _isCapturing:Boolean = false; //
      private static var _prevControlValues:Object = {}; //
      private static var _capturedInput:String = ""; //
      private static var _captureCallback:Function = null; //
      
      public function GamepadController(keyCore:KeyCore, stage:Stage)
      {
         _keyCore = keyCore;
         _stage = stage;
         instance = this; //
         loadMapping(); // 从存档加载手柄映射

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
         loadMapping(); // 连接手柄时重新加载映射配置
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
         // _dirLeft = _dirRight = _dirUp = _dirDown = false; //
         // _prevDirLeft = _prevDirRight = _prevDirUp = _prevDirDown = false; //
         // _modDown = false; //
         // _prevModDown = false; //
         // _stickLeft = _stickRight = _stickUp = _stickDown = false; //
         // _prevStickLeft = _prevStickRight = _prevStickUp = _prevStickDown = false; //
         // _dpadLeft = _dpadRight = _dpadUp = _dpadDown = false; //
         // _prevDpadLeft = _prevDpadRight = _prevDpadUp = _prevDpadDown = false; //
         _exToggle = false; //
         _prevExButton = false; //
         // _rstickDown = false; //
         // _prevRstickDown = false; //
         _prevControlActive = {}; //
         
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
         
         // EX切换2P模式（BUTTON_10 改为按下切换）
         var exDown:Boolean = readButton(10); //
         if(exDown && !_prevExButton) //
         { //
            _exToggle = !_exToggle; //
            if(_exToggle) //
            { //
               showTip("2P转换开启"); //
            } //
            else //
            { //
               showTip("2P转换关闭"); //
            } //
            // 切换模式时释放所有按键
            releaseAllDirectionKeys(); //
         } //
         _prevExButton = exDown; //

         // 读取摇杆轴和D-Pad（方向检测已由checkDirectionInput数据驱动）
         // readStickAxes(); //
         // readDpadButtons(); //
         
         // 读取所有按钮
         readButtons();
         
         // 发送方向键事件
         sendDirectionEvents();
         
         // 发送按钮事件
         sendButtonEvents();
         
         // 换人（数据驱动）
         // _rstickDown = getControlValue("AXIS_3") < -STICK_DEADZONE; //
         sendRightStickEvent();
         
         // 暂停（使用可配置映射）
         // checkButtonSingle(13, KEY_ENTER); //
         checkConfiguredButton("Enter", KEY_ENTER, KEY_ENTER); //
         
         // 练习模式按钮
         sendPracticeButtonEvents(); //

         // 捕获模式：检测控件变化
         checkCapture(); //

         // 保存当前状态为上一帧
         savePrevState();
      }
      
      /**
       * 读取摇杆轴方向
       * AXIS_0: 负值=左, 正值=右
       * AXIS_1: 正值=上(W), 负值=下(S)（用户自定义方向）
       */
      private function readStickAxes():void //
      { //
         var leftX:Number = getControlValue("AXIS_0"); //
         var leftY:Number = getControlValue("AXIS_1"); //
         _stickLeft  = (leftX < -STICK_DEADZONE); //
         _stickRight = (leftX > STICK_DEADZONE); //
         _stickUp    = (leftY > STICK_DEADZONE); //
         _stickDown  = (leftY < -STICK_DEADZONE); //
      } //

      /**
       * 读取D-Pad方向按钮
       */
      private function readDpadButtons():void //
      { //
         _dpadLeft  = readButton(18); //
         _dpadRight = readButton(19); //
         _dpadUp    = readButton(16); //
         _dpadDown  = readButton(17); //
      } //

      // 原readAxes（已注释，被readStickAxes和readDpadButtons替代） //
      // --------------------------------------------------------- //
      // private function readAxes():void //
      // { //
      //    var leftX:Number = getControlValue("AXIS_0"); //
      //    var leftY:Number = getControlValue("AXIS_1"); //
      //    var dpadUp:Boolean    = readButton(16); //
      //    var dpadDown:Boolean  = readButton(17); //
      //    var dpadLeft:Boolean  = readButton(18); //
      //    var dpadRight:Boolean = readButton(19); //
      //    _dirLeft  = (leftX < -STICK_DEADZONE) || dpadLeft; //
      //    _dirRight = (leftX > STICK_DEADZONE) || dpadRight; //
      //    _dirUp    = (leftY > STICK_DEADZONE) || dpadUp; //
      //    _dirDown  = (leftY < -STICK_DEADZONE) || dpadDown; //
      // } //
      
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
       * 发送方向键事件，数据驱动
       */
      private function sendDirectionEvents():void
      {
         // _stickLeft/Right/Up/Down 和 _dpadLeft/... 状态已废弃，改用 checkDirectionInput //
         // 摇杆方向（W1/A1/S1/D1）
         checkDirectionInput("W1", KEY_UP, KEY2_UP); //
         checkDirectionInput("A1", KEY_LEFT, KEY2_LEFT); //
         checkDirectionInput("S1", KEY_DOWN, KEY2_DOWN); //
         checkDirectionInput("D1", KEY_RIGHT, KEY2_RIGHT); //
         // 十字键方向（W2/A2/S2/D2）
         checkDirectionInput("W2", KEY_DPAD_UP, KEY2_UP); //
         checkDirectionInput("A2", KEY_DPAD_LEFT, KEY2_LEFT); //
         checkDirectionInput("S2", KEY_DPAD_DOWN, KEY2_DOWN); //
         checkDirectionInput("D2", KEY_DPAD_RIGHT, KEY2_RIGHT); //
      }

      // 原sendDirectionEvents（已注释） //
      // --------------------------------------------------------- //
      // private function sendDirectionEvents():void //
      // { //
      //    var kLeft:int  = _modDown ? KEY2_LEFT  : KEY_LEFT; //
      //    var kRight:int = _modDown ? KEY2_RIGHT : KEY_RIGHT; //
      //    var kUp:int    = _modDown ? KEY2_UP    : KEY_UP; //
      //    var kDown:int  = _modDown ? KEY2_DOWN  : KEY_DOWN; //
      //    if(_modDown != _prevModDown) //
      //    { //
      //       var oldLeft:int  = _modDown ? KEY_LEFT  : KEY2_LEFT; //
      //       var oldRight:int = _modDown ? KEY_RIGHT : KEY2_RIGHT; //
      //       var oldUp:int    = _modDown ? KEY_UP    : KEY2_UP; //
      //       var oldDown:int  = _modDown ? KEY_DOWN  : KEY2_DOWN; //
      //       if(_prevDirLeft)  _keyCore.onUp(oldLeft); //
      //       if(_prevDirRight) _keyCore.onUp(oldRight); //
      //       if(_prevDirUp)    _keyCore.onUp(oldUp); //
      //       if(_prevDirDown)  _keyCore.onUp(oldDown); //
      //       if(_dirLeft)  _keyCore.onDown(kLeft); //
      //       if(_dirRight) _keyCore.onDown(kRight); //
      //       if(_dirUp)    _keyCore.onDown(kUp); //
      //       if(_dirDown)  _keyCore.onDown(kDown); //
      //    } //
      //    else //
      //    { //
      //       if(_dirLeft && !_prevDirLeft) //
      //          _keyCore.onDown(kLeft); //
      //       else if(!_dirLeft && _prevDirLeft) //
      //          _keyCore.onUp(kLeft); //
      //       if(_dirRight && !_prevDirRight) //
      //          _keyCore.onDown(kRight); //
      //       else if(!_dirRight && _prevDirRight) //
      //          _keyCore.onUp(kRight); //
      //       if(_dirUp && !_prevDirUp) //
      //          _keyCore.onDown(kUp); //
      //       else if(!_dirUp && _prevDirUp) //
      //          _keyCore.onUp(kUp); //
      //       if(_dirDown && !_prevDirDown) //
      //          _keyCore.onDown(kDown); //
      //       else if(!_dirDown && _prevDirDown) //
      //          _keyCore.onUp(kDown); //
      //    } //
      // } //
      
      /**
       * 发送换人事件，数据驱动
       */
      private function sendRightStickEvent():void
      {
         checkDirectionInput("H", KEY_H, KEY2_H); //
      }

      // 原sendRightStickEvent（已注释） //
      // --------------------------------------------------------- //
      // private function sendRightStickEvent():void //
      // { //
      //    var activeKey:int = _modDown ? KEY2_H : KEY_H; //
      //    if(_modDown != _prevModDown) //
      //    { //
      //       var oldKey:int = _modDown ? KEY_H : KEY2_H; //
      //       if(_prevRstickDown) //
      //       { //
      //          _keyCore.onUp(oldKey); //
      //          _keyCore.onDown(activeKey); //
      //       } //
      //    } //
      //    else //
      //    { //
      //       if(_rstickDown && !_prevRstickDown) //
      //          _keyCore.onDown(activeKey); //
      //       else if(!_rstickDown && _prevRstickDown) //
      //          _keyCore.onUp(activeKey); //
      //    } //
      // } //
      
      /**
       * 发送按钮事件，使用可配置映射
       */
      private function sendButtonEvents():void
      {
         // 原硬编码映射（已注释，改用_inputMapping数据驱动）
         // checkButtonDual(4,  KEY_ATTACK,  KEY2_ATTACK);
         // checkButtonDual(5,  KEY_JUMP,    KEY2_JUMP);
         // checkButtonDual(9,  KEY_DASH,    KEY2_DASH);
         // checkButtonDual(6,  KEY_SKILL_U, KEY2_SKILL_U);
         // checkButtonDual(7,  KEY_SKILL_I, KEY2_SKILL_I);
         // checkButtonDual(8,  KEY_SKILL_O, KEY2_SKILL_O);
         // checkButtonDual(11, KEY_SKILL_P, KEY2_SKILL_P);
         checkConfiguredButton("J",  KEY_ATTACK,  KEY2_ATTACK); //
         checkConfiguredButton("K",  KEY_JUMP,    KEY2_JUMP); //
         checkConfiguredButton("L",  KEY_DASH,    KEY2_DASH); //
         checkConfiguredButton("U",  KEY_SKILL_U, KEY2_SKILL_U); //
         checkConfiguredButton("I",  KEY_SKILL_I, KEY2_SKILL_I); //
         checkConfiguredButton("O",  KEY_SKILL_O, KEY2_SKILL_O); //
         checkConfiguredButton("P",  KEY_SKILL_P, KEY2_SKILL_P); //
      }
      
      /**
       * 检测单个按钮的边缘变化，根据EX切换选择1P或2P keycode
       */
      private function checkButtonDual(buttonIndex:int, key1P:int, key2P:int):void
      {
         var activeKey:int = _exToggle ? key2P : key1P; //

         // 正常边缘检测（EX为切换模式，无需处理切换时的释放逻辑）
         if(_currButtons[buttonIndex] && !_prevButtons[buttonIndex]) //
            _keyCore.onDown(activeKey); //
         else if(!_currButtons[buttonIndex] && _prevButtons[buttonIndex]) //
            _keyCore.onUp(activeKey); //
      }

      // 原checkButtonDual（已注释） //
      // --------------------------------------------------------- //
      // private function checkButtonDual(buttonIndex:int, key1P:int, key2P:int):void //
      // { //
      //    var activeKey:int = _modDown ? key2P : key1P; //
      //    if(_modDown != _prevModDown) //
      //    { //
      //       var oldKey:int = _modDown ? key1P : key2P; //
      //       if(_prevButtons[buttonIndex]) //
      //       { //
      //          _keyCore.onUp(oldKey); //
      //          _keyCore.onDown(activeKey); //
      //       } //
      //    } //
      //    else //
      //    { //
      //       if(_currButtons[buttonIndex] && !_prevButtons[buttonIndex]) //
      //          _keyCore.onDown(activeKey); //
      //       else if(!_currButtons[buttonIndex] && _prevButtons[buttonIndex]) //
      //          _keyCore.onUp(activeKey); //
      //    } //
      // } //
      
      /**
       * 判断指定控件当前是否处于激活状态
       */
      private function isControlActive(controlId:String):Boolean //
      { //
         if(!controlId || controlId.length == 0) return false; //
         if(controlId.indexOf("BUTTON_") == 0) //
         { //
            var idx:int = parseInt(controlId.substring(7)); //
            if(idx < 0 || idx >= MAX_BUTTONS) return false; //
            return _currButtons[idx]; //
         } //
         if(controlId.indexOf("AXIS_") == 0) //
         { //
            var lastChar:String = controlId.charAt(controlId.length - 1); //
            var isPositive:Boolean = (lastChar == "+"); //
            var axisId:String = controlId.substring(0, controlId.length - 1); //
            var val:Number = getControlValue(axisId); //
            return isPositive ? (val > STICK_DEADZONE) : (val < -STICK_DEADZONE); //
         } //
         return false; //
      } //

      /**
       * 数据驱动方向检测：根据映射中的控件ID检查激活状态并发送键盘事件
       */
      private function checkDirectionInput(funcId:String, key1P:int, key2P:int):void //
      { //
         var controlId:String = _inputMapping[funcId]; //
         if(!controlId || controlId.length == 0) return; //

         var active:Boolean = isControlActive(controlId); //
         var wasActive:Boolean = _prevControlActive[controlId] == true; //
         var activeKey:int = _exToggle ? key2P : key1P; //

         if(active && !wasActive) //
            _keyCore.onDown(activeKey); //
         else if(!active && wasActive) //
            _keyCore.onUp(activeKey); //

         _prevControlActive[controlId] = active; //
      } //

      /**
       * 从控件ID字符串中提取按钮索引，"BUTTON_4"→4，不是按钮返回-1
       */
      private static function getButtonIndex(controlId:String):int //
      { //
         if(!controlId || controlId.indexOf("BUTTON_") != 0) return -1; //
         return parseInt(controlId.substring(7)); //
      } //

      /**
       * 数据驱动按钮检测：根据映射中的控件ID检查按钮状态
       */
      private function checkConfiguredButton(funcId:String, key1P:int, key2P:int):void //
      { //
         var controlId:String = _inputMapping[funcId]; //
         if(!controlId || controlId.length == 0) return; //
         var btnIdx:int = getButtonIndex(controlId); //
         if(btnIdx < 0 || btnIdx >= MAX_BUTTONS) return; //

         var activeKey:int = _exToggle ? key2P : key1P; //
         if(_currButtons[btnIdx] && !_prevButtons[btnIdx]) //
            _keyCore.onDown(activeKey); //
         else if(!_currButtons[btnIdx] && _prevButtons[btnIdx]) //
            _keyCore.onUp(activeKey); //
      } //

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
       * 捕获模式下检测控件变化，检测到后通过回调通知
       */
      private function checkCapture():void //
      { //
         if(!_isCapturing || !_device) return; //

         for(var c:int = 0; c < _device.numControls; c++) //
         { //
            var control:GameInputControl = _device.getControlAt(c); //
            var id:String = control.id; //
            var prevVal:Number = _prevControlValues[id] !== undefined ? Number(_prevControlValues[id]) : 0; //
            var curVal:Number = control.value; //

            // 检测按钮：从0变到1
            if(id.indexOf("BUTTON_") == 0) //
            { //
               if(prevVal <= 0.5 && curVal > 0.5) //
               { //
                  _isCapturing = false; //
                  if(_captureCallback != null) //
                  { //
                     _captureCallback(id); //
                     _captureCallback = null; //
                  } //
                  return; //
               } //
            } //
            // 检测摇杆：超过死区且上一帧未超过
            else if(id.indexOf("AXIS_") == 0) //
            { //
               if(Math.abs(curVal) > STICK_DEADZONE && Math.abs(prevVal) <= STICK_DEADZONE) //
               { //
                  _isCapturing = false; //
                  if(_captureCallback != null) //
                  { //
                     _captureCallback(id + (curVal > 0 ? "+" : "-")); //
                     _captureCallback = null; //
                  } //
                  return; //
               } //
            } //
         } //

         // 保存当前值供下帧比较
         for(var d:int = 0; d < _device.numControls; d++) //
         { //
            var ctrl:GameInputControl = _device.getControlAt(d); //
            _prevControlValues[ctrl.id] = ctrl.value; //
         } //
      } //

      /**
       * 保存当前状态为上一帧
       */
      private function savePrevState():void
      {
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            _prevButtons[i] = _currButtons[i];
         }
         // _prevStickLeft = _stickLeft; //
         // _prevStickRight = _stickRight; //
         // _prevStickUp = _stickUp; //
         // _prevStickDown = _stickDown; //
         // _prevDpadLeft = _dpadLeft; //
         // _prevDpadRight = _dpadRight; //
         // _prevDpadUp = _dpadUp; //
         // _prevDpadDown = _dpadDown; //
         // _prevRstickDown = _rstickDown; //
         // _prevControlActive 已在 checkDirectionInput 中更新，无需在此处理
      }
      
      /**
       * 根据映射释放指定按钮的所有关联按键
       */
      private function releaseButtonKeys(btnIdx:int):void //
      { //
         // 遍历映射找到使用此按钮的function，释放其1P和2P keycode
         var defMap:Object = getDefaultMapping(); //
         for(var funcId:String in _inputMapping) //
         { //
            var ctrlId:String = _inputMapping[funcId]; //
            if(!ctrlId || ctrlId.length == 0) continue; //
            if(getButtonIndex(ctrlId) == btnIdx) //
            { //
               // 获取该function的默认1P/2P keycode... 
               // 简单方案：释放所有可能对应的keycode
               // 遍历默认映射找到匹配funcId
            } //
         } //
         // 简化：释放该按钮idx对应的所有已知keycode
         switch(btnIdx) //
         { //
            case 4:  _keyCore.onUp(KEY_ATTACK); _keyCore.onUp(KEY2_ATTACK); break; //
            case 5:  _keyCore.onUp(KEY_JUMP); _keyCore.onUp(KEY2_JUMP); break; //
            case 6:  _keyCore.onUp(KEY_SKILL_U); _keyCore.onUp(KEY2_SKILL_U); break; //
            case 7:  _keyCore.onUp(KEY_SKILL_I); _keyCore.onUp(KEY2_SKILL_I); break; //
            case 8:  _keyCore.onUp(KEY_SKILL_O); _keyCore.onUp(KEY2_SKILL_O); break; //
            case 9:  _keyCore.onUp(KEY_DASH); _keyCore.onUp(KEY2_DASH); break; //
            case 11: _keyCore.onUp(KEY_SKILL_P); _keyCore.onUp(KEY2_SKILL_P); break; //
            case 13: _keyCore.onUp(KEY_ENTER); break; //
            case 0:  _keyCore.onUp(KEY_PRACTICE_HP); break; //
            case 1:  _keyCore.onUp(KEY_PRACTICE_MP); break; //
            case 2:  _keyCore.onUp(KEY_PRACTICE_CD); break; //
            case 3:  _keyCore.onUp(KEY_PRACTICE_AI); break; //
            default: break; //
         } //
      } //

      /**
       * 释放所有按下的键（手柄断开时调用）
       */
      private function releaseAllKeys():void
      {
         // 释放所有方向键（数据驱动）
         releaseMappedDirections(); //

         // 释放所有按钮
         for(var i:int = 0; i < MAX_BUTTONS; i++)
         {
            if(_currButtons[i])
            {
               releaseButtonKeys(i); //
            }
            _currButtons[i] = false;
            _prevButtons[i] = false;
         }
         // _stickLeft = ... = false; //
         // _dpadLeft = ... = false; //
         _exToggle = false; //
         _prevExButton = false; //
         _prevControlActive = {}; //
      } //

      /** 释放所有方向映射的按键 */
      private function releaseMappedDirections():void //
      { //
         for(var ctrlId:String in _prevControlActive) //
         { //
            if(_prevControlActive[ctrlId] == true) //
            { //
               // 释放该控件对应的32-keycode
               if(ctrlId == _inputMapping["W1"]) { _keyCore.onUp(KEY_UP); _keyCore.onUp(KEY2_UP); } //
               if(ctrlId == _inputMapping["A1"]) { _keyCore.onUp(KEY_LEFT); _keyCore.onUp(KEY2_LEFT); } //
               if(ctrlId == _inputMapping["S1"]) { _keyCore.onUp(KEY_DOWN); _keyCore.onUp(KEY2_DOWN); } //
               if(ctrlId == _inputMapping["D1"]) { _keyCore.onUp(KEY_RIGHT); _keyCore.onUp(KEY2_RIGHT); } //
               if(ctrlId == _inputMapping["W2"]) { _keyCore.onUp(KEY_DPAD_UP); _keyCore.onUp(KEY2_UP); } //
               if(ctrlId == _inputMapping["A2"]) { _keyCore.onUp(KEY_DPAD_LEFT); _keyCore.onUp(KEY2_LEFT); } //
               if(ctrlId == _inputMapping["S2"]) { _keyCore.onUp(KEY_DPAD_DOWN); _keyCore.onUp(KEY2_DOWN); } //
               if(ctrlId == _inputMapping["D2"]) { _keyCore.onUp(KEY_DPAD_RIGHT); _keyCore.onUp(KEY2_RIGHT); } //
               if(ctrlId == _inputMapping["H"])  { _keyCore.onUp(KEY_H); _keyCore.onUp(KEY2_H); } //
            } //
         } //
         _prevControlActive = {}; //
      } //
      
      /**
       * 释放所有方向键（EX切换时调用）
       */
      private function releaseAllDirectionKeys():void //
      { //
         releaseMappedDirections(); //
         // 释放按钮映射
         for(var i:int = 0; i < MAX_BUTTONS; i++) //
         { //
            if(_currButtons[i]) //
               releaseButtonKeys(i); //
         } //
      } //

      /**
       * 发送练习模式按钮事件（使用可配置映射）
       */
      private function sendPracticeButtonEvents():void //
      { //
         // checkButtonSingle(0, KEY_PRACTICE_HP); //
         // checkButtonSingle(1, KEY_PRACTICE_MP); //
         // checkButtonSingle(2, KEY_PRACTICE_CD); //
         // checkButtonSingle(3, KEY_PRACTICE_AI); //
         checkConfiguredButton("Z", KEY_PRACTICE_HP, KEY_PRACTICE_HP); //
         checkConfiguredButton("X", KEY_PRACTICE_MP, KEY_PRACTICE_MP); //
         checkConfiguredButton("C", KEY_PRACTICE_CD, KEY_PRACTICE_CD); //
         checkConfiguredButton("V", KEY_PRACTICE_AI, KEY_PRACTICE_AI); //
      } //

      /**
       * 从SharedObject加载手柄映射配置
       */
      private static function loadMapping():void //
      { //
         try //
         { //
            var so:SharedObject = SharedObject.getLocal("net.zygame.hxwz.air"); //
            if(so && so.data && so.data.settings && so.data.settings.gameInput) //
            { //
               applyMapping(so.data.settings.gameInput); //
               return; //
            } //
         } //
         catch(err:Error) //
         { //
            trace("[GamepadController] 加载手柄映射失败:", err.message); //
         } //
         // 无存档或异常时使用默认映射
         _inputMapping = getDefaultMapping(); //
      } //

      /**
       * 深拷贝映射对象
       */
      public static function cloneMapping(src:Object):Object //
      { //
         var result:Object = {}; //
         for(var key:String in src) //
            result[key] = src[key]; //
         return result; //
      } //

      /**
       * 获取默认映射配置（手柄输入控件ID格式，如BUTTON_4、AXIS_0+）
       */
      public static function getDefaultMapping():Object //
      { //
         return { //
            "W1":"AXIS_1+", "A1":"AXIS_0-", "S1":"AXIS_1-", "D1":"AXIS_0+", //
            "W2":"BUTTON_16", "A2":"BUTTON_18", "S2":"BUTTON_17", "D2":"BUTTON_19", //
            "J":"BUTTON_4", "K":"BUTTON_5", "L":"BUTTON_9", //
            "U":"BUTTON_6", "I":"BUTTON_7", "O":"BUTTON_8", "P":"BUTTON_11", //
            "H":"AXIS_3-", "Enter":"BUTTON_13", "EX":"BUTTON_10", //
            "Z":"", "X":"", "C":"", "V":"" //
         }; //
      } //

      /**
       * 应用手柄映射配置（手柄输入控件ID格式字符串）
       */
      public static function applyMapping(mapping:Object):void //
      { //
         if(!mapping) return; //

         // 数据兼容：将旧版int格式转换为新版string格式
         var needsConvert:Boolean = false; //
         for(var k:String in mapping) //
         { //
            if(mapping[k] is int || mapping[k] is Number) //
            { //
               needsConvert = true; //
               break; //
            } //
         } //
         if(needsConvert) //
         { //
            trace("[GamepadController] 检测到旧版映射数据，使用默认映射"); //
            _inputMapping = getDefaultMapping(); //
         } //
         else //
         { //
            _inputMapping = cloneMapping(mapping); //
            trace("[GamepadController] 已应用手柄映射: J=" + _inputMapping["J"] + " K=" + _inputMapping["K"]); //
         } //

         // 保存到SharedObject
         try //
         { //
            var so:SharedObject = SharedObject.getLocal("net.zygame.hxwz.air"); //
            if(!so.data.settings) //
               so.data.settings = {}; //
            so.data.settings.gameInput = mapping; //
            so.flush(); //
         } //
         catch(err:Error) //
         { //
            trace("[GamepadController] 保存手柄映射失败:", err.message); //
         } //
      } //

      /** 开始捕获手柄输入，捕获后回调 callback(controlId:String) */
      public static function startCapture(callback:Function):void //
      { //
         _isCapturing = true; //
         _captureCallback = callback; //
         _prevControlValues = {}; //
         _capturedInput = ""; //
         if(instance && instance._device) //
         { //
            for(var c:int = 0; c < instance._device.numControls; c++) //
            { //
               var control:GameInputControl = instance._device.getControlAt(c); //
               _prevControlValues[control.id] = control.value; //
            } //
         } //
      } //

      /** 停止捕获手柄输入 */
      public static function stopCapture():void //
      { //
         _isCapturing = false; //
         _captureCallback = null; //
         _capturedInput = ""; //
      } //

      /** 获取捕获到的手柄输入控件ID（如BUTTON_4、AXIS_0+），没人按下返回空串 */
      public static function getCapturedInput():String //
      { //
         var result:String = _capturedInput; //
         _capturedInput = ""; //
         return result; //
      } //

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