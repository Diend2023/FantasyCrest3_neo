# FantasyCrest3 RoleExtractor

角色资源提取工具 — 通过选择角色文件（`.data` / `.xml`），自动提取角色所依赖的所有资源。

## 功能

- **项目式管理**：创建/打开项目，配置和日志自动保存
- **资源文件夹选择**：分别选择 `role`、`npc`、`effect`、`sound`、`roleui`、`roles` 六个文件夹
- **角色文件选择**：支持选择单个文件或扫描角色文件夹批量选择
- **搜索过滤**：角色列表支持搜索过滤
- **资源提取**：
  - 精灵表（`npc`）— 支持 `atalsCount` 分割
  - 特效（`effect`）— `.png` + `.xml` 成对
  - 音效（`sound`）— 自动补全常见扩展名（`.mp3`/`.wav`/`.ogg` 等）
  - 角色UI（`roleui`）— `{名称}.xml` + `{名称}Atlas.png/xml`
  - 角色类（`roles`）— 按文件名匹配（后缀不固定）
  - 角色文件本身 — 输出到 `output/role/`
  - 特效 XML 中引用的音效 — 自动解析提取
- **大小写不敏感**：所有文件匹配不区分大小写
- **日志记录**：每次提取生成 `log.txt`

## 环境要求

- Python 3.8+
- customtkinter >= 5.2.2

## 安装

```bash
pip install -r requirements.txt
```

## 运行

```bash
python main.py
```

## 打包为 exe

```bash
pip install pyinstaller
pyinstaller --onefile --windowed --icon ..\..\AppIconsForPublish\48.ico --name "FantasyCrest3_RoleExtractor" main.py
```

打包后目录结构：

```
RoleExtractor.exe
├── projects/          ← 自动创建，存放项目
└── requirements.txt   ← 依赖记录（可选保留）
```

`projects/` 文件夹在首次运行时会自动创建。

## 使用流程

1. **新建项目** — 输入项目名称，在 `projects/` 下创建项目目录
2. **选择资源文件夹** — 必选：`role`；非必选：`npc`、`effect`、`sound`、`roleui`、`roles`（未选择的自动跳过）
3. **选择角色** — 两种方式：
   - **文件模式**：手动添加角色文件（`.data` / `.xml`）
   - **文件夹模式**：扫描角色文件夹，勾选需要的角色（支持搜索过滤）
4. **开始提取** — 资源输出到 `projects/{项目名}/output/{时间戳}/`

## 项目目录结构

```
projects/
└── {项目名}/
    ├── config.json     ← 项目配置
    └── output/
        └── {时间戳}/
            ├── role/      ← 角色文件
            ├── npc/       ← 精灵表
            ├── effect/    ← 特效
            ├── sound/     ← 音效
            ├── roleui/    ← 角色UI
            ├── roles/     ← 角色类
            └── log.txt    ← 提取日志
```

## 注意事项

- 角色文件必须是有效 XML 格式，根标签为 `<Role>`
- 资源查找不区分大小写，但提取的文件名保持源文件实际大小写

## 开发

```bash
# 测试解析器
python -c "from role_parser import parse_role_file; info, refs = parse_role_file('test.xml'); print(len(refs))"
```
