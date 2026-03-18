package sunaba.studio;

import sunaba.studio.explorer.PathType;
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
import sunaba.studio.explorer.NewFileWidget;
import sunaba.desktop.ConfirmationDialog;

class Explorer extends EditorWidget {
    var reloadButton: Button;
    var newButton: MenuButton;
    var hamburgerMenuButton: Button;

    var throbberParent: Control;
    var throbberRect: TextureRect;

    var singleColumnTree: Tree;

    var throbberTextures = new Array<ImageTexture>();
    var throbberMaxNumber = 0;

    public var projectDirectory = "";
    public var assetsDirectory ="";
    public var sourceDirectory = "";

    public var fileHandlers: Array<FileHandler> = [];

    public var newFileDialog: ConfirmationDialog;
    public var newFileWidget: NewFileWidget;

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
        if (texture != null && texture.isObjectValid()) {
            throbberRect.texture = texture;
        }

        reloadButton.pressed.connect(Callable.fromFunction(function() {
            if (projectDirectory != "") {
                buildTreeRoot();
            }
        }));

        singleColumnTree = getNodeT(Tree, "vbox/view/singleColumn/tree");

        newFileDialog = getNodeT(ConfirmationDialog, "newFileDialog");
        newFileDialog.contentScaleFactor = getWindow().contentScaleFactor;
        var nfwMinSize = newFileDialog.minSize;
        nfwMinSize.x = Std.int(nfwMinSize.x * newFileDialog.contentScaleFactor);
        nfwMinSize.y = Std.int(nfwMinSize.y * newFileDialog.contentScaleFactor);
        newFileDialog.minSize = nfwMinSize;
        newFileWidget = new NewFileWidget(this);
        newFileDialog.addChild(newFileWidget);
    }

    public function startExplorer() {
        var projFilePathArray  = getEditor().projectFilePath.split("\\").join("/").split("/");
        if (projFilePathArray.length > 0) {
            projectDirectory = projFilePathArray.slice(0, projFilePathArray.length - 1).join("/");

            trace("ProjectTree initialized with directory: " + projectDirectory);

            if (getEditor().projectFile.assetsdir != null
            && getEditor().projectFile.assetsdir != ""
            && !StringTools.contains(getEditor().projectFile.assetsdir, "null"))
                assetsDirectory = projectDirectory + "/" + getEditor().projectFile.assetsdir + "/";
            else
                assetsDirectory = "";

            sourceDirectory = projectDirectory + "/" + getEditor().projectFile.scriptdir + "/";

            trace("Assets Directory: " + assetsDirectory);
            trace("Source Directory: " + sourceDirectory);

            if (assetsDirectory != "") {
                var projectIo = new FileSystemIo();
                projectIo.open(assetsDirectory, getEditor().projectFile.rootUrl);
                getEditor().projectIo = projectIo;
            }

            var sourceIo = new FileSystemIo();
            sourceIo.open(sourceDirectory, "src://");
            getEditor().sourceIo = sourceIo;

            singleColumnTree.itemActivated.connect(Callable.fromFunction(function() {
                var treeItem = singleColumnTree.getSelected();
                onTreeItemActivated(treeItem);
            }));

            var newMenu = newButton.getPopup();
        
            newMenu.addIconItem(loadIcon("studio://icons/16/blue-folder.png"), "Folder");
            newMenu.addIconItem(loadIcon("studio://icons/16/document.png"), "File");

            newMenu.idPressed.add((id: Int) -> {
                trace(id);
                if (id == 0) {
                    Debug.error("Folder creation not implemented.");
                }
                else if (id == 1) {
                    var selectedItem = singleColumnTree.getSelected();
                    if (selectedItem != null) {
                        var dirPath: String = selectedItem.getMetadata(0);
                        if (dirPath == "Root")
                            return;
                        if (!StringTools.endsWith(dirPath, "/")) {
                            var dirPathArray = dirPath.split("/");
                            dirPathArray = dirPathArray.slice(dirPathArray.length);
                            dirPath = dirPathArray.join("/");
                        }
                        var pathType: PathType = -1;
                        trace(dirPath);
                        trace(StringTools.startsWith(dirPath, assetsDirectory));
                        trace(StringTools.startsWith(dirPath, sourceDirectory));
                        if (StringTools.startsWith(dirPath, assetsDirectory))
                            pathType = PathType.assetFile;
                        else if (StringTools.startsWith(dirPath, sourceDirectory))
                            pathType = PathType.scriptFile;

                        if (pathType != -1) {
                            newFileWidget.open(pathType, dirPath);
                            newFileDialog.popupCentered();
                        }
                    }
                }
            });

            buildTreeRoot();
        }
    }

    public function newAssetFile(dirPath: String) {
        newFileWidget.open(PathType.assetFile, dirPath);
        newFileDialog.popupCentered();
    }

    public function onTreeItemActivated(item: TreeItem) {
        var metadata = item.getMetadata(0);
        if (metadata.getType() == VariantType.string) {
            var path: String = metadata;
            openFile(path);
        }
    }

    public function openFile(path: String) {
        for (fileHandler in fileHandlers) {
            if (StringTools.endsWith(path, "." + fileHandler.extension)) {
                fileHandler.openFile(path);
                break;
            }
        }
    }

    var lastThrobberIndex = 0;

    var dirTreeCoroutines : Array<Coroutine<()->Void>> = new Array();

    var rootTreeItem: TreeItem = null;

    var dirIconTexture: ImageTexture = null;
    var fileIconTexture: ImageTexture = null;

    public inline function refresh() {
        buildTreeRoot();
    }

    public function buildTreeRoot() {
        var projectName = getEditor().projectFile.name;

        dirTreeCoroutines = new Array();
        singleColumnTree.clear();
        throbberParent.show();

        rootTreeItem = singleColumnTree.createItem();
        rootTreeItem.setText(0, projectName);
        rootTreeItem.setMetadata(0, "Root");

        var projectIconBytes = io.loadBytes("studio://icons/16/application-blue-studio.png");
        var projectIconImage = new Image();
        projectIconImage.loadPngFromBuffer(projectIconBytes);
        var projectIconTexture = ImageTexture.createFromImage(projectIconImage);
        rootTreeItem.setIcon(0, projectIconTexture);

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
            assetsItem.setMetadata(0, assetsDirectory);
        }

        var sourceItem = singleColumnTree.createItem(rootTreeItem);
        sourceItem.setText(0, "Scripts");
        sourceItem.setIcon(0, dirIconTexture);
        sourceItem.setMetadata(0, sourceDirectory);

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

            if (throbberTextures[lastThrobberIndex] != null && throbberTextures[lastThrobberIndex].isObjectValid())
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
                if (StringTools.startsWith(entry, ".")) continue;
                if (FileSystem.isDirectory(dirPath + entry)) {
                    var dirItem = singleColumnTree.createItem(parentItem);
                    dirItem.setText(0, entry);
                    dirItem.setIcon(0, dirIconTexture);

                    buildDirTree(dirPath + entry, dirItem);
                    dirItem.setMetadata(0, dirPath + entry + "/");
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