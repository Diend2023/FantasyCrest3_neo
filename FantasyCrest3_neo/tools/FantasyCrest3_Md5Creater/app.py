# FantasyCrest3 Md5Creater — 生成 release 的 md5.data 热更新清单
import hashlib
import json
import logging
import os
import sys
import tkinter.messagebox as mb
from datetime import datetime
from pathlib import Path

import pathspec

DEFAULT_IGNORE = """\
# === FantasyCrest3 Md5Creater 默认忽略规则（.gitignore 语法）===
# 工具自身文件（仅匹配 release 根目录）
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
.gitignore
.gitattributes
# IDE
.vscode/
.idea/
*.swp
*.swo
# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
# Node.js
node_modules/
# 系统文件
Thumbs.db
.DS_Store
desktop.ini
"""


def setup_logging(log_dir: Path) -> None:
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"md5creater_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.FileHandler(log_file, encoding="utf-8")],
    )
    logging.info(f"日志文件: {log_file}")


def get_exe_dir() -> Path:
    return Path(sys.executable).parent if getattr(sys, "frozen", False) else Path(__file__).parent


def get_target_dir() -> Path:
    """获取要扫描的目标目录 — 默认从 exe 向上两级(release根目录)，可通过 scan_path.txt 指定"""
    exe_dir = get_exe_dir()
    config_file = exe_dir / "scan_path.txt"
    if config_file.exists():
        target = Path(config_file.read_text(encoding="utf-8").strip())
        if target.exists() and target.is_dir():
            logging.info(f"从 scan_path.txt 读取目标目录: {target}")
            return target
    # exe位于 tools/FantasyCrest3_Md5Creater/，向上两级为 release 根目录
    default = (exe_dir / ".." / "..").resolve()
    logging.info(f"目标目录(release根目录): {default}")
    return default


def get_version(target_dir: Path) -> str:
    """从 version.txt 读取版本号，不存在则自动生成"""
    version_file = target_dir / "version.txt"
    if version_file.exists():
        version = version_file.read_text(encoding="utf-8").strip()
    else:
        version = "1.0.0"
        version_file.write_text(version, encoding="utf-8")
        logging.info(f"自动生成 version.txt: {version}")
    logging.info(f"版本号: {version}")
    return version


def get_base_url(target_dir: Path) -> str:
    """从 baseURL.txt 读取 CNB 地址，不存在则自动生成（占位值）"""
    url_file = target_dir / "baseURL.txt"
    if url_file.exists():
        url = url_file.read_text(encoding="utf-8").strip()
        logging.info(f"baseURL(来自文件): {url}")
        return url
    url = "https://your-server.com/release/"
    url_file.write_text(url, encoding="utf-8")
    logging.info(f"自动生成 baseURL.txt: {url}")
    return url


def load_ignore_spec(target_dir: Path) -> pathspec.PathSpec:
    """加载 .md5ignore 文件，不存在则使用内置默认规则（.gitignore 语法）"""
    ignore_file = target_dir / ".md5ignore"
    if ignore_file.exists():
        lines = ignore_file.read_text(encoding="utf-8").splitlines()
        logging.info(f"从 .md5ignore 加载忽略规则 ({len(lines)} 行)")
    else:
        ignore_file.write_text(DEFAULT_IGNORE, encoding="utf-8")
        lines = DEFAULT_IGNORE.splitlines()
        logging.info(f"自动生成 .md5ignore ({len(lines)} 行)")
    return pathspec.PathSpec.from_lines("gitwildmatch", lines)


def calc_md5(file_path: Path) -> str:
    md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            md5.update(chunk)
    return md5.hexdigest()


def generate(target_dir: Path, version: str, spec: pathspec.PathSpec, base_url: str) -> dict:
    files = {}
    total = 0
    skipped = 0

    for root, dirs, filenames in os.walk(target_dir):
        for name in filenames:
            file_path = Path(root) / name
            rel = str(file_path.relative_to(target_dir)).replace("\\", "/")
            if spec.match_file(rel):
                skipped += 1
                logging.debug(f"  跳过: {rel}")
                continue
            md5 = calc_md5(file_path)
            files[rel] = md5
            total += 1
            logging.info(f"  [{total:04d}] {rel}  {md5}")

    logging.info(f"扫描完成 — 包含 {total} 个文件, 跳过 {skipped} 个文件")
    result = {"version": version, "files": files}
    if base_url:
        result["baseURL"] = base_url
    return result


def main():
    exe_dir = get_exe_dir()
    log_dir = exe_dir / "logs"

    try:
        setup_logging(log_dir)
        logging.info("=== FantasyCrest3 Md5Creater 启动 ===")

        target = get_target_dir()
        version = get_version(target)
        base_url = get_base_url(target)
        spec = load_ignore_spec(target)

        data = generate(target, version, spec, base_url)

        out = exe_dir / "md5.data"  # 输出到工具自身目录，不覆盖 release 中的文件
        out.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

        cnt = len(data["files"])
        logging.info(f"完成 — {cnt} 个文件, 版本 {version}, 输出 {out}")

        mb.showinfo(
            "成功",
            f"md5.data 生成完成！\n\n"
            f"目录: {target}\n"
            f"文件: {cnt}\n"
            f"版本: {version}"
        )
    except Exception:
        import traceback
        tb = traceback.format_exc()
        logging.error(tb)
        mb.showerror("失败", f"md5.data 生成失败！\n\n{tb}")


if __name__ == "__main__":
    main()
