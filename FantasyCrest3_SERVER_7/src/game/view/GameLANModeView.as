package game.view
{
   import game.server.GameServerScoket;
   import game.uilts.GameFont;
   import starling.display.Button;
   import starling.display.Quad;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.text.TextFormat;
   import starling.textures.Texture;
   import zygame.core.DataCore;
   import zygame.core.SceneCore;
   import zygame.display.DisplayObjectContainer;
   import feathers.controls.TextInput; //
   
   public class GameLANModeView extends DisplayObjectContainer
   {

      private var ipInput:TextInput; // 定义IP输入框为类成员变量，以便在事件处理函数中访问

      private var portInput:TextInput; // 定义端口输入框为类成员变量
      
      public function GameLANModeView()
      {
         super();
      }
      
      override public function onInit() : void
      {
         var bg:Quad = new Quad(stage.stageWidth,stage.stageHeight,0);
         bg.alpha = 0.7;
         this.addChild(bg);
         var text:TextField = new TextField(stage.stageWidth,64,"- WIFI局域网对战，请选择你的身份 -",new TextFormat(GameFont.FONT_NAME,24,16777215));
         // text.y = stage.stageHeight / 2 - 100;
         text.y = stage.stageHeight / 2 - 225; //
         this.addChild(text);

         var iPText:TextField = new TextField(200,64,"地址：",new TextFormat(GameFont.FONT_NAME,24,16777215));
         iPText.x = stage.stageWidth / 8; //
         iPText.y = stage.stageHeight / 2 - 175; //
         this.addChild(iPText); //
         ipInput = new TextInput(); //
         ipInput.x = iPText.x + 150; //
         ipInput.y = iPText.y; //
         ipInput.width = 550; //
         ipInput.height = 64; //
         ipInput.restrict = "0-9.:A-Fa-f"; //支持ipv4和ipv6地址输入 //
         ipInput.maxChars = 45; //ipv6地址最长45字符 //
         ipInput.fontStyles = new TextFormat(GameFont.FONT_NAME,24,16777215,"left"); //
         this.addChild(ipInput); //
         var portText:TextField = new TextField(200,64,"端口：",new TextFormat(GameFont.FONT_NAME,24,16777215)); //
         portText.x = stage.stageWidth / 8; //
         portText.y = stage.stageHeight / 2 - 100; //
         this.addChild(portText); //
         portInput = new TextInput(); //
         portInput.x = portText.x + 150; //
         portInput.y = portText.y; //
         portInput.width = 550; //
         portInput.height = 64; //
         portInput.restrict = "0-9"; //端口号只能输入数字 //
         portInput.maxChars = 5; //端口号最大5位 //
         portInput.fontStyles = new TextFormat(GameFont.FONT_NAME,24,16777215,"left"); //
         this.addChild(portInput); //

         var skin:Texture = DataCore.getTextureAtlas("start_main").getTexture("btn_style_1");
         var button:Button = new Button(skin,"房主");
         this.addChild(button);
         button.x = stage.stageWidth / 2 - 100;
         button.y = stage.stageHeight / 2 + 30;
         button.alignPivot();
         button.textFormat.size = 24;
         button.name = "maters";
         var button2:Button = new Button(skin,"参与者");
         this.addChild(button2);
         button2.x = stage.stageWidth / 2 + 100;
         button2.y = stage.stageHeight / 2 + 30;
         button2.alignPivot();
         button2.textFormat.size = 24;
         button2.name = "player";

         var button3:Button = new Button(skin,"取消"); //
         this.addChild(button3); //
         button3.x = stage.stageWidth / 2 + 300; //
         button3.y = stage.stageHeight / 2 + 30; //
         button3.alignPivot(); //
         button3.textFormat.size = 24; //
         button3.name = "cancel"; //

         this.addEventListener("triggered",onTriggered);
      }
      
      public function onTriggered(e:Event) : void
      {
         switch(e.target["name"])
         {
            case "maters":
               // GameServerScoket.init();
               GameServerScoket.init(ipInput.text, int(portInput.text)); //
               // SceneCore.replaceScene(new GameOnlineRoomListView(GameServerScoket.ip));
               SceneCore.replaceScene(new GameOnlineRoomListView(GameServerScoket.ip, GameServerScoket.port, false)); //
               break;
            case "player":
               // SceneCore.replaceScene(new GameOnlineRoomListView(GameServerScoket.ip));
               SceneCore.replaceScene(new GameOnlineRoomListView(ipInput.text, int(portInput.text), false)); //
               break; //
            case "cancel": //
               this.removeFromParent(true); //
         }
      }
   }
}

