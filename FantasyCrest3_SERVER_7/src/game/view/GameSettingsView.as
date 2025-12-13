package game.view
{
   import feathers.controls.Button;
   import feathers.controls.Check;
   import feathers.controls.LayoutGroup;
   import feathers.layout.HorizontalLayout;
   import feathers.layout.VerticalLayout;
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
      
      public function GameSettingsView()
      {
         super();
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

         mainContainer.addChild(createSettingItem("开启全屏", "toggle", (STLConstant.nativeStage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE), function(value:Boolean):void{
            if(value)
               STLConstant.nativeStage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
            else
               STLConstant.nativeStage.displayState = StageDisplayState.NORMAL;
         }));

         mainContainer.addChild(createSettingItem("关闭声音", "toggle", (GameCore.soundCore.volume == 0), function(value:Boolean):void{
            if(value)
               GameCore.soundCore.volume = 0;
            else
               GameCore.soundCore.volume = 1;
            if(GameStartMain.self && GameStartMain.self._music)
               GameStartMain.self._music.upState = DataCore.getTextureAtlas("start_main").getTexture(GameCore.soundCore.volume == 0 ? "sound_close" : "sound_open");
         }));

         mainContainer.addChild(createSettingItem("关闭BGM", "toggle", (GameCore.soundCore.bgvolume == 0), function(value:Boolean):void{
            if(value)
               GameCore.soundCore.bgvolume = 0;
            else
               GameCore.soundCore.bgvolume = 0.4;
         }));

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

      private function createSettingItem(label:String, type:String, initialValue:*, action:Function):LayoutGroup
      {
         var container:LayoutGroup = new LayoutGroup();
         var hLayout:HorizontalLayout = new HorizontalLayout();
         hLayout.gap = 20;
         hLayout.verticalAlign = HorizontalLayout.VERTICAL_ALIGN_MIDDLE;
         container.layout = hLayout;
         container.height = 50;

         var labelField:TextField = new TextField(150, 30, label, new TextFormat(GameFont.FONT_NAME, 20, 0xFFFFFF));
         labelField.touchable = false;
         container.addChild(labelField);

         if (type == "toggle")
         {
            var check:Check = new Check();
            check.defaultSkin = createCheckboxSkin(20, false);
            check.defaultSelectedSkin = createCheckboxSkin(20, true);
            check.isSelected = initialValue;
            check.addEventListener(Event.CHANGE, function():void {
               action(check.isSelected);
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

