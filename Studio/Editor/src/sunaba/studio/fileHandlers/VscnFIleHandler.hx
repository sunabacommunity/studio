package sunaba.studio.fileHandlers;
import sunaba.studio.explorer.FileHandler;

class VscnFileHandler extends FileHandler {
    public override function init() {
        this.extension = "vscn";
        this.iconPath = "studio://icons/16/clapperboard.png";
    }
}