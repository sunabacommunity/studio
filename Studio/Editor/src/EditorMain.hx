import sunaba.App;

import sunaba.studio.Editor;

class EditorMain extends App {
    public static function main() {
        new EditorMain();
    }

    public override function init() {
        var editor = new Editor();
        rootNode.addChild(editor);
    }
}