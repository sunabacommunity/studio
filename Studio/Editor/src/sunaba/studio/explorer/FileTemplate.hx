package sunaba.studio.explorer;

import haxe.io.Bytes;

class FileTemplate {
    public var name:String;
    public var fileExtension: String;
    public var icon: Texture2D;
    public var createFile: String->Void;

    public function new(_name:String, _fileExtension:String, _icon: Texture2D, _createFile: String->Void) {
        name = _name;
        fileExtension =_fileExtension;
        icon = _icon;
        createFile = _createFile;
    }
}