package game.role
{
   import feathers.data.ListCollection;
   import zygame.data.BeHitData;
   import zygame.data.RoleAttributeData;
   import zygame.data.RoleFrameGroup;
   import zygame.display.BaseRole;
   import zygame.display.World;
   
   public class HeiMain extends GameRole
   {
      
      public static var EXMap:Object = {
         "U":5,
         "WI":2,
         "SU":3,
         "SI":4,
         "SI":1,
         "WU":7,
         "I":8,
         "O":9
      };
      
      private var _exs:Array = [];
      
      private var _isExO:Boolean = false;

      private var _exIndex:int = 1; // 当前EX计数位置(1~8)，onHitEnemy递增，iconTop跟随此位置 //
      
      public function HeiMain(roleTarget:String, xz:int, yz:int, pworld:World, fps:int = 24, pscale:Number = 1, troop:int = -1, roleAttr:RoleAttributeData = null)
      {
         super(roleTarget,xz,yz,pworld,fps,pscale,troop,roleAttr);
         // this.listData = new ListCollection([{
         //    "icon":"liliang.png",
         //    "msg":"1off"
         // }]);
         this.listData = new ListCollection([{ //
            "icon":"1close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40}, //
            "iconTop":{"name":"guang.png","width":30,"height":30} //
         }, //
         { //
            "icon":"2close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }, //
         { //
            "icon":"3close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }, //
         { //
            "icon":"4close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }, //
         { //
            "icon":"5close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }, //
         { //
            "icon":"6close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }, //
         { //
            "icon":"7close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }, //
         { //
            "icon":"8close.png", //
            "iconItem":{"width":30,"height":30}, //
            "bg":{"visible":false}, //
            "item":{"width":40,"height":40} //
         }]); //
      }
      
      override public function onHitEnemy(beData:BeHitData, enemy:BaseRole) : void
      {
         super.onHitEnemy(beData,enemy);
         // var data:int = int(this.listData.getItemAt(0).msg.charAt(0));
         // if(++data >= 9)
         // {
         //    data = 1;
         // }
         // this.listData.getItemAt(0).msg = data + (_exs.indexOf(data) == -1 ? "off" : "on");
         // this.listData.updateAll();
         _exIndex++; // 计数递增，到9回绕为1
         if(_exIndex >= 9) //
         { //
            _exIndex = 1; //
         } //
         updateEXDisplay(); // iconTop递增到下一格，已解锁图标保持open
      }

      private function updateEXDisplay():void // 根据当前EX状态与计数位置刷新8个图标显示
      { //
         if(!this.listData) //
         { //
            return; //
         } //
         var exs:Array = _exs is Array ? _exs : []; // 兜底：任何路径下_exs非数组时按空数组处理
         for(var i:int = 1; i <= 8; i++) //
         { //
            var item:Object = this.listData.getItemAt(i - 1); //
            item.icon = i + (exs.indexOf(i) == -1 ? "close" : "open") + ".png"; //
            item.iconTop = i == _exIndex ? {"name":"guang.png","width":30,"height":30} : null; //
         } //
         this.listData.updateAll(); //
      } //

      override public function playSkillFormKey(key:String) : void
      {
         // var data:int = 0;
         var data:int = _exIndex; // 计数器改为成员字段_exIndex，替代原msg文本解析
         var group2:RoleFrameGroup = null;
         var group:RoleFrameGroup = roleXmlData.getFrameGroupFromKey(key);
         // if(key == "P")
         if(key == "P" && this.attribute.getCD("武神") <= 0 && !_isExO) // 只能在未使用过ExO的情况下解锁EX
         {
            if(group && cheakCanPlay(key) && mandatorySkill > 0)
            {
               // data = int(this.listData.getItemAt(0).msg.charAt(0));
               if(data > 0 && data < 9 && _exs.indexOf(data) == -1)
               {
                  _exs.push(data);
                  if(_exs.length == 8)
                  {
                     _exs.push(9);
                  }
                  // this.listData.getItemAt(0).msg = data + (_exs.indexOf(data) == -1 ? "off" : "on");
                  // this.listData.updateAll();
                  updateEXDisplay(); // 当前格图标更新为open状态
               }
            }
         }
         else if(!_isExO)
         {
            group2 = roleXmlData.getFrameGroupFromKey(key + "2");
            if(group2 && cheakCanPlay(key) && _exs.indexOf(EXMap[key]) != -1)
            {
               this.attribute.updateCD(group.name,group.cd);
               key += "2";
               if(key == "O2")
               {
                  _isExO = true;
                  _exs = []; // 使用EX O后清除EX状态
                  updateEXDisplay(); // 全部8个图标回到close状态，iconTop递增照常
                  // this.listData.getItemAt(0).msg = data + (_exs.indexOf(data) == -1 ? "off" : "on"); //
                  // this.listData.updateAll(); //
               }
            }
         }
         super.playSkillFormKey(key);
      }
      
      override public function copyData() : Object
      {
         var ob:Object = super.copyData();
         // ob._exs = _exs;
         ob._exs = _exs.slice(); // 拷贝数组，避免联机/回放快照间共享引用被后续push污染基线
         ob._isExO = _isExO;
         ob._exIndex = _exIndex; // 计数位置同步，回滚/联机时图标状态不漂移
         return ob;
      }
      
      override public function setData(value:Object) : void
      {
         super.setData(value); // 必须先调基类：差分编码在基类内把缺失字段从_netLastFullData合并进value，之后才能读到完整数据
         if(!value._isExO) // 已使用过ExO后不再保留EX状态
         { //
            // this._exs = value._exs;
            this._exs = value._exs is Array ? value._exs.slice() : []; // 兼容缺失字段的旧数据(修复#1009)，并拷贝防止与快照共享引用
         } //
         else //
         { //
            this._exs = []; // 已使用ExO：房主端_exs已清空，本地残留的_exs必须同步清除，否则图标仍显示open
         } //
         this._isExO = value._isExO;
         // super.setData(value);
         this._exIndex = value._exIndex ? value._exIndex : 1; // 恢复计数位置，兼容无此字段的旧数据
         updateEXDisplay(); // 状态恢复后刷新图标显示
      }
   }
}

