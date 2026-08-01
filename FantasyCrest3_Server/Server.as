// 独立游戏服务端主程序，从 FantasyCrest3_SERVER_7 中提取
package
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
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
		private var _userScrolledUp:Boolean = false; // 用户手动上翻时暂停自动滚动
		private var _lineCount:int = 0; // 累积行数，用于trim

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
			_logField.multiline = true;
			_logField.wordWrap = true;
			_logField.width = stage.stageWidth - 20;
			_logField.height = stage.stageHeight;
			_logField.x = 10;
			_logField.y = 10;
			_logField.background = true;
			_logField.backgroundColor = 0x1A1A2E;
			_logField.selectable = true;
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

			// 滚轮支持 + 用户上翻时暂停自动滚动
			_logField.addEventListener(Event.SCROLL, onLogScroll); //
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel); //
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
			var line:String = "[" + getTimeString() + "] " + msg + "\n";
			_logField.appendText(line); //
			_lineCount++; //
			// 超过上限时从顶部裁剪，避免 TextField 无限膨胀
			if(_lineCount > MAX_LOG_LINES) //
			{ //
				var excess:int = _lineCount - MAX_LOG_LINES; //
				var trimPos:int = 0; //
				for(var i:int = 0; i < excess; i++) //
				{ //
					trimPos = _logField.text.indexOf("\n", trimPos) + 1; //
				} //
				if(trimPos > 0) //
				{ //
					_logField.text = _logField.text.substring(trimPos); //
				} //
				_lineCount = MAX_LOG_LINES; //
			} //
			// 用户未上翻时自动滚到底部
			if(!_userScrolledUp) //
			{ //
				_logField.scrollV = _logField.maxScrollV; //
			} //
		}

		// 滚轮事件：分发到TextField
		private function onMouseWheel(e:MouseEvent) : void //
		{ //
			if(_logField.hitTestPoint(e.stageX, e.stageY)) //
			{ //
				_logField.scrollV -= e.delta * 3; //
			} //
		} //

		// 检测用户是否手动上翻
		private function onLogScroll(e:Event) : void //
		{ //
			_userScrolledUp = (_logField.scrollV < _logField.maxScrollV); //
		} //

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
