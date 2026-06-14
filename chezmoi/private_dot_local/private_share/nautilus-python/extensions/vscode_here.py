from gi.repository import Nautilus, GObject
import subprocess
import os

class VSCodeHereExtension(GObject.GObject, Nautilus.MenuProvider):

    def _folder_of(self, file):
        p = file.get_location().get_path()
        return p if os.path.isdir(p) else os.path.dirname(p)

    def _open(self, menu, file):
        folder = self._folder_of(file)
        subprocess.Popen(["code", folder], cwd=folder)

    def get_file_items(self, files):
        if len(files) != 1:
            return
        f = files[0]
        path = f.get_location().get_path()
        if os.path.isdir(path):
            item = Nautilus.MenuItem(
                name="VSCodeHereExtension::Open",
                label="Abrir no VSCode",
                tip="Abrir esta pasta no VSCode"
            )
            item.connect("activate", self._open, f)
            return [item]

    def get_background_items(self, current_folder):
        item = Nautilus.MenuItem(
            name="VSCodeHereExtension::OpenBG",
            label="Abrir no VSCode",
            tip="Abrir esta pasta no VSCode"
        )
        item.connect("activate", self._open, current_folder)
        return [item]
