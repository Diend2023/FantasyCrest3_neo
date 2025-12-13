// 添加志志雄真实(纹4)的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import starling.core.Starling;
   
   public class ZhiZhiXiong extends GameRole
   {
      
      public function ZhiZhiXiong(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }
      
      override public function onInit() : void
      {
         super.onInit();
         Starling.juggler.delayCall(function():void
         {
            attribute.hp -= attribute.hpmax;
         },50);
      }
   }
}

