package game.view
{
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import game.display.CommonButton;
   import game.uilts.GameFont;
   import game.view.item.OnlineRoomItem;
   import starling.display.Image;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.text.TextFormat;
   import starling.textures.TextureAtlas;
   import zygame.core.DataCore;
   import zygame.core.GameCore;
   import zygame.core.SceneCore;
   import zygame.display.DisplayObjectContainer;
   import zygame.server.Service;
   
   public class GameOnlineRoomListView extends DisplayObjectContainer
   {
      
      public static const curIP:String = "120.79.155.18";
      
      public static var _userName:String = "rainy";
      
      public static var _userCode:String = false ? "rainrainrainrain" : "rainy";
      
      public static var _userId:int = Math.random() * 9999;
      
      private var _list:List;
      
      // 原本的IP地址定义
      // private var _ip:String;
      public static var _ip:String // 联机ip

      public static var _port:int = 8888; // 联机端口（go-websocket-server默认端口）

      public var ip:String // 实际使用的联机ip

      public var port:int = 8888; // 实际使用的联机端口


      private var _msg:TextField;
      
      // 原本的联机大厅构造函数
      // public function GameOnlineRoomListView(ip:String = "120.79.155.18")
      public function GameOnlineRoomListView(inIp:String = "", inPort:int = 8888, isOnline:Boolean = true) // 取消原本的默认联机ip
      {
         super();
         if(!isOnline) //
         { //
            ip = inIp; //
            port = inPort; //
         } //
         else //
         { //
            ip = _ip; // 如果为在线模式，优先使用预加载的ip地址
            port = _port; // 如果为在线模式，优先使用预加载的端口
         } //
         // _ip = ip;
      }
      
      override public function onInit() : void
      {
         var ip:String;
         var msg:TextField;
         var textures:TextureAtlas = DataCore.getTextureAtlas("start_main");
         var bg:Image = new Image(textures.getTexture("bg"));
         this.addChild(bg);
         bg.alignPivot();
         bg.x = stage.stageWidth / 2;
         bg.y = stage.stageHeight / 2 + 32;
         if(Service.client && Service.client.connected)
         {
            showList();
            Service.send({"type":"room_list"});
         }
         else
         {
            ip = _ip;
            Service.startService(ip,port,function():void
            {
               SceneCore.replaceScene(new GameStartMain());
               SceneCore.pushView(new GameTipsView("连接服务器失败"));
               trace("连接失败");
            });
            Service.client.handFunc = function():void
            {
               SceneCore.pushView(new GameTipsView("成功登录服务器"));
               Service.client.userName = _userName;
               Service.client.userCode = _userCode;
               showList();
               Service.send({"type":"room_list"});
            };
            Service.client.closeFunc = function():void
            {
               SceneCore.replaceScene(new GameStartMain());
               SceneCore.pushView(new GameTipsView("连接服务器断开"));
               trace("连接断开");
            };
            Service.client.login(_userName, _userCode);
         }
         Service.client.messageFunc = onMessage;
         Service.client.roomlistFunc = onRoomList;
         Service.client.createRoom = onCreateRoom;
         Service.client.userDataFunc = onUserData;
         msg = new TextField(stage.stageWidth,32,"在线人数：0",new TextFormat(GameFont.FONT_NAME,12,16776960,"left"));
         this.addChild(msg);
         msg.x = msg.y = 5;
         _msg = msg;
         var onlineAddress:TextField = new TextField(stage.stageWidth,32,"联机大厅地址：" + ip + ":" + String(port),new TextFormat(GameFont.FONT_NAME,12,16776960,"left"));
         this.addChild(onlineAddress);
         onlineAddress.x = 5;
         onlineAddress.y = msg.y + 15;
      }
      
      private function onUserData(data:Object) : void
      {
         trace("用户数据：",JSON.stringify(data));
      }
      
      private function onCreateRoom(data:Object) : void
      {
         if(GameCore.currentWorld == null || GameCore.currentWorld.parent == null)
         {
            SceneCore.replaceScene(new GameOnlineRoomView(data));
         }
      }
      
      private function onRoomList(data:Object) : void
      {
         trace(JSON.stringify(data));
         _list.dataProvider = new ListCollection(data.list);
         _msg.text = "在线人数：" + data.count;
      }
      
      private function onMessage(data:Object) : void
      {
         trace(JSON.stringify(data));
      }
      
      public function showList() : void
      {
         var textures:TextureAtlas = DataCore.getTextureAtlas("start_main");
         var bg:Image = new Image(textures.getTexture("oline_bg"));
         this.addChild(bg);
         bg.x = stage.stageWidth / 2;
         bg.y = stage.stageHeight / 2;
         bg.alignPivot();
         var create:CommonButton = new CommonButton("oline_create","start_main");
         this.addChild(create);
         create.x = bg.x + bg.width / 2 - create.width / 2 - 15;
         create.y = bg.y - bg.height / 2 + create.height / 2 + 15;
         create.callBack = createRoom;
         var refresh:CommonButton = new CommonButton("btn_style_1","start_main","刷新");
         this.addChild(refresh);
         refresh.x = create.x - refresh.width - 10;
         refresh.y = create.y;
         refresh.callBack = refreshRoomList;
         var exit:CommonButton = new CommonButton("btn_style_1","start_main","返回");
         this.addChild(exit);
         exit.x = refresh.x - exit.width - 10;
         exit.y = create.y;
         exit.callBack = onExit;
         _list = new List();
         this.addChild(_list);
         _list.x = bg.x - bg.width / 2 + 35;
         _list.y = bg.y - bg.height / 2 + 80;
         _list.width = bg.width;
         _list.height = 300;
         _list.itemRendererType = OnlineRoomItem;
         _list.addEventListener("change",onChangeForCheck);
         // 监听服务器推送的房间变更事件（op=3 ChangedRoom），自动刷新列表
         Service.client.exitFunc = function(data:Object):void
         {
            refreshRoomList();
         };
         Service.client.joinFunc = function(data:Object):void
         {
            refreshRoomList();
         };
      }
      
      private function refreshRoomList(target:String = null) : void
      {
         if(Service.client && Service.client.connected)
         {
            Service.send({"type":"room_list"});
         }
      }
      
      public function onExit(target:String) : void
      {
         Service.client.close();
         Service.client = null;
         SceneCore.replaceScene(new GameStartMain());
      }
      
      private function onChangeForCheck(e:Event) : void
      {
         if(_list.selectedItem)
         {
            if(_list.selectedItem.code != "")
            {
               SceneCore.pushView(new JoinCodeView(_list.selectedItem.id));
            }
            else
            {
               Service.client.send({"type":"join_room","id":_list.selectedItem.id,"code":""});
            }
            _list.selectedIndex = -1;
         }
      }
      
      private function createRoom() : void
      {
         SceneCore.pushView(new OnlineCreateRoom());
      }
   }
}

