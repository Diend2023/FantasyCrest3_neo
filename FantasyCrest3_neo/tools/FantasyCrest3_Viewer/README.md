# FantasyCrest3 Viewer

这是一个基于 `customtkinter` 的角色查看器项目，用于查看 FantasyCrest3 的角色数据与帧图。

## 功能

- 解析 `data/fight.xml` 的角色表。
- 解析 `role/*.data` 的角色动作与帧序列。
- 展示角色全部帧列表（来自角色图集 xml）。
- 展示选中技能的帧序列列表。
- 预览所选帧的实际贴图裁剪结果（png + SubTexture）。

## 项目结构

```text
FantasyCrest3_Viewer/
  app.py                  # 启动入口
  requirements.txt
  README.md
  viewer/
    __init__.py
    main.py               # 应用入口
    models.py             # 数据模型
    parsers.py            # fight/data/atlas 解析
    ui.py                 # customtkinter 界面
```

## 安装

```bash
pip install -r requirements.txt
```

## 运行

```bash
python app.py
```

## EXE 打包（不打包资源）

当前工具发布目录约定为：

```text
<游戏根目录>/tools/FantasyCrest3_Viewer/
```

程序会自动从 `exe` 所在目录向上回溯，找到包含 `data/fight.xml` 与 `role/` 的游戏根目录，因此不需要把资源打进 exe。

可选：若需要手动指定游戏根目录，可设置环境变量 `FC3_GAME_ROOT`。

### 打包命令（推荐 onedir）

```bash
pyinstaller --noconfirm --clean --windowed --icon ..\..\AppIconsForPublish\48.ico --name FantasyCrest3_Viewer app.py
```

生成后将 `dist/FantasyCrest3_Viewer/` 整个目录放到 `tools/FantasyCrest3_Viewer/` 即可。

### 打包命令（onefile）

```bash
pyinstaller --noconfirm --clean --windowed --onefile --icon ..\..\AppIconsForPublish\48.ico --name FantasyCrest3_Viewer app.py
```

生成后将 `dist/FantasyCrest3_Viewer.exe` 放到 `tools/FantasyCrest3_Viewer/`。

## 使用说明

1. 默认会尝试自动定位游戏根目录（包含 `data/fight.xml` 与 `role/`）。
2. 左侧选择角色，中间选择技能动作。
3. 右侧上半区可浏览该角色全部图集帧，右侧中部可查看“选中技能”的帧序列。
4. 点击任一帧后，下方显示该帧的图像预览与字段详情。
5. 右侧播放区支持“播放 / 暂停 / 停止”，按动作 fps 自动循环预览技能帧。
