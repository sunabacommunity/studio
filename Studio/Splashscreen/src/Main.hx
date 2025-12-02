import sunaba.App;

import sunaba.studio.Splashscreen;
import sunaba.studio.StudioUtils;

class Main extends App {
    public static function main() {
        new Main();
    }

	public override function init() {
		var splashscreen = new Splashscreen();
        rootNode.addChild(splashscreen);
	}

    public function onReady() {
        StudioUtils.singleTonNative = rootNode.getNode("/root/StudioUtils").native;
    }
}
