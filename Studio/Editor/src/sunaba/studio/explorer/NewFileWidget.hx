package sunaba.studio.explorer;

import sunaba.desktop.FileDialog;
import lua.Package;
import sunaba.ui.Widget;
import sunaba.ui.ItemList;
import sunaba.ui.LineEdit;
import sunaba.ui.Button;

class NewFileWidget extends Widget {
    private var _explorer: Explorer;

    private var assetFileTemplates: Array<FileTemplate>;
    private var scriptFileTemplates: Array<FileTemplate>;

    private var assetLastSelected: FileTemplate;
    private var scriptLastSelected: FileTemplate;

    private var pathType: PathType;
    private var baseDir: String;

    private var assetFilePath: String = "";
    private var scriptFilePath: String = "";

    private var assetFileName: String = "";
    private var scriptFileName: String = "";

    private var itemList: ItemList;
    private var lineEdit: LineEdit;
    private var browseButton: Button;

    public function new(pExplorer: Explorer) {
        _explorer = pExplorer;
        super();
    }

    public override function init() {
        load("studio://NewFileWidget.suml");

        itemList = getNodeT(ItemList, "vbox/itemList");
        lineEdit = getNodeT(LineEdit, "vbox/hbox/lineEdit");
        browseButton = getNodeT(Button, "vbox/hbox/browseButton");

        browseButton.pressed.add(() -> {
            var fileDialog = new FileDialog();
            fileDialog.mode = FileDialogMode.saveFile;
            var realBasePath = "";
            if (pathType == PathType.assetFile) {
                realBasePath = _explorer.getEditor().projectIo.getFilePath(baseDir);
                fileDialog.rootSubfolder = _explorer.assetsDirectory;
                fileDialog.currentFile = StringTools.replace(assetFilePath, baseDir, "");
            }
            else if (pathType == PathType.scriptFile) {
                realBasePath = StringTools.replace(baseDir, "src://", _explorer.sourceDirectory);
                fileDialog.rootSubfolder = _explorer.sourceDirectory;
                fileDialog.currentFile = StringTools.replace(scriptFilePath, baseDir, "");
            }
            fileDialog.currentDir = realBasePath;
            fileDialog.access = 2;
            if (pathType == PathType.assetFile) {
                fileDialog.addFilter("*" + assetLastSelected.fileExtension, assetLastSelected.name);
                fileDialog.title = "Set Asset File Path";
            }
            else if (pathType == PathType.scriptFile) {
                fileDialog.addFilter("*" + scriptLastSelected.fileExtension, scriptLastSelected.name);
                fileDialog.title = "Set Script File Path";
            }
            addChild(fileDialog);
            fileDialog.hide();

            fileDialog.fileSelected.add((path: String) -> {
                var filePath = path;
                var fileName = filePath.split("/").pop().split(".")[0];
                if (pathType == PathType.assetFile) {
                    filePath = _explorer.getEditor().projectIo.getFileUrl(path);
                    assetFilePath = filePath;
                    assetFileName = fileName;
                }
                else if (pathType == PathType.scriptFile) {
                    filePath = StringTools.replace(path, _explorer.sourceDirectory, "src://");
                    scriptFilePath = filePath;
                    scriptFileName = fileName;
                }
                var filePathArray = filePath.split("/");
                baseDir = filePathArray.slice(filePathArray.length).join("/");
                lineEdit.text = filePath;
                fileDialog.queueFree();
            });

            fileDialog.popupCentered();
        });
    }

    public function addAssetFileTemplate(name:String, fileExtension:String, icon: Texture2D, createFile: String->Void) {
        var template = new FileTemplate(name, fileExtension, icon, createFile);
        if (assetFileTemplates == null) {
            assetFileTemplates = [];
        }
        assetFileTemplates.push(template);
        return template;
    }

    public function addScriptFileTemplate(name:String, fileExtension:String, icon: Texture2D, createFile: String->Void) {
        if (fileExtension != ".hx")
            throw "Script file must end in '.hx'";
        var template = new FileTemplate(name, fileExtension, icon, createFile);
        if (scriptFileTemplates == null) {
            scriptFileTemplates = [];
        }
        scriptFileTemplates.push(template);
        return template;
    }

    public function removeAssetFileTemplate(template: FileTemplate) {
        if (assetFileTemplates != null) {
            var index = assetFileTemplates.indexOf(template);
            if (index >= 0) {
                assetFileTemplates.splice(index, 1);
            }
        }
    }

    public function removeScriptFileTemplate(template: FileTemplate) {
        if (scriptFileTemplates != null) {
            var index = scriptFileTemplates.indexOf(template);
            if (index >= 0) {
                scriptFileTemplates.splice(index, 1);
            }
        }
    }

    public function open(pType: PathType, pBaseDir: String) {
        pathType = pType;
        baseDir = pBaseDir;

        if (!StringTools.endsWith(baseDir, "/")) {
            baseDir += "/";
        }
        if (!StringTools.startsWith(baseDir, "assets://") && pathType == PathType.assetFile) {
            baseDir = _explorer.getEditor().projectIo.getFileUrl(baseDir);
        }
        else if (!StringTools.startsWith(baseDir, "src://") && pathType == PathType.scriptFile) {
            baseDir = StringTools.replace(baseDir, _explorer.sourceDirectory, "src://");
        }
        if (!StringTools.endsWith(baseDir, "/")) {
            baseDir += "/";
        }
        
        if (pathType == PathType.assetFile) {
            if (assetLastSelected == null) {
                assetSelect(0);
            }

            itemList.clear();
            for (fileTemplate in assetFileTemplates) {
                var item = itemList.addItem(fileTemplate.name, fileTemplate.icon, true);
            }
        }
        else if (pathType == PathType.scriptFile) {
            if (scriptLastSelected == null) {
                scriptSelect(0);
            }

            itemList.clear();
            for (fileTemplate in scriptFileTemplates) {
                var item = itemList.addItem(fileTemplate.name, fileTemplate.icon, true);
            }
        }

        getWindow().popupCentered();
    }

    private function assetSelect(index: Int) {
        var fileName = "";
        var oldFileName = assetLastSelected.name;
        if (StringTools.contains(oldFileName, " "))
            oldFileName = StringTools.replace(oldFileName, " ", "");

        assetLastSelected = assetFileTemplates[index];
        fileName = assetLastSelected.name;
        if (StringTools.contains(fileName, " "))
            fileName = StringTools.replace(fileName, " ", "");

        if (assetFilePath != "") {
            var lastFileName = assetFilePath.split("/").pop().split(".")[0];
            if (lastFileName != oldFileName)
                fileName = lastFileName;
        }

        assetFileName = fileName;
        assetFilePath = baseDir + fileName + assetLastSelected.fileExtension;
        lineEdit.text = assetFilePath;
    }

    private function scriptSelect(index: Int) {
        var fileName = "";
        var oldFileName = scriptLastSelected.name;
        if (StringTools.contains(oldFileName, " "))
            oldFileName = StringTools.replace(oldFileName, " ", "");

        scriptLastSelected = scriptFileTemplates[index];
        fileName = scriptLastSelected.name;
        if (StringTools.contains(fileName, " "))
            fileName = StringTools.replace(fileName, " ", "");

        if (scriptFilePath != "") {
            var lastFileName = scriptFilePath.split("/").pop().split(".")[0];
            if (lastFileName != oldFileName)
                fileName = lastFileName;
        }

        scriptFileName = fileName;
        scriptFilePath = baseDir + fileName + scriptLastSelected.fileExtension;
        lineEdit.text = scriptFilePath;
    }
    
}