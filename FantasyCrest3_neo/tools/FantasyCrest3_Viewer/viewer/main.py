import traceback
from tkinter import messagebox

from .ui import RoleViewerApp


def main():
    try:
        app = RoleViewerApp()
        app.mainloop()
    except Exception:
        messagebox.showerror("运行异常", traceback.format_exc())
