package sunaba.studio;

import sunaba.core.Color;
import sunaba.ui.StyleBoxEmpty;
import sunaba.core.StringArray;
import sunaba.ui.StyleBoxEmpty;
import sunaba.core.Reference;
import sunaba.input.InputEvent;
import sunaba.ui.Control;
import sunaba.input.InputEventMouseButton;
import sunaba.input.InputService;
import sunaba.core.native.NativeReference;
import sunaba.core.Vector2i;
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
import sunaba.ui.CenterContainer;

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

    var window: Window;
    public var windowSize:Vector2i;
    private var ogWindowSize: Vector2i;
    public var titlebarLmbPressed:Bool = false;
    public var clickcount = 0;
    public var timeSinceClick = 0.1;

    private var resizePreview: Bool = true;
    private var resizeThreshold: Float = 10.0;
    private var resizeThresholdBottomRight: Float = 0.25;

    public override function onReady() {
        window = getWindow();
        var displayScale = DisplayService.screenGetScale(window.currentScreen);
        if (OSService.getName() == "Windows") {
            var dpi = DisplayService.screenGetDpi(window.currentScreen);
            displayScale = dpi * 0.01;
        }
        window.contentScaleFactor = displayScale;
        windowSize = new Vector2i(cast 1152 * displayScale, cast 648 * displayScale);
        ogWindowSize = windowSize;
        window.size = windowSize;
        window.minSize = windowSize;
        window.alwaysOnTop = false;
        window.moveToCenter();
        window.extendToTitle = true;
        window.mode = WindowMode.windowed;
        window.unresizable = false;
        if (OSService.getName() == "macOS") {
            DisplayService.windowSetWindowButtonsOffset(new Vector2i(35, 37), window.getWindowId());
        }
        else {
            window.borderless = true;
        }

        var eventFunc = function(eventN: NativeReference) {
            if (window == null)
                return;

            if (InputService.isMouseButtonPressed(MouseButton.left) && !titlebarLmbPressed && window.mode == WindowMode.windowed && clickcount == 0) {
                titlebarLmbPressed = true;
                if (eventN.isClass("InputEventMouseButton")) {
                    var eventMouseButton = new InputEventMouseButton(eventN);
                    clickcount++;
                    // Top left
                    if (eventMouseButton.position.x < resizeThreshold && eventMouseButton.position.y < resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.fdiagsize);
                        window.startResize(WindowResizeEdge.topLeft);
                        return;
                    }
                    // Top Right
                    if (
                        eventMouseButton.position.x > window.getVisibleRect().size.x - resizeThreshold &&
                        eventMouseButton.position.y < resizeThreshold
                    ) {
                        DisplayService.cursorSetShape(CursorShape.bdiagsize);
                        window.startResize(WindowResizeEdge.topRight);
                        return;
                    }
                    // Top
                    if (eventMouseButton.position.y < resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.vsize);
                        window.startResize(WindowResizeEdge.top);
                        return;
                    }
                    window.startDrag();
                }     
            }
            else if (InputService.isMouseButtonPressed(MouseButton.left) && !titlebarLmbPressed) {
                titlebarLmbPressed = true;
                clickcount++;
            }
            else if (!InputService.isMouseButtonPressed(MouseButton.left) && titlebarLmbPressed) {
                titlebarLmbPressed = false;
            }

            if (clickcount == 2) {
                trace(clickcount);
                clickcount = 0;
                var maximizeButton = getNodeT(Button, "vbox/titlebar/hbox/maximizeButton");
                if (window.mode == WindowMode.maximized) {
                    var maximizedSize = window.size;
                    window.mode = WindowMode.windowed;
                    if (window.size.x == maximizedSize.x && window.size.y == maximizedSize.y) {
                        window.size = ogWindowSize;
                        window.moveToCenter();
                    }
                    else {
                        window.size = windowSize;
                    }
                    maximizeButton.text = "🗖";
                }
                else if (window.mode == WindowMode.windowed) {
                    windowSize = window.size;
                    window.mode = WindowMode.maximized;
                    maximizeButton.text = "🗗";
                }
            }
        };

        var windowTitle = getNodeT(Label, "vbox/titlebar/windowTitle");
        window.title = windowTitle.text;

        var titlebarSpacer: Control = getNodeT(Control, "vbox/titlebar/hbox/spacer");
        var iconContainer = getNodeT(Control, "vbox/titlebar/hbox/iconContainer");
        var iconRect = getNodeT(Control, "vbox/titlebar/hbox/iconContainer/icon");
        titlebarSpacer.guiInput.connect(eventFunc);
        iconContainer.guiInput.connect(eventFunc);
        iconRect.guiInput.connect(eventFunc);

        var styleBoxEmpty = new StyleBoxEmpty();
            
        var buttonFont = new SystemFont();
        if (OSService.getName() == "Windows") {
            buttonFont.fontNames = StringArray.fromArray([
                "Segoe MDL2 Assets",
                "Segoe UI Symbol",
                "Arial Unicode MS"
            ]);
        }
        else if (OSService.getName() == "Linux") {
            var fontNames = buttonFont.fontNames;
            fontNames.add("Noto Sans Symbols2");
            fontNames.add("DejaVu Sans");
            buttonFont.fontNames = fontNames;
            trace(fontNames.toArray().toString());
            trace(buttonFont.fontNames.toArray().toString());
        }

        var minimizeButton = getNodeT(Button, "vbox/titlebar/hbox/minimizeButton");
        minimizeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
        minimizeButton.focusMode = FocusModeEnum.none;
        minimizeButton.addThemeFontOverride("font", buttonFont);
        minimizeButton.text = "🗕";
        minimizeButton.alignment = HorizontalAlignment.center;
        var isMaximized = true;
        minimizeButton.pressed.add(() -> {
            if (window.mode != WindowMode.minimized) {
                isMaximized = window.mode == WindowMode.maximized;
                window.mode = WindowMode.minimized;
            }
            else {
                if (isMaximized == true) {
                    window.mode = WindowMode.maximized;
                }
                else {
                    window.mode = WindowMode.windowed;
                }
            }
        });

        var maximizeButton = getNodeT(Button, "vbox/titlebar/hbox/maximizeButton");
        maximizeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
        maximizeButton.focusMode = FocusModeEnum.none;
        maximizeButton.addThemeFontOverride("font", buttonFont);
        maximizeButton.text = "🗗";
        maximizeButton.alignment = HorizontalAlignment.center;
        if (window.mode == WindowMode.maximized) {
            maximizeButton.text = "🗗";
        }
        else {
            maximizeButton.text = "🗖";
        }
        maximizeButton.pressed.add(() -> {
            if (window.mode == WindowMode.maximized) {
                maximizeButton.text = "🗖";
                var maximizedSize = window.size;
                window.mode = WindowMode.windowed;
                if (window.size.x == maximizedSize.x && window.size.y == maximizedSize.y) {
                    window.size = ogWindowSize;
                    window.moveToCenter();
                }
                else {
                    window.size = windowSize;
                }
            }
            else if (window.mode == WindowMode.windowed) {
                maximizeButton.text = "🗗";
                windowSize = window.size;
                window.mode = WindowMode.maximized;
            }
        });

        var closeButton = getNodeT(Button, "vbox/titlebar/hbox/closeButton");
        closeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
        closeButton.focusMode = FocusModeEnum.none;
        closeButton.addThemeFontOverride("font", buttonFont);
        closeButton.text = "🗙";
        closeButton.alignment = HorizontalAlignment.center;
        closeButton.pressed.add(() -> {
            App.exit(0);
        });

        if (OSService.getName() == "macOS") {
            iconContainer.hide();
            minimizeButton.hide();
            maximizeButton.hide();
            closeButton.hide();
        }
    }

    public override function onProcess(delta:Float) {
        timeSinceClick -= delta;
        if (timeSinceClick <= 0.0) {
            timeSinceClick = 1.0;
            if (clickcount != 0) {
                clickcount = 0;
            }
        }

        if (OSService.getName() != "macOS") {
            window = getWindow();
            if (window != null) {
                if (window.mode != WindowMode.windowed) return;

                var windowsize = window.getVisibleRect().size;

                var mousePosition = window.getMousePosition();
                if (mousePosition.x < resizeThreshold && mousePosition.y < resizeThreshold) { // Top left
                    DisplayService.cursorSetShape(CursorShape.fdiagsize);
                    return;
                }
                if (mousePosition.x > windowsize.x - resizeThreshold && mousePosition.y < resizeThreshold) { // Top Right
                    DisplayService.cursorSetShape(CursorShape.bdiagsize);
                    return;
                }
                if (mousePosition.x < resizeThreshold && mousePosition.y > windowsize.y - resizeThreshold) { // Bottom left
                    DisplayService.cursorSetShape(CursorShape.bdiagsize);
                    return;
                }
                if (mousePosition.x > windowsize.x - resizeThreshold && mousePosition.y > windowsize.y - resizeThreshold) { // Bottom Right
                    DisplayService.cursorSetShape(CursorShape.fdiagsize);
                    return;
                }
                if (mousePosition.x < resizeThreshold) { // left
                    DisplayService.cursorSetShape(CursorShape.hsize);
                    return;
                }
                if (mousePosition.x > windowsize.x - resizeThreshold) { // Right
                    DisplayService.cursorSetShape(CursorShape.hsize);
                    return;
                }
                if (mousePosition.y < resizeThreshold) { // Top
                    DisplayService.cursorSetShape(CursorShape.vsize);
                    return;
                }
                if (mousePosition.y > windowsize.y - resizeThreshold) { // Bottom
                    DisplayService.cursorSetShape(CursorShape.vsize);
                    return;
                }
            }
        }
    }

    public override function onInput(event:InputEvent) {
        if (OSService.getName() != "macOS") {
            if (event.native.isClass("InputEventMouseButton")) {
                var eventMouseButton = Reference.castTo(event, InputEventMouseButton);
                window = getWindow();
                if (window.mode != WindowMode.windowed) return;
                if (
                    eventMouseButton.buttonIndex == MouseButton.left &&
                    eventMouseButton.pressed
                ) {
                    var localX = eventMouseButton.position.x;
                    var localY = eventMouseButton.position.y;

                    // Top left
                    if (localX < resizeThreshold && localY < resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.fdiagsize);
                        window.startResize(WindowResizeEdge.topLeft);
                        return;
                    }
                    // Top Right
                    if (
                        localX > window.getVisibleRect().size.x - resizeThreshold &&
                        localY < resizeThreshold
                    ) {
                        DisplayService.cursorSetShape(CursorShape.bdiagsize);
                        window.startResize(WindowResizeEdge.topRight);
                        return;
                    }
                    // Bottom left
                    if (
                        localX < resizeThreshold &&
                        localY > window.getVisibleRect().size.y - resizeThreshold
                    ) {
                        DisplayService.cursorSetShape(CursorShape.bdiagsize);
                        window.startResize(WindowResizeEdge.bottomLeft);
                        return;
                    }
                    // Bottom Right
                    if (
                        localX > window.getVisibleRect().size.x - resizeThreshold &&
                        localY > window.getVisibleRect().size.y - resizeThreshold
                    ) {
                        DisplayService.cursorSetShape(CursorShape.fdiagsize);
                        window.startResize(WindowResizeEdge.bottomRight);
                        return;
                    }
                    // Left
                    if (localX < resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.hsize);
                        window.startResize(WindowResizeEdge.left);
                        return;
                    }
                    // Right
                    if (localX > window.getVisibleRect().size.x - resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.hsize);
                        window.startResize(WindowResizeEdge.right);
                        return;
                    }
                    // Top
                    if (localY < resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.vsize);
                        window.startResize(WindowResizeEdge.top);
                        return;
                    }
                    // Bottom
                    if (localY > window.getVisibleRect().size.y - resizeThreshold) {
                        DisplayService.cursorSetShape(CursorShape.vsize);
                        window.startResize(WindowResizeEdge.bottom);
                        return;
                    }
                }
            }
        }
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
        var selected = splashRecentProjects.getSelected();
        if (selected != null) {
            var metadata: String = selected.getMetadata(0);
            trace(metadata);
            if (StringTools.endsWith(metadata, ".sproj")) {
                openProject(metadata);
            }
        }
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