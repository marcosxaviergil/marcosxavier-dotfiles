from gi.repository import Nautilus, GObject
import subprocess
import os

class DockerComposeMenuExtension(GObject.GObject, Nautilus.MenuProvider):

    def _path(self, file):
        return file.get_location().get_path()

    def _is_yaml(self, path):
        return os.path.isfile(path) and (path.endswith(".yml") or path.endswith(".yaml"))

    def _run(self, cmd, cwd):
        subprocess.Popen(cmd, cwd=cwd)

    def _compose_up(self, menu, file):
        path = self._path(file)
        if os.path.isdir(path):
            self._run(["docker", "compose", "up", "-d"], cwd=path)
        else:
            self._run(["docker", "compose", "-f", path, "up", "-d"], cwd=os.path.dirname(path))

    def _compose_down(self, menu, file):
        path = self._path(file)
        if os.path.isdir(path):
            self._run(["docker", "compose", "down"], cwd=path)
        else:
            self._run(["docker", "compose", "-f", path, "down"], cwd=os.path.dirname(path))

    def _menu_dir(self, target):
        top = Nautilus.MenuItem(
            name="DockerComposeMenuExtension::TopDir",
            label="Docker Compose",
            tip="Ações de Docker Compose nesta pasta"
        )
        sub = Nautilus.Menu()
        top.set_submenu(sub)

        up = Nautilus.MenuItem(
            name="DockerComposeMenuExtension::UpDir",
            label="Executar Compose aqui",
            tip="docker compose up -d (nesta pasta)"
        )
        up.connect("activate", self._compose_up, target)

        down = Nautilus.MenuItem(
            name="DockerComposeMenuExtension::DownDir",
            label="Parar Compose aqui",
            tip="docker compose down (nesta pasta)"
        )
        down.connect("activate", self._compose_down, target)

        sub.append_item(up)
        sub.append_item(down)
        return top

    def _menu_file(self, target):
        top = Nautilus.MenuItem(
            name="DockerComposeMenuExtension::TopFile",
            label="Docker Compose",
            tip="Ações de Docker Compose usando este arquivo"
        )
        sub = Nautilus.Menu()
        top.set_submenu(sub)

        up = Nautilus.MenuItem(
            name="DockerComposeMenuExtension::UpFile",
            label="Subir Compose",
            tip="docker compose -f <arquivo> up -d"
        )
        up.connect("activate", self._compose_up, target)

        down = Nautilus.MenuItem(
            name="DockerComposeMenuExtension::DownFile",
            label="Desmontar Compose",
            tip="docker compose -f <arquivo> down"
        )
        down.connect("activate", self._compose_down, target)

        sub.append_item(up)
        sub.append_item(down)
        return top

    def get_file_items(self, files):
        if len(files) != 1:
            return
        f = files[0]
        path = self._path(f)

        if self._is_yaml(path):
            return [self._menu_file(f)]

        if os.path.isdir(path):
            return [self._menu_dir(f)]

    def get_background_items(self, current_folder):
        return [self._menu_dir(current_folder)]
