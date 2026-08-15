import html
import json
import os
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

from .models import ActionData, AtlasFrame, FrameData, InitStat, RoleData, RoleIndexItem


def runtime_base_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def find_game_root(start: Path | None = None) -> Path:
    env_root = os.getenv("FC3_GAME_ROOT", "").strip()
    if env_root:
        candidate = Path(env_root)
        if (candidate / "data" / "fight.xml").exists() and (candidate / "role").exists():
            return candidate

    probe = start if start is not None else runtime_base_dir()
    for parent in [probe, *probe.parents]:
        if (parent / "data" / "fight.xml").exists() and (parent / "role").exists():
            return parent
    return probe


def safe_parse_xml(file_path: Path):
    try:
        tree = ET.parse(file_path)
        return tree.getroot(), None
    except Exception as exc:
        return None, str(exc)


def parse_effects_text(raw: str):
    if not raw:
        return []
    text = html.unescape(raw).strip()
    if not text or text == "[]":
        return []

    attempts = [text]
    if text.startswith('"') and text.endswith('"'):
        attempts.append(text[1:-1])

    for candidate in attempts:
        try:
            parsed = json.loads(candidate)
            if isinstance(parsed, list):
                out = []
                for item in parsed:
                    if isinstance(item, str):
                        try:
                            out.append(json.loads(item))
                        except Exception:
                            out.append(item)
                    else:
                        out.append(item)
                return out
            return parsed
        except Exception:
            continue
    return text


def parse_fight_file(fight_path: Path, role_dir: Path):
    root, err = safe_parse_xml(fight_path)
    if err:
        raise ValueError(err)

    init_map: dict[str, InitStat] = {}
    role_index: list[RoleIndexItem] = []

    init_node = root.find("init")
    if init_node is not None:
        for data_node in init_node.findall("data"):
            name = data_node.attrib.get("name", "")
            if not name:
                continue
            init_map[name] = InitStat(
                id=data_node.attrib.get("id", ""),
                value=data_node.attrib.get("value", ""),
                info=data_node.attrib.get("info", ""),
            )

    for child in list(root):
        if child.tag == "init":
            continue
        if not isinstance(child.tag, str):
            continue

        role_id = child.tag
        attrs = dict(child.attrib)
        attrs.setdefault("name", role_id)
        ratios: dict[str, str] = {}
        for data_node in child.findall("data"):
            n = data_node.attrib.get("name", "")
            v = data_node.attrib.get("value", "")
            if n:
                ratios[n] = v

        role_file = role_dir / f"{role_id}.data"
        role_index.append(
            RoleIndexItem(
                role_id=role_id,
                name=attrs.get("name", role_id),
                attrs=attrs,
                ratios=ratios,
                role_file=role_file,
                exists=role_file.exists(),
            )
        )

    role_index.sort(key=lambda item: item.role_id.lower())
    return init_map, role_index


def parse_role_data(role_file: Path) -> RoleData:
    root, err = safe_parse_xml(role_file)
    if err:
        raise ValueError(err)

    class_src = ""
    class_node = root.find("class")
    if class_node is not None:
        class_src = class_node.attrib.get("src", "")

    content_image = ""
    content_xml = ""
    content_node = root.find("content")
    if content_node is not None:
        image_node = content_node.find("image")
        xml_node = content_node.find("xml")
        if image_node is not None:
            content_image = image_node.attrib.get("path", "")
        if xml_node is not None:
            content_xml = xml_node.attrib.get("path", "")

    loads: list[dict[str, str]] = []
    loads_node = root.find("loads")
    if loads_node is not None:
        for n in list(loads_node):
            if isinstance(n.tag, str):
                loads.append({"tag": n.tag, **n.attrib})

    actions: list[ActionData] = []
    action_node = root.find("action")
    if action_node is not None:
        for act in action_node.findall("act"):
            frames: list[FrameData] = []
            # 原始代码: for i, frame in enumerate(act.findall("SubTexture"), start=1):
            for i, frame in enumerate(act.findall("SubTexture"), start=0):  # // 帧序号从0开始
                attrs = dict(frame.attrib)
                effects = parse_effects_text(attrs.get("effects", ""))
                frames.append(FrameData(index=i, attrs=attrs, effects=effects))

            actions.append(
                ActionData(
                    name=act.attrib.get("name", "未命名动作"),
                    attrs=dict(act.attrib),
                    frames=frames,
                )
            )

    return RoleData(
        root_attrs=dict(root.attrib),
        class_src=class_src,
        content_image=content_image,
        content_xml=content_xml,
        loads=loads,
        actions=actions,
    )


def parse_atlas_xml(atlas_xml_path: Path) -> list[AtlasFrame]:
    root, err = safe_parse_xml(atlas_xml_path)
    if err:
        raise ValueError(err)

    frames: list[AtlasFrame] = []
    for st in root.findall("SubTexture"):
        attrs = dict(st.attrib)
        try:
            frame = AtlasFrame(
                name=attrs.get("name", ""),
                x=int(float(attrs.get("x", "0"))),
                y=int(float(attrs.get("y", "0"))),
                width=int(float(attrs.get("width", "0"))),
                height=int(float(attrs.get("height", "0"))),
                attrs=attrs,
            )
            frames.append(frame)
        except Exception:
            continue
    return frames
