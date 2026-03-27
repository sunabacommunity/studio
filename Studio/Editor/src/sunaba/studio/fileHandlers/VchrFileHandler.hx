package sunaba.studio.fileHandlers;

import sunaba.io.IoManager;
import sunaba.studio.explorer.FileHandler;
import sunaba.studio.SceneEditor;
import sunaba.studio.MapViewer;
import haxe.Exception;

class VchrFileHandler extends FileHandler {
    public override function init() {
        this.extension = "vchr";
        this.iconPath = "studio://icons/16/toilet-male.png";
    }

    public override function openFile(path: String) {
        var ioManager: IoManager = cast editor.io;
        var assetPath = path;
        if (!StringTools.contains(assetPath, "://")) {
            assetPath = ioManager.getFileUrl(path);
        }

        try {
            var characterViewer = new CharacterViewer(editor, EditorArea.workspace);
            editor.setWorkspaceTabIcon(characterViewer, explorer.loadIcon(iconPath));

            characterViewer.openCharacter(assetPath);
        }
        catch (e: Exception) {
            Debug.error(e.message + " : " + e.stack);
        }
    }

    public override function getThunbnail(path:String):Texture2D {
        return editor.loadIcon("studio://icons/16_2x/toilet-male.png");
    }
}