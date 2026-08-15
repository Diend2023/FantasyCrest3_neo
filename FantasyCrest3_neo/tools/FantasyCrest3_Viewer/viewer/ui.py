import json
from pathlib import Path
import tkinter as tk
import tkinter.ttk as ttk  # // 新增：用于创建支持自定义深色配色的滚动条
from tkinter import messagebox, filedialog

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
        self.geometry("1400x930")

        self.root_path = find_game_root()
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
        self.role_head_map: dict[str, AtlasFrame] = {}
        self.role_head_image: Image.Image | None = None

        self.current_role: RoleIndexItem | None = None
        self.current_role_data: RoleData | None = None
        self.current_action: ActionData | None = None
        self.play_after_id: str | None = None
        self.is_playing = False
        self.play_index = 0

        self.preview_ctk_image = None
        self.role_draw_ctk_image = None
        self.role_head_ctk_image = None

        self._build_ui()
        self.reload_data()

    def _build_ui(self):
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)

        body = ctk.CTkFrame(self)
        body.grid(row=0, column=0, sticky="nsew", padx=10, pady=(10, 8))
        body.grid_columnconfigure(0, weight=15, uniform="body_col")
        body.grid_columnconfigure(1, weight=85, uniform="body_col")
        body.grid_rowconfigure(0, weight=1)

        left = ctk.CTkFrame(body)
        main_panel = ctk.CTkFrame(body)
        left.grid(row=0, column=0, sticky="nsew", padx=(8, 4), pady=8)
        main_panel.grid(row=0, column=1, sticky="nsew", padx=4, pady=8)

        self._build_left(left)
        self._build_main(main_panel)

        footer = ctk.CTkFrame(self, fg_color="transparent")
        footer.grid(row=1, column=0, sticky="ew", padx=10, pady=(0, 8))
        footer.grid_columnconfigure(0, weight=1)

        self.status_var = tk.StringVar(value="准备就绪")
        ctk.CTkLabel(footer, textvariable=self.status_var, anchor="w").grid(
            row=0, column=0, sticky="ew", padx=4
        )
        ctk.CTkButton(footer, text="重新加载数据", width=100, command=self.reload_data).grid(
            row=0, column=1, padx=4
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

        self.role_listbox = tk.Listbox(
            parent, activestyle="dotbox", exportselection=False,
            bg="#2b2b2b", fg="white", selectbackground="#1f538d",
            highlightthickness=0, borderwidth=1
        )
        self.role_listbox.grid(row=2, column=0, sticky="nsew", padx=10, pady=(0, 10))
        self.role_listbox.bind("<<ListboxSelect>>", self.on_role_select)

    def on_action_hover(self, event):
        if not hasattr(self, 'current_role_data') or not self.current_role_data:
            return
        index = self.action_listbox.nearest(event.y)
        if index < 0 or index >= len(self.current_role_data.actions):
            self._hide_tooltip()
            return

        bbox = self.action_listbox.bbox(index)
        if not bbox:
            self._hide_tooltip()
            return
        x, y, w, h = bbox
        if not (y <= event.y <= y + h):
            self._hide_tooltip()
            return

        action = self.current_role_data.actions[index]
        msg = action.attrs.get("msg", "")
        if not msg:
            self._hide_tooltip()
            return

        if self.tooltip_window and getattr(self.tooltip_window, "_current_index", None) == index:
            return

        self._hide_tooltip()
        tx = x + self.action_listbox.winfo_rootx() + 20
        ty = y + self.action_listbox.winfo_rooty() + h + 2

        self.tooltip_window = tk.Toplevel(self.action_listbox)
        self.tooltip_window.wm_overrideredirect(True)
        self.tooltip_window.wm_geometry(f"+{tx}+{ty}")
        self.tooltip_window._current_index = index

        label = tk.Label(
            self.tooltip_window, text=msg, justify="left",
            background="#2b2b2b", foreground="white", relief="solid", borderwidth=1,
            font=("System", 10, "normal")
        )
        label.pack(ipadx=4, ipady=4)

    def on_action_leave(self, event):
        self._hide_tooltip()

    def _hide_tooltip(self):
        if hasattr(self, 'tooltip_window') and self.tooltip_window:
            self.tooltip_window.destroy()
            self.tooltip_window = None

    def _build_main(self, parent: ctk.CTkFrame):
        # Disable propagation on the main parent too to strictly enforce weight ratios
        parent.grid_propagate(False)
        
        # Enforce uniform weights. Note that 'minsize' guarantees they won't shrink to 0 
        parent.grid_columnconfigure(0, weight=35, uniform="col") # Role Info
        parent.grid_columnconfigure(1, weight=25, uniform="col") # Frames & Controls
        parent.grid_columnconfigure(2, weight=40, uniform="col") # Preview Area
        
        parent.grid_rowconfigure(1, weight=1)
        parent.grid_rowconfigure(4, weight=1)

        # 1. 角色信息 (原中间列)
        ctk.CTkLabel(parent, text="角色信息", font=ctk.CTkFont(size=16, weight="bold")).grid(
            row=0, column=0, sticky="w", padx=10, pady=(10, 6)
        )
        self.role_info = ctk.CTkScrollableFrame(parent)
        self.role_info.grid(row=1, column=0, sticky="nsew", padx=10, pady=(0, 10))
        self.role_info.grid_columnconfigure(0, weight=1)

        self.long_text_labels = []
        
        def update_wraplength(event=None):
            if event and hasattr(event, "width") and event.width > 50:
                current_w = event.width
            else:
                current_w = self.role_info.winfo_width()
                
            # 提供更大的边距（扣除120像素）确保彻底避开由 CustomTkinter 引入的隐藏内部滚动条和内边距遮挡
            w = max(100, current_w - 120)
            for lbl in self.long_text_labels:
                try:
                    if lbl.winfo_exists() and lbl.cget("wraplength") != w:
                        lbl.configure(wraplength=w)
                except Exception:
                    pass

        self.role_info.bind("<Configure>", update_wraplength, add="+")

        self.role_draw_label = ctk.CTkLabel(self.role_info, text="(无立绘)")
        self.role_head_label = ctk.CTkLabel(self.role_info, text="(无头像)")

        ctk.CTkLabel(parent, text="技能动作列表", font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=2, column=0, sticky="w", padx=10, pady=(0, 6)
        )
        self.action_listbox = tk.Listbox(
            parent, activestyle="dotbox", exportselection=False,
            bg="#2b2b2b", fg="white", selectbackground="#1f538d",
            highlightthickness=0, borderwidth=1
        )
        # 通过跨越3、4行，让它在底部与右侧完美平齐对齐
        self.action_listbox.grid(row=3, column=0, rowspan=2, sticky="nsew", padx=10, pady=(0, 10))
        self.action_listbox.bind("<<ListboxSelect>>", self.on_action_select)
        self.action_listbox.bind("<Motion>", self.on_action_hover)
        self.action_listbox.bind("<Leave>", self.on_action_leave)
        self.tooltip_window = None

        # 2. 全部帧与选中帧 (原右侧左列)
        ctk.CTkLabel(parent, text="角色全部帧列表（Atlas）", font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=0, column=1, sticky="w", padx=10, pady=(10, 6)
        )
        self.all_frames_listbox = tk.Listbox(
            parent, activestyle="dotbox", exportselection=False, height=6, width=15,
            bg="#2b2b2b", fg="white", selectbackground="#1f538d",
            highlightthickness=0, borderwidth=1
        )
        # 原始代码
        # self.all_frames_listbox.grid(row=1, column=1, sticky="nsew", padx=10, pady=(0, 10))
        self.all_frames_listbox.grid(row=1, column=1, sticky="nsew", padx=(10, 26), pady=(0, 10))  # // 修改：右侧留出滚动条位置
        # 原始代码，tk.Scrollbar 在 Windows 视觉样式下无法自定义颜色（显示为白色）
        # self.all_frames_scrollbar = tk.Scrollbar(
        #     parent, orient="vertical", width=16,
        #     command=self.all_frames_listbox.yview,
        #     bg="#2b2b2b", troughcolor="#2b2b2b", activebackground="#1f538d",
        # )
        self._scroll_style = ttk.Style()  # // 新增：ttk 深色滚动条样式
        try:  # // 新增：clam 主题才允许自定义滚动条配色
            self._scroll_style.theme_use("clam")  # // 新增
        except tk.TclError:  # // 新增
            pass  # // 新增
        self._scroll_style.configure(  # // 新增
            "Dark.Vertical.TScrollbar",  # // 新增
            # 原始代码，滑块与轨道同为 #2b2b2b，滑块平时不可见
            # background="#2b2b2b", troughcolor="#2b2b2b",
            background="#6f6f6f", troughcolor="#2b2b2b",  # // 修改：平时色取原悬停色，再亮一档
            bordercolor="#2b2b2b", lightcolor="#6f6f6f", darkcolor="#6f6f6f",  # // 修改：高亮/阴影与滑块同色
            arrowcolor="#8a8a8a", gripcount=0,  # // 新增
        )  # // 新增
        self._scroll_style.map(  # // 新增：锁定悬停/按下状态也为深色，避免变回系统默认白色
            "Dark.Vertical.TScrollbar",  # // 新增
            background=[("pressed", "#7f7f7f"), ("active", "#7f7f7f")],  # // 修改：悬停/按下再亮一档
        )  # // 新增
        self.all_frames_scrollbar = ttk.Scrollbar(  # // 新增：改用 ttk 滚动条以支持深色
            parent, orient="vertical", style="Dark.Vertical.TScrollbar",  # // 新增
            command=self.all_frames_listbox.yview,  # // 新增
        )  # // 新增
        # 原始代码，sticky=ns 会在单元格内水平居中，导致滚动条跑到列表中间
        # self.all_frames_scrollbar.grid(row=1, column=1, sticky="ns", padx=(0, 10), pady=(0, 10))
        self.all_frames_scrollbar.grid(row=1, column=1, sticky="nse", padx=(0, 10), pady=(0, 10))  # // 修改：sticky 加 e，垂直拉伸且水平靠右
        self.all_frames_listbox.configure(yscrollcommand=self.all_frames_scrollbar.set)  # // 新增
        self.all_frames_listbox.bind("<<ListboxSelect>>", self.on_all_frame_select)

        title_frame = ctk.CTkFrame(parent, fg_color="transparent")
        title_frame.grid(row=2, column=1, sticky="ew", padx=10, pady=(0, 6))
        ctk.CTkLabel(title_frame, text="选中技能的帧序列", font=ctk.CTkFont(size=15, weight="bold")).pack(side="left")

        controls = ctk.CTkFrame(parent)
        controls.grid(row=3, column=1, sticky="nsew", padx=10, pady=(0, 8))
        controls.grid_columnconfigure(4, weight=1)
        ctk.CTkButton(controls, text="播放", width=36, command=self.play_action).grid(row=0, column=0, padx=2, pady=4)
        ctk.CTkButton(controls, text="暂停", width=36, command=self.pause_action).grid(row=0, column=1, padx=2, pady=4)
        ctk.CTkButton(controls, text="停止", width=36, command=self.stop_action).grid(row=0, column=2, padx=2, pady=4)
        ctk.CTkButton(controls, text="导出", width=36, command=self.export_action_gif).grid(row=0, column=3, padx=2, pady=4)
        self.play_state_var = tk.StringVar(value="停止")
        ctk.CTkLabel(controls, textvariable=self.play_state_var).grid(row=0, column=4, sticky="e", padx=4, pady=4)

        self.action_frames_listbox = tk.Listbox(
            parent, activestyle="dotbox", exportselection=False, height=8, width=15,
            bg="#2b2b2b", fg="white", selectbackground="#1f538d",
            highlightthickness=0, borderwidth=1
        )
        self.action_frames_listbox.grid(row=4, column=1, sticky="nsew", padx=10, pady=(0, 10))
        self.action_frames_listbox.bind("<<ListboxSelect>>", self.on_action_frame_select)

        # 3. 预览区域 (原右侧大图列)
        self.preview_title_var = tk.StringVar(value="预览区域")
        ctk.CTkLabel(parent, textvariable=self.preview_title_var, font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=0, column=2, sticky="w", padx=4, pady=(10, 6)
        )

        preview_wrap = ctk.CTkFrame(parent)
        preview_wrap.grid_propagate(False)  # 核心修复点：禁止内部图片过大时撑大容器，强制由外部 grid 的 weight 分配空间
        preview_wrap.grid(row=1, column=2, rowspan=4, sticky="nsew", padx=(4, 10), pady=(0, 10))
        preview_wrap.grid_columnconfigure(0, weight=1)
        preview_wrap.grid_rowconfigure(0, weight=2)
        preview_wrap.grid_rowconfigure(1, weight=1)

        self.preview_image_label = ctk.CTkLabel(preview_wrap, text="(未选择帧)", width=400, height=420)
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
        self.role_head_map.clear()
        self.role_head_image = None

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

        self.load_role_head_assets()

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

    def _get_empty_img(self):
        if not hasattr(self, "_empty_img"):
            self._empty_img = ctk.CTkImage(Image.new("RGBA", (1, 1), (0, 0, 0, 0)), size=(1, 1))
        return self._empty_img

    def _safe_update_label(self, label: ctk.CTkLabel, text: str, image: ctk.CTkImage | None):
        """安全地更新 CTkLabel，使用 1x1 透明图替代 None 彻底规避 TclError GC 销毁 bug"""
        img_to_set = image if image is not None else self._get_empty_img()
        try:
            label.configure(image=img_to_set)
        except Exception:
            pass
        try:
            label.configure(text=text)
        except Exception:
            pass

    def clear_detail_views(self):
        self.stop_action()
        self.long_text_labels.clear()
        for w in self.role_info.winfo_children():
            if w not in (self.role_draw_label, self.role_head_label):
                w.destroy()
        self.role_draw_label.pack_forget()
        self.role_head_label.pack_forget()
        self.action_listbox.delete(0, tk.END)
        self.all_frames_listbox.delete(0, tk.END)
        self.action_frames_listbox.delete(0, tk.END)
        self.preview_meta.delete("1.0", tk.END)
        self.preview_title_var.set("预览区域")
        self._safe_update_label(self.preview_image_label, "(未选择帧)", None)
        self.preview_ctk_image = None
        self._safe_update_label(self.role_draw_label, "(无立绘)", None)
        self._safe_update_label(self.role_head_label, "(无头像)", None)
        self.role_draw_ctk_image = None
        self.role_head_ctk_image = None
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
        for w in self.role_info.winfo_children():
            if w not in (self.role_draw_label, self.role_head_label):
                w.destroy()
        self.role_draw_label.pack_forget()
        self.role_head_label.pack_forget()
        
        attrs = role_item.attrs
        
        ctk.CTkLabel(self.role_info, text=f"ID: {role_item.role_id}", anchor="w").pack(fill="x", padx=4, pady=2)
        ctk.CTkLabel(self.role_info, text=f"名称: {attrs.get('name', '')}", anchor="w").pack(fill="x", padx=4, pady=2)
        self.role_draw_label.pack(fill="x", padx=4, pady=4)
        
        ctk.CTkLabel(self.role_info, text=f"定位: {attrs.get('profession', '')}", anchor="w").pack(fill="x", padx=4, pady=2)
        ctk.CTkLabel(self.role_info, text=f"作者: {attrs.get('acthor', '')}", anchor="w").pack(fill="x", padx=4, pady=2)
        ctk.CTkLabel(self.role_info, text=f"头像: {attrs.get('head', '')}", anchor="w").pack(fill="x", padx=4, pady=2)
        self.role_head_label.pack(anchor="w", padx=4, pady=4)
        
        ctk.CTkLabel(self.role_info, text=f"可见: {attrs.get('visible', 'true')}", anchor="w").pack(fill="x", padx=4, pady=2)
        ctk.CTkLabel(self.role_info, text=f"金币: {attrs.get('coin', '')}", anchor="w").pack(fill="x", padx=4, pady=2)
        ctk.CTkLabel(self.role_info, text=f"水晶: {attrs.get('crystal', '')}", anchor="w").pack(fill="x", padx=4, pady=2)
        
        w_len = max(100, self.role_info.winfo_width() - 120)
        passive_label = ctk.CTkLabel(self.role_info, text=f"被动: {attrs.get('passive', '')}", anchor="w", justify="left", wraplength=w_len)
        passive_label.pack(fill="x", padx=4, pady=2)
        intro_label = ctk.CTkLabel(self.role_info, text=f"简介: {attrs.get('introduce', '')}", anchor="w", justify="left", wraplength=w_len)
        intro_label.pack(fill="x", padx=4, pady=2)

        self.long_text_labels.extend([passive_label, intro_label])

        ctk.CTkLabel(self.role_info, text="\n=== 角色倍率（fight.xml）===", anchor="w", font=ctk.CTkFont(weight="bold")).pack(fill="x", padx=4, pady=2)
        
        for name, value in role_item.ratios.items():
            base = self.fight_init.get(name)
            if base:
                txt = f"- {name} ({base.id}) : {value}  [默认 {base.value}]"
            else:
                txt = f"- {name} : {value}"
            ctk.CTkLabel(self.role_info, text=txt, anchor="w").pack(fill="x", padx=4, pady=1)

        file_label = ctk.CTkLabel(self.role_info, text=f"\n角色文件: {role_item.role_file}", anchor="w", justify="left", wraplength=w_len)
        file_label.pack(fill="x", padx=4, pady=2)
        self.long_text_labels.append(file_label)
        
        ctk.CTkLabel(self.role_info, text=f"存在: {'是' if role_item.exists else '否'}", anchor="w").pack(fill="x", padx=4, pady=2)

        self.render_role_visuals(role_item)

    def load_role_head_assets(self):
        atlas_xml = self.root_path / "ui" / "role_head.xml"
        atlas_png = self.root_path / "ui" / "role_head.png"
        if not atlas_xml.exists() or not atlas_png.exists():
            return

        try:
            frames = parse_atlas_xml(atlas_xml)
            self.role_head_image = Image.open(atlas_png)
        except Exception:
            self.role_head_map.clear()
            self.role_head_image = None
            return

        mapped: dict[str, AtlasFrame] = {}
        for frame in frames:
            name = frame.name
            mapped[name] = frame
            mapped[name.lower()] = frame
            if "." in name:
                stem = Path(name).stem
                mapped[stem] = frame
                mapped[stem.lower()] = frame
        self.role_head_map = mapped

    def get_head_frame(self, role_item: RoleIndexItem) -> AtlasFrame | None:
        head_attr = role_item.attrs.get("head", "")
        head_stem = Path(head_attr).stem if head_attr else ""
        candidates = [
            role_item.role_id,
            role_item.role_id.lower(),
            head_attr,
            head_attr.lower(),
            head_stem,
            head_stem.lower(),
            "weizhi",
        ]
        for key in candidates:
            if key and key in self.role_head_map:
                return self.role_head_map[key]
        return None

    def render_role_visuals(self, role_item: RoleIndexItem):
        role_draw_path = self.root_path / "role_image" / f"{role_item.role_id}.png"
        if not role_draw_path.exists():
            role_draw_path = self.root_path / "role_image" / "none.png"

        if role_draw_path.exists():
            try:
                draw_img = Image.open(role_draw_path)
                scale = min(300 / draw_img.width, 400 / draw_img.height, 1)
                size = (max(1, int(draw_img.width * scale)), max(1, int(draw_img.height * scale)))
                new_img = ctk.CTkImage(light_image=draw_img, dark_image=draw_img, size=size)
                self._safe_update_label(self.role_draw_label, "", new_img)
                self.role_draw_ctk_image = new_img
            except Exception:
                self.role_draw_ctk_image = None
                self._safe_update_label(self.role_draw_label, "(立绘加载失败)", None)
        else:
            self.role_draw_ctk_image = None
            self._safe_update_label(self.role_draw_label, "(无立绘)", None)

        frame = self.get_head_frame(role_item)
        if frame is None or self.role_head_image is None:
            self.role_head_ctk_image = None
            self._safe_update_label(self.role_head_label, "(无头像)", None)
            return

        x1 = max(0, frame.x)
        y1 = max(0, frame.y)
        x2 = min(self.role_head_image.width, frame.x + frame.width)
        y2 = min(self.role_head_image.height, frame.y + frame.height)
        if x2 <= x1 or y2 <= y1:
            self.role_head_ctk_image = None
            self._safe_update_label(self.role_head_label, "(无头像)", None)
            return

        try:
            head_img = self.role_head_image.crop((x1, y1, x2, y2))
            scale = min(72 / head_img.width, 72 / head_img.height, 1)
            size = (max(1, int(head_img.width * scale)), max(1, int(head_img.height * scale)))
            new_img = ctk.CTkImage(light_image=head_img, dark_image=head_img, size=size)
            self._safe_update_label(self.role_head_label, "", new_img)
            self.role_head_ctk_image = new_img
        except Exception:
            self.role_head_ctk_image = None
            self._safe_update_label(self.role_head_label, "(头像加载失败)", None)

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
            action_type = action.attrs.get("type", "")
            cd = action.attrs.get("cd", "")
            
            other_str = action.attrs.get("other", "[]")
            mp = None
            noc = None
            try:
                if other_str and other_str.strip():
                    import json
                    other_data = json.loads(other_str)
                    for item in other_data:
                        if item.get("id") == "mp":
                            mp = item.get("value", "")
                        elif item.get("id") == "noc":
                            noc = item.get("value", "")
            except Exception:
                pass

            parts = [f"{action.name}"]
            if len(action.frames) > 0:
                parts.append(f"帧:{len(action.frames)}")
            if key:
                parts.append(f"key:{key}")
            if action_type:
                parts.append(f"type:{action_type}")
            if cd:
                parts.append(f"cd:{cd}")
            if mp is not None:
                parts.append(f"mp:{mp}")
            if noc is not None:
                parts.append(f"noc:{noc}")
            if fps:
                parts.append(f"fps:{fps}")

            self.action_listbox.insert(tk.END, " | ".join(parts))

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

        # 原始代码: for idx, frame in enumerate(atlas_frames, start=1):
        for idx, frame in enumerate(atlas_frames, start=0):  # // 序号从0开始
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
        self.play_state_var.set("播放中")

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
        self.play_state_var.set("暂停")

    def stop_action(self, reset_selection: bool = True):
        self.is_playing = False
        if self.play_after_id:
            self.after_cancel(self.play_after_id)
            self.play_after_id = None
        self.play_state_var.set("停止")
        self.play_index = 0
        if reset_selection and self.action_frames_listbox.size() > 0:
            self.action_frames_listbox.selection_clear(0, tk.END)

    def export_action_gif(self):
        if not self.current_role or not self.current_action or not self.current_action.frames:
            messagebox.showinfo("提示", "请先选择一个包含帧的技能动作")
            return
            
        role_id = self.current_role.role_id
        image = self.image_cache.get(role_id)
        if image is None:
            messagebox.showwarning("警告", "当前角色缺少贴图数据，无法导出")
            return

        filepath = filedialog.asksaveasfilename(
            defaultextension=".gif",
            filetypes=[("GIF 图像", "*.gif")],
            initialfile=f"{role_id}_{self.current_action.name}.gif",
            title="导出技能 GIF"
        )
        if not filepath:
            return
            
        atlas_map = self.atlas_map_cache.get(role_id, {})
        valid_frames = []
        max_w = max_h = 0
        
        for frame in self.current_action.frames:
            frame_name = frame.name
            atlas_frame = atlas_map.get(frame_name)
            if not atlas_frame:
                continue
            
            x1 = max(0, atlas_frame.x)
            y1 = max(0, atlas_frame.y)
            x2 = min(image.width, atlas_frame.x + atlas_frame.width)
            y2 = min(image.height, atlas_frame.y + atlas_frame.height)
            
            if x2 <= x1 or y2 <= y1:
                continue
                
            crop = image.crop((x1, y1, x2, y2))
            valid_frames.append(crop)
            
            max_w = max(max_w, crop.width)
            max_h = max(max_h, crop.height)
                
        if not valid_frames:
            messagebox.showwarning("警告", "该动作没有可导出的有效帧")
            return
            
        canvas_w = max_w
        canvas_h = max_h
        if canvas_w <= 0 or canvas_h <= 0:
            messagebox.showwarning("警告", "包含的帧截取信息无效，无法导出")
            return
            
        # 强制设置一个保底的方形大画布并让它居中（防止极端长宽比紧贴画面边缘的情况导致显示在左上角）
        # 强行让画布大小为1比1，并将最后的图形缩放至 400x400
        # 去除所有留白，让角色完全填满并紧贴最大边缘
        side_len = max(canvas_w, canvas_h)
        base_size = max(side_len, 2)  # 兜底防0
            
        gif_frames = []
        for crop in valid_frames:
            # Python PIL 保存动态透明GIF最好是背景色全透明，且带上遮罩
            canvas = Image.new("RGBA", (int(base_size), int(base_size)), (255, 255, 255, 0))
            pos_x = (base_size - crop.width) // 2
            pos_y = (base_size - crop.height) // 2
            
            # 确保图像有透明通道才能作为mask
            crop_rgba = crop.convert("RGBA")
            canvas.paste(crop_rgba, (int(pos_x), int(pos_y)), crop_rgba)
            
            # 缩放至固定的 400x400 大小
            try:
                resample = Image.Resampling.NEAREST
            except AttributeError:
                resample = Image.NEAREST
            canvas_scaled = canvas.resize((400, 400), resample)
            
            gif_frames.append(canvas_scaled)
            
        duration = int(2000 / self.get_action_fps())
        
        try:
            gif_frames[0].save(
                filepath,
                format="GIF",
                save_all=True,
                append_images=gif_frames[1:],
                duration=duration,
                loop=0,
                disposal=2,  # 使用透明背景背景清除防重叠
                transparency=0
            )
            self.status_var.set(f"导出成功: {filepath}")
            messagebox.showinfo("成功", f"成功导出 GIF 到:\n{filepath}")
        except Exception as e:
            messagebox.showerror("导出失败", f"导出 GIF 时发生错误：\n{e}")

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
            self._safe_update_label(self.preview_image_label, "图集中未找到同名帧", None)
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
            self._safe_update_label(self.preview_image_label, "未加载到贴图图片", None)
            self.preview_ctk_image = None
        else:
            x1 = max(0, atlas_frame.x)
            y1 = max(0, atlas_frame.y)
            x2 = min(image.width, atlas_frame.x + atlas_frame.width)
            y2 = min(image.height, atlas_frame.y + atlas_frame.height)

            if x2 <= x1 or y2 <= y1:
                self._safe_update_label(self.preview_image_label, "帧裁剪区域无效", None)
                self.preview_ctk_image = None
            else:
                crop = image.crop((x1, y1, x2, y2))
                
                # 动态获取当前图片 Label 实际被分配到的宽高，如果尚未渲染出来给个默认的兜底大小
                lbl_w = self.preview_image_label.winfo_width()
                lbl_h = self.preview_image_label.winfo_height()
                max_w = lbl_w - 4 if lbl_w > 50 else 500
                max_h = lbl_h - 4 if lbl_h > 50 else 400
                
                scale = min(max_w / crop.width, max_h / crop.height, 1)
                show_size = (max(1, int(crop.width * scale)), max(1, int(crop.height * scale)))
                new_img = ctk.CTkImage(light_image=crop, dark_image=crop, size=show_size)
                self._safe_update_label(self.preview_image_label, "", new_img)
                self.preview_ctk_image = new_img

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
