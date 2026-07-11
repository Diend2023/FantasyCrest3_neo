# 角色文件解析模块 //
# 解析 role.data 或 role.xml 文件（XML格式），提取所有资源引用 //
import json
import html
import os
import xml.etree.ElementTree as ET
from typing import List, Dict, Optional, Tuple


class ResRef:
    """单个资源引用"""
    def __init__(self, folder_type: str, rel_path: str, source_desc: str = ""):
        self.folder_type = folder_type  # "npc" / "effect" / "sound" / "roleui" / "roles" / "role"
        self.rel_path = rel_path        # 相对于对应文件夹的路径
        self.source_desc = source_desc   # 来源说明


def parse_role_file(file_path: str) -> Tuple[Dict, List[ResRef]]:
    """
    解析角色文件，返回 (角色信息, 资源引用列表)
    角色文件为 role.data 或 role.xml，内部是XML格式
    """
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"角色文件不存在: {file_path}")

    # 读取文件内容
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except UnicodeDecodeError:
        with open(file_path, "r", encoding="gbk") as f:
            content = f.read()

    # 解析XML
    try:
        root = ET.fromstring(content)
    except ET.ParseError as e:
        raise ValueError(f"XML解析失败 ({file_path}): {e}")

    if root.tag != "Role":
        raise ValueError(f"根标签不是Role: '{root.tag}'")

    refs: List[ResRef] = []
    info: Dict = {}

    # === Role 标签属性 ===
    info["hitEffectName"] = root.get("hitEffectName", "")
    info["atalsCount"] = int(root.get("atalsCount", "0") or "0")
    info["ui"] = root.get("ui", "")

    # hitEffectName → effect文件夹
    if info["hitEffectName"]:
        p = _ensure_prefix(info["hitEffectName"], "effect")
        refs.append(ResRef("effect", p + ".png", "Role@hitEffectName"))
        refs.append(ResRef("effect", p + ".xml", "Role@hitEffectName"))

    # ui → roleui文件夹（ui名称.xml + ui名称Atlas.png/xml）
    if info["ui"]:
        refs.append(ResRef("roleui", "roleui/" + info["ui"] + ".xml", "Role@ui"))
        refs.append(ResRef("roleui", "roleui/" + info["ui"] + "Atlas.png", "Role@ui"))
        refs.append(ResRef("roleui", "roleui/" + info["ui"] + "Atlas.xml", "Role@ui"))

    # === class 标签（非必选）→ roles文件夹，后缀不固定按文件名匹配 ===
    class_el = root.find("class")
    if class_el is not None:
        src = class_el.get("src", "")
        if src.startswith("game.role."):
            cls_name = src[len("game.role."):]
            refs.append(ResRef("roles", "roles/" + cls_name, "class@src"))

    # === sound 标签（Role的直接子标签）→ sound文件夹 ===
    sound_el = root.find("sound")
    if sound_el is not None:
        sp = sound_el.get("path", "")
        if sp:
            refs.append(ResRef("sound", sp, "sound标签"))

    # === bind 标签 → 绑定的另一个角色文件，也需要处理 ===
    bind_el = root.find("bind")
    bind_file_path = ""
    if bind_el is not None:
        bind_file_path = bind_el.get("path", "")
        if bind_file_path:
            refs.append(ResRef("role", bind_file_path, "bind@path"))

    # === content 标签 → npc文件夹 ===
    content_el = root.find("content")
    npc_xml = ""
    npc_img = ""
    if content_el is not None:
        xml_el = content_el.find("xml")
        if xml_el is not None:
            npc_xml = xml_el.get("path", "")
            if npc_xml:
                refs.append(ResRef("npc", npc_xml, "content.xml"))
        img_el = content_el.find("image")
        if img_el is not None:
            npc_img = img_el.get("path", "")
            if npc_img:
                refs.append(ResRef("npc", npc_img, "content.image"))

    # === atalsCount 精灵表分割 ===
    if info["atalsCount"] > 1:
        for i in range(info["atalsCount"]):
            if npc_img:
                base, ext = os.path.splitext(npc_img)
                refs.append(ResRef("npc", f"{base}_{i}{ext}", f"atalsCount分割"))
            if npc_xml:
                base, ext = os.path.splitext(npc_xml)
                refs.append(ResRef("npc", f"{base}_{i}{ext}", f"atalsCount分割"))

    # === loads 标签 ===
    loads_el = root.find("loads")
    if loads_el is not None:
        # sprites → effect文件夹
        for sp_el in loads_el.findall("sprites"):
            sp = sp_el.get("path", "")
            if sp:
                ep = _ensure_prefix(sp, "effect")
                refs.append(ResRef("effect", ep + ".png", "loads.sprites"))
                refs.append(ResRef("effect", ep + ".xml", "loads.sprites"))
        # file → 根据路径提取
        for f_el in loads_el.findall("file"):
            fp = f_el.get("path", "")
            if fp:
                refs.append(ResRef("sound", fp, "loads.file"))

    # === action / act / SubTexture 标签 ===
    action_el = root.find("action")
    if action_el is not None:
        for act_el in action_el.findall("act"):
            for st_el in act_el.findall("SubTexture"):
                # hitEffectName → effect文件夹
                hen = st_el.get("hitEffectName", "")
                if hen:
                    ep = _ensure_prefix(hen, "effect")
                    refs.append(ResRef("effect", ep + ".png", "SubTexture@hitEffectName"))
                    refs.append(ResRef("effect", ep + ".xml", "SubTexture@hitEffectName"))
                # soundName → sound文件夹
                sn = st_el.get("soundName", "")
                if sn:
                    sp = _ensure_prefix(sn, "sound")
                    refs.append(ResRef("sound", sp, "SubTexture@soundName"))
                # effects → 内部有name、hitEffectName
                eff_str = st_el.get("effects", "")
                if eff_str and eff_str != "[]":
                    try:
                        decoded = html.unescape(eff_str)
                        arr = json.loads(decoded)
                        for item in arr:
                            nm = item.get("name", "")
                            hn = item.get("hitEffectName", "")
                            if nm:
                                ep = _ensure_prefix(nm, "effect")
                                refs.append(ResRef("effect", ep + ".png", "SubTexture@effects.name"))
                                refs.append(ResRef("effect", ep + ".xml", "SubTexture@effects.name"))
                            if hn:
                                ep2 = _ensure_prefix(hn, "effect")
                                refs.append(ResRef("effect", ep2 + ".png", "SubTexture@effects.hitEffectName"))
                                refs.append(ResRef("effect", ep2 + ".xml", "SubTexture@effects.hitEffectName"))
                    except Exception:
                        pass

    return info, refs


