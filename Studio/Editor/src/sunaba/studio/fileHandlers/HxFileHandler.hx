package sunaba.studio.fileHandlers;

import sunaba.studio.explorer.FileHandler;
import sunaba.studio.CodeEditor;
import sunaba.studio.EditorArea;
import sunaba.studio.codeEditor.HaxePlugin;


class HxFileHandler extends FileHandler {
    public override function init() {
        this.extension = "hx";
        this.iconPath = "studio://icons/16/script-code.png";
    }

    public override function openFile(path: String) {
        var codeEditor = new CodeEditor(editor, EditorArea.workspace);
        editor.setWorkspaceTabIcon(codeEditor, explorer.loadIcon(iconPath));
        codeEditor.openFile(path, HaxePlugin);
    }
}