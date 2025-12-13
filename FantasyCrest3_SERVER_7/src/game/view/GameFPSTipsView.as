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
         var button1:Button; // 一键购买所有角色按钮
         var button2:Button; // 版本介绍按钮
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
         // 原本的提示文本
         // text.text = "关于游戏会卡的解决方案：\n掉帧的原因：\n游戏没有启动硬件加速，因此导致掉帧，只要开启硬件加速或者使用默认启动硬件加速的浏览器进行游戏即可得到流畅体验。\n\n方案1：\n1、选择Internet Explorer浏览器或者其他浏览器进行游戏。\n\n方案2：\n1、右键游戏窗口，点击设置。\n2、弹出小窗口后，选择最左边的选项，开启硬件加速。\n3、刷新页面重启游戏。\n4、如果失败，请转试用方案1。";
         text.text = "幻想纹章3本地版0.9\n\n这是一个由多位幻想纹章爱好者共同协助逆向得到的版本。历时两个月的研究，我们终于得到一个可玩的版本\n\n感谢@IS 和@碎风 的指路，感谢@风吟棠华落 提供数据解密方法，感谢@忆雪 提供的角色指导，感谢@正义永无止境 提供真幻想纹章3本地版，感谢@桐 提供的最终更新缓存\n\n再次感谢所有幻想纹章爱好者的支持，如果你不是免费得到的该版本，请立刻举报\n\n幻想纹章3交流群：1055702064"; // 修改为版本介绍
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
         button1 = new Button(skin,"一键购买所有角色"); // 添加一键购买所有角色按钮
         this.addChild(button1); //
         button1.textFormat.size = 18; //
         button1.x = button.x - button1.width - 16; //
         button1.y = stage.stageHeight - button1.height * 2 - 16; //
         button1.addEventListener("triggered",function(e:Event):void //
         { //
            if(Phone.isPhone()) //
            { //
               var buys:Array = ["jianxin","anotherJX","zzx","weizhi","suolong","lufei","shanzhi","kawendixu","AS","hzluo","telankesi","wukong","BLUEGOKU","xiaolin","shalu","fls","jianxin","jianxin","anotherJX","zzx","weizhi","suolong","lufei","shanzhi","kawendixu","AS","hzluo","telankesi","wukong","BLUEGOKU","xiaolin","shalu","fls","buluoli","jianhun","bingjieshi","axiuluo","guijianshi","heianwushi","cike","manyou","mixieer","lanquan","Damotwo","shengzhidashu","huolongaisi","hfh","HML","yumingfangshoushi","JS","tongrendandao","yasina","youzi","xiaomeiyan","wbbd","shenzi","hchq","meihong","BL","Marisa","YL","yihushi","dongshilang","TOF","baimian","Twelve","Naruto","yuzhiboyou","anyou","jiaojiao","Kaixa","KW","shourenjialulu","SUN","naci","penhuolong","Tom","lvbu","anheimolong","qiyu","xiaoguai1","guangyuansu","guanggong","DCR","saber","CTZS","paojie","XC","Gudazi","RG","Ruimu","zhaomei","MH","LX","LXF","Ruler","KKR","baijin","SLK","xiaoli","zhouzuo","mayi","Es","AFTERdragon","heimian","HTZR","Hibiki","erqiao","pop","Nine","zhixubaimian","HZ","YXL","Ruby","ziwan","lian","JIN","Weiss","Blake","devilman","JO","NN","AZ","huajy","Linne","Yuz","Hyde","MJman","GFN","zhizhixiong","doge","huaji","hongguaiwu","JIN_old","BLL","beijita","wukongS","jifengzuo","jiuwei"]; // 一键购买所有角色的角色列表
               Service.userData.userData.buys = buys; // 购买所有角色
               SharedObject.getLocal("net.zygame.hxwz.air").data.userData = Service.userData; // 更新缓存的用户数据
               SharedObject.getLocal("net.zygame.hxwz.air").flush(); //
               SceneCore.pushView(new GameTipsView("已购买所有角色")); // 弹出提示
               removeFromParent(true); //
            } //
            else
            {
               removeFromParent(true);
               SceneCore.pushView(new GameTestView()); // 弹出一键购买所有角色测试视图
            } //
         }); //
         button2 = new Button(skin,"版本介绍"); // 添加版本介绍按钮
         this.addChild(button2); //
         button2.textFormat.size = 18; //
         button2.x = button.x + button2.width + 16; //
         button2.y = stage.stageHeight - button2.height * 2 - 16; //
         button2.addEventListener("triggered",function(e:Event):void //
         { //
            text.text = "幻想纹章3本地版0.9更新内容：\n\n1、修复角色：秩序之力·白面 被动 防反、空条承太郎 被动 TheWorld效果、嘉神慎之介 被动 SP墙效果、由岐照美 被动、布罗利(纹4) 被动、夏目麻衣 BGM\n\n2、添加功能：角色选择界面点击锁定选择、练习模式双选、练习模式暂停界面添加重置地图、2V2模式点击换人、自定义角色登场BGM（添加方法：添加在文件夹bgm/role/角色名称.mp3中即可，角色名称见文档https://docs.qq.com/sheet/DTnB5T0xFSXFRY3ZM?no_promotion=1&tab=BB08J2中的标签名rootName）、2P被动条显示、内置Adobe AIR无需另外安装\n\n3、修复问题：双选界面1P右侧无法点击、2P的BGM无法播放\n\n4、添加地图：幻想纹章4"; //
         }); //
      }
   }
}

