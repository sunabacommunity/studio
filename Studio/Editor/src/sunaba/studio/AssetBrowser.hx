package sunaba.studio;

import sunaba.core.Vector2i;
import lua.Coroutine;
import sunaba.core.Variant;
import sunaba.io.IoManager;
import sunaba.ui.ItemList;
import sunaba.ui.Tree;
import sunaba.ui.TreeItem;
import sunaba.ui.MenuButton;
import sunaba.ui.Button;
import sunaba.ui.LineEdit;

class AssetBrowser extends EditorWidget {
    var backButton: Button;
    var forwardButton: Button;
    var upButton: Button;
    var reloadButton: Button;

    var addressBar: LineEdit;
    var searchBar: LineEdit;

    var newButton: MenuButton;

    var tree: Tree;
    var itemList: ItemList;

    var currentDir = "";
    var previousDirs: Array<String> = [];
    var nextDirs: Array<String> = [];

    var pathTreeItemMap: Map<String, TreeItem> = new Map();
    var pathDisabledMap: Map<String, Bool> = new Map();

    public override function editorInit() {
        load("studio://AssetBrowser.suml");

        getEditor().setDockTabTitle(this, "Assets");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/blue-folder-open-image.png"));

        backButton = getNodeT(Button, "vbox/toolbar/hbox/back");
        backButton.disabled = true;
        backButton.pressed.add(() -> {
            var previousDir = previousDirs.pop();
            nextDirs.push(currentDir);
            setCurrentDir(previousDir);
        });
        forwardButton = getNodeT(Button, "vbox/toolbar/hbox/forward");
        forwardButton.disabled = true;
        forwardButton.pressed.add(() -> {
            var nextDir = nextDirs.pop();
            previousDirs.push(currentDir);
            setCurrentDir(nextDir);
        });
        upButton = getNodeT(Button, "vbox/toolbar/hbox/up");
        upButton.disabled = true;
        upButton.pressed.add(() -> {
            if (StringTools.endsWith(currentDir, "://")) {
                return;
            }
            previousDirs.push(currentDir);
            nextDirs = [];
            setCurrentDir(updir(currentDir));
        });
        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/reload");
        reloadButton.pressed.add(() -> {
            refresh();
        });

        addressBar = getNodeT(LineEdit, "vbox/toolbar/hbox/addressBar");
        addressBar.textSubmitted.add((newText: String) -> {
            previousDirs.push(currentDir);
            nextDirs = [];
            setCurrentDir(newText);
        });
        searchBar = getNodeT(LineEdit, "vbox/toolbar/hbox/searchBar");

        newButton = getNodeT(MenuButton, "vbox/toolbar/hbox/new");var newMenu = newButton.getPopup();
        
        newMenu.addIconItem(getEditor().loadIcon("studio://icons/16/blue-folder.png"), "Folder");
        newMenu.addIconItem(getEditor().loadIcon("studio://icons/16/document.png"), "File");

        newMenu.idPressed.add((id: Int) -> {
            if (id == 0) {
                Debug.error("Folder creation not implemented.");
            }
            else if (id == 1) {
                newFile();
            }
        });

        tree = getNodeT(Tree, "vbox/view/hsplit/tree");
        tree.hideRoot = true;
        tree.itemSelected.add(() -> {
            var selected = tree.getSelected();
            var metadata: String = selected.getMetadata(0);
            previousDirs.push(currentDir);
            nextDirs = [];
            backButton.disabled = false;
            setCurrentDir(metadata);
        });
        itemList = getNodeT(ItemList, "vbox/view/hsplit/itemList");
        itemList.maxColumns = 0;
        itemList.fixedIconSize = new Vector2i(32, 32);
        itemList.fixedColumnWidth = 96;
        itemList.iconMode = 0;
        itemList.itemActivated.add((index: Int) -> {
            var metadata: String = itemList.getItemMetadata(index);
            if (StringTools.endsWith(metadata, "/")) {
                previousDirs.push(currentDir);
                nextDirs = [];
                backButton.disabled = false;
                setCurrentDir(metadata);
            }
            else {
                getEditor().explorer.openFile(metadata);
            }
        });

        currentDir = getEditor().projectIo.pathUrl;
        addressBar.text = currentDir;

        fileIcon32 = getEditor().loadIcon("studio://icons/32/document.png");
        dirIcon32 = getEditor().loadIcon("studio://icons/32/blue-folder-horizontal.png");
        
        refresh();
    }

    public function newFile() {
        getEditor().explorer.newAssetFile(currentDir);
    }

    private inline function updir(dir: String) {
        var dirPathArr = dir.split("/");
        dirPathArr.pop();
        dirPathArr.pop();
        dirPathArr.push("");
        return dirPathArr.join("/");
    }

