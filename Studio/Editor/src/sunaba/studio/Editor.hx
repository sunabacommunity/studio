package sunaba.studio;

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
        if (OSService.getName() != "macOS") {
            windowTitle.hide();
        }

        playBuildWindow = getNodeT(Window, "playBuildWindow");
        playBuildWindow.hide();
        pluginBuildWindow = getNodeT(Window, "pluginBuildWindow");
        pluginBuildWindow.hide();
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
        window.borderless = false;
        window.alwaysOnTop = false;
        window.moveToCenter();
        window.extendToTitle = true;
        window.mode = WindowMode.maximized;

        try {
            trace("hi!");
            var menuBarControl: Control = getNodeT(Control, "vbox/menuBarControl");
            trace("");
            if (OSService.getName() == "macOS") {
                trace("");
                var windowSize = null;
                trace("");
                var eventFunc = function(eventN: NativeReference) {
                    if (window == null)
                        return;

                    if (InputService.isMouseButtonPressed(MouseButton.left) && !titlebarLmbPressed && window.mode == WindowMode.windowed) {
                        titlebarLmbPressed = true;
                        window.startDrag();
                        clickcount++;
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
                        if (window.mode == WindowMode.maximized) {
                            window.mode = WindowMode.windowed;
                        }
                        else if (window.mode == WindowMode.windowed) {
                            windowSize = window.size;
                            window.mode = WindowMode.maximized;
                        }
                    }
                };
                trace("");

                var menuBar: Control = getNodeT(Control, "vbox/menuBarControl/menuBar");
                var toolBarSpacer: Control = getNodeT(Control, "vbox/toolbar/hbox/spacer");
                menuBar.guiInput.connect(eventFunc);
                menuBarControl.guiInput.connect(eventFunc);
                toolBarSpacer.guiInput.connect(eventFunc);
            }

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

            var fileMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/File");
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

            var editMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/Edit");
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
            var viewMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/View");
            viewMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {

            }));
            var toolsMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/Tools");
            toolsMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {

            }));
            debugMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/Debug");
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
            var helpMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/Help");
            if ((PlatformService.deviceType == PlatformDeviceType.desktop) && (OSService.getName() != "Windows")) {
                helpMenu.systemMenuId = 4;
            }
            if (OSService.getName() == "macOS") {
                helpMenu.removeItem(helpMenu.itemCount - 1);
            }
            helpMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == (helpMenu.itemCount - 1)) {
                    showAboutDialog();
                }
                else if (id == 0) {
                    OSService.shellOpen("https://docs.sunaba.gg");
                }
            }));

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

        if (PlatformService.osName == "macOS") {
            if (windowTitle.text != window.title)
                windowTitle.text = window.title;
        } else {
            windowTitle.text = "";
        }

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

        if (Sys.systemName() != "Windows") {
            command += '; echo $? > ' + hiddenDir + '/build.log &';
            return command;
        } else {
            // Create wrapper batch file
            /*var wrapper = hiddenDir + "/run_build.bat";
            var batContent = '@echo off\r\n'
            + command
            + '\r\n'
            + 'echo %ERRORLEVEL% > "'
            + StringTools.replace(hiddenDir, "/", "\\")
            + '\\build.log"\r\n';
            sys.io.File.saveContent(wrapper, batContent);

            var newcmd = 'start /B "" "' + wrapper + '"';
            return StringTools.replace(wrapper, ".bat", "");*/
            return command;
        }
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

    public override function onNotification(what: Int) {
        if (what == 2011) {
            showAboutDialog();
        }
    }
}
