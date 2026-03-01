package editor
{
    import starling.display.DisplayObject;

    import zygame.display.BaseRole;
    import zygame.display.EffectDisplay;
    import zygame.display.RefRole;
    import zygame.display.World;
    import zygame.run.IRunModel;

    /**
     * IRunModel 的空实现，用于编辑器模式。
     * onEffectPasing 返回 true，跳过角色特效的地图挂载逻辑，
     * 防止 World 未加载地图时出现空指针异常。
     */
    public class DummyRunModel implements IRunModel
    {
        public function DummyRunModel() {}

        public function message(world:World, data:Object)               : void    {}
        public function onDown(key:int)                                 : Boolean { return false; }
        public function onUp(key:int)                                   : Boolean { return false; }
        public function onFrame()                                       : Boolean { return false; }
        public function onFrameOver()                                   : Boolean { return false; }
        public function onKillRole(role:BaseRole)                       : Boolean { return false; }
        public function onAddChild(display:DisplayObject)               : void    {}
        public function onRoleFrame(role:RefRole)                       : Boolean { return false; }
        public function onEffectPasing(effects:Array)                   : Boolean { return true;  }
        public function onEffectFrame(effect:EffectDisplay)             : Boolean { return false; }
        public function onMiss(role:BaseRole)                           : Boolean { return false; }
        public function onHurt(role:BaseRole, damage:int)               : Boolean { return false; }
        public function onCDChange(role:BaseRole, skillName:String)     : void    {}
    }
}
