package sunaba.studio.fileHandlers;

class OggVorbisFileHandler extends AudioFileHandler {
    public override function init() {
        super.init();
        this.extension = "ogg";
    }
}