package sunaba.studio.fileHandlers;

import sunaba.io.IoManager;
import sunaba.studio.explorer.FileHandler;

class SmdlFileHandler extends FileHandler {
    public override function init() {
        this.extension = "smdl";
        this.iconPath = "studio://icons/16/block.png";
    }

    public override function openFile(path: String) {
        var ioManager: IoManager = cast editor.io;
        var assetPath = path;
        if (!StringTools.contains(assetPath, "://")) {
            assetPath = ioManager.getFileUrl(path);
        }

        var sceneEditor = new SceneEditor(editor, EditorArea.workspace);
        editor.setWorkspaceTabIcon(sceneEditor, explorer.loadIcon(iconPath));

        try {
            sceneEditor.openPrefab(assetPath);
        }
        catch(e) {
            Debug.error(e.toString(), "Error opening model");
            editor.console.error("Error opening model: " + e.toString());
        }
    }

    public override function getThunbnail(path:String):Texture2D {
        return editor.loadIcon("studio://icons/16_2x/block.png");
    }
}