def _ensure_prefix(path: str, prefix: str) -> str:
    """如果path不是以prefix/开头，则补上"""
    p = path.replace("\\", "/")
    want = prefix + "/"
    if not p.lower().startswith(want.lower()):
        p = want + p
    return p


def find_role_files_in_folder(role_folder: str) -> List[str]:
    """
    在角色文件夹中递归查找所有角色文件（{角色名}.data 或 {角色名}.xml），
    验证文件内容以 <Role 开头，返回文件完整路径列表
    """
    result = []
    if not os.path.isdir(role_folder):
        return result
    for root_dir, dirs, files in os.walk(role_folder):
        for fn in files:
            ext = os.path.splitext(fn)[1].lower()
            if ext not in (".data", ".xml"):
                continue
            full = os.path.join(root_dir, fn)
            # 快速验证是否为有效角色文件
            try:
                with open(full, "r", encoding="utf-8") as f:
                    head = f.read(200)
            except (UnicodeDecodeError, IOError):
                try:
                    with open(full, "r", encoding="gbk") as f:
                        head = f.read(200)
                except Exception:
                    continue
            if "<Role" in head:
                result.append(full)
    return sorted(result)


def get_role_display_name(file_path: str) -> str:
    """获取角色显示名称：文件名去掉扩展名"""
    return os.path.splitext(os.path.basename(file_path))[0]
