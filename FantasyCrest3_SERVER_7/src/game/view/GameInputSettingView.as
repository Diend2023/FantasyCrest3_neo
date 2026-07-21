// 新增手柄映射设置界面，用于自定义手柄输入控件映射
package game.view
{
	import feathers.controls.LayoutGroup;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	import feathers.layout.VerticalAlign;
	import game.uilts.GameFont;
	import starling.display.Button;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.text.TextField;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	import zygame.core.DataCore;
	import zygame.core.GamepadController;
	import zygame.core.SceneCore;
	import zygame.display.DisplayObjectContainer;
	import flash.net.SharedObject;

	public class GameInputSettingView extends DisplayObjectContainer
	{
		private static const SHARED_OBJECT_ID:String = "net.zygame.hxwz.air";

		// 映射项定义：{ id, label, defaultInput }  输入控件ID格式：BUTTON_N 或 AXIS_N+ / AXIS_N-
		private static const MAPPING_ITEMS:Array = [
			{id:"W1", label:"摇杆方向W1", defaultInput:"AXIS_1+"},
			{id:"A1", label:"摇杆方向A1", defaultInput:"AXIS_0-"},
			{id:"S1", label:"摇杆方向S1", defaultInput:"AXIS_1-"},
			{id:"D1", label:"摇杆方向D1", defaultInput:"AXIS_0+"},
			{id:"W2", label:"十字键方向W2", defaultInput:"BUTTON_16"},
			{id:"A2", label:"十字键方向A2", defaultInput:"BUTTON_18"},
			{id:"S2", label:"十字键方向S2", defaultInput:"BUTTON_17"},
			{id:"D2", label:"十字键方向D2", defaultInput:"BUTTON_19"},
			{id:"J",  label:"技能J", defaultInput:"BUTTON_4"},
			{id:"K",  label:"技能K", defaultInput:"BUTTON_5"},
			{id:"L",  label:"技能L", defaultInput:"BUTTON_9"},
			{id:"U",  label:"技能U", defaultInput:"BUTTON_6"},
			{id:"I",  label:"技能I", defaultInput:"BUTTON_7"},
			{id:"O",  label:"技能O", defaultInput:"BUTTON_8"},
			{id:"P",  label:"技能P", defaultInput:"BUTTON_11"},
			{id:"H",  label:"换人", defaultInput:"AXIS_3-"},
			{id:"Enter", label:"暂停", defaultInput:"BUTTON_13"},
			{id:"EX", label:"2P转换", defaultInput:"BUTTON_10"},
			{id:"Z",  label:"练习回血", defaultInput:""},
			{id:"X",  label:"练习回蓝", defaultInput:""},
			{id:"C",  label:"练习重置CD", defaultInput:""},
			{id:"V",  label:"练习AI", defaultInput:""}
		];

		// 当前正在设置的项目索引，-1表示无
		private var _settingIndex:int = -1;

		// 当前编辑中的映射 { id: "BUTTON_N" | "AXIS_N+/-" }
		private var _editMapping:Object;

		// 原始映射（取消时恢复）
		private var _originalMapping:Object;

		// 各项目的按键显示TextField引用
		private var _keyFields:Array;

		// 设置按钮引用数组
		private var _setButtons:Array;

		// 按钮纹理
		private var _btnSkin:Texture; //

		public function GameInputSettingView()
		{
			super();
		}

		override public function onInit():void
		{
			super.onInit();

			var bg:Quad = new Quad(stage.stageWidth, stage.stageHeight, 0x000000);
			this.addChild(bg);
			bg.alpha = 0.7;

			// 加载当前映射
			_editMapping = loadCurrentMapping();
			_originalMapping = GamepadController.cloneMapping(_editMapping); //

			_keyFields = [];
			_setButtons = [];
			_btnSkin = DataCore.getTextureAtlas("start_main").getTexture("btn_style_1"); //

			// 主容器
			var mainContainer:LayoutGroup = new LayoutGroup();
			var mainBg:Quad = new Quad(stage.stageWidth / 1.05, stage.stageHeight / 1.02, 0x000000); //
			mainBg.alpha = 0.7;
			mainContainer.layout = new VerticalLayout();
			(mainContainer.layout as VerticalLayout).gap = 6; //
			(mainContainer.layout as VerticalLayout).paddingTop = 8; //
			(mainContainer.layout as VerticalLayout).paddingBottom = 8; //
			(mainContainer.layout as VerticalLayout).paddingLeft = 10; //
			(mainContainer.layout as VerticalLayout).paddingRight = 10; //
			mainContainer.backgroundSkin = mainBg;
			mainContainer.width = mainBg.width;
			mainContainer.height = mainBg.height;
			this.addChild(mainContainer);
			mainContainer.validate();
			mainContainer.x = (stage.stageWidth - mainContainer.width) / 2;
			mainContainer.y = (stage.stageHeight - mainContainer.height) / 2;

			// 标题
			var titleFormat:TextFormat = new TextFormat(GameFont.FONT_NAME, 18, 0xE9A84C); //
			titleFormat.bold = true;
			var titleField:TextField = new TextField(mainContainer.width - 20, 24, "手柄按键映射设置", titleFormat); //
			mainContainer.addChild(titleField);

			// 表头格式（两个列共用）
			var hdrFormat:TextFormat = new TextFormat(GameFont.FONT_NAME, 12, 0xE9A84C); //
			hdrFormat.bold = true;

			// 双列容器
			var columnsRow:LayoutGroup = new LayoutGroup();
			var columnsHLayout:HorizontalLayout = new HorizontalLayout();
			columnsHLayout.gap = 30; //
			columnsRow.layout = columnsHLayout;

			var leftCol:LayoutGroup = new LayoutGroup();
			leftCol.layout = new VerticalLayout();
			(leftCol.layout as VerticalLayout).gap = 1; //
			leftCol.addChild(createHeaderRow(hdrFormat)); //
			columnsRow.addChild(leftCol);

			var rightCol:LayoutGroup = new LayoutGroup();
			rightCol.layout = new VerticalLayout();
			(rightCol.layout as VerticalLayout).gap = 1; //
			rightCol.addChild(createHeaderRow(hdrFormat)); //
			columnsRow.addChild(rightCol);

			var half:int = Math.ceil(MAPPING_ITEMS.length / 2); //
			for(var i:int = 0; i < MAPPING_ITEMS.length; i++)
			{
				var row:LayoutGroup = createMappingRow(MAPPING_ITEMS[i], i);
				if(i < half) //
					leftCol.addChild(row); //
				else //
					rightCol.addChild(row); //
			}
			mainContainer.addChild(columnsRow);

			// 底部按钮行
			var bottomContainer:LayoutGroup = new LayoutGroup();
			var bottomLayout:HorizontalLayout = new HorizontalLayout();
			bottomLayout.gap = 20; //
			bottomLayout.horizontalAlign = "center";
			bottomLayout.verticalAlign = VerticalAlign.MIDDLE;
			bottomLayout.paddingTop = 6; //
			bottomContainer.layout = bottomLayout;
			mainContainer.addChild(bottomContainer);

			var btnResetDefault:Button = new Button(_btnSkin, "恢复默认");
			btnResetDefault.textFormat.size = 16; //
			btnResetDefault.addEventListener("triggered", onResetDefault);
			bottomContainer.addChild(btnResetDefault);

			var btnSave:Button = new Button(_btnSkin, "保存");
			btnSave.textFormat.size = 16; //
			btnSave.addEventListener("triggered", onSave);
			bottomContainer.addChild(btnSave);

			var btnCancel:Button = new Button(_btnSkin, "取消");
			btnCancel.textFormat.size = 16; //
			btnCancel.addEventListener("triggered", onCancel);
			bottomContainer.addChild(btnCancel);

		}

		/** 创建表头行 */
		private function createHeaderRow(format:TextFormat):LayoutGroup //
		{ //
			var row:LayoutGroup = new LayoutGroup(); //
			var hLayout:HorizontalLayout = new HorizontalLayout(); //
			hLayout.gap = 6; //
			hLayout.verticalAlign = VerticalAlign.MIDDLE; //
			row.layout = hLayout; //
			var lbl1:TextField = new TextField(90, 18, "功能", format); //
			lbl1.touchable = false; //
			row.addChild(lbl1); //
			var lbl2:TextField = new TextField(72, 18, "手柄输入", format); //
			lbl2.touchable = false; //
			row.addChild(lbl2); //
			var sp:Quad = new Quad(90, 1, 0x000000); //
			sp.alpha = 0; //
			row.addChild(sp); //
			return row; //
		} //

		/**
		 * 创建单行映射条目： [功能名] [手柄输入值] [设置] [清空]
		 */
		private function createMappingRow(item:Object, index:int):LayoutGroup
		{
			var row:LayoutGroup = new LayoutGroup();
			var hLayout:HorizontalLayout = new HorizontalLayout();
			hLayout.gap = 6; //
			hLayout.verticalAlign = VerticalAlign.MIDDLE;
			row.layout = hLayout;
			row.name = "row_" + index;

			// 功能名
			var labelFormat:TextFormat = new TextFormat(GameFont.FONT_NAME, 13, 0xCCCCCC); //
			var labelField:TextField = new TextField(90, 22, item.label, labelFormat); //
			labelField.touchable = false;
			row.addChild(labelField);

			// 手柄输入值
			var inputStr:String = _editMapping[item.id] ? _editMapping[item.id] : "未设置";
			var inputFormat:TextFormat = new TextFormat(GameFont.FONT_NAME, 12, 0x55CCFF); //
			var inputField:TextField = new TextField(72, 22, inputStr, inputFormat); //
			inputField.touchable = false;
			row.addChild(inputField);
			_keyFields.push(inputField);

			// 设置/取消按钮
			var setBtn:Button = new Button(_btnSkin, "设置"); //
			setBtn.textFormat = new TextFormat(GameFont.FONT_NAME, 13, 0x000000); //
			setBtn.scaleX = 0.6; //
			setBtn.scaleY = 0.6; //
			setBtn.addEventListener("triggered", function(e:Event):void { onSetClick(index); });
			row.addChild(setBtn);
			_setButtons.push(setBtn);

			// 清空按钮
			var clearBtn:Button = new Button(_btnSkin, "清空"); //
			clearBtn.textFormat = new TextFormat(GameFont.FONT_NAME, 13, 0x000000); //
			clearBtn.scaleX = 0.6; //
			clearBtn.scaleY = 0.6; //
			clearBtn.addEventListener("triggered", function(e:Event):void { onClearClick(index); });
			row.addChild(clearBtn);

			return row;
		}

		/**
		 * 设置按钮点击：进入/取消捕获模式
		 */
		private function onSetClick(index:int):void
		{
			if(_settingIndex == index)
			{
				cancelSetting();
			}
			else
			{
				if(_settingIndex >= 0)
					cancelSetting();
				_settingIndex = index;
				updateSetButtonText(index, "取消");
				var inputField:TextField = _keyFields[index] as TextField;
				if(inputField)
					inputField.text = "按下按键...";
				GamepadController.startCapture(function(captured:String):void { onCaptured(captured); }); //
			}
		}

		/** 捕获回调 */
		private function onCaptured(inputId:String):void //
		{ //
			if(_settingIndex < 0) return; //
			var itemId:String = MAPPING_ITEMS[_settingIndex].id; //
			_editMapping[itemId] = inputId; //
			updateInputDisplay(_settingIndex, inputId); //
			cancelSetting(); //
		} //

		/**
		 * 清空按钮点击
		 */
		private function onClearClick(index:int):void
		{
			_editMapping[MAPPING_ITEMS[index].id] = "";
			updateInputDisplay(index, "");
			if(_settingIndex == index)
				cancelSetting();
		}

		/**
		 * 取消捕获模式
		 */
		private function cancelSetting():void
		{
			if(_settingIndex >= 0)
			{
				updateSetButtonText(_settingIndex, "设置");
				var itemId:String = MAPPING_ITEMS[_settingIndex].id;
				updateInputDisplay(_settingIndex, _editMapping[itemId]);
				_settingIndex = -1;
				GamepadController.stopCapture(); //
			}
		}

		/**
		 * 更新输入显示
		 */
		private function updateInputDisplay(index:int, value:String):void
		{
			var inputField:TextField = _keyFields[index] as TextField;
			if(inputField)
			{
				inputField.text = (value && value.length > 0) ? value : "未设置";
			}
		}

		/**
		 * 更新设置按钮文字
		 */
		private function updateSetButtonText(index:int, text:String):void
		{
			var btn:Button = _setButtons[index] as Button;
			if(btn)
				btn.text = text;
		}

		/**
		 * 恢复默认
		 */
		private function onResetDefault(e:Event):void
		{
			cancelSetting();
			_editMapping = {};
			for(var i:int = 0; i < MAPPING_ITEMS.length; i++)
			{
				_editMapping[MAPPING_ITEMS[i].id] = MAPPING_ITEMS[i].defaultInput;
			}
			refreshAllDisplays();
		}

		/**
		 * 保存
		 */
		private function onSave(e:Event):void
		{
			cancelSetting();
			saveMappingToSharedObject(_editMapping);
			GamepadController.applyMapping(_editMapping); //
			SceneCore.pushView(new GameTipsView("手柄映射已保存"));
			removeFromParent(true);
		}

		/**
		 * 取消
		 */
		private function onCancel(e:Event):void
		{
			cancelSetting();
			removeFromParent(true);
		}

		private function refreshAllDisplays():void
		{
			for(var i:int = 0; i < MAPPING_ITEMS.length; i++)
			{
				updateInputDisplay(i, _editMapping[MAPPING_ITEMS[i].id]);
			}
		}

		/**
		 * 从SharedObject加载当前映射
		 */
		public static function loadCurrentMapping():Object
		{
			var defaultMapping:Object = {};
			for(var i:int = 0; i < MAPPING_ITEMS.length; i++)
			{
				defaultMapping[MAPPING_ITEMS[i].id] = MAPPING_ITEMS[i].defaultInput;
			}

			try
			{
				var so:SharedObject = SharedObject.getLocal(SHARED_OBJECT_ID);
				if(so && so.data && so.data.settings && so.data.settings.gameInput)
				{
					var saved:Object = so.data.settings.gameInput;
					for(var key:String in defaultMapping)
					{
						if(saved[key] !== undefined && saved[key] !== null && String(saved[key]).length > 0)
						{
							defaultMapping[key] = saved[key];
						}
					}
				}
			}
			catch(err:Error)
			{
				trace("[GameInputSettingView] 加载映射失败:", err.message);
			}
			return defaultMapping;
		}

		/**
		 * 保存映射到SharedObject
		 */
		public static function saveMappingToSharedObject(mapping:Object):void
		{
			try
			{
				var so:SharedObject = SharedObject.getLocal(SHARED_OBJECT_ID);
				if(!so.data.settings)
					so.data.settings = {};
				so.data.settings.gameInput = mapping;
				so.flush();
			}
			catch(err:Error)
			{
				trace("[GameInputSettingView] 保存映射失败:", err.message);
			}
		}

		override public function dispose():void
		{
			cancelSetting();
			super.dispose();
		}
	}
}
