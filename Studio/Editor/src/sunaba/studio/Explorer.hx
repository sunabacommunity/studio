package sunaba.studio;

import sunaba.ui.CenterContainer;
import sunaba.ui.MenuButton;
import sunaba.ui.TextureRect;
import sunaba.ui.Label;
import sunaba.ui.Tree;

class Explorer extends EditorWidget {
    public override function editorInit() {
        trace("Hello, World!");
        getEditor().setLeftSidebarTabTitle(this, "Project Explorer");

        var iconBin = io.loadBytes("studio://icons/16_1-5x/blue-folder-stand.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        getEditor().setLeftSidebarTabIcon(this, texture);

        load("studio://Explorer.suml");
    }
}