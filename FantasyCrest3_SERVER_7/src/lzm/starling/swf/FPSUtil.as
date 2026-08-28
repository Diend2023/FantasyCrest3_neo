package lzm.starling.swf
{
   import flash.utils.getTimer;
   
   public class FPSUtil
   {
      
      private var _fps:int;
      
      private var _fpsTime:Number;
      
      private var _currentTime:Number;
      
      private var _lastFrameTimestamp:Number;
      
      private var _pause:Boolean = false;
      
      // 固定时间步长（秒）：>0 时忽略 getTimer 真实时间，每次 update 注入固定时长
      // 用于让动画推进严格跟随逻辑帧，避免逻辑补帧时动画仍按真实时间只走一步而变慢
      public static var fixedDelta:Number = 0; //
      
      public function FPSUtil(fps:int)
      {
         super();
         this.fps = fps;
      }
      
      public function get fps() : int
      {
         return _fps;
      }
      
      public function set fps(value:int) : void
      {
         _fps = value;
         _fpsTime = 1000 / _fps * 0.001;
         _currentTime = 0;
         _lastFrameTimestamp = getTimer() / 1000;
      }
      
      public function update() : Boolean
      {
         if(_pause)
         {
            return false;
         }
         var now:Number = getTimer() / 1000;
         // var passedTime:Number = now - _lastFrameTimestamp;
         var passedTime:Number = fixedDelta > 0 ? fixedDelta : now - _lastFrameTimestamp; //
         _lastFrameTimestamp = now;
         _currentTime += passedTime;
         if(_currentTime >= _fpsTime)
         {
            _currentTime -= _fpsTime;
            if(_currentTime > _fpsTime)
            {
               _currentTime = 0;
            }
            return true;
         }
         return false;
      }
      
      public function pause() : void
      {
         _pause = true;
      }
      
      public function resume() : void
      {
         _pause = false;
      }
   }
}

