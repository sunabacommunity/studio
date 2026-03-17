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

    public override function editorInit() {
        load("studio://AssetBrowser.suml");

        getEditor().setDockTabTitle(this, "Assets");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/blue-folder-open-image.png"));

        backButton = getNodeT(Button, "vbox/toolbar/hbox/back");
        forwardButton = getNodeT(Button, "vbox/toolbar/hbox/forward");
        upButton = getNodeT(Button, "vbox/toolbar/hbox/up");
        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/reload");

        addressBar = getNodeT(LineEdit, "vbox/toolbar/hbox/addressBar");
        addressBar.textSubmitted.add((newText: String) -> {
            currentDir = newText;
            refresh();
        });
        searchBar = getNodeT(LineEdit, "vbox/toolbar/hbox/searchBar");

        newButton = getNodeT(MenuButton, "vbox/toolbar/hbox/new");

        tree = getNodeT(Tree, "vbox/view/hsplit/tree");
        tree.hideRoot = true;
        tree.itemSelected.add(() -> {
            var selected = tree.getSelected();
            var metadata = selected.getMetadata(0);
            currentDir = metadata;
            refresh();
        });
        itemList = getNodeT(ItemList, "vbox/view/hsplit/itemList");
        itemList.maxColumns = 0;
        itemList.fixedIconSize = new Vector2i(32, 32);
        itemList.fixedColumnWidth = 96;
        itemList.iconMode = 0;
        itemList.itemActivated.add((index: Int) -> {
            var metadata: String = itemList.getItemMetadata(index);
            if (StringTools.endsWith(metadata, "/")) {
                currentDir = metadata;
                addressBar.text = currentDir;
                refresh();
            }
            else {
                getEditor().explorer.openFile(metadata);
            }
        });

        currentDir = getEditor().projectIo.pathUrl;
        addressBar.text = currentDir;

        fileIcon32 = getEditor().loadIcon("studio://icons/32/document.png");
        dirIcon32 = getEditor().loadIcon("studio://icons/32/blue-folder-horizontal.png");
        
        buildTreeRoot();
        refreshItemList();
    }

    var dirIconTexture: ImageTexture;

    public function buildTreeRoot() {
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
            pathUrlItem.setIcon(0, getEditor().loadIcon("studio://icons/16/application-blue-studio.png"));
            pathUrlItem.setMetadata(0, pathUrl);
            pathTreeItemMap[pathUrl] = pathUrlItem;

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
                var icon = fileIcon32;
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