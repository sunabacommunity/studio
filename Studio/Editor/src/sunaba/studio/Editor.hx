package sunaba.studio;

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
import sunaba.studio.fileHandlers.VpfbFileHandler;
import sunaba.studio.fileHandlers.VscnFileHandler;
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

class Editor extends Widget {
    var sProjPath = "";

    public var projectFilePath(get, default): String;
    function get_projectFilePath():String {
        return sProjPath;
    }

    public var haxePath:String = "haxe"; // Default path to Haxe compiler

    public var isGameRunning: Bool = false;

    var leftTabBar: VBoxContainer;
    var rightTabBar: VBoxContainer;

    var leftTabContainer: TabContainer;
    var centerTabContainer: TabContainer;
    var rightTabContainer: TabContainer;

    var leftSidebarChildren: Array<EditorWidget> = [];
    var rightSidebarChildren: Array<EditorWidget> = [];
    var workspaceChildern: Array<EditorWidget> = [];

    public var saveFileButton: Button;
    public var reloadButton: Button;
    public var buildButton: Button;

    public var playButton:Button;
    public var pauseButton:Button;
    public var stopButton:Button;

    public var window:Window;
    public var windowSize:Vector2i;
    public var titlebarLmbPressed:Bool = false;
    public var clickcount = 0;
    public var timeSinceClick = 0.1;
    public var windowTitle:Label;
    public var subtitle:String = "";

    private var playBuildWindow: Window;
    private var pluginBuildWindow: Window;

    public var explorer: Explorer;
    public var sceneInspector: SceneInspector;

    public var projectIo: FileSystemIo;

    private var resizePreview: Bool = true;
    private var resizeThreshold: Float = 10.0;
    private var resizeThresholdBottomRight: Float = 0.25;

    private var _projectFile: ProjectFile = null;
    public var projectFile(get, default): ProjectFile;
    function get_projectFile():ProjectFile {
        return _projectFile;
    }

    private var playerSubViewportContainer: SubViewportContainer = null;
    private var playerAppView: DesktopAppView = null;

    private var debugMenu: PopupMenu = null;

    public var plugins: Array<Plugin> = new Array();

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
        centerTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/workspace");
        centerTabContainer.getTabBar().tabCloseDisplayPolicy = CloseButtonDisplayPolicy.showActiveOnly;
        rightTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/rightSidebar");
        rightTabContainer.hide();
        rightTabContainer.tabsVisible = false;

        saveFileButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/saveFile");
        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/reload");
        reloadButton.pressed.connect(Callable.fromFunction(function() {
            buildPlugin();
        }));
        buildButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/build");

        playButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/play");
        pauseButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/pause");
        stopButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/stop");

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
        /*if (OSService.getName() != "macOS") {
            windowTitle.hide();
        }*/

        playBuildWindow = getNodeT(Window, "playBuildWindow");
        playBuildWindow.hide();
        pluginBuildWindow = getNodeT(Window, "pluginBuildWindow");
        pluginBuildWindow.hide();

