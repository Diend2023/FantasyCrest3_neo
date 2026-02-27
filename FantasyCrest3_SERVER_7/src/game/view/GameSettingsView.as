// 添加设置界面
package game.view
{
   import feathers.controls.Button;
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

   public class GameSettingsView extends DisplayObjectContainer
   {
      
      public static var self:GameSettingsView;
      
      private var _fullScreenCheck:Check;
      private var _soundCheck:Check;
      private var _bgmCheck:Check;

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

         // 最外层的垂直容器
         var mainContainer:LayoutGroup = new LayoutGroup();
         var mainContainerBackground:Quad = new Quad(stage.stageWidth / 1.25, stage.stageHeight / 1.25, 0x000000);
         mainContainerBackground.alpha = 0.7;
         mainContainer.layout = new VerticalLayout();
         (mainContainer.layout as VerticalLayout).gap = 20;
         mainContainer.backgroundSkin = mainContainerBackground;
         mainContainer.width = mainContainerBackground.width;
         mainContainer.height = mainContainerBackground.height;
         this.addChild(mainContainer);
         // 将主容器居中
         mainContainer.validate();
         mainContainer.x = (stage.stageWidth - mainContainer.width) / 2;
         mainContainer.y = (stage.stageHeight - mainContainer.height) / 2;

         // 开启全屏
         var fullScreenItem:LayoutGroup = createSettingItem("开启全屏（F11）", "toggle", (STLConstant.nativeStage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE), function(value:Boolean):void{
            GameSettingsView.setFullScreen(value);
         });
         _fullScreenCheck = fullScreenItem.getChildAt(1) as Check;
         mainContainer.addChild(fullScreenItem);

         // 关闭声音 (注意：UI勾选代表关闭，所以传入 !value)
         var soundItem:LayoutGroup = createSettingItem("关闭声音（F1）", "toggle", (GameCore.soundCore.volume == 0), function(value:Boolean):void{
            GameSettingsView.setSoundEnable(!value);
         });
         _soundCheck = soundItem.getChildAt(1) as Check;
         mainContainer.addChild(soundItem);

         // 关闭BGM (同理)
         var bgmItem:LayoutGroup = createSettingItem("关闭BGM（F5）", "toggle", (GameCore.soundCore.bgvolume == 0), function(value:Boolean):void{
            GameSettingsView.setBGMEnable(!value);
         });
         _bgmCheck = bgmItem.getChildAt(1) as Check;
         mainContainer.addChild(bgmItem);

         skin = DataCore.getTextureAtlas("start_main").getTexture("btn_style_1");
         buttonExit = new starling.display.Button(skin,"完成");
         this.addChild(buttonExit);
         buttonExit.textFormat.size = 18;
         buttonExit.x = stage.stageWidth / 2 - buttonExit.width / 2;
         buttonExit.y = stage.stageHeight - buttonExit.height * 2 - 16;
         buttonExit.addEventListener("triggered",function(e:Event):void
         {
            removeFromParent(true);
         });
      }

      // 1. 全屏控制
      public static function setFullScreen(isFull:Boolean):void {
         STLConstant.nativeStage.displayState = isFull ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
         if(self && self._fullScreenCheck) {
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
      public static function toggleFullScreen():void {
         setFullScreen(STLConstant.nativeStage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE);
      }

      // 2. 音效控制
      public static function setSoundEnable(enable:Boolean):void {
         GameCore.soundCore.volume = enable ? 1 : 0;
         // 同步更新主界面的喇叭图标（如果存在）
         if(GameStartMain.self && GameStartMain.self._music) {
            GameStartMain.self._music.upState = DataCore.getTextureAtlas("start_main").getTexture(enable ? "sound_open" : "sound_close");
         }
         if(self && self._soundCheck) {
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
      public static function toggleSound():void {
         setSoundEnable(GameCore.soundCore.volume == 0);
      }

      // 3. BGM控制
      public static function setBGMEnable(enable:Boolean):void {
         GameCore.soundCore.bgvolume = enable ? 0.4 : 0;
         if(self && self._bgmCheck) {
            self._bgmCheck.isSelected = !enable;
         }
         if(enable) 
         {
            SceneCore.pushView(new GameTipsView("开启BGM"));
         }
         else 
         {
            SceneCore.pushView(new GameTipsView("关闭BGM"));
         }
      }
      public static function toggleBGM():void {
         setBGMEnable(GameCore.soundCore.bgvolume == 0);
      }

      private function createSettingItem(label:String, type:String, initialValue:*, action:Function):LayoutGroup
      {
         var container:LayoutGroup = new LayoutGroup();
         var hLayout:HorizontalLayout = new HorizontalLayout();
         hLayout.gap = 20;
         hLayout.verticalAlign = VerticalAlign.MIDDLE;
         hLayout.paddingLeft = 20;
         container.layout = hLayout;
         container.height = 50;

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
            var button:feathers.controls.Button = new feathers.controls.Button();
            button.label = "执行";
            button.defaultSkin = new Quad(80, 30, 0x444488);
            button.fontStyles = new TextFormat(GameFont.FONT_NAME, 16, 0xFFFFFF);
            button.addEventListener(Event.TRIGGERED, function():void {
               action();
            });
            container.addChild(button);
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

