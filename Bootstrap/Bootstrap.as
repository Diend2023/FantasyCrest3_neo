// Bootstrap — 双层启动器入口，优先加载热更新的 WebRuntime.swf
package
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	public class Bootstrap extends Sprite
	{
		public function Bootstrap()
		{
			super();
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			var updated:File = File.applicationStorageDirectory.resolvePath("WebRuntime.swf");
			if(updated.exists)
			{
				trace("Bootstrap: 使用热更版 WebRuntime");
				loadSwf(updated.url);
			}
			else
			{
				trace("Bootstrap: 使用原始 WebRuntime");
				loadSwf("WebRuntime.swf");
			}
		}

		private function loadSwf(path:String):void
		{
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				var bytes:ByteArray = e.target.data as ByteArray;
				var ldr:Loader = new Loader();
				var con:LoaderContext = new LoaderContext();
				con.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain); //
				con.allowCodeImport = true; //
				ldr.loadBytes(bytes, con);
				addChild(ldr);
			});
			loader.load(new URLRequest(path));
		}
	}
}
