package sunaba.studio;

import sunaba.ui.ColorRect;

class Explorer extends EditorWidget {
    public override function editorInit() {
        trace("Hello, World!");

        var iconBin = io.loadBytes("studio://icons/16_1-5x/blue-folder-stand.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        getEditor().setLeftSidebarTabIcon(this, texture);

        load("studio://Explorer.suml");
    }
}