    public function setCurrentDir(dir: String) {
        currentDir = dir;
        if (StringTools.endsWith(currentDir, "://")) {
            upButton.disabled = true;
        }
        else {
            upButton.disabled = false;
        }
        if (previousDirs.length == 0) {
            backButton.disabled = true;
        }
        else {
            backButton.disabled = false;
        }
        if (nextDirs.length == 0) {
            forwardButton.disabled = true;
        }
        else {
            forwardButton.disabled = false;
        }
        if (StringTools.startsWith(currentDir, getEditor().projectIo.pathUrl)) {
            newButton.disabled = false;
        }
        else {
            newButton.disabled = true;
        }
        addressBar.text = currentDir;
        refresh();
    }

    var dirIconTexture: ImageTexture;

    public function buildTreeRoot() {
        while (dirTreeCoroutines.length != 0) {
            onProcess(0);
        }
        var ioManager: IoManager = cast io;

        var pathUrls: Array<String> = ioManager.getPathUrls();

        tree.clear();
        var root = tree.createItem();

        var dirIconBytes = io.loadBytes("studio://icons/16/blue-folder.png");
        var dirIconImage = new Image();
        dirIconImage.loadPngFromBuffer(dirIconBytes);
        dirIconTexture = ImageTexture.createFromImage(dirIconImage);

        var pathUrlDirIconBytes = io.loadBytes("studio://icons/16/blue-folder-network.png");
        var pathUrlDirIconImage = new Image();
        pathUrlDirIconImage.loadPngFromBuffer(pathUrlDirIconBytes);
        var pathUrlDirIconTexture = ImageTexture.createFromImage(pathUrlDirIconImage);
        
        if (!pathUrls.contains(getEditor().projectIo.pathUrl)) {
            var pathUrl = getEditor().projectIo.pathUrl;
            var pathUrlItem = tree.createItem(root);
            pathUrlItem.setText(0, StringTools.replace(pathUrl, "://", ""));
            pathUrlItem.setIcon(0, pathUrlDirIconTexture);
            pathUrlItem.setMetadata(0, pathUrl);
            pathTreeItemMap[pathUrl] = pathUrlItem;
            var collapsed = pathDisabledMap[pathUrl];
            if (collapsed != null) {
                pathUrlItem.collapsed = collapsed;
            }

            var dirTreeCoroutine = Coroutine.create(() -> {
                Coroutine.yield();
                var dirs: Array<Variant> = io.getFileList(pathUrl, "/", false);
                Coroutine.yield();
                if (dirs.length != 0) {
                    for (dir in dirs) {
                        Coroutine.yield();
                        buildDirTree(dir, pathUrlItem);
                        Coroutine.yield();
                    }
                }/*
                else {
                    trace("");
                    var subIo = ioManager.getIoInterface(pathUrl);
                    dirs = subIo.getFileListAll("/", false);
                    trace(dirs.length);
                    if (dirs.length != 0) {
                        for (dir in dirs) {
                            Coroutine.yield();
                            buildDirTree(dir, pathUrlItem);
                            Coroutine.yield();
                        }
                    }
                }*/
                
                Coroutine.yield();
            });
            dirTreeCoroutines.push(dirTreeCoroutine);
            Coroutine.resume(dirTreeCoroutine);
        }
        for (pathUrl in pathUrls) {
            var pathUrlItem = tree.createItem(root);
            pathUrlItem.setText(0, StringTools.replace(pathUrl, "://", ""));
            pathUrlItem.setIcon(0, pathUrlDirIconTexture);
            pathUrlItem.collapsed = true;
            pathUrlItem.setMetadata(0, pathUrl);
            pathTreeItemMap[pathUrl] = pathUrlItem;
            var collapsed = pathDisabledMap[pathUrl];
            if (collapsed != null) {
                pathUrlItem.collapsed = collapsed;
            }

            var dirTreeCoroutine = Coroutine.create(() -> {
                Coroutine.yield();
                var dirs: Array<Variant> = io.getFileList(pathUrl, "/", false);
                Coroutine.yield();
                if (dirs.length != 0) {
                    for (dir in dirs) {
                        Coroutine.yield();
                        buildDirTree(dir, pathUrlItem);
                        Coroutine.yield();
                    }
                }/*
                else {
                    trace("");
                    var subIo = ioManager.getIoInterface(pathUrl);
                    dirs = subIo.getFileListAll("/", false);
                    trace(dirs.length);
                    if (dirs.length != 0) {
                        for (dir in dirs) {
                            Coroutine.yield();
                            buildDirTree(dir, pathUrlItem);
                            Coroutine.yield();
                        }
                    }
                }*/
                
                Coroutine.yield();
            });
            dirTreeCoroutines.push(dirTreeCoroutine);
            Coroutine.resume(dirTreeCoroutine);
        }
    }

