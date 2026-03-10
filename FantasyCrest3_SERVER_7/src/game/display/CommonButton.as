package game.display
{
   import game.uilts.GameFont;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.events.Touch;
   import starling.text.TextField;
   import starling.text.TextFormat;
   import zygame.core.DataCore;
   import zygame.display.TouchDisplayObject;
   
   public class CommonButton extends TouchDisplayObject
   {
      
      public var imageTarget:String;
      
      public var callBack:Function;
      
      public var imageDisplay:Image;
      
      public var textBind:TextField;
      
      public function CommonButton(pimageTarget:String, texturesName:String = "start_main", text:String = null)
      {
         var text2:TextField = null;
         super();
         imageTarget = pimageTarget;
         var image:Image = new Image(DataCore.getTextureAtlas(texturesName).getTexture(imageTarget));
         this.addChild(image);
         imageDisplay = image;
         this.isTouch = true;
         this.touchGroup = true;
         this.alignPivot();
         if(text != null)
         {
            text2 = new TextField(image.width,image.height,text,new TextFormat(GameFont.FONT_NAME,26,0));
            this.addChild(text2);
            textBind = text2;
         }
      }
      
      override public function onTouchBegin(touch:Touch) : void
      {
         Starling.juggler.tween(this,0.1,{"alpha":0.5});
         if(callBack != null && callBack.length >= 2) // 只有明确支持双参数的（虚拟按键）才触发按下
         { //
            callBack(textBind ? textBind.text : imageTarget, true); //
         } //
      }
      
      override public function onTouchEnd(touch:Touch) : void
      {
         Starling.juggler.tween(this,0.1,{"alpha":1});
         if(Boolean(callBack))
         {
            // try
            // {
            //    callBack();
            // }
            // catch(e:Error)
            // {
            //    trace(e.message);
            //    if(Boolean(callBack))
            //    {
            //       callBack(textBind ? textBind.text : imageTarget);
            //    }
            // }
            if(callBack.length >= 2) //
            { //
               callBack(textBind ? textBind.text : imageTarget, false); //
            } //
            else if(callBack.length == 1) //
            { //
               callBack(textBind ? textBind.text : imageTarget); //
            } //
            else //
            { //
               callBack(); // 主菜单、暂停界面等无参按钮，只走这一行，且只走一次
            } //
         }
      }
      
      override public function dispose() : void
      {
         super.dispose();
         this.callBack = null;
         imageDisplay = null;
         textBind = null;
      }
   }
}

