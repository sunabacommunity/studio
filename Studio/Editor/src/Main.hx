import sunaba.App;

import sunaba.studio.Editor;

class Main extends App {
    public static function main() {
        new Main();
    }

    public override function init() {
        var editor = new Editor();
        rootNode.addChild(editor);
    }
}