        var helpMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/Help");
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
        var windowSize = new Vector2i(cast 1152 * displayScale, cast 648 * displayScale);
        window.size = windowSize;
        window.minSize = windowSize;
        window.alwaysOnTop = false;
        window.moveToCenter();
        window.extendToTitle = true;
        window.mode = WindowMode.maximized;
        if (OSService.getName() == "macOS") {
            window.borderless = false;
        }
        else {
            window.borderless = true;
        }
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
                        eventMouseButton.position.x > window.size.x - resizeThreshold &&
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
                    if (window.mode == WindowMode.maximized) {
                        window.mode = WindowMode.windowed;
                        maximizeButton.text = "🗖";
                    }
                    else if (window.mode == WindowMode.windowed) {
                        windowSize = window.size;
                        window.mode = WindowMode.maximized;
                        maximizeButton.text = "🗗";
                    }
                }
            };

            var menuBar: Control = getNodeT(Control, "vbox/menuBarControl/hbox/menuBar");
            var toolBarSpacer: Control = getNodeT(Control, "vbox/toolbar/hbox/spacer");
            menuBar.guiInput.connect(eventFunc);
            menuBarControl.guiInput.connect(eventFunc);
            toolBarSpacer.guiInput.connect(eventFunc);

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

            var fileMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/File");
            fileMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    Debug.error("'New File' not implemented");
                }
                else if (id == 1) {
                    Debug.error("'Open File' not implemented");
                }
                else if (id == 2) {
                    save();
                }
                else if (id == 3) {
                    Debug.error("'Publish' not implemented");
                }
                else if (id == 4) {

                }
                else if (id == 5) {
                    Debug.error("'Open Project in Visual Studio Code' not implemented");
                }
                else if (id == 6) {
                    App.exit(0);
                }
            }));

            saveFileButton.pressed.connect(Callable.fromFunction(function() {
                save();
            }));

            var editMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/Edit");
            editMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    Debug.error("'Undo' not implemented");
                }
                else if (id == 1) {
                    Debug.error("'Redo' not implemented");
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
            var viewMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/View");
            viewMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {

            }));
            var toolsMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/Tools");
            toolsMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {

            }));
            debugMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/Debug");
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
            var helpMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/hbox/menuBar/Help");
            helpMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    OSService.shellOpen("https://docs.sunaba.gg");
                }
                else if (id == (helpMenu.itemCount - 1)) {
                    showAboutDialog();
                }
            }));

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

            var minimizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/minimizeButton");
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

            var maximizeButton = getNodeT(Button, "vbox/menuBarControl/hbox/maximizeButton");
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
                    window.mode = WindowMode.windowed;
                }
                else if (window.mode == WindowMode.windowed) {
                    maximizeButton.text = "🗗";
                    windowSize = window.size;
                    window.mode = WindowMode.maximized;
                }
            });

            var closeButton = getNodeT(Button, "vbox/menuBarControl/hbox/closeButton");
            closeButton.addThemeStyleboxOverride("normal", styleBoxEmpty);
            closeButton.focusMode = FocusModeEnum.none;
            closeButton.addThemeFontOverride("font", buttonFont);
            closeButton.text = "🗙";
            closeButton.alignment = HorizontalAlignment.center;
            closeButton.pressed.add(() -> {
                App.exit(0);
            });

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
            explorer.fileHandlers.push(new HxFileHandler(explorer));
            explorer.fileHandlers.push(new VscnFileHandler(explorer));
            explorer.fileHandlers.push(new VpfbFileHandler(explorer));
            explorer.startExplorer();

            var hiddenDir = explorer.projectDirectory + "/.studio";
            localPluginIo = new FileSystemIo();
            localPluginIo.open(hiddenDir, "plugin://");

            var ioManager: IoManager = cast io;
            ioManager.register(projectIo);
            ioManager.register(localPluginIo);

            sceneInspector = new SceneInspector(this, EditorArea.rightSidebar);

            //loadProjectPlugin();
        }
        catch(e: Exception) {
            Debug.error(e.message);
        }

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
            var batContent = "@echo off\r\nset PATH=" + toolchaindir + ";";
            var haxelibPath = toolchaindir +  "haxelib.exe";
            batContent += " && " + haxelibPath + " newrepo";
            batContent += " && " + haxelibPath + " install " + asmDir + "libsunaba.zip";
            batContent += " && " + haxelibPath + " install " + asmDir + "gamepak.zip";
            batContent += " && " + haxelibPath + " install " + asmDir + "sunaba-studio-api.zip";
            batContent += " && " + haxePath + " %*";
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
            }
            shContent += "\n\"" + haxelibPath + "\" newrepo";
            shContent += "\n\"" + haxelibPath + "\" install \"" + asmDir + "libsunaba.zip\"";
            shContent += "\n\"" + haxelibPath + "\" install \"" + asmDir + "gamepak.zip\"";
            shContent += "\n\"" + haxelibPath + "\" install \"" + asmDir + "sunaba-studio-api.zip\"";
            shContent += "\n\"" + haxePath + "\" \"$@\" ";
            sys.io.File.saveContent(wrapper, shContent);


            trace(FileSystem.exists(wrapper));
            //Sys.command("/bin/chmod", ["+x", wrapper]);
            OSService.execute("chmod", StringArray.fromArray(["+x", wrapper]));

            haxePath = wrapper;
        }
    }

    private var localPluginIo: FileSystemIo;

    public function showAboutDialog() {
        var aboutString = "Sunaba Studio\n";
        aboutString += "Version 0.7.0\n";
        aboutString += "(C) 2022-2025 mintkat\n";
        aboutString += "\n";

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

    public override function onProcess(deltaTime: Float) {
        checkFocus();

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
            }
            else {
                gamepakBuildCoroutine = null;

                playBuildWindow.hide();

                play();
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

        if (OSService.getName() != "macOS") {
            var window = getWindow();
            if (window != null) {
                if (window.mode != WindowMode.windowed) return;

                var windowsize = window.size;

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
                trace(mousePosition.x > windowsize.x + 50.0);
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

    var buildTask:Coroutine<() -> Void> = null;

    public function buildPlugin() {
        if (projectFilePath == "") {
            Debug.error("No project opened. Please open a project first.");
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
                var windowSize = pluginBuildWindow.size;
                var scaleFactor = getWindow().contentScaleFactor;
                pluginBuildWindow.minSize = new Vector2i(Std.int(windowSize.x * scaleFactor), Std.int(windowSize.y * scaleFactor));
                pluginBuildWindow.contentScaleFactor = scaleFactor;
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

            var exitCode = Sys.command(commandName, args);

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
                    checkLeftSideBar();
                }
                else if (leftTabContainer.currentTab == i) {
                    leftTabContainer.hide();
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
                    checkRightSidebar();
                }
                else if (leftTabContainer.currentTab == i) {
                    rightTabContainer.hide();
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

    public function getCurrentWorkspaceChild() {
        return workspaceChildern[centerTabContainer.currentTab];
    }

    public function getCurrentLeftSidebarChild() {
        return leftSidebarChildren[leftTabContainer.currentTab];
    }

    public function getCurrentRightSidebarChild() {
        return rightSidebarChildren[rightTabContainer.currentTab];
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
            if (InputService.isKeyLabelPressed(Key.f6) && isGamePaused)
                unpause();
            else if (InputService.isKeyLabelPressed(Key.f7))
                pause();
            else if (InputService.isKeyLabelPressed(Key.f8))
                stop();
        }
        else
            if (InputService.isKeyLabelPressed(Key.f6))
                buildSnbForPlay();


        if (OSService.getName() != "macOS") {
            if (event.native.isClass("InputEventMouseButton")) {
                var eventMouseButton = Reference.castTo(event, InputEventMouseButton);
                var window = getWindow();
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
                    localX > window.size.x - resizeThreshold &&
                    localY < resizeThreshold
                    ) {
                        DisplayService.cursorSetShape(CursorShape.bdiagsize);
                        window.startResize(WindowResizeEdge.topRight);
                        return;
                    }
                    // Bottom left
                    if (
                    localX < resizeThreshold &&
                    localY > window.size.y - resizeThreshold
                    ) {
                        DisplayService.cursorSetShape(CursorShape.bdiagsize);
                        window.startResize(WindowResizeEdge.bottomLeft);
                        return;
                    }
                    // Bottom Right
                    if (
                    localX > window.size.x - resizeThreshold &&
                    localY > window.size.y - resizeThreshold
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
                    if (localX > window.size.x - resizeThreshold) {
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
                    if (localY > window.size.y - resizeThreshold) {
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

    public function save() {
        if (centerTabContainer.currentTab == -1) return;
        var currentWorkspaceTab = workspaceChildern[centerTabContainer.currentTab];
        if (currentWorkspaceTab == null) return;
        currentWorkspaceTab.onSave();
    }

    var buildSystem: Gamepak = new Gamepak();
    var gamepakBuildCoroutine:Coroutine<()->Void>;

    var isGamePaused = false;

    public function buildSnbForPlay() {
        if (isGameRunning) return;

        playButton.disabled = true;
        debugMenu.setItemDisabled(0, true);
        if (playBuildWindow != null) {
            var scaleFactor = window.contentScaleFactor;

            var windowSize = playBuildWindow.size;
            playBuildWindow.minSize = new Vector2i(Std.int(windowSize.x * scaleFactor), Std.int(windowSize.y * scaleFactor));
            playBuildWindow.contentScaleFactor = scaleFactor;
            playBuildWindow.popupCentered();
        }

        buildSystem.haxePath = haxePath;

        buildSystem.chmodder = (shpath: String) -> {
            OSService.execute("chmod", StringArray.fromArray(["+x", shpath]));
        }

        gamepakBuildCoroutine = buildSystem.buildCoroutine(projectFilePath);

        Coroutine.resume(gamepakBuildCoroutine);
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
        debugMenu.setItemDisabled(0, false);
        debugMenu.setItemDisabled(1, true);
        debugMenu.setItemDisabled(2, true);
        isGameRunning = false;
        isGamePaused = false;

        playerSubViewportContainer.queueFree();
        playerSubViewportContainer = null;
        playerAppView = null;
    }

    function play() {
        playButton.disabled = true;
        pauseButton.disabled = false;
        stopButton.disabled = false;
        debugMenu.setItemDisabled(0, true);
        debugMenu.setItemDisabled(1, false);
        debugMenu.setItemDisabled(2, false);
        isGameRunning = true;
        isGamePaused = false;

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
        subViewport.guiEmbedSubwindows = true;

        var snbPath = buildSystem.zipOutputPath;

        playerAppView = new DesktopAppView();
        subViewport.addChild(playerAppView);
        playerAppView.init(false);
        playerAppView.loadApp(snbPath);
    }

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
}
