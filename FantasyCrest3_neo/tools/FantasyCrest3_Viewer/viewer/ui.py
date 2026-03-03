import json
from pathlib import Path
import tkinter as tk
from tkinter import messagebox

import customtkinter as ctk
from PIL import Image

from .models import ActionData, AtlasFrame, InitStat, RoleData, RoleIndexItem
from .parsers import find_game_root, parse_atlas_xml, parse_fight_file, parse_role_data


class RoleViewerApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")

        self.title("FantasyCrest3 角色查看器")
        self.geometry("1700x930")

        self.root_path = find_game_root(Path(__file__).resolve().parent)
        self.fight_path = self.root_path / "data" / "fight.xml"
        self.role_dir = self.root_path / "role"

        self.fight_init: dict[str, InitStat] = {}
        self.role_index: list[RoleIndexItem] = []
        self.filtered_roles: list[RoleIndexItem] = []

        self.role_data_cache: dict[str, RoleData | None] = {}
        self.role_error_cache: dict[str, str] = {}
        self.atlas_cache: dict[str, list[AtlasFrame]] = {}
        self.atlas_map_cache: dict[str, dict[str, AtlasFrame]] = {}
        self.image_cache: dict[str, Image.Image] = {}

        self.current_role: RoleIndexItem | None = None
        self.current_role_data: RoleData | None = None
        self.current_action: ActionData | None = None
        self.play_after_id: str | None = None
        self.is_playing = False
        self.play_index = 0

        self.preview_ctk_image = None

        self._build_ui()
        self.reload_data()

    def _build_ui(self):
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)

        body = ctk.CTkFrame(self)
        body.grid(row=0, column=0, sticky="nsew", padx=10, pady=(10, 8))
        body.grid_columnconfigure(0, weight=2)
        body.grid_columnconfigure(1, weight=3)
        body.grid_columnconfigure(2, weight=5)
        body.grid_rowconfigure(0, weight=1)

        left = ctk.CTkFrame(body)
        mid = ctk.CTkFrame(body)
        right = ctk.CTkFrame(body)
        left.grid(row=0, column=0, sticky="nsew", padx=(8, 4), pady=8)
        mid.grid(row=0, column=1, sticky="nsew", padx=4, pady=8)
        right.grid(row=0, column=2, sticky="nsew", padx=(4, 8), pady=8)

        self._build_left(left)
        self._build_mid(mid)
        self._build_right(right)

        self.status_var = tk.StringVar(value="准备就绪")
        ctk.CTkLabel(self, textvariable=self.status_var, anchor="w").grid(
            row=1, column=0, sticky="ew", padx=14, pady=(0, 8)
        )

    def _build_left(self, parent: ctk.CTkFrame):
        parent.grid_rowconfigure(2, weight=1)
        parent.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(parent, text="角色列表", font=ctk.CTkFont(size=16, weight="bold")).grid(
            row=0, column=0, sticky="w", padx=10, pady=(10, 6)
        )

        self.search_var = tk.StringVar()
        self.search_var.trace_add("write", lambda *_: self.refresh_role_list())
        ctk.CTkEntry(parent, textvariable=self.search_var, placeholder_text="按ID/名称搜索...").grid(
            row=1, column=0, sticky="ew", padx=10, pady=(0, 8)
        )

        self.role_listbox = tk.Listbox(parent, activestyle="dotbox", exportselection=False)
        self.role_listbox.grid(row=2, column=0, sticky="nsew", padx=10, pady=(0, 10))
        self.role_listbox.bind("<<ListboxSelect>>", self.on_role_select)

    def _build_mid(self, parent: ctk.CTkFrame):
        parent.grid_rowconfigure(3, weight=1)
        parent.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(parent, text="角色信息", font=ctk.CTkFont(size=16, weight="bold")).grid(
            row=0, column=0, sticky="w", padx=10, pady=(10, 6)
        )
        self.role_info = ctk.CTkTextbox(parent, wrap="word", height=260)
        self.role_info.grid(row=1, column=0, sticky="ew", padx=10, pady=(0, 10))

        ctk.CTkLabel(parent, text="技能动作列表", font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=2, column=0, sticky="w", padx=10, pady=(0, 6)
        )
        self.action_listbox = tk.Listbox(parent, activestyle="dotbox", exportselection=False)
        self.action_listbox.grid(row=3, column=0, sticky="nsew", padx=10, pady=(0, 10))
        self.action_listbox.bind("<<ListboxSelect>>", self.on_action_select)

    def _build_right(self, parent: ctk.CTkFrame):
        parent.grid_columnconfigure(0, weight=1)
        parent.grid_rowconfigure(6, weight=1)

        ctk.CTkLabel(parent, text="角色全部帧列表（Atlas）", font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=0, column=0, sticky="w", padx=10, pady=(10, 6)
        )
        self.all_frames_listbox = tk.Listbox(parent, activestyle="dotbox", exportselection=False, height=6)
        self.all_frames_listbox.grid(row=1, column=0, sticky="ew", padx=10, pady=(0, 10))
        self.all_frames_listbox.bind("<<ListboxSelect>>", self.on_all_frame_select)

        ctk.CTkLabel(parent, text="选中技能的帧序列", font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=2, column=0, sticky="w", padx=10, pady=(0, 6)
        )
        self.action_frames_listbox = tk.Listbox(parent, activestyle="dotbox", exportselection=False, height=8)
        self.action_frames_listbox.grid(row=3, column=0, sticky="ew", padx=10, pady=(0, 10))
        self.action_frames_listbox.bind("<<ListboxSelect>>", self.on_action_frame_select)

        controls = ctk.CTkFrame(parent)
        controls.grid(row=4, column=0, sticky="ew", padx=10, pady=(0, 8))
        controls.grid_columnconfigure(4, weight=1)
        ctk.CTkButton(controls, text="播放", width=80, command=self.play_action).grid(row=0, column=0, padx=(8, 4), pady=8)
        ctk.CTkButton(controls, text="暂停", width=80, command=self.pause_action).grid(row=0, column=1, padx=4, pady=8)
        ctk.CTkButton(controls, text="停止", width=80, command=self.stop_action).grid(row=0, column=2, padx=4, pady=8)
        self.play_state_var = tk.StringVar(value="状态: 停止")
        ctk.CTkLabel(controls, textvariable=self.play_state_var).grid(row=0, column=4, sticky="e", padx=(4, 10), pady=8)

        self.preview_title_var = tk.StringVar(value="预览区域")
        ctk.CTkLabel(parent, textvariable=self.preview_title_var, font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=5, column=0, sticky="w", padx=10, pady=(0, 6)
        )

        preview_wrap = ctk.CTkFrame(parent)
        preview_wrap.grid(row=6, column=0, sticky="nsew", padx=10, pady=(0, 10))
        preview_wrap.grid_columnconfigure(0, weight=1)
        preview_wrap.grid_rowconfigure(0, weight=2)
        preview_wrap.grid_rowconfigure(1, weight=1)

        self.preview_image_label = ctk.CTkLabel(preview_wrap, text="(未选择帧)", width=520, height=420)
        self.preview_image_label.grid(row=0, column=0, sticky="nsew", padx=8, pady=(8, 6))

        self.preview_meta = ctk.CTkTextbox(preview_wrap, wrap="word")
        self.preview_meta.grid(row=1, column=0, sticky="nsew", padx=8, pady=(0, 8))

    def reload_data(self):
        self.fight_path = self.root_path / "data" / "fight.xml"
        self.role_dir = self.root_path / "role"

        self.role_index.clear()
        self.fight_init.clear()
        self.role_data_cache.clear()
        self.role_error_cache.clear()
        self.atlas_cache.clear()
        self.atlas_map_cache.clear()
        self.image_cache.clear()

        if not self.fight_path.exists():
            messagebox.showerror("错误", f"找不到 fight.xml:\n{self.fight_path}")
            self.status_var.set("加载失败：fight.xml 不存在")
            return

        try:
            self.fight_init, self.role_index = parse_fight_file(self.fight_path, self.role_dir)
        except Exception as exc:
            messagebox.showerror("错误", f"fight.xml 解析失败:\n{exc}")
            self.status_var.set("加载失败：fight.xml 解析异常")
            return

        self.refresh_role_list()
        self.clear_detail_views()

        total = len(self.role_index)
        ok = sum(1 for item in self.role_index if item.exists)
        self.status_var.set(f"加载完成：角色 {total} 个，角色文件 {ok} 个")

    def refresh_role_list(self):
        key = self.search_var.get().strip().lower()
        self.role_listbox.delete(0, tk.END)
        self.filtered_roles.clear()

        for item in self.role_index:
            text = f"{item.role_id} | {item.name}"
            if key and key not in text.lower():
                continue
            if not item.exists:
                text += "  [缺失.data]"
            self.filtered_roles.append(item)
            self.role_listbox.insert(tk.END, text)

    def clear_detail_views(self):
        self.stop_action()
        self.role_info.delete("1.0", tk.END)
        self.action_listbox.delete(0, tk.END)
        self.all_frames_listbox.delete(0, tk.END)
        self.action_frames_listbox.delete(0, tk.END)
        self.preview_meta.delete("1.0", tk.END)
        self.preview_title_var.set("预览区域")
        self.preview_image_label.configure(text="(未选择帧)", image=None)
        self.preview_ctk_image = None
        self.current_role = None
        self.current_role_data = None
        self.current_action = None

    def on_role_select(self, _event=None):
        self.stop_action()
        sel = self.role_listbox.curselection()
        if not sel:
            return
        idx = sel[0]
        if idx >= len(self.filtered_roles):
            return

        self.current_role = self.filtered_roles[idx]
        self.render_role_info(self.current_role)
        self.load_and_render_role_assets(self.current_role)

    def render_role_info(self, role_item: RoleIndexItem):
        attrs = role_item.attrs
        lines = [
            f"ID: {role_item.role_id}",
            f"名称: {attrs.get('name', '')}",
            f"定位: {attrs.get('profession', '')}",
            f"作者: {attrs.get('acthor', '')}",
            f"头像: {attrs.get('head', '')}",
            f"可见: {attrs.get('visible', 'true')}",
            f"金币: {attrs.get('coin', '')}",
            f"水晶: {attrs.get('crystal', '')}",
            f"被动: {attrs.get('passive', '')}",
            f"简介: {attrs.get('introduce', '')}",
            "",
            "=== 角色倍率（fight.xml）===",
        ]
        for name, value in role_item.ratios.items():
            base = self.fight_init.get(name)
            if base:
                lines.append(f"- {name} ({base.id}) : {value}  [默认 {base.value}]")
            else:
                lines.append(f"- {name} : {value}")

        lines.append("")
        lines.append(f"角色文件: {role_item.role_file}")
        lines.append(f"存在: {'是' if role_item.exists else '否'}")

        self.role_info.delete("1.0", tk.END)
        self.role_info.insert("1.0", "\n".join(lines))

    def load_and_render_role_assets(self, role_item: RoleIndexItem):
        self.action_listbox.delete(0, tk.END)
        self.all_frames_listbox.delete(0, tk.END)
        self.action_frames_listbox.delete(0, tk.END)
        self.preview_meta.delete("1.0", tk.END)

        if not role_item.exists:
            self.status_var.set(f"{role_item.role_id}: 缺少 .data 文件")
            return

        role_id = role_item.role_id
        if role_id not in self.role_data_cache and role_id not in self.role_error_cache:
            try:
                self.role_data_cache[role_id] = parse_role_data(role_item.role_file)
            except Exception as exc:
                self.role_error_cache[role_id] = str(exc)

        if role_id in self.role_error_cache:
            self.status_var.set(f"{role_id}: .data 解析失败")
            self.preview_meta.insert("1.0", self.role_error_cache[role_id])
            return

        role_data = self.role_data_cache.get(role_id)
        if role_data is None:
            return
        self.current_role_data = role_data

        for action in role_data.actions:
            fps = action.attrs.get("fps", role_data.root_attrs.get("fps", ""))
            key = action.attrs.get("key", "")
            cd = action.attrs.get("cd", "")
            self.action_listbox.insert(
                tk.END, f"{action.name} | 帧:{len(action.frames)} | fps:{fps} | key:{key} | cd:{cd}"
            )

        atlas_xml_path = self.root_path / role_data.content_xml if role_data.content_xml else None
        atlas_image_path = self.root_path / role_data.content_image if role_data.content_image else None
        if not atlas_xml_path or not atlas_xml_path.exists():
            self.status_var.set(f"{role_id}: 未找到图集xml")
            return

        try:
            atlas_frames = parse_atlas_xml(atlas_xml_path)
        except Exception as exc:
            self.status_var.set(f"{role_id}: 图集xml解析失败")
            self.preview_meta.insert("1.0", str(exc))
            return

        self.atlas_cache[role_id] = atlas_frames
        self.atlas_map_cache[role_id] = {f.name: f for f in atlas_frames}

        for idx, frame in enumerate(atlas_frames, start=1):
            self.all_frames_listbox.insert(
                tk.END,
                f"#{idx:03d} {frame.name} ({frame.width}x{frame.height}) @({frame.x},{frame.y})",
            )

        if atlas_image_path and atlas_image_path.exists():
            try:
                self.image_cache[role_id] = Image.open(atlas_image_path)
            except Exception as exc:
                self.status_var.set(f"{role_id}: 贴图加载失败")
                self.preview_meta.insert("1.0", str(exc))

        self.status_var.set(f"{role_id}: 动作 {len(role_data.actions)} 个，图集帧 {len(atlas_frames)} 个")

    def on_action_select(self, _event=None):
        if not self.current_role or not self.current_role_data:
            return
        self.stop_action(reset_selection=False)

        sel = self.action_listbox.curselection()
        if not sel:
            return
        idx = sel[0]
        if idx >= len(self.current_role_data.actions):
            return

        self.current_action = self.current_role_data.actions[idx]
        self.action_frames_listbox.delete(0, tk.END)
        for frame in self.current_action.frames:
            name = frame.name
            gox = frame.attrs.get("gox", "0")
            goy = frame.attrs.get("goy", "0")
            self.action_frames_listbox.insert(
                tk.END,
                f"#{frame.index:02d} {name} (gox={gox}, goy={goy})",
            )

        if self.current_action.frames:
            self.action_frames_listbox.selection_set(0)
            self.on_action_frame_select()

    def get_action_fps(self) -> float:
        if not self.current_action:
            return 12.0
        value = self.current_action.attrs.get("fps", "")
        if not value and self.current_role_data:
            value = self.current_role_data.root_attrs.get("fps", "12")
        try:
            fps = float(value)
            if fps <= 0:
                return 12.0
            return fps
        except Exception:
            return 12.0

    def play_action(self):
        if not self.current_action or not self.current_action.frames:
            self.status_var.set("请先选择一个有帧的技能动作")
            return

        if self.is_playing:
            return
        self.is_playing = True
        self.play_state_var.set("状态: 播放中")

        sel = self.action_frames_listbox.curselection()
        self.play_index = sel[0] if sel else 0
        self._schedule_next_frame(0)

    def pause_action(self):
        if not self.is_playing:
            return
        self.is_playing = False
        if self.play_after_id:
            self.after_cancel(self.play_after_id)
            self.play_after_id = None
        self.play_state_var.set("状态: 暂停")

    def stop_action(self, reset_selection: bool = True):
        self.is_playing = False
        if self.play_after_id:
            self.after_cancel(self.play_after_id)
            self.play_after_id = None
        self.play_state_var.set("状态: 停止")
        self.play_index = 0
        if reset_selection and self.action_frames_listbox.size() > 0:
            self.action_frames_listbox.selection_clear(0, tk.END)

    def _schedule_next_frame(self, delay_ms: int):
        self.play_after_id = self.after(delay_ms, self._play_tick)

    def _play_tick(self):
        if not self.is_playing or not self.current_action or not self.current_action.frames:
            return

        frames_len = len(self.current_action.frames)
        if frames_len == 0:
            return
        if self.play_index >= frames_len:
            self.play_index = 0

        self.action_frames_listbox.selection_clear(0, tk.END)
        self.action_frames_listbox.selection_set(self.play_index)
        self.action_frames_listbox.see(self.play_index)
        self.on_action_frame_select()

        self.play_index = (self.play_index + 1) % frames_len
        interval = int(1000 / self.get_action_fps())
        self._schedule_next_frame(max(16, interval))

    def on_all_frame_select(self, _event=None):
        if not self.current_role:
            return
        role_id = self.current_role.role_id
        atlas_frames = self.atlas_cache.get(role_id, [])
        sel = self.all_frames_listbox.curselection()
        if not sel:
            return
        idx = sel[0]
        if idx >= len(atlas_frames):
            return

        frame = atlas_frames[idx]
        self.preview_title_var.set(f"预览（全部帧）: {frame.name}")
        self.render_frame_preview(role_id, frame, extra_meta={"source": "atlas"})

    def on_action_frame_select(self, _event=None):
        if not self.current_role or not self.current_action:
            return
        sel = self.action_frames_listbox.curselection()
        if not sel:
            return

        idx = sel[0]
        if idx >= len(self.current_action.frames):
            return

        frame = self.current_action.frames[idx]
        frame_name = frame.name
        atlas_map = self.atlas_map_cache.get(self.current_role.role_id, {})
        atlas_frame = atlas_map.get(frame_name)
        if not atlas_frame:
            self.preview_title_var.set(f"预览（技能帧）: {frame_name}")
            self.preview_image_label.configure(text="图集中未找到同名帧", image=None)
            self.preview_ctk_image = None
            self.preview_meta.delete("1.0", tk.END)
            self.preview_meta.insert(
                "1.0",
                json.dumps(
                    {
                        "action": self.current_action.name,
                        "frame_index": frame.index,
                        "frame_attrs": frame.attrs,
                        "effects": frame.effects,
                    },
                    ensure_ascii=False,
                    indent=2,
                ),
            )
            return

        self.preview_title_var.set(f"预览（技能帧）: {self.current_action.name} / #{frame.index} {frame_name}")
        self.render_frame_preview(
            self.current_role.role_id,
            atlas_frame,
            extra_meta={
                "source": "action",
                "action": self.current_action.name,
                "action_frame_index": frame.index,
                "action_frame_attrs": frame.attrs,
                "effects": frame.effects,
            },
        )

    def render_frame_preview(self, role_id: str, atlas_frame: AtlasFrame, extra_meta: dict):
        image = self.image_cache.get(role_id)
        if image is None:
            self.preview_image_label.configure(text="未加载到贴图图片", image=None)
            self.preview_ctk_image = None
        else:
            x1 = max(0, atlas_frame.x)
            y1 = max(0, atlas_frame.y)
            x2 = min(image.width, atlas_frame.x + atlas_frame.width)
            y2 = min(image.height, atlas_frame.y + atlas_frame.height)

            if x2 <= x1 or y2 <= y1:
                self.preview_image_label.configure(text="帧裁剪区域无效", image=None)
                self.preview_ctk_image = None
            else:
                crop = image.crop((x1, y1, x2, y2))
                max_w = 640
                max_h = 460
                scale = min(max_w / crop.width, max_h / crop.height, 1)
                show_size = (max(1, int(crop.width * scale)), max(1, int(crop.height * scale)))
                self.preview_ctk_image = ctk.CTkImage(light_image=crop, dark_image=crop, size=show_size)
                self.preview_image_label.configure(text="", image=self.preview_ctk_image)

        meta = {
            "atlas_name": atlas_frame.name,
            "atlas_rect": {
                "x": atlas_frame.x,
                "y": atlas_frame.y,
                "width": atlas_frame.width,
                "height": atlas_frame.height,
            },
            "atlas_attrs": atlas_frame.attrs,
            **extra_meta,
        }
        self.preview_meta.delete("1.0", tk.END)
        self.preview_meta.insert("1.0", json.dumps(meta, ensure_ascii=False, indent=2))
