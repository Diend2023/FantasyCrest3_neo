package zygame.core
{
   import flash.events.Event;
   import flash.media.Sound;
   import flash.media.SoundChannel;
   import flash.media.SoundMixer;
   import flash.media.SoundTransform;
   import flash.utils.Dictionary;
   import lzm.starling.swf.FPSUtil;
   
   public class SoundCore
   {
      
      public var fps:FPSUtil;
      
      private var _bgChannel:SoundChannel;
      
      private var _soundCount:int = 0;
      
      public var soundOld:Array;
      
      private var _currentBGSoundName:String;
      
      public var soundDic:Dictionary;
      
      private var _soundKeys:Vector.<Function>; // soundDic 的 Function 键列表，供 updateSound 索引遍历，避免 Dictionary 的 for-in

      public var bgPausePosition:Number = NaN; // 背景音乐暂停位置
      
      public function SoundCore()
      {
         super();
         soundOld = [];
         soundDic = new Dictionary();
         _soundKeys = new Vector.<Function>(); //
         fps = new FPSUtil(6);
      }
      
      public function playBGSound(target:String) : void
      {
         if(_bgChannel)
         {
            if(target == _currentBGSoundName)
            {
               if(!isNaN(bgPausePosition)) // 如果暂停位置不为NaN，说明音乐被暂停了，恢复播放
               { //
                  resumeBGSound(); //
               } //
               return;
            }
            _bgChannel.stop();
         }
         _currentBGSoundName = target;
         var sound:Sound = DataCore.getSound(target);
         if(sound)
         {
            _bgChannel = sound.play(0,99999,new SoundTransform(0.6));
            bgPausePosition = NaN; //
         }
         bgvolume = bgvolume;
         volume = volume;
      }

      public function pauseBGSound() : void //
      { //
         if(_bgChannel) //
         { //
            bgPausePosition = _bgChannel.position; //
            _bgChannel.stop(); //
         } //
      } //

public function resumeBGSound() : void //
{ //
   if(_bgChannel) //
   { //
      _bgChannel = null; //
   } //
   var sound:Sound = DataCore.getSound(_currentBGSoundName); //
   if(sound && !isNaN(bgPausePosition)) //
   { //
      var resumePos:Number = bgPausePosition; //
      bgPausePosition = NaN; //
      _bgChannel = sound.play(resumePos, 0, new SoundTransform(0.6)); //
      _bgChannel.addEventListener(Event.SOUND_COMPLETE, function(e:Event):void //
      { //
         _bgChannel = sound.play(0, 99999, new SoundTransform(0.6)); //
         bgvolume = bgvolume; //
         volume = volume; //
      }); //
   } //
   bgvolume = bgvolume; //
   volume = volume; //
} //
      
      public function playEffect(target:String, balance:Number = 0, ifFunc:Function = null) : SoundChannel
      {
         var v:Number;
         var sound:Sound;
         var channel:SoundChannel;
         if(volume == 0)
         {
            return null;
         }
         v = balance;
         if(v > 0)
         {
            v *= -1;
         }
         v = 1 + v;
         if(v < 0)
         {
            return null;
         }
         if(soundOld.indexOf(target) == -1)
         {
            soundOld.push(target);
            sound = DataCore.getSound(target);
            if(sound && sound.length > 0)
            {
               channel = sound.play();
               channel.soundTransform = new SoundTransform(v,balance);
               _soundCount++;
               channel.addEventListener("soundComplete",function(e:Event):void
               {
                  if(ifFunc != null)
                  {
                     delete soundDic[ifFunc];
                     var idx:int = _soundKeys.indexOf(ifFunc); // 同步移除键列表中的对应项
                     if(idx != -1) //
                     { //
                        _soundKeys.splice(idx,1); //
                     } //
                  }
                  _soundCount--;
               });
               if(ifFunc != null)
               {
                  soundDic[ifFunc] = channel;
                  _soundKeys.push(ifFunc); // 登记键，供 updateSound 索引遍历
               }
               return channel;
            }
            return null;
         }
         return null;
      }
      
      public function updateSound() : void
      {
         if(fps.update())
         {
            soundOld = [];
         }
         // for(var i in soundDic)
         // {
         //    if(i())
         //    {
         //       if((soundDic[i] as SoundChannel).soundTransform.volume > 0)
         //       {
         //          (soundDic[i] as SoundChannel).soundTransform = new SoundTransform((soundDic[i] as SoundChannel).soundTransform.volume - 0.05,(soundDic[i] as SoundChannel).soundTransform.pan);
         //       }
         //    }
         // }
         // Dictionary 的 for-in 每帧构造迭代器且 key 是 Function，改为索引遍历键列表
         // 复用 SoundTransform 并缓存 channel / soundTransform，原写法每帧每个声道新建对象且重复取值 3 次
         for(var i:int = 0; i < _soundKeys.length; ) //
         { //
            var key:Function = _soundKeys[i]; //
            var channel:SoundChannel = soundDic[key] as SoundChannel; //
            if(channel != null && key()) //
            { //
               var st:SoundTransform = channel.soundTransform; //
               if(st.volume > 0) //
               { //
                  st.volume = st.volume - 0.05; //
                  channel.soundTransform = st; //
               } //
            } //
            i++; //
         } //
      }
      
      public function get playSoundCount() : int
      {
         return _soundCount;
      }
      
      public function set pan(p:Number) : void
      {
         var v:* = p;
         if(v > 0)
         {
            v *= -1;
         }
         v = 1 + v;
         if(v < 0)
         {
            v = 0;
         }
         if(_bgChannel)
         {
            _bgChannel.soundTransform = new SoundTransform(v,p);
         }
      }
      
      public function set bgvolume(i:Number) : void
      {
         DataCore.updateValue("bg_sound_volume",i);
         DataCore.save();
         if(_bgChannel)
         {
            _bgChannel.soundTransform = new SoundTransform(i);
         }
      }
      
      public function get bgvolume() : Number
      {
         return DataCore.getNumber("bg_sound_volume",1);
      }
      
      public function set volume(i:Number) : void
      {
         DataCore.updateValue("sound_volume",i);
         DataCore.save();
         SoundMixer.soundTransform = new SoundTransform(volume);
      }
      
      public function get volume() : Number
      {
         return DataCore.getNumber("sound_volume",1);
      }
   }
}

