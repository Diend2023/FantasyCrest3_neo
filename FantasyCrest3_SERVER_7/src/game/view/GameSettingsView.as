// 添加设置界面
package game.view
{
   import feathers.controls.Check;
   import feathers.controls.LayoutGroup;
   import feathers.layout.HorizontalLayout;
   import feathers.layout.VerticalLayout;
   import feathers.layout.VerticalAlign;
   import game.uilts.GameFont;
   import starling.display.Button;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.text.TextFormat;
   import starling.textures.Texture;
   import zygame.core.DataCore;
   import zygame.core.GameCore;
   import zygame.core.SceneCore;
   import zygame.display.DisplayObjectContainer;
   import lzm.starling.STLConstant;
   import flash.display.StageDisplayState;
   import flash.net.SharedObject;
   import game.uilts.Phone;
   import starling.core.Starling;
   import flash.geom.Rectangle;
   import game.view.GameInputSettingView; // 手柄设置界面

   public class GameSettingsView extends DisplayObjectContainer
   {
      
      public static var self:GameSettingsView;
      
      private var _fullScreenCheck:Check;
      private var _soundCheck:Check;
      private var _bgmCheck:Check;
      private var _bgraCheck:Check;
      private var _antiAliasingCheck:Check;
      private var _NNICheck:Check;
      private var _closeVibrationCheck:Check;
      private var _recordingCheck:Check;

      private static var _isBGRAEnabled:Boolean = false; // 超真全彩默认关闭
      private static var _isNNIEnabled:Boolean = false; // 硬边缘默认关闭
      private static var _isCloseVibration:Boolean = false; // 抗锯齿默认关闭
      private static var _isRecording:Boolean = false // 开启录制默认关闭

      public function GameSettingsView()
      {
         super();
         self = this;
      }
      
      override public function onInit() : void
      {
         var bg:Quad;
         var skin:Texture;
         var buttonExit:starling.display.Button;
         super.onInit();
         bg = new Quad(stage.stageWidth,stage.stageHeight,0x000000);
         this.addChild(bg);
         bg.alpha = 0.7;

         // 最外层容器（水平两列）
         var mainContainer:LayoutGroup = new LayoutGroup();
         var mainContainerBackground:Quad = new Quad(stage.stageWidth / 1.25, stage.stageHeight / 1.25, 0x000000);
         mainContainerBackground.alpha = 0.7;
         mainContainer.layout = new HorizontalLayout();
         (mainContainer.layout as HorizontalLayout).gap = 30;
         mainContainer.backgroundSkin = mainContainerBackground;
         mainContainer.width = mainContainerBackground.width;
         mainContainer.height = mainContainerBackground.height;
         this.addChild(mainContainer);
         // 将主容器居中
         mainContainer.validate();
         mainContainer.x = (stage.stageWidth - mainContainer.width) / 2;
         mainContainer.y = (stage.stageHeight - mainContainer.height) / 2;
         // 两列子容器（左列：nniItem之前的基础设置；右列：nniItem之后的高级/扩展设置）
         var leftContainer:LayoutGroup = new LayoutGroup();
         leftContainer.layout = new VerticalLayout();
         (leftContainer.layout as VerticalLayout).gap = 20;
         mainContainer.addChild(leftContainer);
         var rightContainer:LayoutGroup = new LayoutGroup();
         rightContainer.layout = new VerticalLayout();
         (rightContainer.layout as VerticalLayout).gap = 20;
         mainContainer.addChild(rightContainer);

         // 开启全屏
         var fullScreenItem:LayoutGroup = createSettingItem("开启全屏（F11）", "toggle", (STLConstant.nativeStage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE), function(value:Boolean):void{
            GameSettingsView.setFullScreen(value);
         });
         _fullScreenCheck = fullScreenItem.getChildAt(1) as Check;
         leftContainer.addChild(fullScreenItem);

         // 关闭声音 (注意：UI勾选代表关闭，所以传入 !value)
         var soundItem:LayoutGroup = createSettingItem("关闭声音（F1）", "toggle", (GameCore.soundCore.volume == 0), function(value:Boolean):void{
            GameSettingsView.setSoundEnable(!value);
         });
         _soundCheck = soundItem.getChildAt(1) as Check;
         leftContainer.addChild(soundItem);

         // 关闭BGM (同理)
         var bgmItem:LayoutGroup = createSettingItem("关闭BGM（F5）", "toggle", (GameCore.soundCore.bgvolume == 0), function(value:Boolean):void{
            GameSettingsView.setBGMEnable(!value);
         });
         _bgmCheck = bgmItem.getChildAt(1) as Check;
         leftContainer.addChild(bgmItem);

         // 关闭震动
         var closeVibrationItem:LayoutGroup = createSettingItem("关闭震动", "toggle", _isCloseVibration, function(value:Boolean):void{
            GameSettingsView.setCloseVibration(value);
         });
         _closeVibrationCheck = closeVibrationItem.getChildAt(1) as Check;
         leftContainer.addChild(closeVibrationItem);

         // 开启录制
         var recordItem:LayoutGroup = createSettingItem("开启录制", "toggle", _isRecording, function(value:Boolean):void{
            GameSettingsView.setRecording(value);
         });
         _recordingCheck = recordItem.getChildAt(1) as Check;
         leftContainer.addChild(recordItem);

         // 开启超真全彩
         var bgraItem:LayoutGroup = createSettingItem("真全彩（实验性）", "toggle", _isBGRAEnabled, function(value:Boolean):void{
            GameSettingsView.setBGRAEnable(value);
         });
         _bgraCheck = bgraItem.getChildAt(1) as Check;
         leftContainer.addChild(bgraItem);

         // 开启抗锯齿
         var aaItem:LayoutGroup = createSettingItem("抗锯齿（实验性）", "toggle", (Starling.current.antiAliasing > 0), function(value:Boolean):void{
            GameSettingsView.setAntiAliasingEnable(value);
         });
         _antiAliasingCheck = aaItem.getChildAt(1) as Check;
         leftContainer.addChild(aaItem);

         // 开启硬边缘
         var nniItem:LayoutGroup = createSettingItem("硬边缘（实验性）", "toggle", _isNNIEnabled, function(value:Boolean):void{
            GameSettingsView.setNNIEnable(value);
         });
         _NNICheck = nniItem.getChildAt(1) as Check;
         leftContainer.addChild(nniItem);

         // 手柄按键映射设置按钮
         var gamepadItem:LayoutGroup = createSettingItem("手柄按键映射", "action", null, function():void{ //
            SceneCore.pushView(new GameInputSettingView()); //
         }); //
         // 修改按钮文字为"打开"
         if(gamepadItem.numChildren >= 2) //
         { //
            var gpBtn:Object = gamepadItem.getChildAt(1); //
            if(gpBtn is starling.display.Button) //
            { //
               (gpBtn as starling.display.Button).text = "打开"; //
            } //
         } //
         rightContainer.addChild(gamepadItem); //

         // 查看录像列表按钮
         var replayItem:LayoutGroup = createSettingItem("查看录像列表", "action", null, function():void{ //
            SceneCore.pushView(new ReplayListView()); //
         }); //
         // 修改按钮文字为"打开"
         if(replayItem.numChildren >= 2) //
         { //
            var rpBtn:Object = replayItem.getChildAt(1); //
            if(rpBtn is starling.display.Button) //
            { //
               (rpBtn as starling.display.Button).text = "打开"; //
            } //
         } //
         rightContainer.addChild(replayItem); //

         skin = DataCore.getTextureAtlas("start_main").getTexture("btn_style_1");
         buttonExit = new starling.display.Button(skin,"完成");
         this.addChild(buttonExit);
         buttonExit.textFormat.size = 18;
         buttonExit.x = stage.stageWidth / 2 - buttonExit.width / 2;
         buttonExit.y = stage.stageHeight - buttonExit.height * 2 - 16;
         buttonExit.addEventListener("triggered",function(e:Event):void
         {
            saveBGMSetting(isBGMEnable()); // 保存当前设置
            saveSoundSetting(isSoundEnable());
            saveFullScreenSetting(isFullScreen());
            saveCloseVibrationSetting(isCloseVibration());
            saveRecordingSetting(isRecording());
            removeFromParent(true);
         });
      }

      // 1. 全屏控制
      public static function setFullScreen(isFull:Boolean):void
      {
         STLConstant.nativeStage.displayState = isFull ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
         saveFullScreenSetting(isFull); // 保存设置到本地
         if(self && self._fullScreenCheck)
         {
            self._fullScreenCheck.isSelected = isFull;
         }
         if(isFull)
         {
            SceneCore.pushView(new GameTipsView("开启全屏"));
         }
         else
         {
            SceneCore.pushView(new GameTipsView("关闭全屏"));
         }
      }
      public static function isFullScreen():Boolean
      {
         return STLConstant.nativeStage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE;
      }
      public static function toggleFullScreen():void
      {
         setFullScreen(STLConstant.nativeStage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE);
      }
      public static function saveFullScreenSetting(isFull:Boolean):void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isFullScreen = isFull; // 缓存设置
         SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      // 2. 声音控制
      public static function setSoundEnable(enable:Boolean):void
      {
         GameCore.soundCore.volume = enable ? 1 : 0;
         // 同步更新主界面的喇叭图标（如果存在）
         if(GameStartMain.self && GameStartMain.self._music)
         {
            GameStartMain.self._music.upState = DataCore.getTextureAtlas("start_main").getTexture(enable ? "sound_open" : "sound_close");
         }
         saveSoundSetting(enable); // 保存设置到本地
         if(self && self._soundCheck)
         {
            self._soundCheck.isSelected = !enable;
         }
         if(enable)
         {
            SceneCore.pushView(new GameTipsView("开启声音"));
         }
         else 
         {
            SceneCore.pushView(new GameTipsView("关闭声音"));
         }
      }
      public static function isSoundEnable():Boolean
      {
         return GameCore.soundCore.volume > 0;
      }
      public static function toggleSound():void
      {
         setSoundEnable(GameCore.soundCore.volume == 0);
      }
      public static function saveSoundSetting(enable:Boolean):void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isSoundEnable = enable; // 缓存设置
         SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      // 3. BGM控制
      public static function setBGMEnable(enable:Boolean):void
      {
         GameCore.soundCore.bgvolume = enable ? 0.4 : 0;
         if(self && self._bgmCheck)
         {
            self._bgmCheck.isSelected = !enable;
         }
         saveBGMSetting(enable); // 保存设置到本地
         if(enable)
         {
            SceneCore.pushView(new GameTipsView("开启BGM"));
         }
         else 
         {
            SceneCore.pushView(new GameTipsView("关闭BGM"));
         }
      }
      public static function isBGMEnable():Boolean
      {
         return GameCore.soundCore.bgvolume > 0;
      }
      public static function toggleBGM():void
      {
         setBGMEnable(GameCore.soundCore.bgvolume == 0);
      }
      public static function saveBGMSetting(enable:Boolean):void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isBGMEnable = enable; // 缓存设置
         SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      public static function setCloseVibration(enable:Boolean):void
      {
         _isCloseVibration = enable;
         if(self && self._closeVibrationCheck)
         {
            self._closeVibrationCheck.isSelected = enable;
         }
         if(enable)
         {
            SceneCore.pushView(new GameTipsView("关闭震动"));
         }
         else 
         {
            SceneCore.pushView(new GameTipsView("开启震动"));
         }
      }
      public static function isCloseVibration():Boolean
      {
         return _isCloseVibration;
      }
      public static function toggleCloseVibration():void
      {
         setCloseVibration(!_isCloseVibration);
      }
      public static function saveCloseVibrationSetting(enable:Boolean):void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isCloseVibration = enable; // 缓存设置
         SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      public static function setRecording(enable:Boolean):void
      {
         _isRecording = enable;
         if(self && self._recordingCheck)
         {
            self._recordingCheck.isSelected = enable;
         }
         if(enable)
         {
            SceneCore.pushView(new GameTipsView("开启录制"));
         }
         else 
         {
            SceneCore.pushView(new GameTipsView("关闭录制"));
         }
      }
      public static function isRecording():Boolean
      {
         return _isRecording;
      }
      public static function toggleRecording():void
      {
         setRecording(!_isRecording);
      }
      public static function saveRecordingSetting(enable:Boolean):void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isRecording = enable; // 缓存设置
         SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      public static function setBGRAEnable(enable:Boolean):void
      {
         _isBGRAEnabled = enable;
         if(self && self._bgraCheck)
         {
            self._bgraCheck.isSelected = enable;
         }
         if(enable)
         {
            DataCore.assetsRole.textureFormat = "bgra";
            DataCore.assetsSwf.otherAssets.textureFormat = "bgra";
            SceneCore.pushView(new GameTipsView("开启真全彩"));
         }
         else 
         {
            DataCore.assetsRole.textureFormat = Phone.isPhone() ? "bgraPacked4444" : "compressedAlpha";
            DataCore.assetsSwf.otherAssets.textureFormat = Phone.isPhone() ? "bgraPacked4444" : "compressedAlpha";
            SceneCore.pushView(new GameTipsView("关闭真全彩"));
         }
      }
      public static function isBGRAEnable():Boolean
      {
         return _isBGRAEnabled;
      }
      public static function toggleBGRA():void
      {
         setBGRAEnable(!_isBGRAEnabled);
      }
      public static function saveBGRASetting(enable:Boolean):void
      {
         // SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isBGRAEnable = enable; // 缓存设置
         // SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      public static function setAntiAliasingEnable(enable:Boolean):void
      {
         Starling.current.antiAliasing = enable ? 16 : 0; // 开启16x MSAA
         
         // 强制Starling重新配置BackBuffer以使抗锯齿立即生效
         var viewPort:flash.geom.Rectangle = Starling.current.viewPort;
         viewPort.width += 1;
         Starling.current.viewPort = viewPort;
         viewPort.width -= 1;
         Starling.current.viewPort = viewPort;

         if(self && self._antiAliasingCheck)
         {
            self._antiAliasingCheck.isSelected = enable;
         }
         if(enable)
         {
            SceneCore.pushView(new GameTipsView("开启抗锯齿"));
         }
         else
         {
            SceneCore.pushView(new GameTipsView("关闭抗锯齿"));
         }
      }
      public static function isAntiAliasingEnable():Boolean
      {
         return Starling.current.antiAliasing == 0;
      }
      public static function toggleAntiAliasing():void
      {
         setAntiAliasingEnable(Starling.current.antiAliasing != 0);
      }
      public static function saveAntiAliasingSetting(enable:Boolean):void
      {
         // SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isAntiAliasingEnable = enable; // 缓存设置
         // SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      public static function setNNIEnable(enable:Boolean):void
      {
         _isNNIEnabled = enable;
         if(self && self._NNICheck)
         {
            self._NNICheck.isSelected = enable;
         }
         if(enable)
         {
            SceneCore.pushView(new GameTipsView("开启硬边缘"));
         }
         else
         {
            SceneCore.pushView(new GameTipsView("关闭硬边缘"));
         }
      }
      public static function isNNIEnable():Boolean
      {
         return _isNNIEnabled;
      }
      public static function toggleNNI():void
      {
         setNNIEnable(!_isNNIEnabled);
      }
      public static function saveNNISetting(enable:Boolean):void
      {
         // SharedObject.getLocal("net.zygame.hxwz.air").data.settings.isNNIEnabled = enable; // 缓存设置
         // SharedObject.getLocal("net.zygame.hxwz.air").flush();
      }

      private function createSettingItem(label:String, type:String, initialValue:*, action:Function):LayoutGroup
      {
         var container:LayoutGroup = new LayoutGroup();
         var hLayout:HorizontalLayout = new HorizontalLayout();
         hLayout.gap = 10;
         hLayout.verticalAlign = VerticalAlign.MIDDLE;
         hLayout.paddingLeft = 20;
         container.layout = hLayout;
         container.height = 20;

         var textFormat:TextFormat = new TextFormat(GameFont.FONT_NAME, 20, 0xFFFFFF);
         textFormat.horizontalAlign = "left";
         var labelField:TextField = new TextField(150, 30, label, textFormat);
         labelField.touchable = false;
         labelField.width = 200;
         container.addChild(labelField);

         if (type == "toggle")
         {
            var check:Check = new Check();
            check.defaultSkin = createCheckboxSkin(20, false);
            check.defaultSelectedSkin = createCheckboxSkin(20, true);
            check.isSelected = initialValue;
            check.addEventListener(Event.CHANGE, function():void {
               // 避免在代码修改 isSelected 时触发循环调用
               if(check.touchable) {
                  action(check.isSelected);
               }
            });
            container.addChild(check);
         }
         else if (type == "action")
         {
            // var button:feathers.controls.Button = new feathers.controls.Button(); //
            // button.label = "执行"; //
            // button.defaultSkin = new Quad(80, 30, 0x444488); //
            // button.fontStyles = new TextFormat(GameFont.FONT_NAME, 16, 0xFFFFFF); //
            // button.addEventListener(Event.TRIGGERED, function():void { //
            //    action(); //
            // }); //
            // container.addChild(button); //
            var skin:Texture = DataCore.getTextureAtlas("start_main").getTexture("btn_style_1"); //
            var button:starling.display.Button = new starling.display.Button(skin, "执行"); //
            button.textFormat.size = 16; //
            button.scale = 0.6; //
            button.addEventListener("triggered", function():void { //
               action(); //
            }); //
            container.addChild(button); //
         }
         return container;
      }

      private function createCheckboxSkin(size:int, isSelected:Boolean):Sprite
      {
         var skinContainer:Sprite = new Sprite();

         // 外层边框
         var border:Quad = new Quad(size, size, 0xCCCCCC);
         skinContainer.addChild(border);

         // 内层背景
         var background:Quad = new Quad(size - 4, size - 4, 0x333333);
         background.x = 2;
         background.y = 2;
         skinContainer.addChild(background);

         // 如果是选中状态，再添加一个表示“勾选”的色块
         if (isSelected)
         {
            var checkMark:Quad = new Quad(size - 8, size - 8, 0xE9A84C);
            checkMark.x = 4;
            checkMark.y = 4;
            skinContainer.addChild(checkMark);
         }

         return skinContainer;
      }

   }
}

