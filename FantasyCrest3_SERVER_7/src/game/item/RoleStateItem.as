package game.item
{
   import feathers.controls.Label;
   import starling.display.Image;
   import starling.text.TextFormat;
   import zygame.core.DataCore;
   import zygame.display.BaseItem;
   import starling.textures.Texture; //
   import starling.display.DisplayObject; //
   import starling.display.Sprite; //
   
   public class RoleStateItem extends BaseItem
   {
      
      private var _icon:Image;
      
      private var _lable:Label;

      private var _bg:Image; //

      private var _iconTop:Image; //
      
      private var _iconBottom:Image; //

      private var _lableHolder:Sprite; // 文字容器，2P镜像环境下由容器翻转，Label本体保持scaleX=1
      
      public function RoleStateItem()
      {
         super();
         this.width = 100;
         this.height = 20;
         var bg:Image = new Image(DataCore.getTextureAtlas("hpmp").getTexture("state.png"));
         this.addChild(bg);
         _bg = bg; //
         _lable = new Label();
         // _lable.fontStyles = new TextFormat("mini",16,16777215);
         _lable.fontStyles = new TextFormat("RoleStateItem_font",16,16777215); // 使用新的位图字体
         // _lable.x = 24;
         _lable.x = 0; // 文字改由_lableHolder容器承载定位，Label自身不再参与翻转
         _lable.y = 3;
         _lable.width = bg.width - 26;
         // this.addChild(_lable);
         _lableHolder = new Sprite(); // 新增：普通starling容器，负责x定位与2P镜像翻转，规避Feathers验证期宽度为负的问题
         _lableHolder.addChild(_lable); //
         this.addChild(_lableHolder); //
         _lableHolder.x = 24; //
      }
      
      override public function set data(value:Object) : void
      {
         if(value)
         {
            if(!_icon)
            {
               _icon = new Image(DataCore.getTextureAtlas("hpmp").getTexture(value.icon));
               this.addChild(_icon);
               _icon.width = 20;
               _icon.height = 20;
               _icon.x = 2;
               _icon.y = 2;
            }
            else
            {
               _icon.texture = DataCore.getTextureAtlas("hpmp").getTexture(value.icon);
            }
            _lable.text = value.msg is cint ? value.msg.value : value.msg;
            if(value.item) //
            { //
               if(value.item.width && value.item.width is int) //
               { //
                  this.width = value.item.width; //
               } //
               if(value.item.height && value.item.height is int) //
               { //
                  this.height = value.item.height; //
               } //
            } //
            if(value.bg) //
            { //
               if(value.bg.width && value.bg.width is int) //
               { //
                  _bg.width = value.bg.width; //
               } //
               if(value.bg.height && value.bg.height is int) //
               { //
                  _bg.height = value.bg.height; //
               } //
               if(value.bg.scale != null && value.bg.scale is Number) //
               { //
                  _bg.scale = value.bg.scale; //
               } //
               if(value.bg.visible != null && value.bg.visible is Boolean) //
               { //
                  _bg.visible = value.bg.visible; //
               } //
            } //
            if(value.iconItem) //
            { //
               if(value.iconItem.width && value.iconItem.width is int) //
               { //
                  _icon.width = value.iconItem.width; //
               } //
               if(value.iconItem.height && value.iconItem.height is int) //
               { //
                  _icon.height = value.iconItem.height; //
               } //
               if(value.iconItem.scale && value.iconItem.scale is Number) //
               { //
                  _icon.scale = value.iconItem.scale; //
               } //
            } //
            if(value.lable) //
            { //
               if(value.lable.width && value.lable.width is int) //
               { //
                  _lable.width = value.lable.width; //
               } //
               if(value.lable.height && value.lable.height is int) //
               { //
                  _lable.height = value.lable.height; //
               } //
            } //
            if(value.iconTop != null) //
            { //
               if(value.iconTop.name != null && _icon) //
               { //
                  var topTexture:Texture = DataCore.getTextureAtlas("hpmp").getTexture(value.iconTop.name); //
                  if(!_iconTop) //
                  { //
                     _iconTop = new Image(topTexture); //
                     _iconTop.width = _icon.width; //
                     _iconTop.height = _icon.height; //
                     _iconTop.x = _icon.x; //
                     _iconTop.y = _icon.y; //
                     this.addChild(_iconTop); //
                  } //
                  else //
                  { //
                     _iconTop.texture = topTexture; //
                     if(value.iconTop.width && value.iconTop.width is int) //
                     { //
                        _iconTop.width = value.iconTop.width; //
                     } //
                     if(value.iconTop.height && value.iconTop.height is int) //
                     { //
                        _iconTop.height = value.iconTop.height; //
                     } //
                     if(value.iconTop.scale && value.iconTop.scale is Number) //
                     { //
                        _iconTop.scale = value.iconTop.scale; //
                     } //
                     if(value.iconTop.visible != null && value.iconTop.visible is Boolean) //
                     { //
                        _iconTop.visible = value.iconTop.visible; //
                     } //
                  } //
               } //
            } //
            else //
            { //
               if(_iconTop) //
               { //
                  _iconTop.removeFromParent(true); //
                  _iconTop = null; //
               } //
            } //
            if(value.iconBottom != null) //
            { //
               if(value.iconBottom.name != null && _icon) //
               { //
                  var bottomTexture:Texture = DataCore.getTextureAtlas("hpmp").getTexture(value.iconBottom.name); //
                  if(!_iconBottom) //
                  { //
                     _iconBottom = new Image(bottomTexture); //
                     _iconBottom.width = _icon.width; //
                     _iconBottom.height = _icon.height; //
                     _iconBottom.x = _icon.x; //
                     _iconBottom.y = _icon.y; //
                     this.addChildAt(_iconBottom, 0); //
                  } //
                  else //
                  { //
                     _iconBottom.texture = bottomTexture; //
                     if(value.iconBottom.width && value.iconBottom.width is int) //
                     { //
                        _iconBottom.width = value.iconBottom.width; //
                     } //
                     if(value.iconBottom.height && value.iconBottom.height is int) //
                     { //
                        _iconBottom.height = value.iconBottom.height; //
                     } //
                     if(value.iconBottom.scale && value.iconBottom.scale is Number) //
                     { //
                        _iconBottom.scale = value.iconBottom.scale; //
                     } //
                     if(value.iconBottom.visible != null && value.iconBottom.visible is Boolean) //
                     { //
                        _iconBottom.visible = value.iconBottom.visible; //
                     } //
                  } //
               } //
            } //
            else //
            { //
               if(_iconBottom) //
               { //
                  _iconBottom.removeFromParent(true); //
                  _iconBottom = null; //
               } //
            } //
            var psign:Number = 1; // 沿父级链累计缩放符号，检测当前是否处于镜像容器(如2P血条)；放在末尾确保宽度已确定
            var pobj:DisplayObject = this.parent; //
            while(pobj) //
            { //
               psign *= pobj.scaleX < 0 ? -1 : 1; //
               pobj = pobj.parent; //
            } //
            _lableHolder.scaleX = 1; // 归位后取宽度，starling的bounds宽度恒为正值，不受Feathers验证影响
            var lwidth:Number = _lableHolder.width; //
            if(psign < 0) //
            { //
               _lableHolder.scaleX = -1; // 翻转容器而非Label本体，Label保持scaleX=1使Feathers验证正常
               _lableHolder.x = 24 + lwidth; // scaleX=-1围绕左边缘翻转，补偿一个宽度使文字回到原区域[24,24+width]
            } //
            else //
            { //
               _lableHolder.x = 24; //
            } //
         }
      }
   }
}

