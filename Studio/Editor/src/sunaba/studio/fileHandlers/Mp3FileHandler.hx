package sunaba.studio.fileHandlers;

class Mp3FileHandler extends AudioFileHandler {
    public override function init() {
        super.init();
        this.extension = "mp3";
    }
}