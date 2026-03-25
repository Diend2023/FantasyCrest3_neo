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
    name: str
    x: int
    y: int
    width: int
    height: int
    attrs: dict[str, str]


@dataclass
class RoleData:
    root_attrs: dict[str, str]
    class_src: str
    content_image: str
    content_xml: str
    loads: list[dict[str, str]]
    actions: list[ActionData]
