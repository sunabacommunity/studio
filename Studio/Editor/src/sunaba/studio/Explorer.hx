package sunaba.studio;

import sunaba.ui.CenterContainer;
import sunaba.ui.MenuButton;
import sunaba.ui.TextureRect;
import sunaba.ui.Label;
import sunaba.ui.Tree;
import sunaba.ui.Button;
import sunaba.ui.Control;
import lua.Coroutine;
import sunaba.ui.TreeItem;
import sunaba.Image;
import sunaba.io.FileSystemIo;
import sys.FileSystem;
import sunaba.core.Callable;
import sunaba.studio.explorer.FileHandler;
import sunaba.core.VariantType;

class Explorer extends EditorWidget {
    var reloadButton: Button;
    var newButton: MenuButton;
    var hamburgerMenuButton: Button;

    var throbberParent: Control;
    var throbberRect: TextureRect;

    var singleColumnTree: Tree;

    var throbberTextures = new Array<ImageTexture>();
    var throbberMaxNumber = 0;

    var projectDirectory = "";
    var assetsDirectory ="";
    var sourceDirectory = "";

    public var fileHandlers: Array<FileHandler> = [];

    public override function editorInit() {
        trace("Hello, World!");
        getEditor().setLeftSidebarTabTitle(this, "Project Explorer");

        var iconBin = io.loadBytes("studio://icons/16_1-5x/blue-folder-stand.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        getEditor().setLeftSidebarTabIcon(this, texture);

        load("studio://Explorer.suml");

        reloadButton = getNodeT(Button, "vbox/toolbar1/hbox/reload");
        newButton = getNodeT(MenuButton, "vbox/toolbar1/hbox/new");
        hamburgerMenuButton = getNodeT(MenuButton, "vbox/toolbar1/hbox/hamburgerMenu");

        throbberParent = getNodeT(Control, "vbox/toolbar1/hbox/throbber");
        throbberRect = getNodeT(TextureRect, "vbox/toolbar1/hbox/throbber/textureRect");

        var throbberPath = "studio://throbber-animated";

        trace(io.directoryExists(throbberPath));
        trace(io.fileExists(throbberPath + "/icon0.png"));
        var throbberTxtListN = io.getFileList(throbberPath, ".png", false);
        var throbberTxtList = throbberTxtListN.toArray();
        if (OSService.getName() == "macOS") {
            for (i in 0...40) {
                var iconPath = throbberPath + "/icon" + i + ".png";
                if (io.fileExists(iconPath)) {
                    throbberTxtList.push(iconPath);
                } else {
                    trace("Throbber icon not found: " + iconPath);
                    break;
                }
            }
        }
        trace(throbberTxtList.length);
        for (txtPath in throbberTxtList) {
            var txtBytes = io.loadBytes(txtPath);
            var image = new Image();
            image.loadPngFromBuffer(txtBytes);
            var imageTexture =  ImageTexture.createFromImage(image);
            throbberTextures.push(imageTexture);
            throbberMaxNumber++;
        }

        var texture = throbberTextures[0];
        throbberRect.texture = texture;

        reloadButton.pressed.connect(Callable.fromFunction(function() {
            if (projectDirectory != "") {
                buildTreeRoot();
            }
        }));

        singleColumnTree = getNodeT(Tree, "vbox/view/singleColumn/tree");
    }

    public function startExplorer() {
        var projFilePathArray  = getEditor().projectFilePath.split("\\").join("/").split("/");
        if (projFilePathArray.length > 0) {
            projectDirectory = projFilePathArray.slice(0, projFilePathArray.length - 1).join("/");

            trace("ProjectTree initialized with directory: " + projectDirectory);

            var projectIo = new FileSystemIo();
            projectIo.open(projectDirectory, getEditor().projectFile.rootUrl);
            getEditor().projectIo = projectIo;

            if (getEditor().projectFile.assetsdir != null
            && getEditor().projectFile.assetsdir != ""
            && !StringTools.contains(getEditor().projectFile.assetsdir, "null"))
                assetsDirectory = projectDirectory + "/" + getEditor().projectFile.assetsdir;
            else
                assetsDirectory = "";

            sourceDirectory = projectDirectory + "/" + getEditor().projectFile.scriptdir;

            trace("Assets Directory: " + assetsDirectory);
            trace("Source Directory: " + sourceDirectory);

            singleColumnTree.itemActivated.connect(Callable.fromFunction(function() {
                var treeItem = singleColumnTree.getSelected();
                onTreeItemActivated(treeItem);
            }));

            buildTreeRoot();
        }
    }

    public function onTreeItemActivated(item: TreeItem) {
        var metadata = item.getMetadata(0);
        if (metadata.getType() == VariantType.string) {
            var path: String = metadata;
            for (fileHandler in fileHandlers) {
                if (StringTools.endsWith(path, "." + fileHandler.extension)) {
                    fileHandler.openFile(path);
                    break;
                }
            }
        }
    }

    var lastThrobberIndex = 0;

    var dirTreeCoroutines : Array<Coroutine<()->Void>> = new Array();

    var rootTreeItem: TreeItem = null;

    var dirIconTexture: ImageTexture = null;
    var fileIconTexture: ImageTexture = null;

    public function buildTreeRoot() {
        var projectName = getEditor().projectFile.name;

        dirTreeCoroutines = new Array();
        singleColumnTree.clear();
        throbberParent.show();

        rootTreeItem = singleColumnTree.createItem();
        rootTreeItem.setText(0, projectName);

        var projectIconBytes = io.loadBytes("studio://icons/16/application-blue-studio.png");
        var projectIconImage = new Image();
        projectIconImage.loadPngFromBuffer(projectIconBytes);
        var projectIconTexture = ImageTexture.createFromImage(projectIconImage);

        var dirIconBytes = io.loadBytes("studio://icons/16/blue-folder.png");
        var dirIconImage = new Image();
        dirIconImage.loadPngFromBuffer(dirIconBytes);
        dirIconTexture = ImageTexture.createFromImage(dirIconImage);

        var fileIconBytes = io.loadBytes("studio://icons/16/document.png");
        var fileIconImage = new Image();
        fileIconImage.loadPngFromBuffer(fileIconBytes);
        fileIconTexture = ImageTexture.createFromImage(fileIconImage);

        var assetsItem: TreeItem = null;
        if (assetsDirectory != "") {
            assetsItem = singleColumnTree.createItem(rootTreeItem);
            assetsItem.setText(0, "Assets");
            assetsItem.setIcon(0, dirIconTexture);
        }

        var sourceItem = singleColumnTree.createItem(rootTreeItem);
        sourceItem.setText(0, "Scripts");
        sourceItem.setIcon(0, dirIconTexture);

        if (assetsDirectory != "")
            buildDirTree(assetsDirectory, assetsItem);
        buildDirTree(sourceDirectory, sourceItem);
        if (assetsDirectory != "")
            assetsItem.collapsed = true;
        sourceItem.collapsed = true;
    }

    var timeAccumulator = 1.0;
    var milisec = 0.05;

    public override function onProcess(deltaTime: Float) {
        timeAccumulator += deltaTime;
        if (timeAccumulator >= milisec) {
            timeAccumulator -= milisec;

            throbberRect.texture = throbberTextures[lastThrobberIndex];
            if (lastThrobberIndex == throbberMaxNumber - 1) {
                lastThrobberIndex = 0;
            }
            else {
                lastThrobberIndex++;
            }
        }

        for (dirTreeCoroutine in dirTreeCoroutines) {
            if (Coroutine.status(dirTreeCoroutine) != CoroutineState.Dead) {
                Coroutine.resume(dirTreeCoroutine);
            }
            else {
                dirTreeCoroutines.remove(dirTreeCoroutine);
            }
        }

        if (dirTreeCoroutines.length == 0) {
            throbberParent.hide();
        }
    }

    public function buildDirTree(dirPath: String, parentItem: TreeItem) {
        if (!StringTools.endsWith(dirPath, "/")) {
            dirPath += "/";
        }

        var dirTreeCoroutine = Coroutine.create(function() {
            var entries = FileSystem.readDirectory(dirPath);
            for (entry in entries) {
                if (FileSystem.isDirectory(dirPath + entry)) {
                    var dirItem = singleColumnTree.createItem(parentItem);
                    dirItem.setText(0, entry);
                    dirItem.setIcon(0, dirIconTexture);

                    buildDirTree(dirPath + entry, dirItem);
                    dirItem.collapsed = true;
                } else {
                    var fileItem = singleColumnTree.createItem(parentItem);
                    fileItem.setText(0, entry);
                    var filePath = dirPath + entry;
                    fileItem.setMetadata(0, filePath);
                    fileItem.setIcon(0, fileIconTexture);

                    for (fileHandler in fileHandlers) {
                        var endWith = StringTools.endsWith(entry, "." + fileHandler.extension);
                        if (endWith) {
                            var iconBytes = io.loadBytes(fileHandler.iconPath);
                            if (iconBytes != null) {
                                var iconImage = new Image();
                                iconImage.loadPngFromBuffer(iconBytes);
                                var iconTexture = ImageTexture.createFromImage(iconImage);
                                fileItem.setIcon(0, iconTexture);
                            }
                        }
                    }
                }
                Coroutine.yield();
            }
        });

        dirTreeCoroutines.push(dirTreeCoroutine);
        Coroutine.resume(dirTreeCoroutine);
    }

    public function loadIcon(path: String) {
        var iconBytes = io.loadBytes(path);
        if (iconBytes != null) {
            var iconImage = new Image();
            iconImage.loadPngFromBuffer(iconBytes);
            var iconTexture = ImageTexture.createFromImage(iconImage);
            return iconTexture;
        }
        return null;
    }
}