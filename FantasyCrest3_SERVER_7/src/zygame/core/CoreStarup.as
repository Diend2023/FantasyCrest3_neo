// 直接更新整个文件以修复无法缩放的问题
package zygame.core
{
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Rectangle;
   import flash.media.SoundMixer;
   import flash.media.SoundTransform;
   import flash.system.Capabilities;
   import lzm.starling.STLConstant;
   import lzm.starling.STLRootClass;
   import starling.core.Starling;
   import starling.utils.AssetManager;
   import starling.utils.SystemUtil;
   import zygame.utils.RestoreTextureUtils;
   import zygame.utils.SuperTextureAtlas;
   
   public class CoreStarup extends Sprite
   {
      
      public static var restoreTextureUtils:RestoreTextureUtils;
      
      public static var testPath:String = null;
      
      public static var testRole:String = null;
      
      public static var testRoles:Array = null;
      
      public static var testRunderType:String = null;
      
      private var _isPc:Boolean = false;
      
      private var _statusBarHeight:Number = 0;
      
      private var _mStarling:GameCore;
      
      private var _viewRect:Rectangle;
      
      private var _currentValue:Number = 1;
      
      private var _configPath:String; //
      
      private var _mainClass:Class; //
      
      private var _HDHeight:int; //
      
      private var _debug:Boolean; //
      
      private var _stage3DProfile:String; //
      
      private var _isMultitouch:Boolean; //
      
      private var _runMode:String; //
      
      private var _antiAliasing:int; //
      
      private var _loadContextImage:BitmapData; //
      
      private var _designWidth:int = 0; //
      
      private var _designHeight:int = 0; //
      
      private var _targetAspectRatio:Number = 0; //
      
      public function CoreStarup()
      {
         super();
         this.addEventListener(Event.ADDED_TO_STAGE,onAddedToStage); //
      }

      private function onAddedToStage(event:Event) : void //
      { //
         this.removeEventListener(Event.ADDED_TO_STAGE,onAddedToStage); //
         stage.addEventListener(Event.RESIZE,onResize); //
      } //

      private function onResize(event:Event) : void //
      { //
         trace("窗口大小改变:",stage.stageWidth,stage.stageHeight); //
         updateStarlingViewPort(); //
         if(_mStarling) //
         { //
            _mStarling.setRequiresRedraw(); //
         } //
      } //

      protected function initStarling(configPath:String, mainClass:Class, HDHeight:int = 960, debug:Boolean = false, isPc:Boolean = false, stage3DProfile:String = "auto", isMultitouch:Boolean = true, runMode:String = "auto", antiAliasing:int = 4, loadContextImage:BitmapData = null) : void
      {
         var stageWidth:Number; //
         var stageHeight:Number; //
         var viewPort:Rectangle;
         var hscale:Number;
         var wscale:Number; //
         var scale:Number; //
         _configPath = configPath; //
         _mainClass = mainClass; //
         _HDHeight = HDHeight; //
         _debug = debug; //
         _stage3DProfile = stage3DProfile; //
         _isMultitouch = isMultitouch; //
         _runMode = runMode; //
         _antiAliasing = antiAliasing; //
         _loadContextImage = loadContextImage; //
         STLConstant.nativeStage = stage;
         trace("初始化高度比：",HDHeight);
         _isPc = isPc;
         Starling.multitouchEnabled = isMultitouch;
         // stageWidth = stage.stageWidth; //
         // stageHeight = stage.stageHeight; //
         // _designWidth = stageWidth; //
         // _designHeight = stageHeight; //
         // _targetAspectRatio = _designWidth / _designHeight; //
         _designHeight = HDHeight; // 使用传入的 960 或其他值作为基准高度
         _targetAspectRatio = 10 / 5.5; // 定义一个固定的目标宽高比，例如 10:5.5
         _designWidth = Math.round(_designHeight * _targetAspectRatio); // 根据高度和比例计算宽度
         trace("设计尺寸:",_designWidth,"x",_designHeight,"宽高比:",_targetAspectRatio); //
         // viewPort = _viewRect ? _viewRect : new Rectangle(0,0,isPc ? stage.stageWidth : stage.stageWidth,isPc ? stage.stageHeight : stage.stageHeight);
         // if(viewPort.width == 0)
         // {
         //    viewPort.width = 800;
         // }
         // if(viewPort.height == 0)
         // {
         //    viewPort.height = 550;
         // }
         // viewPort.y = _statusBarHeight;
         // viewPort.height -= _statusBarHeight;
         viewPort = calculateViewPort(); //
         hscale = viewPort.height / HDHeight;
         wscale = viewPort.width / HDHeight; //
         scale = Math.min(hscale,wscale); //
         STLConstant.scale = scale; //
         // STLConstant.StageWidth = (viewPort.width - viewPort.height) / hscale + HDHeight;
         // STLConstant.StageHeight = HDHeight;
         STLConstant.StageWidth = viewPort.width / scale; //
         STLConstant.StageHeight = viewPort.height / scale; //
         _mStarling = new GameCore(configPath,this,STLRootClass,stage,viewPort,null,runMode,stage3DProfile);
         _mStarling.stage.stageWidth = STLConstant.StageWidth;
         _mStarling.stage.stageHeight = STLConstant.StageHeight;
         _mStarling.enableErrorChecking = Capabilities.isDebugger;
         _mStarling.antiAliasing = antiAliasing;
         _mStarling.addEventListener("rootCreated",(function():*
         {
            var onRootCreated:Function;
            return onRootCreated = function(event:Object, app:STLRootClass):void
            {
               STLConstant.currnetAppRoot = app;
               _mStarling.removeEventListener("rootCreated",onRootCreated);
               _mStarling.start();
               if(debug)
               {
                  _mStarling.showStatsAt("right");
               }
               app.start(mainClass);
               if(runMode == "software")
               {
                  SuperTextureAtlas.support = true;
               }
               else if(["baselineExtended","standardExtended"].indexOf(_mStarling.profile) != -1)
               {
               }
               restoreTextureUtils.initAssetses(Vector.<AssetManager>([DataCore.assetsMap.assets,DataCore.assetsSwf.otherAssets]));
               trace("baselineExtended","::",_mStarling.profile);
            };
         })());
         log("Scale:" + STLConstant.scale);
         log("StageWidth:" + STLConstant.StageWidth);
         log("StageHeight:" + STLConstant.StageHeight);
         log("WindowViewPort:" + viewPort);
         log("Starling.multitouchEnabled auto open");
         log("IsPc:" + _isPc);
         this.addEventListener("activate",onActivate);
         this.addEventListener("deactivate",onDeactivate);
         restoreTextureUtils = new RestoreTextureUtils(stage,_mStarling,loadContextImage);
      }

      public function calculateViewPort() : Rectangle //
      { //
         // 根据目标宽高比计算视口，实现黑边效果
         var screenWidth:Number = stage.stageWidth; //
         var screenHeight:Number = stage.stageHeight; //
         var screenAspectRatio:Number = screenWidth / screenHeight; //

         var viewPortWidth:Number; //
         var viewPortHeight:Number; //

         if (screenAspectRatio > _targetAspectRatio) //
         { //
            // 屏幕太宽，上下留黑边 (Letterboxing)
            viewPortHeight = screenHeight; //
            viewPortWidth = viewPortHeight * _targetAspectRatio; //
         } //
         else //
         { //
            // 屏幕太高，左右留黑边 (Pillarboxing)
            viewPortWidth = screenWidth; //
            viewPortHeight = viewPortWidth / _targetAspectRatio; //
         } //

         // 计算居中的位置
         var viewPortX:Number = (screenWidth - viewPortWidth) / 2; //
         var viewPortY:Number = (screenHeight - viewPortHeight) / 2; //

         return new Rectangle(viewPortX, viewPortY, viewPortWidth, viewPortHeight); //
      } //
      
      public function updateStarlingViewPort() : void //
      { //
         if(!_mStarling) //
         { //
            return; //
         } //
         var viewPort:Rectangle = calculateViewPort(); //
         _mStarling.viewPort = viewPort; //
         _mStarling.stage.stageWidth = STLConstant.StageWidth; //
         _mStarling.stage.stageHeight = STLConstant.StageHeight; //
         trace("updateStarlingViewPort"); //
         // trace("自动缩放更新:"); //
         // trace("当前窗口: " + stage.stageWidth + "x" + stage.stageHeight); //
         // trace("新视口: " + viewPort); //
         // trace("设计尺寸: " + STLConstant.StageWidth + "x" + STLConstant.StageHeight); //
      } //
      
      public function onActivate(event:Event) : void
      {
         if(GameCore.currentCore)
         {
            GameCore.currentCore.start();
            trace("onActivate"); //
         }
         if(!SystemUtil.isDesktop)
         {
            SoundMixer.soundTransform = new SoundTransform(_currentValue);
         }
      }
      
      public function onDeactivate(event:Event) : void
      {
         if(GameCore.currentCore)
         {
            GameCore.currentCore.stop();
            trace("onDeactivate"); //
         }
         if(!SystemUtil.isDesktop)
         {
            _currentValue = SoundMixer.soundTransform.volume;
            SoundMixer.soundTransform = new SoundTransform(0);
         }
      }
      
      public function set nativePath(str:String) : void
      {
         trace(str.split("/").join("\\"));
         str = str.split("\\").join("/");
         DataCore.webAssetsPath = str;
      }
      
      public function set testTmxPath(str:String) : void
      {
         testPath = str;
      }
      
      public function set viewRect(rect:Rectangle) : void
      {
         _viewRect = rect;
      }
      
      public function run(mapName:String, useRole:Array) : void
      {
         GameCore.currentCore.loadTMXMap(mapName,null);
      }
      
      public function set uesRole(str:String) : void
      {
         testRole = str;
      }
      
      public function set runderType(i:int) : void
      {
         switch(i)
         {
            case 0:
               testRunderType = "high";
               break;
            case 1:
               testRunderType = "medium";
               break;
            case 2:
               testRunderType = "low";
         }
      }
   }
}
