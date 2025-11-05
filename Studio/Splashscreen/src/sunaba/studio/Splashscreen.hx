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

class Splashscreen extends Widget {
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
    }

    public function openProject(path: String) {
        var window = new Window();

        var appView = new AppView();
        window.addChild(appView);
        var args = appView.args;
        args.add(path);
        appView.init();

        var studioUtils = new NativeObject("res://Studio/StudioUtils.cs", new ArrayList(), ScriptType.csharp);
        if (studioUtils.isNull()) Debug.error("StudioUtils not found");
        var baseDir: String = studioUtils.call("GetBaseDirectory", new ArrayList());
        if (StringTools.contains(baseDir, "\\"))
            baseDir = StringTools.replace(baseDir, "\\", "/");
        if (!StringTools.endsWith(baseDir, "/"))
            baseDir += "/";

        appView.loadApp(baseDir + "editor.snb");

        window.closeRequested.connect(Callable.fromFunction(function() {
            window.queueFree();
        }));

        window.hide();
        addChild(window);
        window.hide();

        window.popupCentered();
    }
}