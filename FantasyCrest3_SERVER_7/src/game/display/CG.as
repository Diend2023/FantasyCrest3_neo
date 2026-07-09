// CG — 全屏播放 EffectDisplay，播放完毕自动关闭
package game.display
{
   import starling.events.Event;
   import zygame.core.SceneCore;
   import zygame.display.DisplayObjectContainer;
   import zygame.display.EffectDisplay;

   public class CG extends DisplayObjectContainer
   {
      private var _effect:EffectDisplay;

      public function CG(effect:EffectDisplay)
      {
         super();
         _effect = effect;
      }

      override public function onInit() : void
      {
         super.onInit();
         this.addChild(_effect);

         this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
         _effect.addEventListener(Event.REMOVED_FROM_STAGE, onEffectEnd);
      }

      private function onEnterFrame(e:Event) : void
      {
         _effect.onFrame();
      }

      private function onEffectEnd(e:Event) : void
      {
         this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
         _effect.removeEventListener(Event.REMOVED_FROM_STAGE, onEffectEnd);
         SceneCore.removeView(this);
      }
   }
}
