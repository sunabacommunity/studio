package sunaba.studio;

class AssetBrowser extends EditorWidget {
    public override function editorInit() {
        load("studio://AssetBrowser.suml");

        getEditor().setDockTabTitle(this, "Assets");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/blue-folder-open-image.png"));
    }
}