package
{
    import flash.display.Sprite;
    import flash.events.Event;

    import starling.core.Starling;
    import starling.events.Event;

    import editor.EditorStarlingRoot;

    [SWF(frameRate="60", width="1280", height="720", backgroundColor="#333333")]
    public class EditorMain extends Sprite
    {
        private var _starling:Starling;

        public function EditorMain()
        {
            super();
            if (this.stage)
                init();
            else
                this.addEventListener(flash.events.Event.ADDED_TO_STAGE, init);
        }

        private function init(e:flash.events.Event = null):void
        {
            this.removeEventListener(flash.events.Event.ADDED_TO_STAGE, init);

            this.stage.scaleMode = "noScale";
            this.stage.align     = "topLeft";

            _starling = new Starling(EditorStarlingRoot, this.stage);
            _starling.showStats = true;
            _starling.addEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            _starling.start();
        }

        private function onRootCreated(e:starling.events.Event):void
        {
            _starling.removeEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            (_starling.root as EditorStarlingRoot).startEditor();
        }
    }
}
