package sunaba.studio;

import haxe.crypto.Base64;
import haxe.io.Path;
import sunaba.desktop.FileDialog;
import haxe.Json;
import haxe.macro.Expr.Catch;
import sunaba.desktop.AcceptDialog;
import sunaba.core.AABB;
import sunaba.studio.fileHandlers.SmdlBinaryFileHandler;
import sunaba.core.Signal;
import sunaba.core.native.NativeObject;
import sunaba.core.Dictionary;
import sunaba.core.ByteArray;
import sunaba.core.Color;
import sunaba.input.InputEventMouseButton;
import sunaba.core.Reference;
import sunaba.ui.StyleBox;
import sunaba.ui.Widget;
import sunaba.ui.Panel;
import sunaba.ui.VBoxContainer;
import sunaba.ui.Label;
import sunaba.ui.MenuBar;
import sunaba.desktop.PopupMenu;
import sunaba.ui.HBoxContainer;
import sunaba.ui.Button;
import sunaba.core.Vector2i;
import sunaba.HorizontalAlignment;
import sunaba.ui.HSplitContainer;
import sunaba.ui.TabContainer;
import sunaba.desktop.Window;
import sunaba.io.FileSystemIo;
import sunaba.ui.Control;
import sunaba.core.native.NativeReference;
import sunaba.input.InputService;
import sunaba.core.Callable;
import sunaba.PlatformService;
import sunaba.PlatformDeviceType;
import haxe.Exception;
import sunaba.ui.ButtonGroup;
import sunaba.core.Vector2;
import sys.io.File;
import sys.FileSystem;
import sunaba.studio.fileHandlers.HxFileHandler;
import sunaba.input.InputEvent;
import sunaba.GameEvent;
import lua.Coroutine;
import sunaba.ui.ProgressBar;
import sunaba.ui.SubViewportContainer;
import sunaba.SubViewport;
import sunaba.core.ArrayList;
import sunaba.studio.fileHandlers.SmdlFileHander;
import sunaba.studio.fileHandlers.VpfbFileHandler;
import sunaba.studio.fileHandlers.VscnFileHandler;
import sunaba.studio.fileHandlers.MapFileHandler;
import sunaba.studio.fileHandlers.BmpFileHandler;
import sunaba.studio.fileHandlers.DdsFileHandler;
import sunaba.studio.fileHandlers.JpegFileHandler;
import sunaba.studio.fileHandlers.JpgFileHandler;
import sunaba.studio.fileHandlers.KtxFileHandler;
import sunaba.studio.fileHandlers.PngFileHandler;
import sunaba.studio.fileHandlers.SvgFileHandler;
import sunaba.studio.fileHandlers.TgaFileHandler;
import sunaba.studio.fileHandlers.WebpFileHandler;
import sunaba.studio.fileHandlers.Mp3FileHandler;
import sunaba.studio.fileHandlers.OggVorbisFileHandler;
import sunaba.studio.fileHandlers.WavFileHandler;
import sunaba.io.IoManager;
import sunaba.studio.sceneEditor.SceneInspector;
import lua.Table;
import sunaba.core.StringArray;
import sunaba.LibraryLoader.LibraryLoadResult;
import Type;
import sunaba.desktop.NativeMenuService;
import sunaba.core.VariantNative;
import sunaba.OSService;
import sunaba.ui.StyleBoxEmpty;
import sunaba.SystemFont;
import sunaba.HorizontalAlignment;
import sunaba.core.native.ScriptType;
import sunaba.internal.ProcessSpawner;
import sunaba.studio.fileHandlers.VchrFileHandler;

class Editor extends Widget {
    var sProjPath = "";

    public var projectFilePath(get, default): String;
    function get_projectFilePath():String {
        return sProjPath;
    }

    public var haxePath:String = "haxe"; // Default path to Haxe compiler
    public var haxeExecutablePath:String = "haxe";

    public var isGameRunning: Bool = false;

    var leftTabBar: VBoxContainer;
    var rightTabBar: VBoxContainer;

    var leftTabContainer: TabContainer;
    var centerTabContainer: TabContainer;
    var bottomCenterTabContainer: TabContainer;
    var rightTabContainer: TabContainer;

    var leftSidebarChildren: Array<EditorWidget> = [];
    var rightSidebarChildren: Array<EditorWidget> = [];
    var workspaceChildern: Array<EditorWidget> = [];
    var dockChildren: Array<EditorWidget> = [];

    public var newFileButton: Button;
    public var saveFileButton: Button;
    public var undoButton: Button;
    public var redoButton: Button;
    public var reloadButton: Button;
    public var publishButton: Button;
    public var trenchbroomButton: Button;
    //public var netradiantButton: Button;

    public var buildButton: Button;
    public var playButton:Button;
    public var pauseButton:Button;
    public var stopButton:Button;

    public var window:Window;
    public var windowSize:Vector2i;
    private var ogWindowSize: Vector2i;
    public var titlebarLmbPressed:Bool = false;
    public var clickcount = 0;
    public var timeSinceClick = 0.1;
    public var windowTitle:Label;
    public var subtitle:String = "";
    var windowIsMaximized: Bool = false;

    private var playBuildWindow: Window;
    private var pluginBuildWindow: Window;

    public var explorer: Explorer;
    public var assetBrowser: AssetBrowser;
    public var sceneInspector: SceneInspector;
    public var resourceInspector: ResourceInspector;
    public var console: Console;
    public var characterEditor: CharacterEditor;

    public var projectIo: FileSystemIo;
    public var sourceIo: FileSystemIo;

    private var resizePreview: Bool = true;
    private var resizeThreshold: Float = 10.0;
    private var resizeThresholdBottomRight: Float = 0.25;

    private var toolFunctions: Array<()->Void> = new Array();

    public var toolchainDir: String;

    private var _projectFile: ProjectFile = null;
    public var projectFile(get, default): ProjectFile;
    function get_projectFile():ProjectFile {
        return _projectFile;
    }

    public var customTitlebar(get, set): Bool;
    function get_customTitlebar() {
        return window.borderless;
    }
    function set_customTitlebar(value: Bool): Bool {
        var minimizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/minimizeButton");
        minimizeButton.visible = value;
        var maximizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/maximizeButton");
        maximizeButton.visible = value;
        var closeButton = getNodeT(Button, "vbox/menuBarControl/hbox/closeButton");
        closeButton.visible = value;
        var iconContainer = getNodeT(Control, "vbox/menuBarControl/hbox/iconContainer");
        iconContainer.visible = value;
        windowTitle.visible = value;
        return window.borderless = value;
    }

    private var playerSubViewportContainer: SubViewportContainer = null;
    private var playerAppView: DesktopAppView = null;

    private var toolsMenu: PopupMenu = null;
    private var debugMenu: PopupMenu = null;

    public var plugins: Array<Plugin> = new Array();

    private var leftSidebarVisible: Bool = true;
    private var rightSidebarVisible: Bool = true;

    var leftSidebarToggled: Bool = true;
    var rightSidebarToggled: Bool = true;

