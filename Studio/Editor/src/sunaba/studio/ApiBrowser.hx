package sunaba.studio;
import sunaba.core.Color;
import sunaba.ui.CodeHighlighter;
import sunaba.ui.CodeEdit;
import sunaba.core.VariantType;
import haxe.xml.Fast;
import sunaba.io.IoInterface;
import sunaba.ui.TreeItem;
import sunaba.io.FileSystemIo;
import haxe.io.Path;
import sunaba.io.IoManager;
import sunaba.ui.TabContainer;
import sunaba.ui.Tree;
import sunaba.ui.Widget;
import sunaba.ui.Label;
import sunaba.ui.Control;
import sunaba.ui.Button;
import sunaba.desktop.Window;
import sunaba.core.Vector2i;
import sunaba.ui.VBoxContainer;
import sunaba.ui.HBoxContainer;
import sunaba.input.InputService;
import sunaba.core.native.NativeReference;
import sunaba.input.InputEventMouseButton;
import sunaba.core.Reference;
import sunaba.core.StringArray;
import sunaba.ui.StyleBoxEmpty;
import sunaba.input.InputEvent;
import sunaba.io.IoInterfaceZip;

class ApiBrowser extends Widget {
    public var editor: Editor;

    var menuBarControl: Control;
    public var window:Window;
    public var windowSize:Vector2i;
    private var ogWindowSize: Vector2i;
    public var titlebarLmbPressed:Bool = false;
    public var clickcount = 0;
    public var timeSinceClick = 0.1;
    public var windowTitle:Label;
    var maximizeButton: Button;
    var windowIsMaximized: Bool = false;

    private var resizePreview: Bool = true;
    private var resizeThreshold: Float = 10.0;
    private var resizeThresholdBottomRight: Float = 0.25;

    public var customTitlebar(get, set): Bool;
    function get_customTitlebar() {
        return window.borderless;
    }
    inline function set_customTitlebar(value: Bool): Bool {
        menuBarControl.visible = value;
        return window.borderless = value;
    }

    var isMaximized: Bool;

    private var vbox: VBoxContainer;
    private var menuBarHbox: HBoxContainer;

    private var apiTree: Tree;
    private var apiTabs: TabContainer;

    public function new(editor: Editor) {
        this.editor = editor;
        super();
    }

    public override function init() {
        load("studio://ApiBrowser.suml");
    }

