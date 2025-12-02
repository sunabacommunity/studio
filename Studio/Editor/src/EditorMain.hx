import sunaba.App;

import sunaba.studio.Editor;
import sunaba.studio.StudioUtils;

class EditorMain extends App {
    public static function main() {
        new EditorMain();
    }

    public override function init() {
        var editor = new Editor();
        rootNode.addChild(editor);
    }

    public function onReady() {
        StudioUtils.singleTonNative = rootNode.getNode("/root/StudioUtils").native;
    }
}