    public override function init() {
        load("studio://Editor.suml");

        if (OSService.getName() == "Windows") {
            resizeThreshold = 2.5;
        }

        var __this__ = this;
        untyped __lua__("_G['editor'] = __this__");

        leftTabBar = getNodeT(VBoxContainer, "vbox/hbox/leftTabBar");
        rightTabBar = getNodeT(VBoxContainer, "vbox/hbox/rightTabBar");

        leftTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/leftSidebar");
        leftTabContainer.hide();
        leftTabContainer.tabsVisible = false;
        centerTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/vsplit/workspace");
        centerTabContainer.getTabBar().tabCloseDisplayPolicy = CloseButtonDisplayPolicy.showActiveOnly;
        bottomCenterTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/vsplit/dock");
        bottomCenterTabContainer.tabsPosition = 1;
        rightTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/rightSidebar");
        rightTabContainer.hide();
        rightTabContainer.tabsVisible = false;

        newFileButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/newFile");
        saveFileButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/saveFile");
        undoButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/undo");
        undoButton.pressed.add(() -> {
            undo();
        });
        redoButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/redo");
        redoButton.pressed.add(() -> {
            redo();
        });
        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/reload");
        reloadButton.pressed.connect(Callable.fromFunction(function() {
            buildPlugin();
        }));
        publishButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/publish");
        trenchbroomButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/trenchbroom");
        trenchbroomButton.pressed.add(() -> {
            openTrenchbroom();
        });
        /*netradiantButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/netradiant");
        netradiantButton.pressed.add(() -> {
            openNetRadiant();
        });*/

        buildButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/build");
        playButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/play");
        pauseButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/pause");
        stopButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/stop");

        buildButton.pressed.connect(Callable.fromFunction(function() {
            if (isGameRunning == false)
                buildProject();
        }));
        playButton.pressed.connect(Callable.fromFunction(function() {
            if (isGameRunning == true && isGamePaused == true)
                unpause();
            else if (isGameRunning == false)
                buildSnbForPlay();
        }));
        pauseButton.pressed.connect(Callable.fromFunction(function() {
            pause();
        }));
        stopButton.pressed.connect(Callable.fromFunction(function() {
            stop();
        }));

        pauseButton.disabled = true;
        stopButton.disabled = true;

        windowTitle = getNodeT(Label, "vbox/menuBarControl/windowTitle");
        windowTitle.show();
        windowTitle.addThemeFontOverride("font", Reference.castTo(ResourceLoaderService.load("res://Engine/Theme/fonts/NunitoSans-Medium.ttf"), Font));
        /*if (OSService.getName() != "macOS") {
            windowTitle.hide();
        }*/

        var leftSidebarToggle: Button = getNodeT(Button, "vbox/statusbar/hbox/left/leftSidebarToggle");
        leftSidebarToggled = true;
        leftSidebarToggle.pressed.add(() -> {
            leftSidebarToggled = !leftSidebarToggled;
            leftTabBar.visible = leftSidebarToggled;
            if (leftSidebarToggled == true) {
                leftTabContainer.visible = leftSidebarVisible;
            }
            else {
                leftTabContainer.hide();
            }
        });

        var rightSidebarToggle: Button = getNodeT(Button, "vbox/statusbar/hbox/left/rightSidebarToggle");
        rightSidebarToggled = true;
        rightSidebarToggle.pressed.add(() -> {
            rightSidebarToggled = !rightSidebarToggled;
            rightTabBar.visible = rightSidebarToggled;
            if (rightSidebarToggled == true) {
                rightTabContainer.visible = rightSidebarVisible;
            }
            else {
                rightTabContainer.hide();
            }
        });

        var dockToggle: Button = getNodeT(Button, "vbox/statusbar/hbox/left/dockToggle");
        dockToggle.pressed.add(() -> {
            bottomCenterTabContainer.visible = !bottomCenterTabContainer.visible; 
        });

        var workspacesToggle: Button = getNodeT(Button, "vbox/statusbar/hbox/left/workspacesToggle");
        workspacesToggle.pressed.add(() -> {
            centerTabContainer.visible = !centerTabContainer.visible;
        });

        playBuildWindow = getNodeT(Window, "playBuildWindow");
        playBuildWindow.hide();
        pluginBuildWindow = getNodeT(Window, "pluginBuildWindow");
        pluginBuildWindow.hide();

        var helpMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/Help");
        if (OSService.getName() == "macOS") {
            helpMenu.removeItem(helpMenu.itemCount - 1);
            helpMenu.systemMenuId = 4;

            var appMenu = NativeMenuService.getSystemMenu(2);

            NativeMenuService.addSeparator(appMenu);

            var settingsIdx = NativeMenuService.addItem(
                appMenu,
                "Settings",
                Callable.fromFunction(function() {
                    trace("Hello, Settings");
                }),
                Callable.fromFunction(function() {
                    trace("Hello, Settings (keyCallback)");
                }),
                new VariantNative(),
                KeyModifierMask.maskMeta | Key.comma
            );

            NativeMenuService.setItemIcon(appMenu, settingsIdx, loadIcon("studio://icons/16/gear.png"));
        }
    }

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
        window.mode = WindowMode.maximized;
        window.unresizable = false;
        windowIsMaximized = true;
        if (OSService.getName() == "macOS") {
            DisplayService.windowSetWindowButtonsOffset(new Vector2i(35, 37), window.getWindowId());
        }
        else {
            var useCustomTitlebar = true;
            var osArgs = Sys.args();
            for (i in 0...osArgs.length) {
                var arg = osArgs[i];
                if (arg == "--no-custom-titlebar") {
                    useCustomTitlebar = false;
                }
            }
            window.borderless = useCustomTitlebar;
        }
        var windowSize = pluginBuildWindow.size;
        var scaleFactor = getWindow().contentScaleFactor;
        pluginBuildWindow.minSize = new Vector2i(Std.int(windowSize.x * scaleFactor), Std.int(windowSize.y * scaleFactor));
        pluginBuildWindow.contentScaleFactor = scaleFactor;
        playBuildWindow.minSize = pluginBuildWindow.minSize;
        playBuildWindow.contentScaleFactor = scaleFactor;

        haxePath = StudioUtils.singleton.getToolchainDirectory() + "/haxe";
        if (Sys.systemName() == "Windows") {
            haxePath += ".exe";
        }
        

