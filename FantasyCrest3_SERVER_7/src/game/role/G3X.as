// 添加G3X
package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import zygame.ai.AiHeart;
   import zygame.core.DataCore;
   import zygame.data.BeHitData;
   
   public class G3X extends GameRole
   {
      
      public function G3X(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
      }

      override public function onInit() : void
      {
         super.onInit();
         this.ai = true;
         this.setAi(new AiHeart(this,DataCore.getXml("ordinary")));
      }

      override public function onFrame():void
      {
         if(this.isKeyDown(65) || this.isKeyDown(68) || this.isKeyDown(87) || this.isKeyDown(83))
         {
            trace("isKeyDown");
            this.ai = false;
         }
         else
         {
            this.ai = true;
         }
         super.onFrame();
      }

      override public function onBeHit(beData:BeHitData) : void
      {
         super.onBeHit(beData);
         if (this.actionName == "当身" && this.frameAt(1,8))
         {
            this.clearDebuffMove();
            this.golden += 30;
            if(this.currentMp.value >= 1)
            {
               this.playSkill("吃瘪连续拳");
               this.currentMp.value -= 1;
            }
         }
      }

      override public function move(tag:String) : void
      {
         left = false;
         right = false;
         switch(tag)
         {
            case "left":
               left = true;
               break;
            case "right":
               right = true;
               break;
            case "wait":
         }
      }
      
   }
}

