package game.view
{
   import game.uilts.GameFont;
   import starling.display.Button;
   import starling.display.Quad;
   import starling.events.Event;
   import starling.text.TextField;
   // 原本使用的是starling的TextField
   // import starling.text.TextFormat;
   import flash.text.TextFormat; // feathers的ScrollText使用的是flash的TextFormat
   import starling.textures.Texture;
   import zygame.core.DataCore;
   import zygame.core.SceneCore; // 导入SceneCore用于弹出提示
   import zygame.display.DisplayObjectContainer;
   import feathers.controls.ScrollText; // 使用feathers的ScrollText
   import game.uilts.Phone; // 导入Phone用于判断是否为手机版
   import zygame.server.Service; // 导入Service用于更新用户数据
   import flash.net.SharedObject; // 导入SharedObject用于更新缓存的用户数据
   import flash.net.navigateToURL; // 导入navigateToURL用于打开链接

   public class GameFPSTipsView extends DisplayObjectContainer
   {
      
      public function GameFPSTipsView()
      {
         super();
      }
      
      override public function onInit() : void
      {
         var bg:Quad;
         // 原本使用的是starling的TextField
         // var text:TextField;
         var text:ScrollText; // 使用feathers的ScrollText
         var skin:Texture;
         var button:Button;
         var button1:Button; // 版本介绍按钮
         var button2:Button; // 一键购买所有角色按钮
         var button3:Button; // 加入交流群按钮
         var button4:Button; // 官方网站按钮

         super.onInit();
         bg = new Quad(stage.stageWidth,stage.stageHeight,0);
         this.addChild(bg);
         bg.alpha = 0.7;
         // 原本设置的TextField
         // text = new TextField(stage.stageWidth - 100,stage.stageHeight - 100,"",new TextFormat(GameFont.FONT_NAME,18,16777215,"left"));
         text = new ScrollText(); // 调整高度以适应新增按钮
         text.textFormat = new TextFormat(GameFont.FONT_NAME,18,16777215); // feathers的ScrollText使用的是flash的TextFormat
         text.width = stage.stageWidth - 100; // 调整宽度
         text.height = stage.stageHeight - 200; // 调整高度
         text.verticalScrollPolicy = "on"; // 强制允许垂直滚动
         // 原本的提示文本
         // text.text = "关于游戏会卡的解决方案：\n掉帧的原因：\n游戏没有启动硬件加速，因此导致掉帧，只要开启硬件加速或者使用默认启动硬件加速的浏览器进行游戏即可得到流畅体验。\n\n方案1：\n1、选择Internet Explorer浏览器或者其他浏览器进行游戏。\n\n方案2：\n1、右键游戏窗口，点击设置。\n2、弹出小窗口后，选择最左边的选项，开启硬件加速。\n3、刷新页面重启游戏。\n4、如果失败，请转试用方案1。";
         text.isHTML = true; // 开启HTML格式支持
         text.text = "<font color='#FFDE00' size='22'><b>幻想纹章3V1.2</b></font><br><br><font color='#E8E8E8' size='18'>这是一个由多位幻想纹章爱好者共同协助逆向得到的版本。历时两个月的研究，我们终于得到一个可玩的版本</font><br><br><font color='#00FFCC' size='18'>感谢@IS 和@碎风 的指路<br>感谢@风吟棠华落 提供数据解密方法<br>感谢@忆雪 提供的角色指导<br>感谢@正义永无止境 提供真幻想纹章3本地版<br>感谢@桐 提供的最终更新缓存<br>感谢开源项目JPEXS对反编译工作的支持</font><br><br><font color='#FF5555' size='18'><b>再次感谢所有幻想纹章爱好者的支持，如果你不是免费得到的该版本，请立刻举报</b></font><br><br><font color='#44CCFF' size='18'>幻想纹章3交流群：<u><a href='https://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=NKKmX64I09HS90RrF-0lABHCy_Pbk-ZG&authKey=KcyDbNw%2F17UKTfofV1dm4KRyvuIz7r3KF3OfZk50SFjEYvgfk5RWAhLEHBMHEsT8&noverify=0&group_code=1055702064' target='_blank'><font color='#44CCFF'>1055702064</font></a></u><br>幻想纹章Club：<u><a href='https://hxwz3.cn' target='_blank'><font color='#44CCFF'>hxwz3.cn</font></a></u></font>"; // 修改为带有排版颜色的版本介绍
         this.addChild(text);
         text.y = 50; // 调整文本位置
         text.x = 50;
         skin = DataCore.getTextureAtlas("start_main").getTexture("btn_style_1");
         button = new Button(skin,"我知道了");
         this.addChild(button);
         button.textFormat.size = 18;
         button.x = stage.stageWidth / 2 - button.width / 2;
         button.y = stage.stageHeight - button.height * 2 - 16;
         button.addEventListener("triggered",function(e:Event):void
         {
            removeFromParent(true);
         });
         button1 = new Button(skin,"版本介绍"); // 添加版本介绍按钮
         this.addChild(button1); //
         button1.textFormat.size = 18; //
         button1.x = button.x + button1.width + 16; //
         button1.y = stage.stageHeight - button1.height * 2 - 16; //
         button1.addEventListener("triggered",function(e:Event):void //
         { //
            text.isHTML = true; //
            text.text = "<font color='#FFDE00' size='22'><b>=========== 幻想纹章3 V1.2 更新详情 ===========</b></font><br><br><font color='#00FFCC' size='20'><b>【本地版更新内容】</b></font><br><font color='#00FFCC'><b>[功能新增]</b></font><br>&nbsp;&nbsp;解密全部加密数据（纹4布罗利、纹4志志雄除外），兼容未加密数据加载<br>&nbsp;&nbsp;提供幻想纹章3角色查看器（tools文件夹中）<br>&nbsp;&nbsp;实现自定义创建局域网房间（支持ipv6直接联机）<br>&nbsp;&nbsp;允许观战位在角色选择界面鼠标操作<br>&nbsp;&nbsp;禁止观战位在角色选择界面锁定角色<br>&nbsp;&nbsp;设置支持保存到存档中，每次启动时自动启用设置<br>&nbsp;&nbsp;新增三个实验性设置：真全彩、抗锯齿、硬边缘<br>&nbsp;&nbsp;新增3个全局快捷键：F1（开启/关闭声音）、F5（开启/关闭BGM）、F11（开启/关闭全屏）<br><br><font color='#00FFCC'><b>[角色更新]</b></font><br>&nbsp;&nbsp;<b>夏目麻衣：</b>添加被动实现<br>&nbsp;&nbsp;<b>志志雄：</b>添加被动实现，添加P的效果为直接开启被动5S<br>&nbsp;&nbsp;<b>Weiss：</b>添加被动实现，WO最后一击增加X轴追踪，SI冷却时间7 -&gt; 10<br>&nbsp;&nbsp;<b>逢坂大河：</b>添加被动实现，添加瞬步，SJ，U，原先的U改为SU<br>&nbsp;&nbsp;<b>空条承太郎：</b>时停时关闭背景音乐逻辑优化（音量改为0 -&gt; 暂停BGM再恢复播放BGM）<br>&nbsp;&nbsp;<b>空我：</b>优化变身音效播放逻辑<br>&nbsp;&nbsp;<b>黑面：</b>修复被动显示错误<br>&nbsp;&nbsp;<b>纹4布罗利：</b>优化SL、WL释放方法，添加KWP和KSL冷却时间同步<br>&nbsp;&nbsp;<b>城户灰都：</b>削弱大部分技能伤害<br>&nbsp;&nbsp;<b>哈扎马：</b>被动伤害改为施加伤害，削弱大部分技能伤害<br>&nbsp;&nbsp;<b>波风水门：</b>P、WP冷却时间6 -&gt; 12并且消耗1水晶，SP冷却时间3 -&gt; 6，削弱部分技能伤害<br><br><font color='#FF5555'><b>[BUG修复]</b></font><br>&nbsp;&nbsp;修复除了1P以外角色均不重置连击数的问题<br><br><font color='#00FFCC' size='20'><b>【手机版更新内容】</b></font><br>&nbsp;&nbsp;与本地版1.2完全一致<br><font color='#00FFCC'><b>[额外更新]</b></font><br>&nbsp;&nbsp;虚拟按键添加L键位<br>&nbsp;&nbsp;虚拟按键支持上下滑动释放更多技能（例如上滑U释放WU）<br>&nbsp;&nbsp;优化虚拟按键触发逻辑（修复纹4布罗利普通攻击后续无法触发）"; //
         }); //
         button2 = new Button(skin,"一键购买所有角色"); // 添加一键购买所有角色按钮
         this.addChild(button2); //
         button2.textFormat.size = 18; //
         button2.x = button1.x + button2.width + 16; //
         button2.y = stage.stageHeight - button2.height * 2 - 16; //
         button2.addEventListener("triggered",function(e:Event):void //
         { //
            // if(Phone.isPhone()) //
            // { //
            //    var buys:Array = ["jianxin","anotherJX","zzx","weizhi","suolong","lufei","shanzhi","kawendixu","AS","hzluo","telankesi","wukong","BLUEGOKU","xiaolin","shalu","fls","jianxin","jianxin","anotherJX","zzx","weizhi","suolong","lufei","shanzhi","kawendixu","AS","hzluo","telankesi","wukong","BLUEGOKU","xiaolin","shalu","fls","buluoli","jianhun","bingjieshi","axiuluo","guijianshi","heianwushi","cike","manyou","mixieer","lanquan","Damotwo","shengzhidashu","huolongaisi","hfh","HML","yumingfangshoushi","JS","tongrendandao","yasina","youzi","xiaomeiyan","wbbd","shenzi","hchq","meihong","BL","Marisa","YL","yihushi","dongshilang","TOF","baimian","Twelve","Naruto","yuzhiboyou","anyou","jiaojiao","Kaixa","KW","shourenjialulu","SUN","naci","penhuolong","Tom","lvbu","anheimolong","qiyu","xiaoguai1","guangyuansu","guanggong","DCR","saber","CTZS","paojie","XC","Gudazi","RG","Ruimu","zhaomei","MH","LX","LXF","Ruler","KKR","baijin","SLK","xiaoli","zhouzuo","mayi","Es","AFTERdragon","heimian","HTZR","Hibiki","erqiao","pop","Nine","zhixubaimian","HZ","YXL","Ruby","ziwan","lian","JIN","Weiss","Blake","devilman","JO","NN","AZ","huajy","Linne","Yuz","Hyde","MJman","GFN","zhizhixiong","doge","huaji","hongguaiwu","JIN_old","BLL","beijita","wukongS","jifengzuo","jiuwei"]; // 一键购买所有角色的角色列表
            //    Service.userData.userData.buys = buys; // 购买所有角色
            //    SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; // 更新缓存的用户数据
            //    SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
            //    SceneCore.pushView(new GameTipsView("已购买所有角色")); // 弹出提示
            //    removeFromParent(true); //
            // } //
            // else
            // {
               removeFromParent(true);
               SceneCore.pushView(new GameTestView()); // 弹出一键购买所有角色测试视图
            // } //
         }); //
         button3 = new Button(skin,"加入交流群"); // 添加加入交流群按钮
         this.addChild(button3); //
         button3.textFormat.size = 18; //
         button3.x = button.x - button3.width - 16; //
         button3.y = stage.stageHeight - button3.height * 2 - 16; //
         button3.addEventListener("triggered",function(e:Event):void //
         { //
            navigateToURL(new flash.net.URLRequest("https://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=NKKmX64I09HS90RrF-0lABHCy_Pbk-ZG&authKey=KcyDbNw%2F17UKTfofV1dm4KRyvuIz7r3KF3OfZk50SFjEYvgfk5RWAhLEHBMHEsT8&noverify=0&group_code=1055702064"), "_blank");
         }); //
         button4 = new Button(skin,"官方网站"); // 添加官方网站按钮
         this.addChild(button4); //
         button4.textFormat.size = 18; //
         button4.x = button3.x - button4.width - 16; //
         button4.y = stage.stageHeight - button4.height * 2 - 16; //
         button4.addEventListener("triggered",function(e:Event):void //
         { //
            navigateToURL(new flash.net.URLRequest("https://hxwz3.cn"), "_blank");
         }); //
      }
   }
}

