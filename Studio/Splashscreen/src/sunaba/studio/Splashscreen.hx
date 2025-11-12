package sunaba.studio;

import sunaba.ui.Widget;
import sunaba.ui.Panel;
import sunaba.ui.VBoxContainer;
import sunaba.ui.HBoxContainer;
import sunaba.ui.TextureRect;
import sunaba.ui.Label;
import sunaba.ui.Button;
import sunaba.ui.Tree;
import sunaba.core.Callable;
import sunaba.desktop.FileDialog;
import sunaba.core.ArrayList;
import sunaba.core.Variant;
import sunaba.core.TypedArray;
import sunaba.core.VariantNative;
import sunaba.desktop.Window;
import sunaba.core.native.NativeObject;
import sunaba.core.native.ScriptType;
import sunaba.studio.RecentProjects;

class Splashscreen extends Widget {

    var recentProjects: RecentProjects;
    var splashRecentProjects: Tree;

    public override function init() {
        load("app://Splashscreen.suml");

        var openProjectButton: Button = getNodeT(Button, "vbox/panel/vbox/header/hbox/openProject");
        openProjectButton.pressed.connect(Callable.fromFunction(function() {
            var fileDialog = new FileDialog();
            fileDialog.fileMode = FileDialogMode.openFile;
            fileDialog.useNativeDialog = true;
            fileDialog.access = 2;
            fileDialog.title = "Open project";
            fileDialog.addFilter("*.sproj", "Sunaba project");
            addChild(fileDialog);

            fileDialog.fileSelected.connect(Callable.fromFunction(function(path: String) {
                fileDialog.hide();
                fileDialog.queueFree();
                trace(path);
                openProject(path);
            }));

            fileDialog.popupCentered();
        }));

        splashRecentProjects = getNodeT(Tree, "vbox/panel/vbox/recentProjects");
        splashRecentProjects.itemActivated.connect(Callable.fromFunction(function() {
            onRecentProjectSelected();
        }));

        reloadRecentProjects();
    }

    public function reloadRecentProjects() {
        var recentProjectsPath = "user://recentProjects.json";
        if (io.fileExists(recentProjectsPath)) {
            var recentProjectsStr = io.loadText(recentProjectsPath);
            recentProjects = haxe.Json.parse(recentProjectsStr);
        }
        else {
            recentProjects = { list: [] };
            var recentProjectsStr = haxe.Json.stringify(recentProjects);
            io.saveText(recentProjectsPath, recentProjectsStr);
        }

        splashRecentProjects.clear();
        splashRecentProjects.hideRoot = true;
        var rootItem = splashRecentProjects.createItem();

        for (index in 0...recentProjects.list.length) {
            var projPath = recentProjects.list[index];
            var projName = "Unknown";
            var pathParts = projPath.split("\\").join("/").split("/");
            if (pathParts.length > 0) {
                projName = pathParts[pathParts.length - 1];
                projName = StringTools.replace(projName, ".sproj", "");
            }
            var projectItem = splashRecentProjects.createItem(rootItem);
            projectItem.setText(0, projName);
            var projecticonTextureData = io.loadBytes("app://icons/32/application-blue-studio.png");
            var projecticonImage = new Image();
            projecticonImage.loadPngFromBuffer(projecticonTextureData);
            var projecticonTexture = ImageTexture.createFromImage(projecticonImage);
            projectItem.setIcon(0, projecticonTexture);
            projectItem.setMetadata(0, projPath);
        }
    }

    public function onRecentProjectSelected() {
        trace("");
        var selected = splashRecentProjects.getSelected();
        trace("");
        if (selected != null) {
            trace("");
            var metadata: String = selected.getMetadata(0);
            trace("");
            trace(metadata);
            trace("");
            if (StringTools.endsWith(metadata, ".sproj")) {
                trace("");
                openProject(metadata);
                trace("");
            }
            trace("");
        }
        trace("");
    }

    public function openProject(path: String) {
        var appView = new DesktopAppView();
        getParent().addChild(appView);
        var args = appView.args;
        args.add(path);
        appView.init();
        appView.setVar("projectPath", path);

        var studioUtils = new NativeObject("res://Studio/StudioUtils.cs", new ArrayList(), ScriptType.csharp);
        if (studioUtils.isNull()) Debug.error("StudioUtils not found");
        var baseDir: String = studioUtils.call("GetBaseDirectory", new ArrayList());
        if (StringTools.contains(baseDir, "\\"))
            baseDir = StringTools.replace(baseDir, "\\", "/");
        if (!StringTools.endsWith(baseDir, "/"))
            baseDir += "/";

        var window = getWindow();
        window.unresizable = false;
        window.extendToTitle = true;
        window.mode = WindowMode.maximized;

        appView.loadApp(baseDir + "editor.snb");
        queueFree();
    }
}