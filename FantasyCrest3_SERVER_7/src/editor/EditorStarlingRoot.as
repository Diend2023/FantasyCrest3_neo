package editor
{
    import flash.filesystem.File;

    import parser.Script;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.utils.EncodeAssets;

    import zygame.core.DataCore;
    import zygame.core.GameCore;
    import zygame.core.SoundCore;
    import zygame.data.GameFightData;
    import zygame.display.BaseRole;
    import zygame.display.DisplayObjectContainer;
    import zygame.display.SpriteRole;
    import zygame.display.World;
    import zygame.event.GameMapHitType;

    /**
     * 角色编辑器的 Starling 根节点。
     * 负责伪造游戏核心环境，加载并展示指定角色。
     */
    public class EditorStarlingRoot extends Sprite
    {
        /** 固定资源根目录：applicationDirectory 的上两级目录 */

        private var _infoText:TextField;
        private var _role:BaseRole;
        private var _gameRoot:File;

        public function EditorStarlingRoot()
        {
            super();
        }

        /** 由 EditorMain 在 ROOT_CREATED 后调用，启动编辑器流程。 */
        public function startEditor():void
        {
            _infoText = new TextField(1000, 40, "正在初始化编辑器环境...");
            _infoText.format.setTo("Arial", 14, 0xFFFFFF);
            _infoText.x = 20;
            _infoText.y = 20;
            this.addChild(_infoText);

            setupEnvironment();
        }

        // ----------------------------------------------------------------
        //  环境初始化
        // ----------------------------------------------------------------

        /**
         * 伪造游戏核心依赖，使 BaseRole 可在脱离完整游戏的情况下正常实例化。
         */
        private function setupEnvironment():void
        {
            setupPathConversion();
            setupScriptVM();
            setupDataCore();
            setupGameCore();
            setupWorld();

            loadRole("jianxin");
        }

        /**
         * 拦截 AssetManager 的路径解析，将 app:/ 相对路径转换为
         * 基于 GAME_ROOT 的绝对 file:// 路径。
         */
        private function setupPathConversion():void
        {
            if (EncodeAssets.loadPathConversion != null) return;

            EncodeAssets.loadPathConversion = function(url:String):String
            {
                // 屏蔽空请求
                if (!url || url == "" || url == "/" || url == "app:/" || url == "app://")
                    return "dummy.xml";

                // 已是绝对 file:// 路径，直接返回
                if (url.indexOf("file://") != -1)
                    return url;

                // 去掉 app:/ 前缀和多余斜杠，得到相对路径
                var rel:String = url;
                if (rel.indexOf("app:/") == 0)
                    rel = rel.replace("app:/", "");
                while (rel.charAt(0) == "/")
                    rel = rel.substr(1);

                if (rel == "")
                    return "dummy.xml";

                // 先在游戏资源目录下查找
                var target:File = new File(pathJoin(getGameRoot().nativePath, rel));
                if (target.exists && !target.isDirectory)
                    return target.url;

                // 末尾是 / 表示目录请求，忽略
                if (url.charAt(url.length - 1) == "/")
                    return "dummy.xml";

                return url;
            };
        }

        /**
         * 初始化 AScript 脚本虚拟机（Script.vm）。
         * 须传入拥有有效 loaderInfo 的原生 Sprite 根节点。
         */
        private function setupScriptVM():void
        {
            if (Script.vm != null) return;
            var nativeRoot:* = Starling.current.nativeStage.getChildAt(0);
            Script.init(nativeRoot);
        }

        /**
         * 初始化 DataCore：资源管理器、空 fightData（供 RoleAttributeData 读取）。
         */
        private function setupDataCore():void
        {
            DataCore.init(Starling.current.nativeStage);
            DataCore.webAssetsPath = "";

            if (DataCore.assetsRole == null)
                DataCore.initData();

            if (DataCore.fightData == null)
                DataCore.fightData = new GameFightData(new XML("<fightdata><init></init></fightdata>"));
        }

        /**
         * 初始化 GameCore 单例（含 SoundCore）。
         */
        private function setupGameCore():void
        {
            new GameCore(null, Starling.current.nativeStage, null, Starling.current.nativeStage);
            GameCore.soundCore = new SoundCore();
        }

        /**
         * 创建一个空白的虚拟世界并设置为当前世界。
         * 禁用 drawRect 裁剪检测，防止未挂载地图时 intersects 报 #1009。
         */
        private function setupWorld():void
        {
            DisplayObjectContainer.disableIFMustDraw = true;

            var world:World = new World("map1", "jianxin");
            world.runModel = new DummyRunModel();
            GameCore.currentWorld = world;
        }

        // ----------------------------------------------------------------
        //  角色加载
        // ----------------------------------------------------------------

        /**
         * 加载指定角色的资源包（.data 文件）。
         * @param roleName  角色名，对应 GAME_ROOT/role/<roleName>.data
         */
        private function loadRole(roleName:String):void
        {
            var dataFile:File = new File(pathJoin(getGameRoot().nativePath, "role/" + roleName + ".data"));

            if (!dataFile.exists)
            {
                _infoText.text = "错误：找不到角色资源\n"
                    + dataFile.nativePath
                    + "\nappDir=" + File.applicationDirectory.nativePath
                    + "\nroot=" + getGameRoot().nativePath;
                return;
            }

            _infoText.text = "正在加载: " + roleName;
            DataCore.assetsRole.load(dataFile.url);
            DataCore.assetsRole.start(function(progress:Number):void
            {
                if (progress < 1)
                {
                    _infoText.text = "资源加载中: " + int(progress * 100) + "%";
                }
                else
                {
                    _infoText.text = "加载完成，实例化角色...";
                    showRole(roleName);
                }
            });
        }

        /**
         * 返回游戏资源根目录（固定相对路径，不做自动探测）。
         */
        private function getGameRoot():File
        {
            if (_gameRoot && _gameRoot.exists)
                return _gameRoot;

            // 固定规则：.../tools/FantasyCrest3_Editor -> 去掉该后缀得到 FantasyCrest3_neo
            var appDir:File = File.applicationDirectory;
            var appPath:String = appDir.nativePath;
            var normPath:String = appPath.replace(/\\/g, "/");
            var marker:String = "/tools/FantasyCrest3_Editor";
            var markerIndex:int = normPath.indexOf(marker);

            if (markerIndex >= 0)
            {
                _gameRoot = new File(normPath.substring(0, markerIndex));
            }
            else if (appDir && appDir.parent && appDir.parent.parent)
            {
                _gameRoot = appDir.parent.parent;
            }
            else
            {
                _gameRoot = appDir;
            }

            return _gameRoot;
        }

        private function pathJoin(basePath:String, relativePath:String):String
        {
            var left:String = basePath.replace(/\\/g, "/");
            var right:String = relativePath.replace(/\\/g, "/");
            if (left.charAt(left.length - 1) == "/")
                left = left.substr(0, left.length - 1);
            while (right.charAt(0) == "/")
                right = right.substr(1);
            return left + "/" + right;
        }

        /**
         * 实例化角色并添加到舞台，播放待机动作。
         */
        private function showRole(roleName:String):void
        {
            try
            {
                _role = new SpriteRole(roleName, 0, 0, GameCore.currentWorld, 24, 1);
                _role.ai    = false; // 编辑器模式禁用 AI
                _role.x     = 640;
                _role.y     = 500;
                _role.mapHitType = GameMapHitType.HIT;
                _role.jumpBoolean = false;
                _role.jumpMath = 0;
                this.addChild(_role);

                _role.action = "待机";
                _infoText.text = roleName + " 加载成功";

                Starling.current.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                Starling.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
            catch (e:Error)
            {
                _infoText.text = "实例化失败: " + e.message + "\n" + e.getStackTrace();
            }
        }

        // ----------------------------------------------------------------
        //  帧循环
        // ----------------------------------------------------------------

        private function onEnterFrame(e:EnterFrameEvent):void
        {
            if (_role)
            {
                // 编辑器没有真实地图碰撞，强制角色保持“着地”状态，避免动作机切到“降落”
                _role.mapHitType = GameMapHitType.HIT;
                _role.jumpBoolean = false;
                _role.jumpMath = 0;

                _role.onFrame();
                // if (_role.actionName == "降落" || _role.actionName == "跳跃")
                //     _role.action = "普通攻击";

                trace(_role.x, _role.y, _role.actionName, _role.currentFrame);
            }
        }
    }
}
