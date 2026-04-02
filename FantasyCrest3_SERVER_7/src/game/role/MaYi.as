// 添加夏目麻衣被动

package game.role
{
   import zygame.data.RoleAttributeData;
   import zygame.display.World;
   import feathers.data.ListCollection;
   import zygame.data.RoleFrameGroup;
   import zygame.data.BeHitData;
   
   public class MaYi extends GameRole
   {

      private static var _staticWjFrameGroup:RoleFrameGroup;
      private static var _staticKuFrameGroup:RoleFrameGroup;

      private var _isPowerMode:Boolean = false; // 是否处于高爆发模式
      
      public function MaYi(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         // 只要新对局读取到的技能数据不为空，就立刻刷新缓存（防止上一局结束时存留的是已经被引擎 dispose 销毁的旧对象）
         if(roleXmlData.roleFrameGroupActions.airActions["WJ"] != null) {
             _staticWjFrameGroup = roleXmlData.roleFrameGroupActions.airActions["WJ"];
         }
         if(roleXmlData.roleFrameGroupActions.airActions["U"] != null) {
             _staticKuFrameGroup = roleXmlData.roleFrameGroupActions.airActions["U"];
         }

         if(!_isPowerMode)
         {
            // 确保新建角色时恢复这两个动作
            this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = _staticWjFrameGroup;
            this.roleXmlData.roleFrameGroupActions.airActions["U"] = _staticKuFrameGroup;
         }
         listData = new ListCollection([{
            "icon":"sudu.png",
            "msg":"Ready"
         }]);
      }

      override public function onInit():void
      {
         super.onInit();
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
      }

      override public function hitDataBuff(beData:BeHitData) : void
      {
         super.hitDataBuff(beData);
         beData.invincibleGod = !_isPowerMode; // 高机动模式下无视无敌
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
            this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = null; // 移除高机动 WJ 绞杀
            this.roleXmlData.roleFrameGroupActions.airActions["U"] = null; // 移除高机动 KU 空猎
            switch(str)
            {
               case "高机动 WU 莲华":
                  this.actionName = "高爆发 WU";
                  this.attribute.updateCD("高机动 WU 莲华", 10);
                  break;
               case "高机动 U 横穿":
                  this.actionName = "高爆发 U";
                  this.attribute.updateCD("高机动 U 横穿", 8);
                  break;
               case "高机动 SU 血刃连斩":
                  this.actionName = "高爆发 SU";
                  this.attribute.updateCD("高机动 SU 血刃连斩", 9);
                  break;
               // case "高机动 KU 空猎":
               //    this.breakAction(); // 取消当前动作
               //    break;
               case "高机动 WI 上绞":
                  this.actionName = "高爆发 WI";
                  this.attribute.updateCD("高机动 WI 上绞", 10);
                  break;
               case "高机动 I 赤斩":
                  this.actionName = "高爆发 I";
                  this.attribute.updateCD("高机动 I 赤斩", 9);
                  break;
               case "高机动 SI 深红之狱":
                  this.actionName = "高爆发 SI";
                  this.attribute.updateCD("高机动 SI 深红之狱", 10);
                  break;
               case "高机动 WJ 绞杀":
                  this.actionName = "高爆发 WJ";
                  this.attribute.updateCD("高机动 WJ 绞杀", 8);
                  break;
               case "高机动 SJ 炽翼":
                  this.actionName = "高爆发 SJ";
                  this.attribute.updateCD("高机动 SJ 炽翼", 11);
            }
         }
         else
         {
            listData.getItemAt(0).icon = "sudu.png"; // 显示正常状态图标
            var wjAirAction:RoleFrameGroup = this.roleXmlData.roleFrameGroupActions.airActions["WJ"];
            var kuAirAction:RoleFrameGroup = this.roleXmlData.roleFrameGroupActions.airActions["U"];
            if(wjAirAction == null)
            {
               this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = _staticWjFrameGroup; // 恢复高机动 WJ 绞杀
            }
            if(kuAirAction == null)
            {
               this.roleXmlData.roleFrameGroupActions.airActions["U"] = _staticKuFrameGroup; // 恢复高机动 KU 空猎
            }
         }
         listData.updateItemAt(0); // 刷新列表显示
      }

      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         ob._isPowerMode = this._isPowerMode;
         return ob;
      }

      override public function setData(value:Object) : void
      {
         super.setData(value);
         _isPowerMode = value._isPowerMode;
         listData.getItemAt(0).icon = _isPowerMode ? "liliang.png" : "sudu.png"; // 根据高爆发模式状态显示不同图标
         listData.updateItemAt(0); // 刷新列表显示
         
         // 状态同步时，如果同步来的状态是高爆发，移除原本动作；否则若没有动作，为其恢复默认动作
         if(_isPowerMode)
         {
            this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = null;
            this.roleXmlData.roleFrameGroupActions.airActions["U"] = null;
         }
         else
         {
            if(this.roleXmlData.roleFrameGroupActions.airActions["WJ"] == null && _staticWjFrameGroup != null)
            {
               this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = _staticWjFrameGroup;
            }
            if(this.roleXmlData.roleFrameGroupActions.airActions["U"] == null && _staticKuFrameGroup != null)
            {
               this.roleXmlData.roleFrameGroupActions.airActions["U"] = _staticKuFrameGroup;
            }
         }
      }

      override public function dispose() : void
      {
         if (_staticWjFrameGroup != null) {
            this.roleXmlData.roleFrameGroupActions.airActions["WJ"] = _staticWjFrameGroup;
         }
         if (_staticKuFrameGroup != null) {
            this.roleXmlData.roleFrameGroupActions.airActions["U"] = _staticKuFrameGroup;
         }
         super.dispose();
      }

   }
}

