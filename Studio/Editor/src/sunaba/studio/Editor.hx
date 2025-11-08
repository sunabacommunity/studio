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

    public var explorer: Explorer;

    public var projectIo: FileSystemIo;

    private var _projectFile: ProjectFile = null;
    public var projectFile(get, default): ProjectFile;
    function get_projectFile():ProjectFile {
        return _projectFile;
    }

    public var saveEvent: GameEvent<()->Void> = new GameEvent();

    public override function init() {
        load("studio://Editor.suml");

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
        buildButton = getNodeT(Button, "vbox/toolbar/hbox/leftToolbar/build");

        playButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/play");
        pauseButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/pause");
        stopButton = getNodeT(Button, "vbox/toolbar/hbox/rightToolbar/stop");

        windowTitle = getNodeT(Label, "vbox/menuBarControl/windowTitle");
        if (OSService.getName() != "macOS") {
            windowTitle.hide();
        }

    }

    public override function onReady() {
        var window = getWindow();
        var displayScale = DisplayService.screenGetScale(window.currentScreen);
        if (OSService.getName() != "macOS") {
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
                else if (id == 2) {
                    Debug.error("'Cut' not implemented");
                }
                else if (id == 3) {
                    Debug.error("'Copy' not implemented");
                }
                else if (id == 4) {
                    Debug.error("'Paste' not implemented");
                }
            }));
            var viewMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/View");
            viewMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {

            }));
            var toolsMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/Tools");
            toolsMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {

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
                return;
            }

            _projectFile = haxe.Json.parse(projJson);

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

            explorer.startExplorer();
        }
        catch(e: Exception) {
            Debug.error(e.message);
        }
    }

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

        var window = getWindow();

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
                if (toggled == true) {
                    leftTabContainer.currentTab = i;
                }
                else if (leftTabContainer.currentTab == i) {
                    leftTabContainer.currentTab = -1;
                }
                checkLeftSideBar();
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
                if (toggled == true) {
                    rightTabContainer.currentTab = i;
                }
                else if (rightTabContainer.currentTab == i) {
                    rightTabContainer.currentTab = -1;
                }
                checkRightSidebar();
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
        trace(saveEvent == null);
        saveEvent.call();
    }
}