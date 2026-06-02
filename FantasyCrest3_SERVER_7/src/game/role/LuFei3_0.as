package game.role
{
   import feathers.data.ListCollection;
   import flash.geom.Rectangle;
   import zygame.buff.AttributeChangeBuff;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.display.BaseRole;
   import zygame.display.World;
   
   public class LuFei3_0 extends GameRole
   {
      
      public var attr:RoleAttributeData;
      
      private var _cd:int = 0;
      
      public function LuFei3_0(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"mingzhong.png",
            "msg":"auto"
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
         attr = new RoleAttributeData();
         this.addBuff(new AttributeChangeBuff("lufeibuff",this,-1,attr));
      }
      
      override public function onBeHit(beData:BeHitData) : void
      {
         _cd = 600;
         super.onBeHit(beData);
      }
      
      override public function onFrame() : void
      {
         var diren:BaseRole = null;
         super.onFrame();
         if(_cd <= 0)
         {
            attr.dodgeRate = 100;
            this.listData.getItemAt(0).msg = "auto";
         }
         else
         {
            _cd--;
            attr.dodgeRate = 1;
            this.listData.getItemAt(0).msg = (_cd / 60).toFixed(1);
         }
         this.listData.updateAll();
         if(frameAt(2,4) && this.currentGroup.key == "WJ")
         {
            go(5);
         }
         else if(inFrame("大猿王枪",11))
         {
            diren = this.findRole(new Rectangle(this.x - 500,this.y - 300,1000,600));
            if(diren)
            {
               this.posx = diren.posx;
               this.posy = diren.posy - 300;
            }
            else
            {
               this.posy -= 300;
            }
         }
      }
   }
}

