package sunaba.studio.fileHandlers;

import sunaba.io.IoManager;
import sunaba.studio.explorer.FileHandler;

class VpfbFileHandler extends FileHandler {
    public override function init() {
        this.extension = "vpfb";
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

        sceneEditor.openPrefab(assetPath);
    }

    public override function getThunbnail(path:String):Texture2D {
        return editor.loadIcon("studio://icons/16_2x/block.png");
    }
}