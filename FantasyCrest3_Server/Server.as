// 独立游戏服务端主程序，从 FantasyCrest3_SERVER_7 中提取
package
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;
	import zygame.server.GameServer;

	public class Server extends Sprite
	{
		private static const MAX_LOG_LINES:int = 500;

		private var _logField:TextField;
		private var _logLines:Vector.<String>;

		public function Server()
		{
			super();
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.color = 0x1A1A2E;
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event) : void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			initUI();
			startServer();
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function initUI() : void
		{
			_logLines = new Vector.<String>();

			_logField = new TextField();
			_logField.defaultTextFormat = new TextFormat("_typewriter", 14, 0xE0E0E0);
			_logField.autoSize = TextFieldAutoSize.LEFT;
			_logField.multiline = true;
			_logField.wordWrap = true;
			_logField.width = stage.stageWidth;
			_logField.height = stage.stageHeight;
			_logField.x = 10;
			_logField.y = 10;
			addChild(_logField);

			var title:TextField = new TextField();
			title.defaultTextFormat = new TextFormat("_typewriter", 18, 0x4FC3F7, true);
			title.text = "FantasyCrest3 Game Server";
			title.x = 10;
			title.y = 10;
			title.autoSize = TextFieldAutoSize.LEFT;
			addChild(title);

			_logField.y = title.y + title.height + 10;
			_logField.height = stage.stageHeight - _logField.y - 10;
		}

		private function startServer() : void
		{
			var ip:String = "0.0.0.0";
			var port:int = 4888;

			log("=== FantasyCrest3 游戏服务端启动 ===");
			log("绑定地址: " + ip + ":" + port);

			// 输出本机IP信息
			displayLocalIPs();

			// 延迟启动以确保UI就绪
			setTimeout(function() : void
			{
				var server:GameServer = new GameServer(ip, port);
				server.logFunc = function(msg:String) : void
				{
					log(msg);
				};
				server.changeFunc = function() : void
				{
					updateStatus();
				};
				updateStatus();
			}, 200);
		}

		private function displayLocalIPs() : void
		{
			try
			{
				var netInfo:NetworkInfo = NetworkInfo.networkInfo;
				var interfaces:Vector.<NetworkInterface> = netInfo.findInterfaces();
				log("--- 本机网络接口 ---");
				for each(var iface:NetworkInterface in interfaces)
				{
					if(iface.active)
					{
						for each(var addr:String in iface.addresses)
						{
							if(addr.indexOf(".") != -1)
							{
								log("  " + iface.name + ": " + addr);
							}
						}
					}
				}
			}
			catch(e:Error)
			{
				log("无法获取网络接口信息: " + e.message);
			}
		}

		private function updateStatus() : void
		{
			if(GameServer.mServer)
			{
				log("[状态] 连接数: " + GameServer.mServer.connectCount + " | 房间数: " + GameServer.mServer.roomCount);
			}
		}

		private function onEnterFrame(e:Event) : void
		{
			if(GameServer.mServer)
			{
				GameServer.mServer.onFrame();
			}
		}

		private function log(msg:String) : void
		{
			trace(msg);
			if(!_logField)
			{
				return;
			}
			var line:String = "[" + getTimeString() + "] " + msg;
			_logLines.push(line);
			// 超过上限时裁剪旧日志，避免 TextField 文本无限膨胀导致渲染卡顿
			while(_logLines.length > MAX_LOG_LINES)
			{
				_logLines.shift();
			}
			_logField.text = _logLines.join("\n");
			_logField.scrollV = _logField.maxScrollV;
		}

		private function getTimeString() : String
		{
			var d:Date = new Date();
			var h:String = padZero(d.hours);
			var m:String = padZero(d.minutes);
			var s:String = padZero(d.seconds);
			return h + ":" + m + ":" + s;
		}

		private function padZero(n:int) : String
		{
			return n < 10 ? "0" + n : String(n);
		}
	}
}