        try {
            trace("hi!");
            var menuBarControl: Control = getNodeT(Control, "vbox/menuBarControl/hbox/spacer");
            var eventFunc = function(eventN: NativeReference) {
                if (window == null)
                    return;

                if (customTitlebar == false && OSService.getName() != "macOS")
                    return;

                if (InputService.isMouseButtonPressed(MouseButton.left) && !titlebarLmbPressed && windowIsMaximized == false && clickcount == 0) {
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

            var menuBar: Control = getNodeT(Control, "vbox/menuBarControl/hbox/menuBar");
            var toolBarSpacer: Control = getNodeT(Control, "vbox/toolbar/hbox/spacer");
            var iconContainer = getNodeT(Control, "vbox/menuBarControl/hbox/iconContainer");
            var iconRect = getNodeT(Control, "vbox/menuBarControl/hbox/iconContainer/icon");
            menuBar.guiInput.connect(eventFunc);
            menuBarControl.guiInput.connect(eventFunc);
            toolBarSpacer.guiInput.connect(eventFunc);
            iconContainer.guiInput.connect(eventFunc);
            iconRect.guiInput.connect(eventFunc);

            centerTabContainer.getTabBar().tabClosePressed.connect(Callable.fromFunction(function(tab: Int) {
                var widget = workspaceChildern[tab];
                if (widget != null) {
                    widget.destroy();
                    workspaceChildern.remove(widget);
                }
            }));
            centerTabContainer.dragToRearrangeEnabled = true;
            centerTabContainer.activeTabRearranged.connect(Callable.fromFunction(function(idxTo: Int) {
                var newWorkspaceChildren: Array<EditorWidget> = new Array();
                for (i in 0...centerTabContainer.getTabCount()) {
                    for (child in workspaceChildern) {
                        if (child.getIndex() == i) {
                            newWorkspaceChildren.push(child);
                        }
                    }
                }
                workspaceChildern = newWorkspaceChildren;
            }));

            var fileMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/File");
            fileMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    assetBrowser.newFile();
                }
                else if (id == 1) {
                    save();
                }
                else if (id == 2) {
                    Debug.error("'Publish' not implemented");
                }
                else if (id == 4) {
                    Debug.error("'Open Project in Code Editor' not implemented");
                }
                else if (id == 5) {
                    OSService.shellOpen(explorer.projectDirectory);
                }
                else if (id == 6) {
                    App.exit(0);
                }
            }));

            newFileButton.pressed.add(() -> {
                assetBrowser.newFile();
            });
            saveFileButton.pressed.connect(Callable.fromFunction(function() {
                save();
            }));

            var editMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/Edit");
            editMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    undo();
                }
                else if (id == 1) {
                    redo();
                }
                else if (id == 3) {
                    Debug.error("'Cut' not implemented");
                }
                else if (id == 4) {
                    Debug.error("'Copy' not implemented");
                }
                else if (id == 5) {
                    Debug.error("'Paste' not implemented");
                }
            }));
            var viewMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/View");
            viewMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    leftSidebarToggled = !leftSidebarToggled;
                    leftTabBar.visible = leftSidebarToggled;
                    if (leftSidebarToggled == true) {
                        leftTabContainer.visible = leftSidebarVisible;
                    }
                    else {
                        leftTabContainer.hide();
                    }
                }
                else if (id == 1) {
                    rightSidebarToggled = !rightSidebarToggled;
                    rightTabBar.visible = rightSidebarToggled;
                    if (rightSidebarToggled == true) {
                        rightTabContainer.visible = rightSidebarVisible;
                    }
                    else {
                        rightTabContainer.hide();
                    }
                }
                else if (id == 2) {
                    centerTabContainer.visible = !centerTabContainer.visible; 
                }
                else if (id == 3) {
                    bottomCenterTabContainer.visible = !bottomCenterTabContainer.visible; 
                }
            }));
            toolsMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/Tools");
            toolsMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                var func = toolFunctions[id];
                if (func != null) {
                    func();
                }
            }));
            debugMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/Debug");
            debugMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    if (isGameRunning)
                        unpause();
                    else
                        buildSnbForPlay();
                }
                else if (id == 1)
                    pause();
                else if (id == 2)
                    stop();

            }));
            var helpMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBarContainer/menuBar/Help");
            helpMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    OSService.shellOpen("https://docs.sunaba.gg");
                }
                else if (id == 1) {
                    var window = new Window();
                    window.size = new Vector2i(800, 600);
                    var apiBrowser = new ApiBrowser(this);
                    window.addChild(apiBrowser);
                    addChild(window);
                    window.popupCentered();
                }
                else if (id == (helpMenu.itemCount - 1)) {
                    showAboutDialog();
                }
            }));

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
            var isMaximized = true;
            minimizeButton.pressed.add(() -> {
                if (window.mode != WindowMode.minimized) {
                    isMaximized = windowIsMaximized == true;
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

            var maximizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/maximizeButton");
            maximizeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
            maximizeButton.focusMode = FocusModeEnum.none;
            maximizeButton.addThemeFontOverride("font", buttonFont);
            maximizeButton.text = "🗗";
            maximizeButton.alignment = HorizontalAlignment.center;
            if (OSService.getName() == "Windows") {
                maximizeButton.customMinimumSize = newCustomMinimumSize;
            }
            if (windowIsMaximized == true) {
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
                else if (windowIsMaximized == false) {
                    maximizeButton.text = "🗗";
                    if (OSService.getName() == "Windows") {
                        maximizeButton.text = "";
                    }
                    windowSize = window.size;
                    window.mode = WindowMode.maximized;
                    windowIsMaximized = true;
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
                App.exit(0);
            });

            if (OSService.getName() == "macOS") {
                iconContainer.hide();
                minimizeButton.hide();
                maximizeButton.hide();
                closeButton.hide();
            }

            refreshLeftSidebar();
            refreshRightSidebar();
            trace("Hello, World!");

            var args = Sys.args();
            for (arg in args) {
                if (StringTools.endsWith(arg, ".sproj")) {
                    sProjPath = arg;
                    break;
                }
            }

            if (sProjPath == "") {
                sProjPath = untyped __lua__("_G.projectPath");
            }

            sProjPath = FileSystem.absolutePath(sProjPath).split("\\").join("/");

            trace(sProjPath);

            var projJson: String = "";
            if (sProjPath != "") {
                projJson = File.getContent(sProjPath);
            }

            trace(sProjPath == "" );
            trace(projJson == "");
            if (sProjPath == "" || projJson == "") {
                Debug.error("Project not found.");
                App.exit(-1);
                return;
            }



            _projectFile = haxe.Json.parse(projJson);

            if (_projectFile.type != "executable") {
                playButton.disabled = true;
            }

            var sprojPathArr = sProjPath.split("/");
            sprojPathArr.slice(0, sprojPathArr.length - 1);
            var dirPath = sprojPathArr.join("/");
            dirPath += "/";
            var assetPath = dirPath + _projectFile.assetsdir;
            trace(_projectFile.assetsdir);
            while (!StringTools.endsWith(assetPath, _projectFile.assetsdir)) {
                assetPath += _projectFile.assetsdir;
            }
            trace(assetPath);

            var recentProjectsPath = "user://recentProjects.json";
            if (io.fileExists(recentProjectsPath)) {
                var recentProjectsStr = io.loadText(recentProjectsPath);
                var recentProjects: RecentProjects = haxe.Json.parse(recentProjectsStr);

                if (recentProjects.list.contains(sProjPath)) {
                    recentProjects.list.remove(sProjPath);
                }
                var newProjList: Array<String> = [];
                newProjList.push(sProjPath);
                for (proj in recentProjects.list) {
                    if (newProjList.length >= 10)
                        break;
                    newProjList.push(proj);
                }
                recentProjects.list = newProjList;
                var recentProjJson = haxe.Json.stringify(recentProjects);
                io.saveText("user://recentProjects.json", recentProjJson);
            }

            explorer = new Explorer(this, EditorArea.leftSidebar);
            explorer.fileHandlers.push(new BmpFileHandler(explorer));
            explorer.fileHandlers.push(new DdsFileHandler(explorer));
            explorer.fileHandlers.push(new JpegFileHandler(explorer));
            explorer.fileHandlers.push(new JpgFileHandler(explorer));
            explorer.fileHandlers.push(new KtxFileHandler(explorer));
            explorer.fileHandlers.push(new PngFileHandler(explorer));
            explorer.fileHandlers.push(new SvgFileHandler(explorer));
            explorer.fileHandlers.push(new TgaFileHandler(explorer));
            explorer.fileHandlers.push(new WebpFileHandler(explorer));
            explorer.fileHandlers.push(new Mp3FileHandler(explorer));
            explorer.fileHandlers.push(new OggVorbisFileHandler(explorer));
            explorer.fileHandlers.push(new WavFileHandler(explorer));
            explorer.fileHandlers.push(new HxFileHandler(explorer));
            explorer.fileHandlers.push(new VscnFileHandler(explorer));
            explorer.fileHandlers.push(new VpfbFileHandler(explorer));
            explorer.fileHandlers.push(new SmdlFileHandler(explorer));
            explorer.fileHandlers.push(new SmdlBinaryFileHandler(explorer));
            explorer.fileHandlers.push(new MapFileHandler(explorer));
            explorer.fileHandlers.push(new VchrFileHandler(explorer));
            explorer.newFileWidget.addAssetFileTemplate("Empty Scene", ".vscn", explorer.loadIcon("studio://icons/16_2x/clapperboard.png"), (path: String) -> {
                var sceneRoot = new SceneRoot();
                var sceneFile = SceneFile.create(sceneRoot);
                sceneFile.save(path);
                sceneRoot.queueFree();
            });
            explorer.newFileWidget.addAssetFileTemplate("Sinple Map", ".map", explorer.loadIcon("studio://icons/16_2x/clapperboard.png"), (path: String) -> {
                var mapContents = io.loadBytes("studio://scenes/Template.map");
                io.saveBytes(path, mapContents);
            });
            explorer.newFileWidget.addScriptFileTemplate("Empty Script", ".hx", explorer.loadIcon("studio://icons/16_2x/document.png"), (path: String) -> {
                sourceIo.saveText(path, "");
            });
            explorer.startExplorer();

            assetBrowser = new AssetBrowser(this, EditorArea.dock);

            addToolFunction(() -> {
                    var textureListEditorAcceptDialog = new AcceptDialog();
                    textureListEditorAcceptDialog.contentScaleFactor = getWindow().contentScaleFactor;
                    textureListEditorAcceptDialog.minSize = new Vector2i(
                        Std.int(450 * textureListEditorAcceptDialog.contentScaleFactor), 
                        Std.int(350 * textureListEditorAcceptDialog.contentScaleFactor)
                    );
                    textureListEditorAcceptDialog.title = "Edit Texture Path List";
                    textureListEditorAcceptDialog.closeRequested.add(() -> {
                        textureListEditorAcceptDialog.queueFree();
                    });
                    textureListEditorAcceptDialog.confirmed.add(() -> {
                        textureListEditorAcceptDialog.queueFree();
                    });

                    var textureListEditor = new TextureListEditor();
                    textureListEditor.editor = this;

                    textureListEditorAcceptDialog.addChild(textureListEditor);
                    addChild(textureListEditorAcceptDialog);
                    textureListEditorAcceptDialog.popupCentered();
                }, 
                "Edit Texture Path List", 
                loadIcon("studio://icons/16/images-stack.png")
            );
            
            addToolFunction(() -> {
                    openTrenchbroom();
                }, 
                "TrenchBroom", 
                loadIcon("studio://icons/16/trenchbroom.png")
            );

            addToolFunction(() -> {
                    trace("");
                    var fileDialog = new FileDialog();
                    fileDialog.fileMode = FileDialogMode.openFile;
                    fileDialog.useNativeDialog = true;
                    fileDialog.access = 2;
                    fileDialog.title = "Open 3D Model";
                    fileDialog.addFilter("*.gltf", "GLTF");
                    fileDialog.addFilter("*.glb", "GLTF Binary");
                    fileDialog.addFilter("*.fbx", "FBX");
                    addChild(fileDialog);

                    fileDialog.fileSelected.connect(Callable.fromFunction(function(srcPath: String) {
                        var fileDialog2 = new FileDialog();
                        fileDialog2.fileMode = FileDialogMode.saveFile;
                        fileDialog2.access = 2;
                        fileDialog2.currentDir = projectIo.getFilePath(_projectFile.rootUrl);
                        fileDialog2.title = "Select 3D Model Destination";
                        fileDialog2.addFilter("*.smdl", "Sunaba 3D Model");
                        addChild(fileDialog2);

                        fileDialog2.fileSelected.connect(Callable.fromFunction(function(_destPath: String) {
                            try {
                                var destPath = projectIo.getFileUrl(_destPath);
                                trace(srcPath, destPath);
                                ModelImportService.inport(srcPath, destPath);
                            }
                            catch(e) {
                                Debug.error(e.message + " : " + e.stack);
                            }
                            fileDialog2.queueFree();
                            fileDialog.queueFree();
                        }));
                        fileDialog2.canceled.add(() -> {
                            fileDialog2.queueFree();
                            fileDialog.queueFree();
                        });
                        fileDialog2.closeRequested.add(() -> {
                            fileDialog2.queueFree();
                            fileDialog.queueFree();
                        });

                        fileDialog2.popupCentered();
                    }));
                    fileDialog.canceled.add(() -> {
                        fileDialog.queueFree();
                    });
                    fileDialog.closeRequested.add(() -> {
                        fileDialog.queueFree();
                    });

                    fileDialog.popupCentered();
                },
                "Import 3D Model",
                loadIcon("studio://icons/16/block.png")
            );

            var hiddenDir = explorer.projectDirectory + "/.studio";
            localPluginIo = new FileSystemIo();
            localPluginIo.open(hiddenDir, "plugin://");

            var ioManager: IoManager = cast io;
            ioManager.register(projectIo);
            ioManager.register(localPluginIo);

            sceneInspector = new SceneInspector(this, EditorArea.rightSidebar);

            resourceInspector = new ResourceInspector(this, EditorArea.rightSidebar);

            console = new Console(this, EditorArea.dock);

            bottomCenterTabContainer.currentTab = 0;

            characterEditor = new CharacterEditor(this, EditorArea.dock);

            console.addCommand("toggle-custom-titlebar", (args) -> {
                if (OSService.getName() == "macOS") {
                    console.log("The custom titlebar cannot be disabled on macOS");
                    return -1;
                }
                customTitlebar = !customTitlebar;
                explorer.refresh();
                return 0;
            });

            console.addCommand("import-model", (args) -> {
                var srcPath = args[0];
                var destPath = args[1];
                ModelImportService.isRunningCoroutine = false;

                try {
                    ModelImportService.inport(srcPath, destPath);
                }
                catch(e) {
                    console.error(e.message + " : " + e.stack);
                    return -1;
                }

                return 0;
            });
            console.addCommand("import-model-binary", (args) -> {
                var srcPath = args[0];
                var destPath = args[1];
                ModelImportService.isRunningCoroutine = false;

                try {
                    ModelImportService.inport(srcPath, destPath, true);
                }
                catch(e) {
                    console.error(e.message + " : " + e.stack);
                    return -1;
                }
                
                return 0;
            });

            var osArgs = Sys.args();
            for (i in 0...osArgs.length) {
                var arg = osArgs[i];
                if (OSService.getName() != "macOS") {
                    if (arg == "--no-custom-titlebar") {
                        customTitlebar = false;
                    }
                }
            }

            //loadProjectPlugin();
        }
        catch(e: Exception) {
            Debug.error(e.message);
        }

        toolchainDir = StudioUtils.singleton.getToolchainDirectory();

        if (OSService.getName() == "Windows") {
            var hiddenDir = explorer.projectDirectory + "/.studio";
            if (!FileSystem.exists(hiddenDir))
                FileSystem.createDirectory(hiddenDir);
            // Command Prompt fucking sucks
            var wrapper = hiddenDir + "/run_haxe.bat";
            var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
            toolchaindir = StringTools.replace(toolchaindir, "\\/" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/\\" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/" , "\\");
            if (!StringTools.endsWith(toolchaindir, "\\")) {
                toolchaindir += "\\";
            }
            var asmDir = StudioUtils.singleton.getBaseDirectory();
            asmDir = StringTools.replace(asmDir, "\\/" , "\\");
            asmDir = StringTools.replace(asmDir, "/\\" , "\\");
            asmDir = StringTools.replace(asmDir, "/" , "\\");
            if (!StringTools.endsWith(asmDir, "\\")) {
                asmDir += "\\";
            }
            var batContent = "@echo off\r\nset PATH=\"" + toolchaindir + "\";";
            var haxelibPath = toolchaindir +  "haxelib.exe";
            batContent += " && \"" + haxelibPath + "\" newrepo";
            batContent += " && \"" + haxelibPath + "\" install \"" + asmDir + "libsunaba.zip\"";
            batContent += " && \"" + haxelibPath + "\" install \"" + asmDir + "gamepak.zip\"";
            batContent += " && \"" + haxelibPath + "\" install \"" + asmDir + "sunaba-studio-api.zip\"";
            batContent += " && \"" + haxePath + "\" %*";
            /*var batContent = '@echo off\r\n'
            + command
            + '\r\n'
            + 'echo %ERRORLEVEL% > "'
            + StringTools.replace(hiddenDir, "/", "\\")
            + '\\build.log"\r\n';*/
            sys.io.File.saveContent(wrapper, batContent);

            haxeExecutablePath = haxePath;
            haxePath = StringTools.replace(wrapper, ".bat", "");
        }
        else {
            var hiddenDir = explorer.projectDirectory + "/.studio";
            if (!FileSystem.exists(hiddenDir))
                FileSystem.createDirectory(hiddenDir);
            var wrapper = hiddenDir + "/run_haxe.sh";
            var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
            if (!StringTools.endsWith(toolchaindir, "/")) {
                toolchaindir += "/";
            }
            if (StringTools.contains(toolchaindir, "//")) {
                toolchaindir = StringTools.replace(toolchaindir, "//", "/");
            }
            var asmDir = StudioUtils.singleton.getBaseDirectory();
            if (!StringTools.endsWith(asmDir, "/")) {
                asmDir += "/";
            }
            if (StringTools.contains(asmDir, "//")) {
                asmDir = StringTools.replace(asmDir, "//", "/");
            }
            if (StringTools.contains(haxePath, "//")) {
                haxePath = StringTools.replace(haxePath, "//", "/");
            }
            var shContent = "#!/bin/sh\n";
            var haxelibPath = toolchaindir +  "haxelib";
            
            shContent += "chmod +x \"" + haxePath + "\"";
            shContent += "\nchmod +x \"" + haxelibPath + "\"";
            shContent += "\nchmod +x \"" + toolchaindir + "neko\"";
            shContent += "\nexport PATH=\"" + toolchaindir + "\":$PATH";
            if (OSService.getName() == "macOS") {
                shContent += "\nexport DYLD_LIBRARY_PATH=\"" + toolchaindir + "\":$DYLD_LIBRARY_PATH";
                shContent += "\nexport DYLD_FALLBACK_LIBRARY_PATH=\"" + toolchaindir + "\":$DYLD_FALLBACK_LIBRARY_PATH";
                shContent += "\ninstall_name_tool -add_rpath \"" + toolchaindir + "\" \"" + haxelibPath + "\" 2>/dev/null || true";
                shContent += "\ninstall_name_tool -add_rpath \"" + toolchaindir + "\" \"" + haxePath + "\" 2>/dev/null || true";
                shContent += "\ninstall_name_tool -add_rpath \"" + toolchaindir + "\" \"" + toolchaindir + "neko\" 2>/dev/null || true";
            }
            else if (OSService.getName() == "Linux") {
                shContent += "\nexport LD_LIBRARY_PATH=\"" + toolchaindir + "\":$LD_LIBRARY_PATH";
                shContent += "\nexport HAXE_STD_PATH=\"" + toolchaindir + "/std\":$HAXE_STD_PATH";
            }
            shContent += "\n\"" + haxelibPath + "\" newrepo";
            shContent += "\n\"" + haxelibPath + "\" install \"" + asmDir + "libsunaba.zip\"";
            shContent += "\n\"" + haxelibPath + "\" install \"" + asmDir + "gamepak.zip\"";
            shContent += "\n\"" + haxelibPath + "\" install \"" + asmDir + "sunaba-studio-api.zip\"";
            shContent += "\n\"" + haxePath + "\" \"$@\" ";
            sys.io.File.saveContent(wrapper, shContent);//


            trace(FileSystem.exists(wrapper));
            //Sys.command("/bin/chmod", ["+x", wrapper]);
            OSService.execute("chmod", StringArray.fromArray(["+x", wrapper]));

            haxeExecutablePath = haxePath;
            haxePath = wrapper;
        }

        leftTabContainer.visible = false;
        rightTabContainer.visible = false;

        var baseDirectory = StudioUtils.singleton.getBaseDirectory();
        if (!StringTools.endsWith(baseDirectory, "/")) {
            baseDirectory += "/";
        }
        if (StringTools.contains(baseDirectory, "//")) {
            baseDirectory = StringTools.replace(baseDirectory, "//", "/");
        }
        if (StringTools.contains(baseDirectory, "\\")) {
            baseDirectory = StringTools.replace(baseDirectory, "\\", "/");
        }

        var basePluginDir = baseDirectory + "plugins/";
        if (FileSystem.exists(basePluginDir)) {
            loadPluginDir(basePluginDir);
        }

        var sprojPathArr = sProjPath.split("/");
        sprojPathArr.slice(0, sprojPathArr.length - 1);
        var dirPath = sprojPathArr.join("/");
        dirPath += "/";

        var projectPluginDir = dirPath + "plugins/";
        if (FileSystem.exists(projectPluginDir)) {
            loadPluginDir(projectPluginDir);
        }
    }

    private function generateHaxeWrapper() {
        if (OSService.getName() == "Windows") {
            var hiddenDir = explorer.projectDirectory + "/.studio";
            if (!FileSystem.exists(hiddenDir))
                FileSystem.createDirectory(hiddenDir);
            // Command Prompt fucking sucks
            var wrapper = hiddenDir + "/run_haxe_fast.bat";
            var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
            toolchaindir = StringTools.replace(toolchaindir, "\\/" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/\\" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/" , "\\");
            if (!StringTools.endsWith(toolchaindir, "\\")) {
                toolchaindir += "\\";
            }
            var asmDir = StudioUtils.singleton.getBaseDirectory();
            asmDir = StringTools.replace(asmDir, "\\/" , "\\");
            asmDir = StringTools.replace(asmDir, "/\\" , "\\");
            asmDir = StringTools.replace(asmDir, "/" , "\\");
            if (!StringTools.endsWith(asmDir, "\\")) {
                asmDir += "\\";
            }
            var batContent = "@echo off\r\nset PATH=\"" + toolchaindir + "\";";
            var haxelibPath = toolchaindir +  "haxelib.exe";
            batContent += " && \"" + haxeExecutablePath + "\" %*";
            /*var batContent = '@echo off\r\n'
            + command
            + '\r\n'
            + 'echo %ERRORLEVEL% > "'
            + StringTools.replace(hiddenDir, "/", "\\")
            + '\\build.log"\r\n';*/
            sys.io.File.saveContent(wrapper, batContent);

            haxePath = StringTools.replace(wrapper, ".bat", "");
        }
        else {
            var hiddenDir = explorer.projectDirectory + "/.studio";
            if (!FileSystem.exists(hiddenDir))
                FileSystem.createDirectory(hiddenDir);
            var wrapper = hiddenDir + "/run_haxe_fast.sh";
            var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
            if (!StringTools.endsWith(toolchaindir, "/")) {
                toolchaindir += "/";
            }
            if (StringTools.contains(toolchaindir, "//")) {
                toolchaindir = StringTools.replace(toolchaindir, "//", "/");
            }
            var asmDir = StudioUtils.singleton.getBaseDirectory();
            if (!StringTools.endsWith(asmDir, "/")) {
                asmDir += "/";
            }
            if (StringTools.contains(asmDir, "//")) {
                asmDir = StringTools.replace(asmDir, "//", "/");
            }
            if (StringTools.contains(haxePath, "//")) {
                haxePath = StringTools.replace(haxePath, "//", "/");
            }
            var shContent = "#!/bin/sh\n";
            var haxelibPath = toolchaindir +  "haxelib";
            
            shContent += "chmod +x \"" + haxePath + "\"";
            shContent += "\nchmod +x \"" + haxelibPath + "\"";
            shContent += "\nchmod +x \"" + toolchaindir + "neko\"";
            shContent += "\nexport PATH=\"" + toolchaindir + "\":$PATH";
            if (OSService.getName() == "macOS") {
                shContent += "\nexport DYLD_LIBRARY_PATH=\"" + toolchaindir + "\":$DYLD_LIBRARY_PATH";
                shContent += "\nexport DYLD_FALLBACK_LIBRARY_PATH=\"" + toolchaindir + "\":$DYLD_FALLBACK_LIBRARY_PATH";
                shContent += "\ninstall_name_tool -add_rpath \"" + toolchaindir + "\" \"" + haxelibPath + "\" 2>/dev/null || true";
                shContent += "\ninstall_name_tool -add_rpath \"" + toolchaindir + "\" \"" + haxePath + "\" 2>/dev/null || true";
                shContent += "\ninstall_name_tool -add_rpath \"" + toolchaindir + "\" \"" + toolchaindir + "neko\" 2>/dev/null || true";
            }
            else if (OSService.getName() == "Linux") {
                shContent += "\nexport LD_LIBRARY_PATH=\"" + toolchaindir + "\":$LD_LIBRARY_PATH";
                shContent += "\nexport HAXE_STD_PATH=\"" + toolchaindir + "/std\":$HAXE_STD_PATH";
            }
            shContent += "\n\"" + haxeExecutablePath + "\" \"$@\" ";
            sys.io.File.saveContent(wrapper, shContent);//


            trace(FileSystem.exists(wrapper));
            //Sys.command("/bin/chmod", ["+x", wrapper]);
            OSService.execute("chmod", StringArray.fromArray(["+x", wrapper]));

            haxePath = wrapper;
        }
    }

    private var localPluginIo: FileSystemIo;

    public function showAboutDialog() {
        var aboutString = "Sunaba Studio\n";
        aboutString += "Version ";
        aboutString += PlatformService.getVersion(); 
        aboutString += "\n(C) 2022-2026 mintkat\n";
        aboutString += "\n";

        var engineVersion = PlatformService.getEngineVersion();
        aboutString += "Engine Version: " + engineVersion + "\n";
        var osname = OSService.getName();
        aboutString += "OS: " + osname + "\n";
        var deviceTypeStr = "Unknown";
        if (PlatformService.deviceType == PlatformDeviceType.desktop) {
            deviceTypeStr = "Desktop";
        }
        else if (PlatformService.deviceType == PlatformDeviceType.mobile) {
            deviceTypeStr = "Mobile";
        }
        else if (PlatformService.deviceType == PlatformDeviceType.web) {
            deviceTypeStr = "Web";
        }
        else if (PlatformService.deviceType == PlatformDeviceType.xr) {
            deviceTypeStr = "XR";
        }
        aboutString += "Device Type: " + deviceTypeStr + "\n";
        var buildDate = PlatformService.getCompDate();
        aboutString += "Build Date: " + buildDate + "\n";
        Debug.info(aboutString, "About Sunaba Studio");
    }

    // big dumb hack
    private var hasGrabedFocus = false;
    private inline function checkFocus() {
        if (!hasGrabedFocus) {
            getWindow().grabFocus();
            hasGrabedFocus = true;
        }
    }

    private var pluginBuilt: Bool = false;

    public override function onProcess(deltaTime: Float) {
        checkFocus();

        if (pluginBuilt == false) {
            pluginBuilt = true;
            buildPlugin();
        }

        if (showDialog == true) {
            showDialog = false;
            showAboutDialog();
        }

        if (windowTitle.text != window.title)
            windowTitle.text = window.title;

        var windowTitle = window.title;
        if (projectFile != null) {
            if (centerTabContainer.getTabCount() == 0)
                windowTitle = projectFile.name + " - Sunaba Studio";
            else
                windowTitle = centerTabContainer.getTabTitle(centerTabContainer.currentTab) + " - " + projectFile.name + " - Sunaba Studio";
        } else {
            if (centerTabContainer.getTabCount() == 0)
                windowTitle = "Sunaba Studio";
            else
                windowTitle = centerTabContainer.getTabTitle(centerTabContainer.currentTab) + " - Sunaba Studio";
        }
        if (window.title != windowTitle)
            window.title = windowTitle;

        timeSinceClick -= deltaTime;
        if (timeSinceClick <= 0.0) {
            timeSinceClick = 1.0;
            if (clickcount != 0) {
                clickcount = 0;
            }
        }

        if (gamepakBuildCoroutine != null) {
            if (Coroutine.status(gamepakBuildCoroutine) != CoroutineState.Dead) {
                Coroutine.resume(gamepakBuildCoroutine);
                if (buildProgress == null) {
                    try {
                        startTrack();
                    }
                }
                else {
                    buildProgress.value = buildSystem.cnt;
                }
            }
            else {
                gamepakBuildCoroutine = null;

                playBuildWindow.hide();

                if (playOnBuild == true)
                    play();
                else {
                    playButton.disabled = false;
                    buildButton.disabled = false;
                    if (_projectFile.type != "executable") {
                        playButton.disabled = true;
                    }
                }
            }
        }
        
        if (buildTask != null) {
            if (Coroutine.status(buildTask) != CoroutineState.Dead) {
                Coroutine.resume(buildTask);
            }
            else {
                buildTask = null;
            }
        }

        if (playerSubViewportContainer != null)
            if (centerTabContainer.currentTab == playerSubViewportContainer.getIndex())
                centerTabContainer.getTabBar().tabCloseDisplayPolicy = CloseButtonDisplayPolicy.showNever;
            else
                centerTabContainer.getTabBar().tabCloseDisplayPolicy = CloseButtonDisplayPolicy.showActiveOnly;
        else
            centerTabContainer.getTabBar().tabCloseDisplayPolicy = CloseButtonDisplayPolicy.showActiveOnly;

        if (OSService.getName() != "macOS" && customTitlebar) {
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

    public function addToolFunction(func: ()->Void, title: String, icon: Texture2D) {
        toolFunctions.push(func);
        toolsMenu.addIconItem(icon, title, toolFunctions.indexOf(func));
    }

    public function removeToolFunctions(func: ()->Void) {
        if (!toolFunctions.contains(func)) {
            throw "Tool function has not been added";
        }
        toolsMenu.removeItem(toolFunctions.indexOf(func));
        toolFunctions.remove(func);
    }

    var buildTask:Coroutine<() -> Void> = null;

    public function buildPlugin() {
        if (projectFilePath == "") {
            pluginBuilt = false;
            return;
        }

        if (projectFile.pluginEntrypoint == null || projectFile.pluginEntrypoint == "") {
            Debug.error("No plugin entrypoint specified in the project file.");
            return;
        }

        if (projectFile.scriptdir == null || projectFile.scriptdir == "") {
            Debug.error("No script directory specified in the project file.");
            return;
        }

        var command = generateHaxeBuildCommand();

        buildTask = Coroutine.create(function() {
            trace("Starting build task...");

            if (pluginBuildWindow != null) {
                pluginBuildWindow.popupCentered();
            }

            Coroutine.yield();

            var logFilePath = explorer.projectDirectory + "/.studio/build.log";
            if (FileSystem.exists(logFilePath)) {
                FileSystem.deleteFile(logFilePath);
            }

            Coroutine.yield();

            trace("Build command: " + command);
            var args = StringArray.create();
            var cmdArr = command.split(" ");
            var commandName = cmdArr[0];
            //Sys.println("command name: " + commandName);
            for (i in 1...cmdArr.length) {
                var arg = cmdArr[i];
                if (arg == "") continue;
                //trace("Arg #" + i + ": " + arg);
                args.add(arg);
            }

            Coroutine.yield();

            Sys.setCwd(explorer.projectDirectory);

            var process = new ProcessSpawner();
            addChild(process);
            process.spawn(commandName, args);
            while (!process.hasExited()) {
                Coroutine.yield();
            }
            var exitCode = process.getExitCode();
            generateHaxeWrapper();

            trace("Build command result: " + exitCode);

            Coroutine.yield();

            if (pluginBuildWindow != null) {
                pluginBuildWindow.hide();
            }

            if (exitCode == 0) {
                loadProjectPlugin();
            }
            else {
                Debug.error("Plugin failed to build with exit code: " + exitCode);
            }
        });

        Coroutine.resume(buildTask);
    }

    public inline function loadPluginDir(dir: String) {
        if (!FileSystem.isDirectory(dir)) {
            Debug.error("Invalid Directory");
            return;
        }

        if (StringTools.contains(dir, "\\")) {
            dir = StringTools.replace(dir, "\\", "/");
        }
        if (!StringTools.endsWith(dir, "/")) {
            dir += "/";
        }

        var files = FileSystem.readDirectory(dir);
        for (file in files) {
            var pluginPath = dir + file;
            if (StringTools.endsWith(dir, ".slib")) {
                loadPluginLibrary(pluginPath);
            }
        }
    }

    public inline function loadPluginLibrary(pluginPath: String) {
        try {
            var rootUrl = App.loadlib(pluginPath);
            var headerStr = io.loadText(rootUrl + "header.json");
            var header: HeaderFile = Json.parse(headerStr);
            loadPlugin(header.luabin);
        }
        catch(e) {
            Debug.error("Failed to load plugin - " + pluginPath + " : " + e.message + " - " + e.stack, "Plugin loading error");
        }
    }

    inline function loadProjectPlugin() {
        var pluginName = projectFile.name;
        var pluginPath = "plugin://plugin.lua";
        if (!localPluginIo.fileExists(pluginPath)) {
            return;
        }

        try {
            loadPlugin(pluginPath, true);
        }
        catch(e: String) {
            Debug.error(e.toString(), "Error loading project plugin");
        }
    }

    var projectPlugin: Plugin = null;

    public inline function loadPlugin(path: String, isProjectPlugin: Bool = false) {
        var loader = new LibraryLoader();
        loader.libraryName = name;

        loader.loadLibrary(path);
        loader.main();

        var pluginEnv  = loader.env;

        var plugin: Plugin = untyped __lua__("pluginEnv['plugin']");
        if (plugin != null) {
            if (isProjectPlugin == true) {
                if (projectPlugin != null) {
                    projectPlugin.uninit();
                    plugins.remove(projectPlugin);
                }
                projectPlugin = plugin;
            }
            plugins.push(plugin);
            plugin.init();
        }
    }

    public function pushBehaviorClass(_class: Class<Behavior>) {
        var className = Type.getClassName(_class);
        untyped {
            _hxClasses[className] = _class;
        }
        if (sceneInspector != null) {
            for (componentClass in sceneInspector.componentClasses) {
                if (Type.getClassName(componentClass) == Type.getClassName(_class)) {
                    sceneInspector.componentClasses.remove(componentClass);
                }
            }
            sceneInspector.componentClasses.push(_class);
        }
    }

    inline function getExitCode():Null<Int> {
        var hiddenDir = explorer.projectDirectory + "/.studio";
        var logFilePath = hiddenDir + "/build.log";
        if (sys.FileSystem.exists(logFilePath)) {
            var content = StringTools.trim(sys.io.File.getContent(logFilePath));
            return Std.parseInt(content);
        }
        // trace("Build log not found or empty.");
        return null;
    }

    private inline function generateHaxeBuildCommand():String {
        var command = this.haxePath + " --class-path " + explorer.projectDirectory + "/" + this.projectFile.scriptdir + " -main "
        + this.projectFile.pluginEntrypoint + " --library libsunaba --library gamepak --library sunaba-studio";
        command += " -D source-map";
        var hiddenDir = explorer.projectDirectory + "/.studio";
        if (!FileSystem.exists(hiddenDir))
            FileSystem.createDirectory(hiddenDir);
        command += " -lua " + hiddenDir + "/plugin.lua -D lua-vanilla";

        var librariesStr = "";
        for (lib in this.projectFile.libraries)
            librariesStr += " --library " + lib;
        command += " " + this.projectFile.compilerFlags.join(" ");

        return command;
        //if (Sys.systemName() != "Windows") {
            //command += '; echo $? > ' + hiddenDir + '/build.log &';
            
            //return command;
        //} else {
            // Create wrapper batch file
            //var wrapper = hiddenDir + "/run_build.bat";
            //var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
            //toolchaindir = StringTools.replace(toolchaindir, "\\/" , "\\");
            //toolchaindir = StringTools.replace(toolchaindir, "/\\" , "\\");
            //toolchaindir = StringTools.replace(toolchaindir, "/" , "\\");
            //var batContent = "@echo off\r\nset PATH=" + toolchaindir + "; && PATH && " + command;
            /*var batContent = '@echo off\r\n'
            + command
            + '\r\n'
            + 'echo %ERRORLEVEL% > "'
            + StringTools.replace(hiddenDir, "/", "\\")
            + '\\build.log"\r\n';*/
            //sys.io.File.saveContent(wrapper, batContent);

            //var newcmd = wrapper;
            //return StringTools.replace(wrapper, ".bat", "");
            //return command;
        //}
    }

    public inline function generateHaxeBuildHxml():String {
        var hxml = " --class-path " + explorer.projectDirectory + "/" + this.projectFile.scriptdir + "\n-main "
        + this.projectFile.pluginEntrypoint + "\n--library libsunaba\n--library gamepak\n--library sunaba-studio";
        hxml += "\n-D source-map";
        var hiddenDir = explorer.projectDirectory + "/.studio";
        if (!FileSystem.exists(hiddenDir))
            FileSystem.createDirectory(hiddenDir);
        hxml += "\n-lua " + hiddenDir + "/plugin.lua -D lua-vanilla";

        var librariesStr = "";
        for (lib in this.projectFile.libraries)
            librariesStr += "\n--library " + lib;
        hxml += " " + this.projectFile.compilerFlags.join("\n");

        var hxmlPath = Path.addTrailingSlash(explorer.projectDirectory) + "ide.hxml";
        File.saveContent(hxmlPath, hxml);

        return hxmlPath;
        //if (Sys.systemName() != "Windows") {
            //command += '; echo $? > ' + hiddenDir + '/build.log &';
            
            //return command;
        //} else {
            // Create wrapper batch file
            //var wrapper = hiddenDir + "/run_build.bat";
            //var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
            //toolchaindir = StringTools.replace(toolchaindir, "\\/" , "\\");
            //toolchaindir = StringTools.replace(toolchaindir, "/\\" , "\\");
            //toolchaindir = StringTools.replace(toolchaindir, "/" , "\\");
            //var batContent = "@echo off\r\nset PATH=" + toolchaindir + "; && PATH && " + command;
            /*var batContent = '@echo off\r\n'
            + command
            + '\r\n'
            + 'echo %ERRORLEVEL% > "'
            + StringTools.replace(hiddenDir, "/", "\\")
            + '\\build.log"\r\n';*/
            //sys.io.File.saveContent(wrapper, batContent);

            //var newcmd = wrapper;
            //return StringTools.replace(wrapper, ".bat", "");
            //return command;
        //}
    }

    private function checkLeftSideBar() {
        if (leftTabContainer.currentTab == -1) {
            leftTabContainer.hide();
        }
        else {
            leftTabContainer.show();
        }
    }

    private function checkRightSidebar() {
        if (rightTabContainer.currentTab == -1) {
            rightTabContainer.hide();
        }
        else {
            rightTabContainer.show();
        }
    }

    public function refreshLeftSidebar() {
        for (i in 0...leftTabBar.getChildCount(false)) {
            var button = leftTabBar.getChild(i);
            if (!button.isNull()) {
                button.queueFree();
            }
        }

        if (leftSidebarChildren.length == 0) {
            leftTabBar.hide();
            leftTabContainer.currentTab = -1;
            checkLeftSideBar();
            return;
        }

        leftTabBar.show();
        var tabButtonGroup = new ButtonGroup();
        tabButtonGroup.allowUnpress = true;

        var tabContainerBar = leftTabContainer.getTabBar();
        for (i in 0...leftSidebarChildren.length) {
            trace(i);
            var tabIcon = tabContainerBar.getTabIcon(i);
            var tabTitle = tabContainerBar.getTabTitle(i);
            var tabButton = new Button();
            tabButton.customMinimumSize = new Vector2(40, 40);
            tabButton.flat = true;
            tabButton.iconAlignment = HorizontalAlignment.center;
            if (tabIcon.isObjectValid()) {
                tabButton.icon = tabIcon;
            }
            else {
                var iconBin = io.loadBytes("studio://icons/16_1-5x/question-button.png");
                var iconImage = new Image();
                iconImage.loadPngFromBuffer(iconBin);
                var texture = ImageTexture.createFromImage(iconImage);
                tabButton.icon = texture;
            }
            tabButton.tooltipText = tabTitle;
            tabButton.toggled.connect(Callable.fromFunction(function(toggled: Bool) {
                if (leftTabContainer.currentTab != i || leftTabContainer.visible == false) {
                    leftTabContainer.currentTab = i;
                    leftTabContainer.show();
                    leftSidebarVisible = true;
                    checkLeftSideBar();
                }
                else if (leftTabContainer.currentTab == i) {
                    leftTabContainer.hide();
                    leftSidebarVisible = false;
                }

            }));
            tabButton.toggleMode = true;
            tabButton.buttonGroup = tabButtonGroup;
            leftTabBar.addChild(tabButton);
        }
        checkLeftSideBar();
    }

    public function refreshRightSidebar() {
        for (i in 0...rightTabBar.getChildCount(false)) {
            var button = rightTabBar.getChild(i);
            if (!button.isNull()) {
                button.queueFree();
            }
        }

        if (rightSidebarChildren.length == 0) {
            rightTabBar.hide();
            rightTabContainer.currentTab = -1;
            checkRightSidebar();
            return;
        }

        rightTabBar.show();
        var tabButtonGroup = new ButtonGroup();
        tabButtonGroup.allowUnpress = true;

        var tabContainerBar = rightTabContainer.getTabBar();
        for (i in 0...rightSidebarChildren.length) {
            var tabIcon = tabContainerBar.getTabIcon(i);
            var tabTitle = tabContainerBar.getTabTitle(i);
            var tabButton = new Button();
            tabButton.customMinimumSize = new Vector2(40, 40);
            tabButton.flat = true;
            tabButton.iconAlignment = HorizontalAlignment.center;
            if (tabIcon.isObjectValid()) {
                tabButton.icon = tabIcon;
            }
            else {
                var iconBin = io.loadBytes("studio://icons/16_1-5x/question-button.png");
                var iconImage = new Image();
                iconImage.loadPngFromBuffer(iconBin);
                var texture = ImageTexture.createFromImage(iconImage);
                tabButton.icon = texture;
            }
            tabButton.tooltipText = tabTitle;
            tabButton.toggled.connect(Callable.fromFunction(function(toggled: Bool) {
                if (rightTabContainer.currentTab != i || rightTabContainer.visible == false) {
                    rightTabContainer.currentTab = i;
                    rightTabContainer.show();
                    rightSidebarVisible = true;
                    checkRightSidebar();
                }
                else if (rightTabContainer.currentTab == i) {
                    rightTabContainer.hide();
                    rightSidebarVisible = false;
                }
            }));
            tabButton.toggleMode = true;
            tabButton.buttonGroup = tabButtonGroup;
            rightTabBar.addChild(tabButton);
        }
        checkRightSidebar();
    }

    public function setLeftSidebarTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = leftSidebarChildren.indexOf(widget);
        leftTabContainer.setTabIcon(index, icon);
        refreshLeftSidebar();
    }

    public function setRightSiderbarTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = rightSidebarChildren.indexOf(widget);
        rightTabContainer.setTabIcon(index, icon);
        refreshRightSidebar();
    }

    public function setLeftSidebarTabTitle(widget: EditorWidget, title: String) {
        var index = leftSidebarChildren.indexOf(widget);
        leftTabContainer.setTabTitle(index, title);
        refreshLeftSidebar();
    }

    public function setRightSidebarTabTitle(widget: EditorWidget, title: String) {
        var index = rightSidebarChildren.indexOf(widget);
        rightTabContainer.setTabTitle(index, title);
        refreshRightSidebar();
    }

    public function setWorkspaceTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = workspaceChildern.indexOf(widget);
        centerTabContainer.setTabIcon(index, icon);
    }

    public function setWorkspaceTabTitle(widget: EditorWidget, title: String) {
        var index = workspaceChildern.indexOf(widget);
        centerTabContainer.setTabTitle(index, title);
    }

    public function getWorkspaceTabTitle(widget: EditorWidget) {
        var index = workspaceChildern.indexOf(widget);
        return centerTabContainer.getTabTitle(index);
    }

    public function setDockTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = dockChildren.indexOf(widget);
        bottomCenterTabContainer.setTabIcon(index, icon);
    }

    public function getDockTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = dockChildren.indexOf(widget);
        return bottomCenterTabContainer.getTabIcon(index);
    }

    public function getDockTabTitle(widget: EditorWidget) {
        var index = dockChildren.indexOf(widget);
        return bottomCenterTabContainer.getTabTitle(index);
    }

    public function setDockTabTitle(widget: EditorWidget, title: String) {
        var index = dockChildren.indexOf(widget);
        bottomCenterTabContainer.setTabTitle(index, title);
    }

    public function addLeftSidebarChild(child: EditorWidget) {
        leftSidebarChildren.push(child);
        leftTabContainer.addChild(child);
        var iconBin = io.loadBytes("studio://icons/16_1-5x/question-button.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        setLeftSidebarTabIcon(child, texture);
        refreshLeftSidebar();
    }

    public function addRightSidebarChild(child: EditorWidget) {
        rightSidebarChildren.push(child);
        rightTabContainer.addChild(child);
        var iconBin = io.loadBytes("studio://icons/16_1-5x/question-button.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        setRightSiderbarTabIcon(child, texture);
        refreshRightSidebar();
    }

    public function addWorkspaceChild(child: EditorWidget) {
        workspaceChildern.push(child);
        centerTabContainer.addChild(child);
        centerTabContainer.currentTab = centerTabContainer.getTabIdxFromControl(child);
    }

    public function addDockChild(child: EditorWidget) {
        dockChildren.push(child);
        bottomCenterTabContainer.addChild(child);
    }

    public function getCurrentWorkspaceChild() {
        return workspaceChildern[centerTabContainer.currentTab];
    }

    public function setCurrentWorkspaceChild(child: EditorWidget) {
        if (workspaceChildern.contains(child)) {
            var index = workspaceChildern.indexOf(child);
            centerTabContainer.currentTab = index;
        }
    }

    public function getCurrentLeftSidebarChild() {
        return leftSidebarChildren[leftTabContainer.currentTab];
    }

    public function setCurrentLeftSidebarChild(child: EditorWidget) {
        if (leftSidebarChildren.contains(child)) {
            var index = leftSidebarChildren.indexOf(child);
            leftTabContainer.currentTab = index;
            if (leftTabContainer.visible == false && leftTabBar.visible == true) {
                leftTabContainer.visible = true;
                checkLeftSideBar();
            }
        }
    }

    public function getCurrentRightSidebarChild() {
        return rightSidebarChildren[rightTabContainer.currentTab];
    }

    public function setCurrentRightSidebarChild(child: EditorWidget) {
        if (rightSidebarChildren.contains(child)) {
            var index = rightSidebarChildren.indexOf(child);
            rightTabContainer.currentTab = index;
            if (rightTabContainer.visible == false && rightTabBar.visible == true) {
                rightTabContainer.visible = true;
                checkRightSidebar();
            }
        }
    }

    public function getCurrentDockChild() {
        return dockChildren[bottomCenterTabContainer.currentTab];
    }

    public function setCurrentDockChlid(child: EditorWidget) {
        if (dockChildren.contains(child)) {
            var index = dockChildren.indexOf(child);
            bottomCenterTabContainer.currentTab = index;
        }
    }

    var isSaveKeyPressed: Bool = false;

    public override function onInput(event: InputEvent) {
        if (isControlKeyPressed() && InputService.isKeyLabelPressed(Key.s)) {
            if (!isSaveKeyPressed) {
                isSaveKeyPressed = true;
                save();
            }
        } else {
            isSaveKeyPressed = false;
        }

        if (isGameRunning) {
            if (InputService.isKeyLabelPressed(Key.f5) && isGamePaused)
                unpause();
            else if (InputService.isKeyLabelPressed(Key.f7))
                pause();
            else if (InputService.isKeyLabelPressed(Key.f8))
                stop();
        }
        else if (gamepakBuildCoroutine == null) {
            if (InputService.isKeyLabelPressed(Key.f5))
                buildSnbForPlay();
            else if (InputService.isKeyLabelPressed(Key.f6))
                buildProject();
        }
        if (InputService.isKeyLabelPressed(Key.f4) && buildTask == null) {
            buildPlugin();
        }



        if (OSService.getName() != "macOS" && customTitlebar) {
            if (event.native.isClass("InputEventMouseButton")) {
                var eventMouseButton = Reference.castTo(event, InputEventMouseButton);
                if (window.mode != WindowMode.windowed) return;
                if (
                eventMouseButton.buttonIndex == MouseButton.left &&
                eventMouseButton.pressed
                ) {
                    var windowPosition = window.position;
                    var localX = eventMouseButton.position.x;
                    var localY = eventMouseButton.position.y;

                    /*if (OSService.getName() == "Linux") {
                        localX = eventMouseButton.position.x;
                        localY = eventMouseButton.position.y;
                    }*/

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

    public function isControlKeyPressed(): Bool {
        if (OSService.getName() == "macOS") {
            return InputService.isKeyLabelPressed(Key.meta);
        }
        else {
            return InputService.isKeyLabelPressed(Key.ctrl);
        }
    }


    public function undo() {
        getCurrentWorkspaceChild().onUndo();
    }

    public function redo() {
        getCurrentWorkspaceChild().onRedo();
    }

    public function save() {
        if (centerTabContainer.currentTab == -1) return;
        var currentWorkspaceTab = workspaceChildern[centerTabContainer.currentTab];
        if (currentWorkspaceTab == null) return;
        currentWorkspaceTab.onSave();
    }

    var buildSystem: Gamepak = new Gamepak();
    var gamepakBuildCoroutine:Coroutine<()->Void>;
    var progressBarCoroutine:Coroutine<()->Void> = null;

    var isGamePaused = false;

    var playOnBuild:Bool = false;

    public function buildSnbForPlay() {
        if (isGameRunning) return;

        playButton.disabled = true;
        buildButton.disabled = true;
        debugMenu.setItemDisabled(0, true);
        if (playBuildWindow != null) {
            var scaleFactor = window.contentScaleFactor;
            playBuildWindow.popupCentered();
        }

        buildSystem.haxePath = haxePath;

        buildSystem.chmodder = (shpath: String) -> {
            OSService.execute("chmod", StringArray.fromArray(["+x", shpath]));
        }

        var zipBuilder = new NativeReference("res://Studio/ZipBuilder.cs", new ArrayList(), ScriptType.csharp);
        trace(zipBuilder.isValid());
        buildSystem.createZip = (path) -> {
            var args = new ArrayList();
            args.append(path);
            zipBuilder.call("CreateZip", args);
        };
        buildSystem.addToZipFile = (path, bytes) -> {
            var args = new ArrayList();
            args.append(path);
            var base64 = Base64.encode(bytes);
            args.append(base64);
            zipBuilder.call("AddToZipFile", args);
        };
        buildSystem.buildZip = (path) -> {
            var args = new ArrayList();
            args.append(path);
            zipBuilder.call("BuildZip", args);
        };

        buildSystem.jsonToMsgpackConverter = (json: String) -> {
            var data : Dictionary = JSON.parseString(json);
            trace(data.keys().size());

            var script = new NativeReference("res://Engine/MessagePack.gd", new ArrayList(), ScriptType.gdscript);
			var args = new ArrayList();
			args.append(data);
			var res: Dictionary = script.call("encode", args);

            var bytes : ByteArray = res.get("value"); 
            var haxeBytes = ByteArrayUtils.binaryDataToBytes(bytes);
            return haxeBytes;
        };

        gamepakBuildCoroutine = buildSystem.buildCoroutine(projectFilePath);
        progressBarCoroutine = getPbcrt();
        playOnBuild = true;

        Coroutine.resume(gamepakBuildCoroutine);
        Coroutine.resume(progressBarCoroutine);
    }

    public function buildProject() {
        if (isGameRunning) return;

        playButton.disabled = true;
        buildButton.disabled = true;
        debugMenu.setItemDisabled(0, true);
        if (playBuildWindow != null) {
            var scaleFactor = window.contentScaleFactor;
            playBuildWindow.contentScaleFactor = scaleFactor;
            playBuildWindow.popupCentered();
        }

        buildSystem.haxePath = haxePath;

        buildSystem.chmodder = (shpath: String) -> {
            OSService.execute("chmod", StringArray.fromArray(["+x", shpath]));
        }

        var zipBuilder = new NativeReference("res://Studio/ZipBuilder.cs", new ArrayList(), ScriptType.csharp);
        trace(zipBuilder.isValid());
        buildSystem.createZip = (path) -> {
            var args = new ArrayList();
            args.append(path);
            zipBuilder.call("CreateZip", args);
        };
        buildSystem.addToZipFile = (path, bytes) -> {
            var args = new ArrayList();
            args.append(path);
            var base64 = Base64.encode(bytes);
            args.append(base64);
            zipBuilder.call("AddToZipFile", args);
        };
        buildSystem.buildZip = (path) -> {
            var args = new ArrayList();
            args.append(path);
            zipBuilder.call("BuildZip", args);
        };

        buildSystem.jsonToMsgpackConverter = (json: String) -> {
            var data : Dictionary = JSON.parseString(json);
            trace(data.keys().size());

            var script = new NativeReference("res://Engine/MessagePack.gd", new ArrayList(), ScriptType.gdscript);
			var args = new ArrayList();
			args.append(data);
			var res: Dictionary = script.call("encode", args);

            var bytes : ByteArray = res.get("value"); 
            var haxeBytes = ByteArrayUtils.binaryDataToBytes(bytes);
            return haxeBytes;
        };
        

        gamepakBuildCoroutine = buildSystem.buildCoroutine(projectFilePath);
        progressBarCoroutine = getPbcrt();
        playOnBuild = false;

        Coroutine.resume(gamepakBuildCoroutine);
        Coroutine.resume(progressBarCoroutine);
    }
    
    inline function getPbcrt(): Coroutine<()->Void> {
        return Coroutine.create(() -> {
            
            //Coroutine.yield();
            //trace(buildSystem.cnt != maxCount);
            //while (buildSystem.cnt != maxCount) {
            //    Coroutine.yield();
            //    buildProgress.value = buildSystem.cnt;
            //}
        });
    }

    var buildProgress: ProgressBar = null;
    
    function startTrack() {
        var maxCount = buildSystem.buildCoroutineCount(projectFilePath);
        trace(maxCount);

        buildProgress = getNodeT(ProgressBar, "playBuildWindow/vbox/buildProgress");
        if (buildProgress == null) {
            trace("ARE YOU FOCKING KIDDING ME");
            Sys.exit(-1);
        }
        buildProgress.maxValue = maxCount;
    }

    function unpause() {
        playButton.disabled = true;
        pauseButton.disabled = false;
        stopButton.disabled = false;
        debugMenu.setItemDisabled(0, true);
        debugMenu.setItemDisabled(1, false);
        debugMenu.setItemDisabled(2, false);
        isGamePaused = false;

        playerSubViewportContainer.processMode = CanvasItemProcessMode.inherit;
        playerAppView.processMode = CanvasItemProcessMode.inherit;
    }

    function pause() {
        pauseButton.disabled = true;
        playButton.disabled = false;
        stopButton.disabled = false;
        debugMenu.setItemDisabled(0, false);
        debugMenu.setItemDisabled(1, true);
        debugMenu.setItemDisabled(2, false);
        isGamePaused = true;

        playerSubViewportContainer.processMode = CanvasItemProcessMode.disabled;
        playerAppView.processMode = CanvasItemProcessMode.disabled;
    }

    function stop() {
        playButton.disabled = false;
        pauseButton.disabled = true;
        stopButton.disabled = true;
        buildButton.disabled = false;
        debugMenu.setItemDisabled(0, false);
        debugMenu.setItemDisabled(1, true);
        debugMenu.setItemDisabled(2, true);
        isGameRunning = false;
        isGamePaused = false;

        playerOnPrint.remove(playerPrintCallable);
        playerPrintCallable = null;
        playerOnPrint = null;

        playerSubViewportContainer.queueFree();
        playerSubViewportContainer = null;
        playerAppView = null;
    }

    var playerPrintCallable: Callable;
    var playerOnPrint: Signal;

    function play() {
        playButton.disabled = true;
        pauseButton.disabled = false;
        stopButton.disabled = false;
        debugMenu.setItemDisabled(0, true);
        debugMenu.setItemDisabled(1, false);
        debugMenu.setItemDisabled(2, false);
        isGameRunning = true;
        isGamePaused = false;
        bottomCenterTabContainer.currentTab = 1;

        playerSubViewportContainer = new SubViewportContainer();
        centerTabContainer.addChild(playerSubViewportContainer);
        playerSubViewportContainer.name = "Game";
        var iconBytes = io.loadBytes("studio://icons/16/game-monitor.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBytes);
        var iconTexture = ImageTexture.createFromImage(iconImage);
        var index = playerSubViewportContainer.getIndex();
        centerTabContainer.setTabIcon(index, iconTexture);
        playerSubViewportContainer.stretch = true;
        centerTabContainer.currentTab = index;

        var subViewport = new SubViewport();
        playerSubViewportContainer.addChild(subViewport);
        subViewport.guiEmbedSubwindows = false;

        var snbPath = buildSystem.zipOutputPath;

        playerAppView = new DesktopAppView(new NativeObject("res://Studio/game_view.gd", new ArrayList(), ScriptType.gdscript));
        playerOnPrint = Signal.createFromObject(playerAppView.native, "on_print");
        playerPrintCallable = playerOnPrint.add((line: String) -> {
            console.log(line);
        });
        subViewport.addChild(playerAppView);
        playerAppView.init(false);
        var studioUtils = StudioUtils.singleton;
        if (baseDir == null) {
            baseDir = studioUtils.getBaseDirectory();
        }
        studioUtils.queueFree();
        playerAppView.loadLibrary(baseDir + "basetxt.slib");
        playerAppView.loadLibrary(baseDir + "basesfx.slib");
        playerAppView.loadLibrary(baseDir + "basechar.slib");
        playerAppView.loadApp(snbPath);
    }

    public var baseDir: String = null;

    private var showDialog = false;

    public override function onNotification(what: Int) {
        if (what == 2011) {
            showDialog = true;
        }
    }

    public inline function loadIcon(path: String) {
        var iconBytes = io.loadBytes(path);
        if (iconBytes != null) {
            var iconImage = new Image();
            iconImage.loadPngFromBuffer(iconBytes);
            var iconTexture = ImageTexture.createFromImage(iconImage);
            return iconTexture;
        }
        return null;
    }

    public inline function openTrenchbroom(mapPath: String = "") {
        var processSpawner = new ProcessSpawner();
        var toolchaindir = toolchainDir;
        var nrProgramName = "TrenchBroom";
        if (Sys.systemName() == "Windows") {
            toolchaindir = StringTools.replace(toolchaindir, "\\/" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/\\" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/" , "\\");
            if (!StringTools.endsWith(toolchaindir, "\\")) {
                toolchaindir += "\\";
            }
            nrProgramName += "\\TrenchBroom.exe";
        }
        else {
            if (!StringTools.endsWith(toolchaindir, "/")) {
                toolchaindir += "/";
            }
            if (StringTools.contains(toolchaindir, "//")) {
                toolchaindir = StringTools.replace(toolchaindir, "//", "/");
            }
            if (Sys.systemName() == "Linux") {
                nrProgramName = "squashfs-root/usr/bin/trenchbroom";
                /*var trenchbroomPath = "~/.TrenchBroom/";
                if (!FileSystem.exists(trenchbroomPath)) {
                    FileSystem.createDirectory(trenchbroomPath);
                }
                var gamesPath = trenchbroomPath + "games";
                if (!FileSystem.exists(gamesPath)) {
                    Sys.command("ln", ["-s", gamesPath, toolchaindir + "games"]);
                }
                else {
                    Sys.command("ln", ["-sf", gamesPath, toolchaindir + "games"]);
                }*/
            }
            if (Sys.systemName() == "macOS") {
                nrProgramName = nrProgramName + ".app/Contents/MacOS/" + nrProgramName;
            }
        }
        var radiantExecutablePath = toolchaindir + nrProgramName;
        trace(radiantExecutablePath);
        trace(FileSystem.exists(radiantExecutablePath));
        if (Sys.systemName() != "Windows") {
            Sys.command("chmod", ["+x", radiantExecutablePath]);
            Sys.command("chmod", ["+X", radiantExecutablePath]);
        }
        processSpawner.spawn(radiantExecutablePath, StringArray.fromArray([mapPath]));
    }

    public inline function openNetRadiant(mapPath: String = "") {
        var processSpawner = new ProcessSpawner();
        var toolchaindir = StudioUtils.singleton.getToolchainDirectory();
        var nrProgramName = "radiant";
        if (Sys.systemName() == "Windows") {
            toolchaindir = StringTools.replace(toolchaindir, "\\/" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/\\" , "\\");
            toolchaindir = StringTools.replace(toolchaindir, "/" , "\\");
            if (!StringTools.endsWith(toolchaindir, "\\")) {
                toolchaindir += "\\";
            }
            nrProgramName += ".exe";
        }
        else {
            if (!StringTools.endsWith(toolchaindir, "/")) {
                toolchaindir += "/";
            }
            if (StringTools.contains(toolchaindir, "//")) {
                toolchaindir = StringTools.replace(toolchaindir, "//", "/");
            }
            if (Sys.systemName() == "Linux") {
                nrProgramName += ".x86_64";
            }
            if (Sys.systemName() == "macOS") {
                nrProgramName += ".arm64";
                if (!FileSystem.exists(nrProgramName)) {
                    Debug.error("NetRadiant Custom is not supported on Intel Macs running macOS");
                }
            }
        }
        var radiantExecutablePath = toolchaindir + nrProgramName;
        if (StringTools.contains(radiantExecutablePath, " ")) {
            radiantExecutablePath = "\"" + radiantExecutablePath + "\"";
        }
        if (StringTools.contains(mapPath, " ")) {
            mapPath = "\"" + mapPath + "\"";
        }
        processSpawner.spawn(radiantExecutablePath, StringArray.fromArray([mapPath]));
    }
}
