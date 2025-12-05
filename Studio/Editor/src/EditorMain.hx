import sunaba.App;

import sunaba.studio.Editor;
import sunaba.studio.StudioUtils;
import sunaba.OSService;
import sys.FileSystem;

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

        if (!OSService.hasFeature("editor")) {
            var haxelibPath = StudioUtils.singleton.getToolchainDirectory() + "/haxelib";
            if (Sys.systemName() == "Windows") {
                haxelibPath += ".exe";
            }
            if (!FileSystem.exists(Sys.getCwd() + "/.haxelib")) {    
                Sys.command(haxelibPath, ["newrepo"]);
            }
            //Sys.command(haxelibPath, ["install", StudioUtils.singleton.getBaseDirectory() + "/libsunaba.zip"]);
            //Sys.command(haxelibPath, ["install", StudioUtils.singleton.getBaseDirectory() + "/gamepak.zip"]);
            //Sys.command(haxelibPath, ["install", StudioUtils.singleton.getBaseDirectory() + "/sunaba-studio-api.zip"]);
            
        }
    }
}