# FantasyCrest3 RoleExtractor - 主程序入口 //
# 基于customtkinter的角色资源提取工具 //
import customtkinter as ctk
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
import os
import threading
import sys

# exe打包兼容：获取脚本/程序所在目录
if getattr(sys, "frozen", False):
    _BASE = os.path.dirname(sys.executable)
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _BASE)

from config import ProjectConfig, create_project, load_config, project_exists
from extractor import Extractor, ExtractResult
from role_parser import find_role_files_in_folder, get_role_display_name

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")


class RoleExtractorApp(ctk.CTk):
    """主应用"""

    def __init__(self):
        super().__init__()
        self.title("FantasyCrest3 RoleExtractor")
        self.geometry("800x850")
        self.minsize(700, 700)

        self.config: ProjectConfig = None
        self.project_root: str = os.path.join(_BASE, "projects")
        os.makedirs(self.project_root, exist_ok=True)

        # --- 打开/创建项目区域 ---
        self.frame_project = ctk.CTkFrame(self)
        self.frame_project.pack(fill="x", padx=10, pady=(10, 5))

        ctk.CTkLabel(self.frame_project, text="项目", font=ctk.CTkFont(size=16, weight="bold")).pack(
            side="left", padx=10)

        self.btn_new_project = ctk.CTkButton(
            self.frame_project, text="新建项目", width=100, command=self._new_project)
        self.btn_new_project.pack(side="left", padx=5)

        self.btn_open_project = ctk.CTkButton(
            self.frame_project, text="打开项目", width=100, command=self._open_project)
        self.btn_open_project.pack(side="left", padx=5)

        self.lbl_project = ctk.CTkLabel(self.frame_project, text="未打开项目", text_color="gray")
        self.lbl_project.pack(side="left", padx=10)

        # --- 资源文件夹选择区域 ---
        self.frame_folders = ctk.CTkFrame(self)
        self.frame_folders.pack(fill="x", padx=10, pady=5)
        ctk.CTkLabel(self.frame_folders, text="资源文件夹（除role外均可留空）",
                     font=ctk.CTkFont(weight="bold")).pack(anchor="w", padx=5, pady=(5, 2))

        self.folder_vars = {}
        self.folder_labels = {}
        folders = [
            ("role", "角色文件夹 (必选)"),
            ("npc", "npc文件夹 (精灵表)"),
            ("effect", "effect文件夹 (特效)"),
            ("sound", "sound文件夹 (音效)"),
            ("roleui", "roleui文件夹 (角色UI)"),
            ("roles", "roles文件夹 (角色类)"),
        ]
        for key, title in folders:
            row = ctk.CTkFrame(self.frame_folders)
            row.pack(fill="x", padx=5, pady=2)
            ctk.CTkLabel(row, text=title, width=180, anchor="w").pack(side="left", padx=5)
            var = tk.StringVar()
            self.folder_vars[key] = var
            entry = ctk.CTkEntry(row, textvariable=var)
            entry.configure(state="readonly")
            entry.pack(side="left", fill="x", expand=True, padx=5)
            btn = ctk.CTkButton(row, text="选择", width=60,
                                command=lambda k=key: self._select_folder(k))
            btn.pack(side="left", padx=(5, 2))
            ctk.CTkButton(row, text="×", width=30, fg_color="transparent", border_width=1,
                          command=lambda k=key: self._clear_one_folder(k)).pack(side="left", padx=0)

        # --- role选择区域 ---
        self.frame_role_select = ctk.CTkFrame(self)
        self.frame_role_select.pack(fill="x", padx=10, pady=5)
        ctk.CTkLabel(self.frame_role_select, text="角色选择",
                     font=ctk.CTkFont(weight="bold")).pack(anchor="w", padx=5, pady=(5, 2))

        # 选择模式
        mode_row = ctk.CTkFrame(self.frame_role_select)
        mode_row.pack(fill="x", padx=5, pady=2)
        ctk.CTkLabel(mode_row, text="选择方式:", width=80).pack(side="left", padx=5)
        self.role_mode_var = tk.StringVar(value="file")
        self.radio_file = ctk.CTkRadioButton(mode_row, text="选择文件", variable=self.role_mode_var,
                                              value="file", command=self._on_role_mode_change)
        self.radio_file.pack(side="left", padx=10)
        self.radio_folder = ctk.CTkRadioButton(mode_row, text="选择文件夹", variable=self.role_mode_var,
                                                value="folder", command=self._on_role_mode_change)
        self.radio_folder.pack(side="left", padx=10)

        # 选文件模式
        self.frame_role_file = ctk.CTkFrame(self.frame_role_select)
        self.frame_role_file.pack(fill="x", padx=5, pady=2)
        ctk.CTkLabel(self.frame_role_file, text="角色文件:", width=80).pack(side="left", padx=5)
        self.role_files_var = tk.StringVar()
        entry = ctk.CTkEntry(self.frame_role_file, textvariable=self.role_files_var)
        entry.configure(state="readonly")
        entry.pack(side="left", fill="x", expand=True, padx=5)
        self.btn_add_role = ctk.CTkButton(self.frame_role_file, text="添加文件", width=80,
                                          command=self._add_role_file)
        self.btn_add_role.pack(side="left", padx=5)
        self.btn_clear_roles = ctk.CTkButton(self.frame_role_file, text="清除", width=60,
                                             command=self._clear_role_files)
        self.btn_clear_roles.pack(side="left", padx=5)

        # 选文件夹模式
        self.frame_role_folder = ctk.CTkFrame(self.frame_role_select)

        list_row = ctk.CTkFrame(self.frame_role_folder)
        list_row.pack(fill="x", padx=5, pady=2)
        ctk.CTkLabel(list_row, text="角色列表:", width=80).pack(side="left", padx=5)
        self.btn_scan_folder = ctk.CTkButton(list_row, text="扫描角色文件夹", width=110,
                                              command=self._scan_role_folder)
        self.btn_scan_folder.pack(side="left", padx=5)
        ctk.CTkButton(list_row, text="全选", width=50, command=lambda: self._toggle_all_roles(True)).pack(
            side="left", padx=2)
        ctk.CTkButton(list_row, text="全不选", width=50, command=lambda: self._toggle_all_roles(False)).pack(
            side="left", padx=2)

        # 搜索框
        search_row = ctk.CTkFrame(self.frame_role_folder)
        search_row.pack(fill="x", padx=5, pady=(2, 0))
        ctk.CTkLabel(search_row, text="搜索:", width=80).pack(side="left", padx=5)
        self.role_search_var = tk.StringVar()
        self.role_search_var.trace_add("write", lambda *_: self._filter_role_list())
        ctk.CTkEntry(search_row, textvariable=self.role_search_var, placeholder_text="输入角色名过滤...").pack(
            side="left", fill="x", expand=True, padx=5)

        self.role_list_frame = ctk.CTkScrollableFrame(self.frame_role_folder, height=150)
        self.role_list_frame.pack(fill="x", padx=5, pady=2)
        self.role_checkboxes = {}     # name -> CTkCheckBox (当前显示)
        self._all_role_cbs = {}       # name -> CTkCheckBox (当前显示的全部checkbox)
        self._all_role_files = []     # 全部角色文件路径
        self._role_checked = {}       # name -> bool 勾选状态
        self.lbl_role_count = ctk.CTkLabel(self.frame_role_folder, text="已选择: 0 个角色", text_color="gray")
        self.lbl_role_count.pack(anchor="w", padx=5, pady=(0, 5))

        # 默认显示文件模式
        self._on_role_mode_change()

        # --- 提取按钮 ---
        self.frame_actions = ctk.CTkFrame(self)
        self.frame_actions.pack(fill="x", padx=10, pady=5)

        self.btn_extract = ctk.CTkButton(
            self.frame_actions, text="开始提取", height=36,
            font=ctk.CTkFont(size=14, weight="bold"),
            command=self._start_extract, state="disabled")
        self.btn_extract.pack(side="left", padx=10)

        self.progress_bar = ctk.CTkProgressBar(self.frame_actions)
        self.progress_bar.pack(side="left", fill="x", expand=True, padx=10)
        self.progress_bar.set(0)

        # --- 日志输出区域 ---
        self.frame_log = ctk.CTkFrame(self)
        self.frame_log.pack(fill="both", expand=True, padx=10, pady=5)
        ctk.CTkLabel(self.frame_log, text="日志",
                     font=ctk.CTkFont(weight="bold")).pack(anchor="w", padx=5, pady=(5, 2))

        self.log_text = ctk.CTkTextbox(self.frame_log, wrap="word")
        self.log_text.pack(fill="both", expand=True, padx=5, pady=5)

    # ===== 项目操作 =====

    def _new_project(self) -> None:
        name = simpledialog.askstring("新建项目", "请输入项目名称:", parent=self)
        if not name:
            return
        # 清空旧项目UI
        self._clear_ui()
        # 创建项目目录和配置文件
        try:
            self.config = create_project(self.project_root, name)
        except Exception as e:
            messagebox.showerror("错误", f"创建项目失败: {e}")
            return
        # 项目加载成功后立即启用提取按钮
        self.btn_extract.configure(state="normal")
        self.lbl_project.configure(text=f"当前项目: {self.config.project_name}")
        self._log("项目创建成功!")

    def _open_project(self) -> None:
        """扫描projects文件夹，列表选择已有项目"""
        projects = self._scan_projects()
        if not projects:
            messagebox.showinfo("提示", f"projects文件夹中暂无项目\n路径: {self.project_root}")
            return
        # 弹出选择对话框
        name = self._show_project_select_dialog(projects)
        if not name:
            return
        path = projects[name]
        # 清空旧项目UI
        self._clear_ui()
        try:
            self.config = load_config(path)
        except Exception as e:
            messagebox.showerror("错误", f"加载项目失败: {e}")
            return
        # 项目加载成功后立即启用提取按钮
        self.btn_extract.configure(state="normal")
        self.lbl_project.configure(text=f"当前项目: {self.config.project_name}")
        self._log("项目加载成功!")
        # 恢复UI状态
        self._restore_ui_from_config()

    def _clear_ui(self) -> None:
        """清空界面所有输入"""
        # 清空文件夹路径
        for key in self.folder_vars:
            self.folder_vars[key].set("")
        # 清空角色文件
        self.role_files_var.set("")
        # 清空角色复选框列表
        for w in self.role_list_frame.winfo_children():
            w.destroy()
        self._all_role_cbs.clear()
        self.role_checkboxes.clear()
        self._all_role_files = []
        self._role_checked = {}
        # 重置选择模式
        self.role_mode_var.set("file")
        self._on_role_mode_change()
        # 清空日志
        self.log_text.delete("1.0", "end")
        # 重置进度条
        self.progress_bar.set(0)

    def _scan_projects(self) -> dict:
        """扫描projects文件夹，返回 {项目名: 项目路径} 字典"""
        result = {}
        if not os.path.isdir(self.project_root):
            return result
        for entry in os.listdir(self.project_root):
            proj_dir = os.path.join(self.project_root, entry)
            if os.path.isdir(proj_dir) and project_exists(proj_dir):
                result[entry] = proj_dir
        return result

    def _show_project_select_dialog(self, projects: dict) -> str:
        """弹出项目选择对话框，返回选中的项目名"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("选择项目")
        dialog.geometry("400x400")
        dialog.transient(self)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="已有项目:", font=ctk.CTkFont(size=14, weight="bold")).pack(pady=(15, 5))

        # 可滚动列表
        list_frame = ctk.CTkScrollableFrame(dialog, height=250)
        list_frame.pack(fill="both", expand=True, padx=15, pady=5)

        selected = tk.StringVar()
        for name in sorted(projects.keys()):
            rb = ctk.CTkRadioButton(list_frame, text=name, variable=selected, value=name)
            rb.pack(anchor="w", pady=2)

        # 按钮
        result = [""]
        def on_ok():
            result[0] = selected.get()
            dialog.destroy()
        def on_cancel():
            dialog.destroy()

        btn_frame = ctk.CTkFrame(dialog)
        btn_frame.pack(pady=(10, 15))
        ctk.CTkButton(btn_frame, text="确定", width=80, command=on_ok).pack(side="left", padx=10)
        ctk.CTkButton(btn_frame, text="取消", width=80, fg_color="transparent", border_width=1,
                      command=on_cancel).pack(side="left", padx=10)

        dialog.wait_window()
        return result[0]

    def _restore_ui_from_config(self) -> None:
        """从配置恢复UI各控件的值"""
        # 恢复文件夹路径（只用配置中的非空值覆盖，保留用户已有选择）
        for key in self.folder_vars:
            val = getattr(self.config, key + "_folder", "")
            if val:
                self.folder_vars[key].set(val)

        # 恢复role选择
        self.role_mode_var.set(self.config.role_select_mode)
        self._on_role_mode_change()

        if self.config.role_select_mode == "file":
            files = getattr(self.config, "selected_role_files", [])
            self.role_files_var.set("; ".join(files))
        else:
            names = getattr(self.config, "selected_role_names", [])
            self._scan_role_folder()
            for n in names:
                self._role_checked[n] = True
            self._filter_role_list()  # 重建列表，带上勾选状态
            self._save_role_folder_selection()

    # ===== 文件夹选择 =====

    def _select_folder(self, key: str) -> None:
        path = filedialog.askdirectory(title=f"选择 {key} 文件夹")
        if path:
            self.folder_vars[key].set(path)
            self._save_folders()

    def _clear_one_folder(self, key: str) -> None:
        """清空单个资源文件夹选择"""
        self.folder_vars[key].set("")
        self._save_folders()

    def _save_folders(self) -> None:
        if not self.config:
            return
        for key in self.folder_vars:
            setattr(self.config, key + "_folder", self.folder_vars[key].get())
        # 保存到文件
        from config import _save_config
        _save_config(self.config)

    # ===== 角色选择 =====

    def _on_role_mode_change(self) -> None:
        mode = self.role_mode_var.get()
        # frame_role_select 子控件: [0]=标签, [1]=mode_row
        anchor = self.frame_role_select.winfo_children()[1]
        if mode == "file":
            self.frame_role_folder.pack_forget()
            self.frame_role_file.pack(fill="x", padx=5, pady=2, after=anchor)
        else:
            self.frame_role_file.pack_forget()
            self.frame_role_folder.pack(fill="x", padx=5, pady=2, after=anchor)
        if self.config:
            self.config.role_select_mode = mode
            from config import _save_config
            _save_config(self.config)

    def _add_role_file(self) -> None:
        files = filedialog.askopenfilenames(
            title="选择角色文件",
            filetypes=[("角色文件", "*.data;*.xml"), ("所有文件", "*.*")])
        if files:
            existing = self.role_files_var.get()
            parts = existing.split("; ") if existing else []
            for f in files:
                if f not in parts:
                    parts.append(f)
            self.role_files_var.set("; ".join(parts))
            self._save_role_files()

    def _clear_role_files(self) -> None:
        self.role_files_var.set("")
        self._save_role_files()

    def _save_role_files(self) -> None:
        if not self.config:
            return
        files_str = self.role_files_var.get()
        self.config.selected_role_files = [f for f in files_str.split("; ") if f]
        from config import _save_config
        _save_config(self.config)

    def _scan_role_folder(self) -> None:
        """扫描角色文件夹，显示所有角色文件"""
        role_dir = self.folder_vars["role"].get()
        if not role_dir:
            messagebox.showwarning("提示", "请先选择角色文件夹")
            return
        self._all_role_files = find_role_files_in_folder(role_dir)
        self._role_checked = {}  # name -> bool，保存勾选状态
        self._log(f"扫描到 {len(self._all_role_files)} 个角色文件")
        self._filter_role_list()

    def _filter_role_list(self) -> None:
        """根据搜索框内容过滤角色列表显示，不影响勾选状态"""
        keyword = self.role_search_var.get().strip().lower()
        # 保存当前勾选状态
        for name, cb in self._all_role_cbs.items():
            self._role_checked[name] = (cb.get() == 1)
        # 清空重建
        for w in self.role_list_frame.winfo_children():
            w.destroy()
        self._all_role_cbs.clear()
        self.role_checkboxes.clear()

        for fp in self._all_role_files:
            name = get_role_display_name(fp)
            if keyword and keyword not in name.lower():
                continue
            row = ctk.CTkFrame(self.role_list_frame)
            row.pack(fill="x", pady=1)
            cb = ctk.CTkCheckBox(row, text="", width=20, command=self._update_role_count)
            cb.pack(side="left", padx=5)
            if self._role_checked.get(name, False):
                cb.select()
            ctk.CTkLabel(row, text=name, anchor="w").pack(side="left", fill="x", expand=True, padx=5)
            self._all_role_cbs[name] = cb
            self.role_checkboxes[name] = cb
        self._update_role_count()

    def _toggle_all_roles(self, select: bool) -> None:
        val = select
        for fp in self._all_role_files:
            name = get_role_display_name(fp)
            self._role_checked[name] = val
            if name in self._all_role_cbs:
                cb = self._all_role_cbs[name]
                if val:
                    cb.select()
                else:
                    cb.deselect()
        self._update_role_count()
        self._save_role_folder_selection()

    def _update_role_count(self) -> None:
        """更新已选角色数量显示"""
        # 同步当前显示的checkbox状态到 _role_checked
        for name, cb in self.role_checkboxes.items():
            self._role_checked[name] = (cb.get() == 1)
        count = sum(1 for v in self._role_checked.values() if v)
        total = len(self._all_role_files)
        self.lbl_role_count.configure(text=f"已选择: {count} / {total} 个角色")

    def _save_role_folder_selection(self) -> None:
        if not self.config:
            return
        self.config.selected_role_names = [
            n for n, v in self._role_checked.items() if v
        ]
        from config import _save_config
        _save_config(self.config)

    # ===== 提取 =====

    def _start_extract(self) -> None:
        """开始提取"""
        if not self.config:
            messagebox.showerror("错误", "请先打开或创建项目")
            return

        # 保存当前配置
        self._save_folders()
        if self.role_mode_var.get() == "file":
            self._save_role_files()
        else:
            self._save_role_folder_selection()
        self.config.role_select_mode = self.role_mode_var.get()

        # 校验
        if not self.config.role_folder:
            messagebox.showerror("错误", "请选择角色文件夹")
            return
        if self.config.role_select_mode == "file" and not self.config.selected_role_files:
            messagebox.showerror("错误", "请添加角色文件")
            return

        self.btn_extract.configure(state="disabled")
        self.progress_bar.set(0)
        self.log_text.delete("1.0", "end")

        # 后台线程执行
        def run():
            extractor = Extractor(self.config, on_log=self._log_thread_safe)
            result = extractor.run()
            self.after(0, lambda: self._on_extract_done(result))

        threading.Thread(target=run, daemon=True).start()

    def _log_thread_safe(self, msg: str) -> None:
        """线程安全的日志输出"""
        if msg.startswith("__PROGRESS__"):
            try:
                pct = float(msg[len("__PROGRESS__"):])
                self.after(0, lambda p=pct: self.progress_bar.set(p))
            except Exception:
                pass
            return
        self.after(0, lambda m=msg: self._log(m))

    def _log(self, msg: str) -> None:
        """向日志区域添加一行"""
        self.log_text.insert("end", msg + "\n")
        self.log_text.see("end")

    def _on_extract_done(self, result: ExtractResult) -> None:
        """提取完成回调"""
        self.btn_extract.configure(state="normal")
        self.progress_bar.set(1.0)
        messagebox.showinfo(
            "提取完成",
            f"角色: {result.role_count}\n"
            f"资源引用: {result.total}\n"
            f"成功: {result.success}  失败: {result.failed}  跳过: {result.skipped}\n\n"
            f"输出: {result.output_dir}")


if __name__ == "__main__":
    app = RoleExtractorApp()
    app.mainloop()
