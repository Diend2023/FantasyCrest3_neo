// 添加麻将人的被动
package game.role
{
   import zygame.data.RoleAttributeData;
   import feathers.data.ListCollection;
   import zygame.display.World;
   
   public class MJMan extends GameRole
   {

      public function MJMan(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         listData = new ListCollection([{
         "icon":"cd_O_mp.png",
         "msg":"Off"
         }]);
      }
      
      override public function onInit() : void
      {
         super.onInit();
      }

      override public function onFrame() : void
      {
         super.onFrame();
         var skillL:int = this.attribute.getCD("瞬步");
         var skillU:int = this.attribute.getCD("九 莲 宝 灯");
         var skillSU:int = this.attribute.getCD("绿 一 色");
         var skillI:int = this.attribute.getCD("大 四 喜");
         var skillSI:int = this.attribute.getCD("国 士 无 双 十 三 面");
         if(skillL > 0 && skillU > 0 && skillSU > 0 && skillI > 0 && skillSI > 0)
         {
            if(this.currentMp.value == 10)
            {
               this.attribute.updateCD("四 暗 刻 单 骑", 0);
               listData.getItemAt(0).msg = "Ready";
            }
            else
            {
               this.attribute.updateCD("四 暗 刻 单 骑", 999);
               listData.getItemAt(0).msg = "Off";
            }
         }
         else
         {
            this.attribute.updateCD("四 暗 刻 单 骑", 999);
            listData.getItemAt(0).msg = "Off";
         }
         listData.updateItemAt(0);
      }
   }
}

