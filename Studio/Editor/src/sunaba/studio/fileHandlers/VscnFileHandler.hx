package sunaba.studio.fileHandlers;

import sunaba.studio.explorer.FileHandler;
import sunaba.studio.SceneEditor;

class VscnFileHandler extends FileHandler {
    public override function init() {
        this.extension = "vscn";
        this.iconPath = "studio://icons/16/clapperboard.png";
    }

    public override function openFile(path: String) {
        var sceneEditor = new SceneEditor(editor, EditorArea.workspace);
        editor.setWorkspaceTabIcon(sceneEditor, explorer.loadIcon(iconPath));
    }
}