    public override function onReady() {
        vbox = getNodeT(VBoxContainer, "vbox");
        menuBarHbox = getNodeT(HBoxContainer, "vbox/menuBarControl/hbox");

        window = getWindow();
        window.title = "API Reference - Sunaba Studio";
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


        menuBarControl = getNodeT(Control, "vbox/menuBarControl");
        var menuBarSpacer = getNodeT(Control, "vbox/menuBarControl/hbox/spacer");
        var eventFunc = function(eventN: NativeReference) {
            if (window == null && customTitlebar == false && OSService.getName() != "macOS")
                return;

            if (InputService.isMouseButtonPressed(MouseButton.left) && !titlebarLmbPressed && window.mode == WindowMode.windowed && clickcount == 0) {
                titlebarLmbPressed = true;
                if (eventN.isClass("InputEventMouseButton")) {
                    var eventMouseButton = new InputEventMouseButton(eventN);
                    clickcount++;
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
                var maximizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/maximizeButton");
                if (windowIsMaximized == true) {
                    var maximizedSize = window.size;
                    window.mode = WindowMode.windowed;
                    windowIsMaximized = false;
                    if (window.size.x == maximizedSize.x && window.size.y == maximizedSize.y) {
                        window.size = ogWindowSize;
                        window.moveToCenter();
                    }
                    else {
                        window.size = windowSize;
                    }
                    maximizeButton.text = "🗖";
                    if (OSService.getName() == "Windows") {
                        maximizeButton.text = "";
                    }
                }
                else if (windowIsMaximized == false) {
                    windowSize = window.size;
                    window.mode = WindowMode.maximized;
                    windowIsMaximized = true;
                    maximizeButton.text = "🗗";
                    if (OSService.getName() == "Windows") {
                        maximizeButton.text = "";
                    }
                }
            }
        };

        var iconContainer = getNodeT(Control, "vbox/menuBarControl/hbox/iconContainer");
        var iconRect = getNodeT(Control, "vbox/menuBarControl/hbox/iconContainer/icon");
        menuBarSpacer.guiInput.connect(eventFunc);
        iconContainer.guiInput.connect(eventFunc);
        iconRect.guiInput.connect(eventFunc);


        var styleBoxEmpty = new StyleBoxEmpty();

        var buttonFont: Font = new SystemFont();
        var buttonSysFont = new SystemFont();
        if (OSService.getName() == "Windows") {//
            buttonSysFont.fontNames = StringArray.fromArray([
                "Segoe Fluent icons",
                "Segoe MDL2 Assets"
            ]);
            buttonFont = buttonSysFont;
        }
        else if (OSService.getName() == "Linux") {
            var fontRes = ResourceLoaderService.load("res://Engine/Theme/fonts/NotoSansSymbols2-Regular.ttf");
            buttonFont = Reference.castTo(fontRes, Font);
        }

        var minimizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/minimizeButton");
        minimizeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
        minimizeButton.focusMode = FocusModeEnum.none;
        minimizeButton.addThemeFontOverride("font", buttonFont);
        var newCustomMinimumSize = minimizeButton.customMinimumSize;
        minimizeButton.text = "🗕";
        if (OSService.getName() == "Windows") {
            minimizeButton.text = "";
            newCustomMinimumSize.x = 40;
            minimizeButton.customMinimumSize = newCustomMinimumSize;
        }
        minimizeButton.alignment = HorizontalAlignment.center;
        isMaximized = true;
        minimizeButton.pressed.add(() -> {
            if (window.mode != WindowMode.minimized || windowIsMaximized == false) {
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

        maximizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/maximizeButton");
        maximizeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
        maximizeButton.focusMode = FocusModeEnum.none;
        maximizeButton.addThemeFontOverride("font", buttonFont);
        maximizeButton.text = "🗗";
        maximizeButton.alignment = HorizontalAlignment.center;
        if (OSService.getName() == "Windows") {
            maximizeButton.customMinimumSize = newCustomMinimumSize;
        }
        if (window.mode != WindowMode.windowed) {
            maximizeButton.text = "🗗";
            if (OSService.getName() == "Windows") {
                maximizeButton.text = "";
            }
        }
        else {
            maximizeButton.text = "🗖";
            if (OSService.getName() == "Windows") {
                maximizeButton.text = "";
            }
        }
        maximizeButton.pressed.add(() -> {
            if (windowIsFullscreen == true) {
                toggleFullscreen();
                return;
            }
            if (windowIsMaximized == true) {
                maximizeButton.text = "🗖";
                if (OSService.getName() == "Windows") {
                    maximizeButton.text = "";
                }
                var maximizedSize = window.size;
                window.mode = WindowMode.windowed;
                windowIsMaximized = false;
                if (window.size.x == maximizedSize.x && window.size.y == maximizedSize.y) {
                    window.size = ogWindowSize;
                    window.moveToCenter();
                }
                else {
                    window.size = windowSize;
                }
            }
            else {
                windowIsMaximized = true;
                maximizeButton.text = "🗗";
                if (OSService.getName() == "Windows") {
                    maximizeButton.text = "";
                }
                windowSize = window.size;
                window.mode = WindowMode.maximized;
            }
        });

        var closeButton = getNodeT(Button, "vbox/menuBarControl/hbox/closeButton");
        closeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
        closeButton.focusMode = FocusModeEnum.none;
        closeButton.addThemeFontOverride("font", buttonFont);
        closeButton.text = "🗙";
        if (OSService.getName() == "Windows") {
            closeButton.text = "";
            closeButton.customMinimumSize = newCustomMinimumSize;
        }
        closeButton.alignment = HorizontalAlignment.center;
        closeButton.pressed.add(() -> {
            window.queueFree();
        });
        window.closeRequested.add(() -> {
            window.queueFree();
        });

        if (OSService.getName() == "macOS") {
            iconContainer.hide();
            minimizeButton.hide();
            maximizeButton.hide();
            closeButton.hide();
        }
        else {
            //customTitlebar = editor.customTitlebar;
            customTitlebar = false;
        }

        apiTree = getNodeT(Tree, "vbox/hsplit/tree");
        apiTabs = getNodeT(TabContainer, "vbox/hsplit/workspace");
        var apiTabBar = apiTabs.getTabBar();
        apiTabBar.tabCloseDisplayPolicy = 1;
        apiTabBar.tabClosePressed.add((tab: Int) -> {
            var tabControl = apiTabs.getTabControl(tab);
            tabControl.queueFree();
        });
        apiTree.itemActivated.add(() -> {
            var selected = apiTree.getSelected();
            var metadata = selected.getMetadata(0);
            if (metadata.getType() == VariantType.string) {
                var codeEdit = new CodeEdit();
                codeEdit.text = apiIo.loadText(metadata);
                codeEdit.clearUndoHistory();
                codeEdit.editable = false;
                apiTabs.addChild(codeEdit);
                var idx = apiTabs.getTabIdxFromControl(codeEdit);
                apiTabs.setTabTitle(idx, selected.getText(0));
                apiTabs.setTabIcon(idx, selected.getIcon(0));
                apiTabs.currentTab = idx;

                var highlighter = new CodeHighlighter();
                codeEdit.syntaxHighlighter = highlighter;

                highlighter.numberColor = Color.code("#df7aff");
                highlighter.symbolColor = Color.code("#9a9a9a");
                highlighter.functionColor = Color.code("#83cdff");
                highlighter.memberVariableColor = Color.code("#00cebe");
                highlighter.addKeywordColor("extern", Color.code("#9f6eff"));
                highlighter.addKeywordColor("typedef", Color.code("#9f6eff"));
                highlighter.addKeywordColor("class", Color.code("#5195ff"));
                highlighter.addKeywordColor("abstract", Color.code("#5195ff"));
                highlighter.addKeywordColor("extends", Color.code("#5195ff"));
                highlighter.addKeywordColor("interface", Color.code("#5195ff"));
                highlighter.addKeywordColor("enum", Color.code("#5195ff"));
                highlighter.addKeywordColor("function", Color.code("#5195ff"));
                highlighter.addKeywordColor("var", Color.code("#5195ff"));
                highlighter.addKeywordColor("new", Color.code("#5195ff"));
                highlighter.addKeywordColor("macro", Color.code("#5195ff"));
                highlighter.addKeywordColor("import", Color.code("#9f6eff"));
                highlighter.addKeywordColor("package", Color.code("#9f6eff"));
                highlighter.addKeywordColor("using", Color.code("#9f6eff"));
                highlighter.addKeywordColor("from", Color.code("#9f6eff"));
                highlighter.addKeywordColor("to", Color.code("#9f6eff"));
                highlighter.addKeywordColor("in", Color.code("#9f6eff"));
                highlighter.addKeywordColor("return", Color.code("#ff9d00"));
                highlighter.addKeywordColor("break", Color.code("#ff9d00"));
                highlighter.addKeywordColor("continue", Color.code("#ff9d00"));
                highlighter.addKeywordColor("if", Color.code("#ff9d00"));
                highlighter.addKeywordColor("else", Color.code("#ff9d00"));
                highlighter.addKeywordColor("switch", Color.code("#ff9d00"));
                highlighter.addKeywordColor("case", Color.code("#ff9d00"));
                highlighter.addKeywordColor("default", Color.code("#ff9d00"));
                highlighter.addKeywordColor("while", Color.code("#ff9d00"));
                highlighter.addKeywordColor("do", Color.code("#ff9d00"));
                highlighter.addKeywordColor("for", Color.code("#ff9d00"));
                highlighter.addKeywordColor("try", Color.code("#ff9d00"));
                highlighter.addKeywordColor("catch", Color.code("#ff9d00"));
                highlighter.addKeywordColor("throw", Color.code("#ff9d00"));
                highlighter.addKeywordColor("null", Color.code("#ff5fae"));
                highlighter.addKeywordColor("true", Color.code("#ff9d00"));
                highlighter.addKeywordColor("false", Color.code("#ff9d00"));
                highlighter.addKeywordColor("this", Color.code("#ff9d00"));
                highlighter.addKeywordColor("super", Color.code("#ff9d00"));
                highlighter.addKeywordColor("untyped", Color.code("#9f6eff"));
                highlighter.addKeywordColor("dynamic", Color.code("#9f6eff"));
                highlighter.addKeywordColor("override", Color.code("#9f6eff"));
                highlighter.addKeywordColor("implements", Color.code("#ff9d00"));
                highlighter.addKeywordColor("private", Color.code("#9f6eff"));
                highlighter.addKeywordColor("protected", Color.code("#9f6eff"));
                highlighter.addKeywordColor("public", Color.code("#9f6eff"));
                highlighter.addKeywordColor("static", Color.code("#9f6eff"));
                highlighter.addKeywordColor("trace", Color.code("#ff8080"));
                highlighter.addColorRegion("/*", "*/", Color.code("#9bda7b"), false);
                highlighter.addColorRegion("//", "", Color.code("#9bda7b"), true);
                highlighter.addColorRegion("\"", "\"", Color.code("#9bda7b"), false);
                highlighter.addColorRegion("'", "'", Color.code("#9bda7b"), false);
            }
        });

        loadAllApis();
    }

    private var haxelibIo: FileSystemIo = null;
    private var apiIo: IoManager = null;

    public function loadAllApis() {
        if (apiIo == null) {
            apiIo = new IoManager();
        }
        if (haxelibIo == null) {
            var haxelibDir = Path.addTrailingSlash(Sys.getCwd()) + ".haxelib/";
            haxelibIo = new FileSystemIo();
            haxelibIo.open(haxelibDir, "haxelib://");
            apiIo.register(haxelibIo);
        }

        var rootItem = apiTree.createItem();
        apiTree.hideRoot = true;

        var libraries = haxelibIo.getFileListAll("/", false);

        for (i in 0...libraries.size()) {
            var library: String = libraries.get(i);
            trace(library);
            var apiName = library.split("/")[2];
            trace(apiName);
            var dirPath = Path.addTrailingSlash(library) + "0,0,0/";
            if (haxelibIo.directoryExists(dirPath)) {
                loadApi(dirPath, apiName);
            }
        }
    }

    public function loadApi(path: String, apiName: String) {
        
        var item = apiTree.createItem();
        item.setText(0, apiName);
        item.setIcon(0, editor.loadIcon("studio://icons/16/haxe.png"));
        item.collapsed = true;

        var pathIo = new FileSystemIo();
        pathIo.open(haxelibIo.getFilePath(path), apiName + "://");
        apiIo.register(pathIo);

        var directories = pathIo.getFileListAll("/", false);

        for (i in 0...directories.size()) {
            var dir = directories.get(i);
            recurseDir(dir, item, pathIo);
        }

        var hxFiles = pathIo.getFileListAll(".hx", false);

        for (i in 0...hxFiles.size()) {
            var hxFilePath: String = hxFiles.get(i);
            var hxFileName = hxFilePath.split("/").pop().split(".")[0];
            var codeItem = apiTree.createItem(item);
            codeItem.setText(0, hxFileName);
            codeItem.setIcon(0, editor.loadIcon("studio://icons/16/document-code.png"));
            codeItem.setMetadata(0, hxFilePath);
        }
    }

    private function recurseDir(path: String, parent: TreeItem, pathIo: IoInterface) {
        var item = apiTree.createItem(parent);
        var pathArr = path.split("/");
        var packageName = pathArr[pathArr.length - 1];
        if (packageName == "") {
            packageName = pathArr[pathArr.length - 2];
        }

        item.setText(0, packageName);
        item.setIcon(0, editor.loadIcon("studio://icons/16/blue-folder.png"));
        item.collapsed = true;

        var directories = pathIo.getFileList(path, "/", false);

        for (i in 0...directories.size()) {
            var dir = directories.get(i);
            recurseDir(dir, item, pathIo);
        }

        var hxFiles = pathIo.getFileList(path, ".hx", false);

        for (i in 0...hxFiles.size()) {
            var hxFilePath: String = hxFiles.get(i);
            var hxFileName = hxFilePath.split("/").pop().split(".")[0];
            var codeItem = apiTree.createItem(item);
            codeItem.setText(0, hxFileName);
            codeItem.setIcon(0, editor.loadIcon("studio://icons/16/document-code.png"));
            codeItem.setMetadata(0, hxFilePath);
        }
    }

    public override function onProcess(delta:Float) {
        if (OSService.getName() == "macOS") {
            if (OSService.getName() == "macOS") {
                menuBarControl.visible = window.mode != WindowMode.fullscreen;
            }
        }
        if ((windowIsMaximized == false) && OSService.getName() != "macOS" && customTitlebar == true) {
            vbox.offsetBottom = -5;
            vbox.offsetLeft = 5;
            vbox.offsetRight = -5;
            vbox.offsetTop = 5;
            menuBarHbox.offsetLeft = 0;
            menuBarHbox.offsetRight = 0;
        }
        else {
            vbox.offsetBottom = 0;
            vbox.offsetLeft = 0;
            vbox.offsetRight = 0;
            if (menuBarControl.visible) {
                vbox.offsetTop = 5;
                menuBarHbox.offsetLeft = 5;
                menuBarHbox.offsetRight = -5;
            }
            else {
                vbox.offsetTop = 0;
            }
        }

        timeSinceClick -= delta;
        if (timeSinceClick <= 0.0) {
            timeSinceClick = 1.0;
            if (clickcount != 0) {
                clickcount = 0;
            }
        }

        if (OSService.getName() != "macOS" && customTitlebar == true) {
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

    public override function onInput(event: InputEvent) {
        if (OSService.getName() != "macOS") {
            if (InputService.isKeyLabelPressed(Key.ctrl) && InputService.isKeyLabelPressed(Key.f1)) {
                App.exit(0);
            }
            if (InputService.isKeyLabelPressed(Key.f2)) {
                toggleMenuBar();
            }
            if (InputService.isKeyLabelPressed(Key.f11)) {
                toggleFullscreen();
            }
        }
        else {
            if (InputService.isKeyLabelPressed(Key.meta) && InputService.isKeyLabelPressed(Key.f)) {
                toggleFullscreen();
            }
            if (InputService.isKeyLabelPressed(Key.meta) && InputService.isKeyLabelPressed(Key.q)) {
                App.exit(0);
            }
        }

        if (OSService.getName() != "macOS" && customTitlebar == true) {
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

    inline  function toggleMenuBar() {
        menuBarControl.visible = !menuBarControl.visible;
    }

    public var windowIsFullscreen: Bool = false;

    inline function toggleFullscreen() {
        var window = getWindow();
        if (windowIsMaximized != true) {
            window.mode = WindowMode.fullscreen;
            windowIsFullscreen == true;
            windowIsMaximized = true;
        }
        else {
            if (isMaximized == true) {
                window.mode = WindowMode.maximized;
                windowIsMaximized = true;
            }
            else {
                window.mode = WindowMode.windowed;
                windowIsMaximized = false;
            }
            windowIsFullscreen = false;
        }
        if (window.mode != WindowMode.windowed) {
            maximizeButton.text = "🗗";
            if (OSService.getName() == "Windows") {
                maximizeButton.text = "";
            }
        }
        else {
            maximizeButton.text = "🗖";
            if (OSService.getName() == "Windows") {
                maximizeButton.text = "";
            }
        }
    }


}