# 项目配置管理模块 //
# 负责创建/加载/保存项目配置 //
import json
import os
from dataclasses import dataclass, field, asdict
from typing import List


@dataclass
class ProjectConfig:
    """项目配置"""
    project_name: str = ""
    project_path: str = ""
    # 6个资源文件夹路径（由用户选择，role必选，其余非必选）
    role_folder: str = ""
    npc_folder: str = ""
    effect_folder: str = ""
    sound_folder: str = ""
    roleui_folder: str = ""
    roles_folder: str = ""
    # role选择方式："file"（选单个角色文件）或 "folder"（选角色文件夹）
    role_select_mode: str = "file"
    # 选文件模式时：所选角色文件路径列表
    selected_role_files: List[str] = field(default_factory=list)
    # 选文件夹模式时：角色文件夹中勾选的角色文件名列表
    selected_role_names: List[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, d: dict) -> "ProjectConfig":
        # 兼容旧字段名
        d = dict(d)
        if "role_selection_mode" in d:
            d["role_select_mode"] = d.pop("role_selection_mode")
        if "role_files" in d:
            d["selected_role_files"] = d.pop("role_files")
        return cls(**{k: v for k, v in d.items() if k in cls.__dataclass_fields__})


def create_project(project_path: str, project_name: str) -> ProjectConfig:
    """创建新项目，在project文件夹下建立项目目录"""
    project_dir = os.path.join(project_path, project_name)
    os.makedirs(project_dir, exist_ok=True)
    os.makedirs(os.path.join(project_dir, "output"), exist_ok=True)
    config = ProjectConfig(project_name=project_name, project_path=project_dir)
    _save_config(config)
    return config


def load_config(project_path: str) -> ProjectConfig:
    """加载项目配置"""
    config_file = os.path.join(project_path, "config.json")
    if not os.path.exists(config_file):
        raise FileNotFoundError(f"项目配置文件不存在: {config_file}")
    with open(config_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    return ProjectConfig.from_dict(data)


def _save_config(config: ProjectConfig) -> None:
    """保存配置到文件"""
    config_file = os.path.join(config.project_path, "config.json")
    with open(config_file, "w", encoding="utf-8") as f:
        json.dump(config.to_dict(), f, ensure_ascii=False, indent=2)


def project_exists(project_path: str) -> bool:
    """检查是否为有效项目"""
    return os.path.isfile(os.path.join(project_path, "config.json"))
