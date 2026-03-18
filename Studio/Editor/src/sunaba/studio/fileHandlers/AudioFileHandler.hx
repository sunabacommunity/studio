package sunaba.studio.fileHandlers;

import sunaba.studio.explorer.FileHandler;

class AudioFileHandler extends FileHandler {
    public override function init() {
        this.iconPath = "studio://icons/16/document-music.png";
    }

    public override function openFile(path: String) {
        var realPath = editor.io.getFilePath(path);
        OSService.shellOpen(realPath);
    }

    public override function getThunbnail(path:String):Texture2D {
        return editor.loadIcon("studio://icons/16_2x/document-music.png");
    }
}