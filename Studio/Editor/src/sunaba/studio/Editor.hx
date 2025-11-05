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

class Editor extends Widget {
    var sProjPath = "";

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

    private var projectIo: FileSystemIo;

    public override function init() {
        load("studio://Editor.suml");

        leftTabBar = getNodeT(VBoxContainer, "vbox/hbox/leftTabBar");
        rightTabBar = getNodeT(VBoxContainer, "vbox/hbox/rightTabBar");

        leftTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/leftSidebar");
        leftTabContainer.hide();
        centerTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/workspace");
        rightTabContainer = getNodeT(TabContainer, "vbox/hbox/hsplit1/hsplit2/rightSidebar");
        rightTabContainer.hide();

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
        //window.extendToTitle = true;
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

            var fileMenu: PopupMenu = getNodeT(PopupMenu, "vbox/menuBarControl/menuBar/File");
            fileMenu.idPressed.connect(Callable.fromFunction(function(id: Int) {
                if (id == 0) {
                    Debug.error("'New File' not implemented");
                }
                else if (id == 1) {
                    Debug.error("'Open File' not implemented");
                }
                else if (id == 2) {
                    Debug.error("'Save File' not implemented");
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
                    Debug.error("'About' not implemented");
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
        }
        catch(e: Exception) {
            Debug.error(e.message);
        }
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
            var tabIcon = tabContainerBar.getTabIcon(i);
            var tabTitle = tabContainerBar.getTabTitle(i);
            var tabButton = new Button();
            if (!tabIcon.isNull()) {
                tabButton.icon = tabIcon;
            }
            else {

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
        }
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
            if (!tabIcon.isNull()) {
                tabButton.icon = tabIcon;
            }
            else {

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
        }
    }

    public function setLeftSidebarTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = leftSidebarChildren.indexOf(widget);
        if (leftTabContainer.getTabControl(index).isNull()) {
            return;
        }
        leftTabContainer.setTabIcon(index, icon);
    }

    public function setRightSiderbarTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = rightSidebarChildren.indexOf(widget);
        if (rightTabContainer.getTabControl(index).isNull()) {
            return;
        }
        rightTabContainer.setTabIcon(index, icon);
    }

    public function setLeftSidebarTabTitle(widget: EditorWidget, title: String) {
        var index = leftSidebarChildren.indexOf(widget);
        if (leftTabContainer.getTabControl(index).isNull()) {
            return;
        }
        leftTabContainer.setTabTitle(index, title);
    }

    public function setRightSidebarTabTitle(widget: EditorWidget, title: String) {
        var index = rightSidebarChildren.indexOf(widget);
        if (rightTabContainer.getTabControl(index).isNull()) {
            return;
        }
        rightTabContainer.setTabTitle(index, title);
    }

    public function setWorkspaceTabIcon(widget: EditorWidget, icon: Texture2D) {
        var index = workspaceChildern.indexOf(widget);
        if (centerTabContainer.getTabControl(index).isNull()) {
            return;
        }
        centerTabContainer.setTabIcon(index, icon);
    }

    public function setWorkspaceTabTitle(widget: EditorWidget, title: String) {
        var index = workspaceChildern.indexOf(widget);
        if (centerTabContainer.getTabControl(index).isNull()) {
            return;
        }
        centerTabContainer.setTabTitle(index, title);
    }

    public function addLeftSidebarChild(child: EditorWidget) {
        leftSidebarChildren.push(child);
        leftTabContainer.addChild(child);
        refreshLeftSidebar();
    }

    public function addRightSidebarChild(child: EditorWidget) {
        rightSidebarChildren.push(child);
        rightTabContainer.addChild(child);
        refreshRightSidebar();
    }

    public function addWorkspaceChild(child: EditorWidget) {
        workspaceChildern.push(child);
        centerTabContainer.addChild(child);
    }
}