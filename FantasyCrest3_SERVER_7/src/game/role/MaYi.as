// 添加夏目麻衣被动

package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import feathers.data.ListCollection;
   import zygame.data.RoleFrameGroup;
   
   public class MaYi extends GameRole
   {

      private static var _wjFrameGroup:RoleFrameGroup;

      private static var _kuFrameGroup:RoleFrameGroup;

      private var _isPowerMode:Boolean = false; // 是否处于高爆发模式
      
      public function MaYi(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         _wjFrameGroup = roleXmlData.roleFrameGroupActions.airActions["WJ"];
         _kuFrameGroup = roleXmlData.roleFrameGroupActions.airActions["U"];
         listData = new ListCollection([{
            "icon":"sudu.png",
            "msg":"Ready"
         }]);
      }
      
	   override public function onFrame():void
      {
         super.onFrame();
         var cd:int = this.attribute.getCD("切换");
         var pCd:String = Number(cd / 60).toFixed(1); // 获取切换技能的CD，转换为秒并保留一位小数
         if(cd > 0)
         {
            listData.getItemAt(0).msg = pCd;
         }
         else
         {
            listData.getItemAt(0).msg = "Ready";
         }
         listData.updateItemAt(0);
         if(_isPowerMode)
         {

         }
         else
         {
         }
      }

	   override public function runLockAction(str:String, canBreak:Boolean = false) : void
      {
         super.runLockAction(str, canBreak);
         if(str == "切换" || str == "深红冥斩")
         {
            _isPowerMode = !_isPowerMode; // 切换高爆发模式状态
         }
         if(_isPowerMode)
         {
            listData.getItemAt(0).icon = "liliang.png"; // 显示高爆发状态图标
            // this.attribute.updateCD("高机动 KU 空猎", 999999); // 设置高机动 KU 空猎无法使用
            this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = null; // 移除高机动 WJ 绞杀
            this.roleXmlData.roleFrameGroupActions.airActions["U"] = null; // 移除高机动 KU 空猎
            switch(str)
            {
               case "高机动 WU 莲华":
                  this.actionName = "高爆发 WU";
                  break;
               case "高机动 U 横穿":
                  this.actionName = "高爆发 U";
                  break;
               case "高机动 SU 血刃连斩":
                  this.actionName = "高爆发 SU";
                  break;
               // case "高机动 KU 空猎":
               //    this.breakAction(); // 取消当前动作
               //    break;
               case "高机动 WI 上绞":
                  this.actionName = "高爆发 WI";
                  break;
               case "高机动 I 赤斩":
                  this.actionName = "高爆发 I";
                  break;
               case "高机动 SI 深红之狱":
                  this.actionName = "高爆发 SI";
                  break;
               case "高机动 WJ 绞杀":
                  this.actionName = "高爆发 WJ";
                  break;
               case "高机动 SJ 炽翼":
                  this.actionName = "高爆发 SJ";
            }
         }
         else
         {
            listData.getItemAt(0).icon = "sudu.png"; // 显示正常状态图标
            var wjAirAction:RoleFrameGroup = this.roleXmlData.roleFrameGroupActions.airActions["WJ"];
            var kuAirAction:RoleFrameGroup = this.roleXmlData.roleFrameGroupActions.airActions["U"];
            if(wjAirAction == null)
            {
               this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = _wjFrameGroup; // 恢复高机动 WJ 绞杀
            }
            if(kuAirAction == null)
            {
               this.roleXmlData.roleFrameGroupActions.airActions["U"] = _kuFrameGroup; // 恢复高机动 KU 空猎
            }
            // this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = _wjFrameGroup; // 恢复高机动 WJ 绞杀
            // this.roleXmlData.roleFrameGroupActions.airActions["U"] = _kuFrameGroup; // 恢复高机动 KU 空猎
            // this.attribute.updateCD("高机动 KU 空猎", 0); // 恢复高机动 KU 空猎的使用
         }
         listData.updateItemAt(0); // 刷新列表显示
      }

   }
}

