from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class InitStat:
    id: str = ""
    value: str = ""
    info: str = ""


@dataclass
class RoleIndexItem:
    role_id: str
    name: str
    attrs: dict[str, str]
    ratios: dict[str, str]
    role_file: Path
    exists: bool


@dataclass
class FrameData:
    index: int
    attrs: dict[str, str]
    effects: Any = field(default_factory=list)

    @property
    def name(self) -> str:
        return self.attrs.get("name", "")


@dataclass
class ActionData:
    name: str
    attrs: dict[str, str]
    frames: list[FrameData] = field(default_factory=list)


@dataclass
class AtlasFrame:
    name: str = ""
    x: int = 0
    y: int = 0
    width: int = 0
    height: int = 0
    frame_x: int = 0
    frame_y: int = 0
    attrs: dict[str, str] = field(default_factory=dict)


@dataclass
class AtlasData:
    """图集根数据，对应 Maplive Pool.getPx/getPy 的锚点与全部帧"""
    px: int = 0
    py: int = 0
    frames: list[AtlasFrame] = field(default_factory=list)


@dataclass
class RoleData:
    root_attrs: dict[str, str]
    class_src: str
    content_image: str
    content_xml: str
    loads: list[dict[str, str]]
    actions: list[ActionData]
