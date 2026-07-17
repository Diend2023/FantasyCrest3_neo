# FantasyCrest3 Md5Creater

生成 release 的 `md5.data` 热更新清单，供 WebRuntime 启动器的热更新功能使用。

## 功能

-   扫描 release 目录下所有文件，计算 MD5 值
-   生成 `md5.data` JSON 文件（包含版本号、baseURL、文件列表）
-   支持 `.gitignore` 语法的黑名单配置（`.md5ignore`）
-   首次运行自动生成配置文件（`version.txt`、`baseURL.txt`、`.md5ignore`）
-   打包为 exe 后双击即用，成功/失败弹窗提示，日志写入 `logs/`

## 项目结构

```text
FantasyCrest3_Md5Creater/
  app.py                           # 启动入口
  requirements.txt
  FantasyCrest3_Md5Creater.spec    # PyInstaller 打包配置
  README.md
```

## 生成的 md5.data 格式

```json
{
    "version": "3.0.2",
    "baseURL": "https://your-server.com/release/",
    "files": {
        "FantasyCrest3_SERVER_7.swf": "abc123def",
        "config.xml": "456789abc",
        "effect/xxx.png": "def456abc"
    }
}
```

## 配置文件

工具首次运行时会在 release 根目录自动生成以下文件，可直接编辑后重新运行：

| 文件 | 用途 | 默认值 |
|------|------|--------|
| `version.txt` | 版本号 | `1.0.0` |
| `baseURL.txt` | 热更新文件服务器地址（写入 md5.data 供迁移使用） | `https://` |
| `.md5ignore` | 忽略规则（`.gitignore` 语法） | 内置默认规则 |
| `scan_path.txt` | 手动指定扫描路径（放在 exe 同目录，可选） | — |

## 安装

```bash
pip install -r requirements.txt
```

## 运行

```bash
python app.py
```

## EXE 打包

```bash
pyinstaller  FantasyCrest3_Md5Creater.spec
```

生成 `dist/FantasyCrest3_Md5Creater.exe`，放到 release 的 `tools/FantasyCrest3_Md5Creater/` 目录下。

exe 运行时默认向上两级定位 release 根目录：

```text
release/
├── FantasyCrest3_SERVER_7.swf
├── config.xml
├── effect/
├── ...
└── tools/
    └── FantasyCrest3_Md5Creater/
        ├── FantasyCrest3_Md5Creater.exe  ← 放这里
        └── md5.data                      ← 生成在这里
```

如需指定其他扫描路径，在 exe 同目录创建 `scan_path.txt` 写入绝对路径即可。

## 忽略规则（.md5ignore）

支持完整 `.gitignore` 语法（`*`、`**`、`!` 取反、目录 `/` 匹配等）。不提供该文件时使用以下内置默认规则：

```gitignore
# 工具自身文件（仅匹配根目录）
/md5.data
/scan_path.txt
/version.txt
/baseURL.txt
/.md5ignore
# WebRuntime 启动器（不参与热更新）
WebRuntime.swf
# 隐藏文件/目录
.*
# 日志
logs/
# 开发用目录
src/
reference/
# Git
.git/
# IDE
.vscode/
.idea/
# Python
__pycache__/
.venv/
# 系统文件
Thumbs.db
.DS_Store
```
