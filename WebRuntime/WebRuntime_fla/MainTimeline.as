package WebRuntime_fla
{
   import adobe.utils.*;
   import flash.accessibility.*;
   import flash.desktop.*;
   import flash.display.*;
   import flash.errors.*;
   import flash.events.*;
   import flash.external.*;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.filters.*;
   import flash.geom.*;
   import flash.globalization.*;
   import flash.media.*;
   import flash.net.*;
   import flash.net.drm.*;
   import flash.printing.*;
   import flash.profiler.*;
   import flash.sampler.*;
   import flash.sensors.*;
   import flash.system.*;
   import flash.text.*;
   import flash.text.engine.*;
   import flash.text.ime.*;
   import flash.ui.*;
   import flash.utils.*;
   import flash.xml.*;
   import zygame.server.BaseSocketClient;
   import zygame.utils.SendDataUtils;
   import flash.net.FileReference; // 添加FileReference用于读取存档
   import flash.events.PermissionEvent; // 添加事件
   import flash.media.Sound; // 添加背景音乐
   import flash.media.SoundChannel; // 添加声音通道

   public dynamic class MainTimeline extends MovieClip
   {
      
      private const DESIGN_WIDTH:int = 1000; //设置宽度
      
      private const DESIGN_HEIGHT:int = 550; //设置高度
      
      private var container:Sprite; //
      
      public var loading:MovieClip;
      
      public var mimaxiugai:MovieClip;
      
      public var zhuce:MovieClip;
      
      public var loadName:String;
      
      public var errorLog:String;
      
      public var path2:String;
      
      public var path:String;
      
      public var files:Array;
      
      public var oldFiles:Array;
      
      public var maxCount:int;
      
      public var loadCount:int;
      
      public var md5Data:String;
      
      public var userName:String;
      
      public var batch:int;
      
      public var userData:Object;
      
      public var errorCount:int;

	   public var main0:Sound = new Sound(); // 背景音乐
	  
      public var soundChannel:SoundChannel; // 声音通道
      
      public function MainTimeline()
      {
         super();
         main0.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void { //
            trace("bgm加载失败"); //
            main0 = new Sound(); // 没有加载成功则重新实例化Sound对象以防止错误
         }); //
         addFrameScript(0,this.frame1);
      }

      // 用于使登录界面居中显示，且支持缩放
      private function handleStageResize(e:Event = null) : void //
      { //
         if(!stage) //
         { //
            return; //
         } //
         // 从比例缩放改为全屏拉伸
         container.scaleX = stage.stageWidth / DESIGN_WIDTH;
         container.scaleY = stage.stageHeight / DESIGN_HEIGHT;
         container.x = 0;
         container.y = 0;
      } //
      
      public function zhuceFunc(param1:MouseEvent) : void
      {
         this.zhuce.visible = true;
      }
      
      public function mimaFunc(param1:MouseEvent) : void
      {
         this.mimaxiugai.visible = true;
      }

      // 新增导入存档按钮功能
      public function loadFunc(param1:MouseEvent) : void //
      { //
         // Android系统下使用File类读取存档文件
         if (File.applicationDirectory.resolvePath("phone.xml").exists) //
         { //
            var file:File = new File(); //
            file.addEventListener(Event.SELECT, function(e:Event):void { //
               file.removeEventListener(Event.SELECT, arguments.callee); //
               var selectedFile:File = file; //
               var stream:FileStream = new FileStream(); //
               stream.addEventListener(Event.COMPLETE, function(e:Event):void { //
                  try //
                  { //
                     var jsonData:String = stream.readUTFBytes(stream.bytesAvailable); //
                     var importedData:Object = JSON.parse(jsonData); //
                     if (importedData.nickName) { //
                        loading.userData = importedData; //
                        loading.pname.text = importedData.nickName; //
                        SharedObject.getLocal("net.zygame.hxwz.air").data.userData = importedData; //
                        SharedObject.getLocal("net.zygame.hxwz.air").data.userName = importedData.nickName; //
                        SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
                        trace("import UserData success:", jsonData); //
                     } //
                  } //
                  catch (error:Error) //
                  { //
                     trace("import UserData failed:", error.message); //
                  } //
                  stream.close(); //
               }); //
               if (!selectedFile.resolvePath("幻想纹章3存档.json").exists) //
               { //
                  stream.openAsync(selectedFile.resolvePath("幻想纹章3存档.json"), FileMode.WRITE); //
                  stream.writeUTFBytes("{}"); //
                  stream.close(); //
               } //
               else //
               { //
                  stream.openAsync(selectedFile.resolvePath("幻想纹章3存档.json"), FileMode.READ); //
               } //
            }); //
            file.browseForDirectory("创建并选择存档文件夹"); //
         } //
         else //
         { //
            // Window系统下使用FileReference读取存档文件
            var fileRef:FileReference = new FileReference(); //
            fileRef.addEventListener(Event.SELECT, function(e:Event):void { //
               fileRef.load(); //
            }); //
            fileRef.addEventListener(Event.COMPLETE, function(e:Event):void { //
               try { //
                  var jsonData:String = fileRef.data.toString(); //
                  var importedData:Object = JSON.parse(jsonData); //
                  if (importedData.nickName) { //
                     loading.userData = importedData; //
                     loading.pname.text = importedData.nickName; //
                     SharedObject.getLocal("net.zygame.hxwz.air").data.userData = importedData; //
                     SharedObject.getLocal("net.zygame.hxwz.air").data.userName = importedData.nickName; //
                     SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
                     trace("import UserData success:", jsonData); //
                  } //
               } catch (error:Error) { //
                  trace("import UserData failed:", error.message); //
               } //
            }); //
            fileRef.browse([new FileFilter("幻想纹章3存档文件", "*.json")]); //
         } //
      } //

      public function clear(param1:MouseEvent) : void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = {}; // 清除用户数据缓存
         SharedObject.getLocal("net.zygame.hxwz.air").data.address = ""; // 清除联机地址缓存
         SharedObject.getLocal("net.zygame.hxwz.air").data.userName = ""; // 清除用户名缓存
         SharedObject.getLocal("net.zygame.hxwz.air").data.userCode = ""; // 清除用户密码缓存
         SharedObject.getLocal("net.zygame.hxwz.air").flush(); // 刷新缓存
         this.loading.userData = {}; // 清除当前生成的用户数据
         this.loading.address.text = ""; // 清除当前生成的联机地址
         // 去除原本的清除缓存代码
         // this.loading.pname.text = ""; //
         // this.loading.pcode.text = ""; //

         // if(File.applicationStorageDirectory.exists)
         // {
         //    File.applicationStorageDirectory.deleteDirectory(true);
         // }
         // this.loading.clear.visible = false;
         // this.loading.start.visible = false;
         // this.cheakUpdate();
      }
      
      public function cheakUpdate() : void
      {
         var _loc2_:File = null;
         var _loc3_:FileStream = null;
         var _loc4_:String = null;
         this.files = [];
         this.oldFiles = [];
         this.maxCount = 0;
         this.loadCount = 0;
         this.errorCount = 0;
         try
         {
            _loc2_ = File.applicationStorageDirectory.resolvePath("md5.data");
            if(_loc2_.exists)
            {
               _loc3_ = new FileStream();
               _loc3_.open(_loc2_,FileMode.READ);
               _loc4_ = _loc3_.readUTFBytes(_loc3_.bytesAvailable);
               this.oldFiles = this.getMD5s(_loc4_);
            }
         }
         catch(e:Error)
         {
         }
         var _loc1_:URLLoader = new URLLoader(new URLRequest(this.path + "md5.data?acl=GRPS000000ANONYMOUSE&math=" + Math.random()));
         _loc1_.addEventListener(Event.COMPLETE,this.onMD5Complete);
         _loc1_.addEventListener(IOErrorEvent.IO_ERROR,this.onMD5Error);
         trace("MD5 Start ",this.path + "md5.data?acl=GRPS000000ANONYMOUSE&math=" + Math.random());
      }
      
      public function onMD5Error(param1:IOErrorEvent) : void
      {
         this.loading.error_tips.visible = true;
      }
      
      public function getMD5s(param1:String) : Array
      {
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc2_:Array = [];
         var _loc3_:Array = param1.split(",");
         for(_loc4_ in _loc3_)
         {
            if(_loc3_[_loc4_] != "")
            {
               _loc5_ = _loc3_[_loc4_].split(":");
               _loc2_.push(_loc5_[0] + ":" + _loc5_[1]);
            }
         }
         return _loc2_;
      }
      
      public function onMD5Complete(param1:Event) : void
      {
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc6_:Array = null;
         var _loc7_:int = 0;
         var _loc8_:File = null;
         var _loc2_:String = param1.target.data;
         trace(_loc2_);
         _loc2_ = _loc2_.substr(0,_loc2_.length - 1);
         this.md5Data = _loc2_;
         var _loc3_:Array = _loc2_.split(",");
         for(_loc4_ in _loc3_)
         {
            if(_loc3_[_loc4_] != "")
            {
               _loc5_ = _loc3_[_loc4_].split(":");
               this.files.push({
                  "url":_loc5_[0],
                  "md5":_loc5_[1]
               });
            }
         }
         this.maxCount = this.files.length;
         this.nextLoad();
         trace("清理确认",this.maxCount);
         if(SharedObject.getLocal("net.zygame.hxwz.air.301").data.isClear == null)
         {
            trace("清理缓存");
            _loc6_ = File.applicationStorageDirectory.getDirectoryListing();
            _loc7_ = 0;
            for(; _loc7_ < _loc6_.length; _loc7_++)
            {
               _loc8_ = _loc6_[_loc7_];
               if(!_loc8_.isDirectory)
               {
                  try
                  {
                     _loc8_.deleteFile();
                  }
                  catch(e:Error)
                  {
                  }
                  continue;
               }
               try
               {
                  _loc8_.deleteDirectory(true);
               }
               catch(e:Error)
               {
               }
            }
            SharedObject.getLocal("net.zygame.hxwz.air.301").data.isClear = true;
            SharedObject.getLocal("net.zygame.hxwz.air.301").flush();
         }
         trace(JSON.stringify(this.files));
      }
      
      public function nextLoad() : void
      {
         var load:Object = null;
         var loader:URLLoader = null;
         var md5File:File = null;
         var fileSave:FileStream = null;
         var error:TextField = null;
         if(this.files.length > 0)
         {
            load = this.files[0];
            if(this.oldFiles.indexOf(load.url + ":" + load.md5) == -1 || File.applicationStorageDirectory.resolvePath(load.url).exists == false)
            {
               this.loading.loadFile.text = load.url;
               trace(this.path + load.url);
               loader = new URLLoader(new URLRequest(this.path + load.url + "?acl=GRPS000000ANONYMOUSE&math=" + Math.random()));
               loader.dataFormat = URLLoaderDataFormat.BINARY;
               loader.addEventListener(Event.COMPLETE,function(param1:Event):void
               {
                  var _loc2_:ByteArray = param1.target.data as ByteArray;
                  _loc2_.position = 0;
                  var _loc3_:File = File.applicationStorageDirectory.resolvePath(load.url);
                  var _loc4_:FileStream = new FileStream();
                  _loc4_.open(_loc3_,FileMode.WRITE);
                  _loc4_.writeBytes(_loc2_);
                  _loc4_.close();
                  ++loadCount;
                  loading.update.scaleX = loadCount / maxCount;
                  loading.loaded.text = loadCount + "/" + maxCount + " Error:" + errorCount;
                  files.shift();
                  nextLoad();
               });
               loader.addEventListener(ProgressEvent.PROGRESS,function(param1:ProgressEvent):void
               {
                  loading.loadFile.text = load.url + " " + (param1.bytesLoaded / 1024 / 1024).toFixed(2) + "/" + (param1.bytesTotal / 1024 / 1024).toFixed(2) + "mb";
               });
               loader.addEventListener(IOErrorEvent.IO_ERROR,this.onError);
            }
            else
            {
               this.files.shift();
               ++this.loadCount;
               this.loading.update.scaleX = this.loadCount / this.maxCount;
               this.loading.loaded.text = this.loadCount + "/" + this.maxCount + " Error:" + this.errorCount;
               if(this.batch > 0)
               {
                  --this.batch;
                  this.nextLoad();
               }
               else
               {
                  this.batch = 100;
                  setTimeout(this.nextLoad,1 / 60);
               }
            }
         }
         else
         {
            trace("加载完毕");
            try
            {
               this.loading.start.visible = true;
               this.loading.clear.visible = true;
               md5File = File.applicationStorageDirectory.resolvePath("md5.data");
               // 去除原本的md5保存代码
               // fileSave = new FileStream();
               // fileSave.open(md5File,FileMode.WRITE);
               // fileSave.writeUTFBytes(this.md5Data);
               // fileSave.close();
               trace("错误信息\r",this.errorLog);
            }
            catch(e:Error)
            {
               error = new TextField();
               this.addChild(error);
               error.width = 500;
               error.height = 500;
               error.text = e.errorID + e.message + "md5:\n" + md5Data;
            }
         }
      }
      
      public function login(param1:MouseEvent) : void
      {
         if(this.loading.pname.text == "") // 不允许用户名为空
         { //
               this.loginError(); //
               return; //
         } //
         if(this.loading.pname.text.indexOf("#") > -1) // 给用户名自动添加后缀防止重复
         { //
         } //
         else //
         { //
            this.loading.pname.text = this.loading.pname.text + "#" + String(Math.round(Math.random() * 10000)); //
         } //
         if(!this.loading.userData.nickName) // 如果没有用户名则创建
         { //
            this.loading.userData = { //
               nickName: this.loading.pname.text, //
               coin: 0, //
               crystal: 0, //
               fight: "", //
               ofigth: "", //
               fbs: "", //
               userData: { //
                  buys: [], //
                  fight: "", //
                  allFight: 0, //
                  ofigth: "", //
                  vip: 0, //
                  version: "", //
                  fbs: "" //
               }, //
               _4399userData: this.loading._4399userData[0] //
            }; //
         } //
         else if(this.loading.userData.nickName != this.loading.pname.text) // 更新用户名
         { //
            this.loading.userData.nickName = this.loading.pname.text; //
         } //
         trace("userData2",JSON.stringify(this.loading.userData)); //
         this.loading.address.text = this.loading.pcode.text; // 存入联机地址
         this.loading.userData._4399userData = this.loading._4399userData; // 存入4399用户数据
         this.loading.userData._4399userData[0].nickName = this.loading.pname.text; // 存入昵称
         this.loading.userData._4399userData[0].name = this.loading.pname.text; // 存入用户名
         trace("登录"); //
         startGame(); // 开始游戏
         // 下面的代码是原本的登录代码，已被注释掉
        //  var clinet:BaseSocketClient = null;
        //  var e:MouseEvent = param1;
        //  var socket:Socket = new Socket("120.220.73.176",24888); //
        // //  var socket:Socket = new Socket("120.79.155.18",4888);
        //  clinet = new BaseSocketClient(socket);
        //  clinet.handFunc = function():void
        //  {
        //     trace("握手");
        //     clinet.send(SendDataUtils.handData(loading.pname.text,loading.pcode.text));
        //  };
        //  clinet.ioerrorFunc = function():void
        //  {
        //     trace("登录失败");
        //     loginError();
        //  };
        //  clinet.closeFunc = function():void
        //  {
        //     trace("登录失败");
        //     loginError();
        //  };
        //  clinet.dataFunc = function(param1:Object):void
        //  {
        //     trace(JSON.stringify(param1));
        //     if(param1.type == "handed")
        //     {
        //        clinet.close();
        //        if(param1.userData)
        //        {
        //           trace("登录成功");
        //           userData = param1.userData;
        //           startGame();
        //           clinet.closeFunc = null;
        //           clinet.close();
        //        }
        //        else
        //        {
        //           trace("登录失败");
        //           loginError();
        //        }
        //     }
        //  };
      }
      
      public function loginError() : void
      {
         this.loading.login_error.visible = true;
         setTimeout(function():void
         {
            loading.login_error.visible = false;
         },1000);
      }
      
      public function startGame() : void
      {
         SharedObject.getLocal("net.zygame.hxwz.air").data.userName = this.loading.pname.text;
         // 原本的缓存密码代码
         // SharedObject.getLocal("net.zygame.hxwz.air").data.userCode = this.loading.pcode.text;
         SharedObject.getLocal("net.zygame.hxwz.air").data.userCode = this.loading.pname.text; // 缓存用户名并且作为密码
         SharedObject.getLocal("net.zygame.hxwz.air").data.userData = this.loading.userData; //缓存用户数据
         SharedObject.getLocal("net.zygame.hxwz.air").data.address = this.loading.address.text; //缓存地址
         SharedObject.getLocal("net.zygame.hxwz.air").flush();
         trace("startGame");
         var _loc1_:URLLoader = new URLLoader();
         _loc1_.dataFormat = URLLoaderDataFormat.BINARY;
         if(File.applicationStorageDirectory.resolvePath(this.loadName + ".swf").exists)
         {
            _loc1_.load(new URLRequest(File.applicationStorageDirectory.resolvePath(this.loadName + ".swf").url));
         }
         else
         {
            _loc1_.load(new URLRequest(File.applicationDirectory.resolvePath(this.loadName + ".swf").url));
         }
         _loc1_.addEventListener(Event.COMPLETE,this.onComplete);
         _loc1_.addEventListener(ProgressEvent.PROGRESS,this.onProgress);
         this.loading.start.visible = false;
      }
      
      public function onProgress(param1:ProgressEvent) : void
      {
         this.loading.txt.text = "Update " + int(param1.bytesLoaded / param1.bytesTotal * 100) + "%";
      }
      
      public function onComplete(param1:Event) : void
      {
         var con:LoaderContext;
         var loader:Loader = null;
         var e:Event = param1;
         if (this.loading.address.text.indexOf(":") > -1) // 检查地址是否包含端口
         { //
            var ip:String = this.loading.address.text.split(":")[0]; //获取ip
            var port:String = this.loading.address.text.split(":")[1]; //获取端口
         } //
         else if (this.loading.address.text.indexOf("：") > -1) // 兼容中文冒号
         { //
            var ip:String = this.loading.address.text.split("：")[0]; //获取ip
            var port:String = this.loading.address.text.split("：")[1]; //获取端口
         } //
         else //
         { //
            var ip:String = ""; //
            var port:String = ""; //
         } //
         trace("加载完成");
         loader = new Loader();
         this.addChild(loader);
         con = new LoaderContext();
         con.allowCodeImport = true;
         loader.loadBytes(e.target.data as ByteArray,con);
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(param1:Event):void
         {
            loader.contentLoaderInfo.applicationDomain.getDefinition("game.view.GameOnlineRoomListView")["_userName"] = loading.pname.text;
            // 这是原本的预加载用户密码的代码
            // loader.contentLoaderInfo.applicationDomain.getDefinition("game.view.GameOnlineRoomListView")["_userCode"] = loading.pcode.text;
            loader.contentLoaderInfo.applicationDomain.getDefinition("game.view.GameOnlineRoomListView")["_userCode"] = loading.pname.text; // 使用用户名作为密码
            loader.contentLoaderInfo.applicationDomain.getDefinition("game.view.GameOnlineRoomListView")["_ip"] = ip; // 预加载联机地址ip
            loader.contentLoaderInfo.applicationDomain.getDefinition("game.view.GameOnlineRoomListView")["_port"] = port; // 预加载联机地址端口
            loader.contentLoaderInfo.applicationDomain.getDefinition("zygame.server.Service")["userData"] = loading.userData; // 预加载用户数据
         });
         this.loading.visible = false;
         soundChannel.stop(); // 停止所有正在播放的声音
      }
      
      public function onError(param1:IOErrorEvent) : void
      {
         ++this.errorCount;
         this.files.shift();
         ++this.loadCount;
         this.loading.update.scaleX = this.loadCount / this.maxCount;
         this.loading.loaded.text = this.loadCount + "/" + this.maxCount + " Error:" + this.errorCount;
         this.nextLoad();
      }
      
      public function getFileType(param1:String, param2:ByteArray) : String
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:String = "unknown";
         try
         {
            _loc4_ = int(param2.readUnsignedByte());
            _loc5_ = int(param2.readUnsignedByte());
            trace(param1,_loc4_,_loc5_);
            if(_loc4_ == 66 && _loc5_ == 77)
            {
               _loc3_ = "bmp";
            }
            else if(_loc4_ == 255 && _loc5_ == 216)
            {
               _loc3_ = "jpg";
            }
            else if(_loc4_ == 137 && _loc5_ == 80)
            {
               _loc3_ = "png";
            }
            else if(_loc4_ == 71 && _loc5_ == 73)
            {
               _loc3_ = "gif";
            }
            else if(_loc4_ == 73 && _loc5_ == 68)
            {
               _loc3_ = "mp3";
            }
         }
         catch(e:Error)
         {
         }
         return _loc3_;
      }
      
      // internal function frame1() : *
      // {
      //    container = new Sprite(); //
      //    while(this.numChildren > 0) //
      //    { //
      //       container.addChild(this.getChildAt(0)); //
      //    } //
      //    this.addChild(container); //
      //    stage.scaleMode = StageScaleMode.NO_SCALE;
      //    stage.align = StageAlign.TOP_LEFT;
      //    stage.addEventListener(Event.RESIZE,handleStageResize); //
      //    handleStageResize(); //
      //    this.loadName = "FantasyCrest3_SERVER_7";
      //    this.loading.start.addEventListener(MouseEvent.CLICK,this.login);
      //    this.loading.zhuce.addEventListener(MouseEvent.CLICK,this.zhuceFunc);
      //    this.loading.mimaxiug.addEventListener(MouseEvent.CLICK,this.mimaFunc);
      //    this.loading.load.addEventListener(MouseEvent.CLICK,this.loadFunc); // 新增导入存档按钮功能
      //    this.loading.clear.addEventListener(MouseEvent.CLICK,this.clear);
      //    this.path2 = "http://www.4399api.com/system/attachment/100/05/24/100052440/";
      //    this.path = "http://www.4399api.com/system/attachment/100/05/24/100052440/";
      //    this.files = [];
      //    this.oldFiles = [];
      //    this.maxCount = 0;
      //    this.loadCount = 0;
      //    this.batch = 100;
      //    this.errorCount = 0;
      //    this.nextLoad(); //
      //   //  this.cheakUpdate();
      //    loading._4399userData = [ // 初始化4399用户数据
      //       { //
      //          nickName: "", //
      //          name: "", //
      //          uid: 0, //
      //          allFight: 0, //
      //          fight: "", //
      //          ofigth: "", //
      //          vip: 0, //
      //          version: "", //
      //          fbs: ""}]; //
      //    loading.userData = { // 初始化用户数据
      //       nickName: "???", //
      //       coin: 0, //
      //       crystal: 0, //
      //       fight: "", //
      //       ofigth: "", //
      //       fbs: "", //
      //       userData: { //
      //          buys: [], //
      //          fight: "", //
      //          allFight: 0, //
      //          ofigth: "", //
      //          vip: 0, //
      //          version: "", //
      //          fbs: "" //
      //       }, //
      //       _4399userData: loading._4399userData //
      //    }; //
      //    loading.address = {text:""}; // 初始化联机地址
      //    trace("userData1",JSON.stringify(loading.userData)); //
      //    setTimeout(function():void
      //    {
      //       try
      //       {
      //          loading.pname.text = SharedObject.getLocal("net.zygame.hxwz.air").data.userName;
      //          // 原本的读取密码缓存代码
      //          // loading.pcode.text = SharedObject.getLocal("net.zygame.hxwz.air").data.userCode;
      //          loading.pcode.text = SharedObject.getLocal("net.zygame.hxwz.air").data.address; // 读取联机地址缓存
      //          loading.userData = SharedObject.getLocal("net.zygame.hxwz.air").data.userData; // 读取用户数据缓存
      //          loading.address.text = SharedObject.getLocal("net.zygame.hxwz.air").data.address; // 读取联机地址缓存
      //       }
      //       catch(e:Error)
      //       {
      //          trace("123",e.message);
      //       }
      //    },300);
      //    try
      //    {
      //       if(this.stage)
      //       {
      //          this.stage.nativeWindow.x = this.stage.fullScreenWidth / 2 - this.stage.nativeWindow.width / 2;
      //          this.stage.nativeWindow.y = this.stage.fullScreenHeight / 2 - this.stage.nativeWindow.height / 2;
      //       }
      //    }
      //    catch(e:Error)
      //    {
      //    }
      // }
   }
}