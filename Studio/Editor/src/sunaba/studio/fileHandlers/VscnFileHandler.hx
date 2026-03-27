package sunaba.studio.fileHandlers;

import sunaba.io.IoManager;
import sunaba.studio.explorer.FileHandler;
import sunaba.studio.SceneEditor;

class VscnFileHandler extends FileHandler {
    public override function init() {
        this.extension = "vscn";
        this.iconPath = "studio://icons/16/clapperboard.png";
    }

    public override function openFile(path: String) {
        var ioManager: IoManager = cast editor.io;
        var assetPath = path;
        if (!StringTools.contains(assetPath, "://")) {
            assetPath = ioManager.getFileUrl(path);
        }

        var sceneEditor = new SceneEditor(editor, EditorArea.workspace);
        editor.setWorkspaceTabIcon(sceneEditor, explorer.loadIcon(iconPath));

        sceneEditor.openScene(assetPath);
    }

    public override function getThunbnail(path:String):Texture2D {
        return editor.loadIcon("studio://icons/16_2x/clapperboard.png");
    }
}