    var dirTreeCoroutines : Array<Coroutine<()->Void>> = new Array();

    private function buildDirTree(dir: String, parent: TreeItem) {
        if (parent == null || parent.isNull()) {
            return;
        }
        var dirTreeCoroutine = Coroutine.create(() -> {
            Coroutine.yield();
            var item = tree.createItem(parent);
            Coroutine.yield();
            var pathArray = dir.split("/");
            var dirName = pathArray[pathArray.length - 1];
            if (dirName == "") {
                dirName = pathArray[pathArray.length - 2];
            }
            if (dirName != "") {
                Coroutine.yield();
                item.setText(0, dirName);
                Coroutine.yield();
                item.setIcon(0, dirIconTexture);
                Coroutine.yield();
                item.setMetadata(0, dir);
                pathTreeItemMap[dir] = item;
                Coroutine.yield();
                item.collapsed = true;
                Coroutine.yield();
                var subDirs: Array<Variant> = io.getFileList(dir, "/", false);
                var collapsed = pathDisabledMap[dir];
                if (collapsed != null) {
                    item.collapsed = collapsed;
                }
                Coroutine.yield();
                for (subDir in subDirs) {
                    Coroutine.yield();
                    buildDirTree(subDir, item);
                    Coroutine.yield();
                }
                Coroutine.yield();
            }
            
        });
        dirTreeCoroutines.push(dirTreeCoroutine);
        Coroutine.resume(dirTreeCoroutine);
    }

    public function refresh() {
        // hack fix to prevent crashes
        while (dirTreeCoroutines.length != 0) {
            onProcess(0);
        }
        pathDisabledMap = new Map();
        for (path in pathTreeItemMap.keys()) {
            var treeItem = pathTreeItemMap[path];
            pathDisabledMap[path] = treeItem.collapsed;
        }
        pathTreeItemMap = new Map();
        buildTreeRoot();
        refreshItemList();
    }

    var fileIcon32: ImageTexture;
    var dirIcon32: ImageTexture;

    var itemListCoroutine: Coroutine<()->Void> = null;

    public function refreshItemList() {
        if (itemListCoroutine != null) {
            dirTreeCoroutines.remove(itemListCoroutine);
        }
        itemListCoroutine = Coroutine.create(() -> {
            Coroutine.yield();
            Coroutine.yield();
            var dirs: Array<Variant> = io.getFileList(currentDir, "/", false);
            Coroutine.yield();
            var files: Array<Variant> = io.getFileList(currentDir, "", false);
            Coroutine.yield();
            itemList.clear();
            Coroutine.yield();
            for (dir in dirs) {
                Coroutine.yield();
                var dirPathArray = dir.toString().split("/");
                Coroutine.yield();
                dirPathArray.remove(dirPathArray.pop());
                Coroutine.yield();
                var dirName = dirPathArray.pop();
                Coroutine.yield();
                var item = itemList.addIconItem(dirIcon32, true);
                Coroutine.yield();
                itemList.setItemText(item, dirName);
                Coroutine.yield();
                itemList.setItemMetadata(item, dir);
                Coroutine.yield();
            }
            Coroutine.yield();
            for (file in files) {
                Coroutine.yield();
                var icon: Texture2D = fileIcon32;
                var fileHandlers = getEditor().explorer.fileHandlers;
                for (fileHandler in fileHandlers) {
                    if (StringTools.endsWith(file, "." + fileHandler.extension)) {
                        var thumb = fileHandler.getThunbnail(file);
                        if (thumb != null) {
                            icon = thumb;
                        }
                    }
                }
                Coroutine.yield();
                var fileName = file.toString().split("/").pop();
                Coroutine.yield();
                if (StringTools.endsWith(file, "/")) {
                    Coroutine.yield();
                    continue;
                }
                Coroutine.yield();
                var item = itemList.addIconItem(icon, true);
                Coroutine.yield();
                itemList.setItemText(item, fileName);
                Coroutine.yield();
                itemList.setItemMetadata(item, file);
                Coroutine.yield();
            }
            Coroutine.yield();
        });
        dirTreeCoroutines.push(itemListCoroutine);
        Coroutine.resume(itemListCoroutine);
    }

    public override function onProcess(delta:Float) {
        for (dirTreeCoroutine in dirTreeCoroutines) {
            if (Coroutine.status(dirTreeCoroutine) != CoroutineState.Dead) {
                Coroutine.resume(dirTreeCoroutine);
            }
            else {
                dirTreeCoroutines.remove(dirTreeCoroutine);
            }
        }
    }
}