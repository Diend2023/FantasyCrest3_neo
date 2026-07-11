# 资源提取引擎模块 //
# 根据角色文件解析结果，从用户选择的资源文件夹中提取资源到output目录 //
import os
import re
import shutil
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import List, Set, Callable, Optional

from config import ProjectConfig
from role_parser import ResRef, parse_role_file, find_role_files_in_folder, get_role_display_name, _ensure_prefix


class ExtractResult:
    """提取结果"""
    def __init__(self):
        self.total = 0
        self.success = 0
        self.failed = 0
        self.skipped = 0
        self.output_dir = ""
        self.role_count = 0
        self.log_lines: List[str] = []


class Extractor:
    """资源提取器"""

    def __init__(self, config: ProjectConfig, on_log: Optional[Callable] = None):
        self.cfg = config
        self.on_log = on_log or (lambda _: None)
        self.result = ExtractResult()
        self._done_roles: Set[str] = set()  # 已处理的角色文件路径，防止bind循环
        self._roles_got: bool = False       # 是否有roles资源被成功提取

    def _log(self, msg: str) -> None:
        self.result.log_lines.append(msg)
        self.on_log(msg)

    def run(self) -> ExtractResult:
        """执行提取"""
        self._roles_got = False
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.result.output_dir = os.path.join(self.cfg.project_path, "output", ts)

        self._log("=" * 50)
        self._log("FantasyCrest3 RoleExtractor")
        self._log(f"项目: {self.cfg.project_name}")
        self._log(f"输出: {self.result.output_dir}")
        self._log("=" * 50)

        # 收集角色文件
        role_files = self._gather_role_files()
        if not role_files:
            self._log("\n[错误] 未找到任何角色文件！")
            return self.result

        self._log(f"\n找到 {len(role_files)} 个角色文件\n")

        # 解析所有角色文件
        all_refs: List[ResRef] = []
        for rf in role_files:
            self._process_one_role(rf, all_refs)

        self.result.role_count = len(self._done_roles)

        # 去重
        uniq = self._dedup(all_refs)
        self.result.total = len(uniq)
        self._log(f"\n--- 解析完成: {self.result.role_count}角色, {len(all_refs)}引用, 去重{len(uniq)} ---\n")

        # 逐个提取资源
        self._log("--- 开始提取资源 ---\n")
        for i, ref in enumerate(uniq):
            self._extract_one(ref)
            pct = (i + 1) / len(uniq)
            self.on_log(f"__PROGRESS__{pct:.4f}")

        # 将角色文件复制到 output/role/ 中
        self._log("\n--- 复制角色文件 ---\n")
        role_out = os.path.join(self.result.output_dir, "role")
        for rf in sorted(self._done_roles):
            name = get_role_display_name(rf)
            ext = os.path.splitext(rf)[1]
            dst = os.path.join(role_out, name + ext)
            try:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(rf, dst)
                self._log(f"  [角色] {name}{ext}")
            except Exception as e:
                self._log(f"  [失败] {name}{ext} - {e}")

        # 写日志文件
        self._write_log()

        self._log(f"\n{'=' * 50}")
        self._log(f"提取完成！")
        self._log(f"  角色: {self.result.role_count}  引用: {self.result.total}")
        self._log(f"  成功: {self.result.success}  失败: {self.result.failed}  跳过: {self.result.skipped}")
        self._log(f"{'=' * 50}")

        return self.result

    # ---- 内部方法 ----

    def _gather_role_files(self) -> List[str]:
        """根据配置收集角色文件"""
        if self.cfg.role_select_mode == "file":
            valid = [f for f in self.cfg.selected_role_files if os.path.isfile(f)]
            self._log(f"角色选择方式: 文件 ({len(valid)}个)")
            return valid
        else:
            # 文件夹模式：从role_folder中查找，按勾选过滤
            all_files = find_role_files_in_folder(self.cfg.role_folder)
            if self.cfg.selected_role_names:
                all_files = [f for f in all_files
                             if get_role_display_name(f) in self.cfg.selected_role_names]
            self._log(f"角色选择方式: 文件夹 ({len(all_files)}个)")
            return all_files

    def _process_one_role(self, file_path: str, all_refs: List[ResRef]) -> None:
        """处理一个角色文件，包括其bind绑定的角色"""
        if file_path in self._done_roles:
            return
        self._done_roles.add(file_path)

        name = get_role_display_name(file_path)
        self._log(f"[角色] {name}")

        try:
            info, refs = parse_role_file(file_path)
            self._log(f"  识别到 {len(refs)} 个资源引用")
            all_refs.extend(refs)
            # 如果选择了roles文件夹，同时用角色文件名去匹配（与class名并列）
            if self.cfg.roles_folder:
                all_refs.append(ResRef("roles", "roles/" + name, "角色文件名匹配"))

            # 处理bind
            bind_refs = [r for r in refs if r.folder_type == "role"]
            for br in bind_refs:
                # bind路径如 "role/xxx.data"，去掉前缀后在role_folder下查找
                bind_name = os.path.basename(br.rel_path)
                bind_full = os.path.join(self.cfg.role_folder, bind_name)
                if os.path.isfile(bind_full):
                    self._log(f"  [bind] → {bind_name}")
                    self._process_one_role(bind_full, all_refs)
                else:
                    self._log(f"  [bind] {bind_name} (未找到)")
        except Exception as e:
            self._log(f"  [解析失败] {e}")

    def _dedup(self, refs: List[ResRef]) -> List[ResRef]:
        """去重"""
        seen: Set[str] = set()
        uniq: List[ResRef] = []
        for r in refs:
            key = f"{r.folder_type}|{r.rel_path}"
            if key not in seen:
                seen.add(key)
                uniq.append(r)
        return uniq

    def _extract_one(self, ref: ResRef) -> None:
        """提取单个资源文件"""
        # 获取对应的源文件夹
        folder_map = {
            "npc": self.cfg.npc_folder,
            "effect": self.cfg.effect_folder,
            "sound": self.cfg.sound_folder,
            "roleui": self.cfg.roleui_folder,
            "roles": self.cfg.roles_folder,
            "role": self.cfg.role_folder,
        }
        src_folder = folder_map.get(ref.folder_type, "")

        # 未选择此类型文件夹，跳过
        if not src_folder:
            self.result.skipped += 1
            self._log(f"  [跳过] {ref.rel_path} - 未选择该类型文件夹")
            return

        # 去掉路径中的类型前缀（因为源文件夹已经是该类型目录）
        prefix = ref.folder_type + "/"
        rel = ref.rel_path
        if rel.lower().startswith(prefix.lower()):
            rel = rel[len(prefix):]

        # npc精灵表：同一基础名只尝试实际存在的模式（分割/非分割），避免双重失败
        if ref.folder_type == "npc":
            alt = self._npc_alt_exists(src_folder, rel)
            if alt:
                return  # 另一种模式存在，静默跳过此引用

        # 查找源文件（音效可能缺少扩展名，需要尝试常见格式）
        src_path = self._find_source(src_folder, rel, ref.folder_type)
        if not src_path:
            if ref.folder_type == "roles":
                if self._roles_got:
                    return  # 已有其他roles匹配成功，静默跳过
                self.result.failed += 1
                self._log(f"  [失败] {ref.rel_path} - 源文件不存在")
                return
            self.result.failed += 1
            self._log(f"  [失败] {ref.rel_path} - 源文件不存在")
            return

        # 输出路径：目录结构按ref，文件名以源文件实际大小写为准
        ref_dir = os.path.dirname(ref.rel_path.replace("/", os.sep))
        actual_name = os.path.basename(src_path)
        if ref_dir:
            dst_path = os.path.join(self.result.output_dir, ref_dir, actual_name)
        else:
            dst_path = os.path.join(self.result.output_dir, actual_name)

        try:
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            shutil.copy2(src_path, dst_path)
            self.result.success += 1
            self._log(f"  [成功] {ref.rel_path}")
            if ref.folder_type == "roles":
                self._roles_got = True
            # 如果是effect的xml文件，检查其内部的sound引用
            if ref.folder_type == "effect" and src_path.lower().endswith(".xml"):
                self._extract_effect_sound_refs(src_path)
        except Exception as e:
            self.result.failed += 1
            self._log(f"  [失败] {ref.rel_path} - {e}")

    @staticmethod
    def _find_file_icase(dir_path: str, filename: str) -> str:
        """大小写不敏感查找文件，返回实际路径，未找到返回空字符串"""
        if not os.path.isdir(dir_path):
            return ""
        target = filename.lower()
        try:
            for entry in os.listdir(dir_path):
                if entry.lower() == target:
                    return os.path.join(dir_path, entry)
        except OSError:
            pass
        return ""

    def _find_source(self, src_folder: str, rel: str, folder_type: str) -> str:
        """查找源文件（大小写不敏感），处理缺少扩展名的情况"""
        norm = rel.replace("/", os.sep)
        dname = os.path.dirname(norm)
        fname = os.path.basename(norm)
        search_dir = os.path.join(src_folder, dname) if dname else src_folder

        # 先精确匹配（含大小写不敏感）
        found = self._find_file_icase(search_dir, fname)
        if found:
            return found
        # 音效文件可能缺少扩展名，尝试常见音频格式
        if folder_type == "sound":
            for ext in (".mp3", ".wav", ".ogg", ".flac", ".aac", ".wma"):
                found = self._find_file_icase(search_dir, fname + ext)
                if found:
                    return found
        # roles 按文件名匹配，后缀不固定（大小写不敏感）
        if folder_type == "roles":
            target = fname.lower()
            try:
                for entry in os.listdir(search_dir):
                    stem = os.path.splitext(entry)[0]
                    if stem.lower() == target:
                        return os.path.join(search_dir, entry)
            except OSError:
                pass
        return ""

    def _extract_effect_sound_refs(self, effect_xml_path: str) -> None:
        """解析effect的xml文件，提取其中所有sound属性引用的音效"""
        try:
            tree = ET.parse(effect_xml_path)
            root = tree.getroot()
        except Exception:
            return
        # 遍历所有元素，查找sound属性
        for el in root.iter():
            sv = el.get("sound", "")
            if sv:
                sp = _ensure_prefix(sv, "sound")
                sr = ResRef("sound", sp, f"effect.xml@sound={sv}")
                self._extract_one(sr)  # 递归提取音效

    def _npc_alt_exists(self, src_folder: str, rel: str) -> bool:
        """检查npc精灵表的另一种模式是否存在（分割↔非分割），大小写不敏感"""
        dname = os.path.dirname(rel)
        fname = os.path.basename(rel)
        search_dir = os.path.join(src_folder, dname) if dname else src_folder
        stem, ext = os.path.splitext(fname)
        m = re.match(r"^(.+)_(\d+)$", stem)
        if m:
            return bool(self._find_file_icase(search_dir, m.group(1) + ext))
        else:
            return bool(self._find_file_icase(search_dir, stem + "_0" + ext))

    def _write_log(self) -> None:
        """将日志写入log.txt"""
        log_path = os.path.join(self.result.output_dir, "log.txt")
        with open(log_path, "w", encoding="utf-8") as f:
            f.write("\n".join(self.result.log_lines))
        self._log(f"\n日志已保存: {log_path}")
