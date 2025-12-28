package sunaba.studio.fileHandlers;

import sunaba.studio.explorer.FileHandler;

class SmdlFileHandler extends FileHandler {
    public override function init() {
        this.extension = "smdl";
        this.iconPath = "studio://icons/16/block.png";
    }

    public override function openFile(path: String) {
        var assetPath = StringTools.replace(path, explorer.assetsDirectory, editor.projectIo.pathUrl);

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
}