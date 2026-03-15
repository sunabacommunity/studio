package sunaba.studio;

import sunaba.ui.ItemList;
import sunaba.ui.Tree;
import sunaba.ui.TreeItem;
import sunaba.ui.MenuButton;
import sunaba.ui.Button;
import sunaba.ui.LineEdit;

class AssetBrowser extends EditorWidget {
    var backButton: Button;
    var forwardButton: Button;
    var upButton: Button;
    var reloadButton: Button;

    var addressBar: LineEdit;
    var searchBar: LineEdit;

    var newButton: MenuButton;

    var tree: Tree;
    var itemList: ItemList;

    var currentDir = "";
    var previousDirs: Array<String> = [];
    var nextDirs: Array<String> = [];

    var pathTreeItemMap: Map<String, TreeItem> = new Map();

    public override function editorInit() {
        load("studio://AssetBrowser.suml");

        getEditor().setDockTabTitle(this, "Assets");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/blue-folder-open-image.png"));

        backButton = getNodeT(Button, "vbox/toolbar/hbox/back");
        forwardButton = getNodeT(Button, "vbox/toolbar/hbox/forward");
        upButton = getNodeT(Button, "vbox/toolbar/hbox/up");
        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/reload");

        addressBar = getNodeT(LineEdit, "vbox/toolbar/hbox/addressBar");
        searchBar = getNodeT(LineEdit, "vbox/toolbar/hbox/searchBar");

        newButton = getNodeT(MenuButton, "vbox/toolbar/hbox/new");

        tree = getNodeT(Tree, "vbox/view/hsplit/tree");
        itemList = getNodeT(ItemList, "vbox/view/hsplit/itemList");

        currentDir = getEditor().projectIo.pathUrl;
        
    }
}