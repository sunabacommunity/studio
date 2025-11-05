import sunaba.App;

import sunaba.studio.Splashscreen;

class Main extends App {
    public static function main() {
        new Main();
    }

	public override function init() {
		var splashscreen = new Splashscreen();
        rootNode.addChild(splashscreen);
	}
}
