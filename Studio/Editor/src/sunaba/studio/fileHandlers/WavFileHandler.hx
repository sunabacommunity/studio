package sunaba.studio.fileHandlers;

class WavFileHandler extends AudioFileHandler {
    public override function init() {
        super.init();
        this.extension = "wav";
    }
}