package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import feathers.data.ListCollection;
   
   public class LianLian extends GameRole
   {

      private var skillObj:Object = {"Shoot Back":"U","Reflex Radar":"SU","Fidgety Snatcher":"WU","Catch and Rose":"I","Shoot the Heart":"SI","Stingting Mind":"WJ","Push Upside Donw":"KSI","HELLO":"SJ","Bingo":"WI","LOVE":"KSU"};

      private var lastSkill:String = "";

      private var lastSkillResetTimer:int = 0;
      
      public function LianLian(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         this.listData = new ListCollection([{
            "icon":"mofa.png",
            "msg":""
         }]);
      }

      override public function onInit():void
      {
         super.onInit();
      }

      override public function onFrame():void
      {
         super.onFrame();
         if(lastSkillResetTimer > 0)
         {
            lastSkillResetTimer--;
            if(lastSkillResetTimer == 0 && lastSkill != "")
            {
               this.attribute.updateCD(lastSkill,0);
               lastSkill = "";
            }
         }
         if(lastSkill != "")
         {
            this.listData.getItemAt(0).msg = skillObj[lastSkill];

         }
         else
         {
            this.listData.getItemAt(0).msg = "";
         }
         this.listData.updateItemAt(0);
      }
      
      override public function runLockAction(str:String, canBreak:Boolean = false):void
      {
         super.runLockAction(str, canBreak);
         if(skillObj.hasOwnProperty(str))
         {
            lastSkill = str;
            lastSkillResetTimer = 120; // 重置被动计时
         }
      }
   }
}

