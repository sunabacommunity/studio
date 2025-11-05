import sys.FileSystem;
import sys.io.File;
import js.node.Os;

class Main {

    static var godotCommand = "godot-mono";

    static var targetPlatform = "";

    static var exportType = ExportType.debug;

    static var packageFormat = PackageFormat.none;

    static var targetName:String = "";

    public static function main() {
        var args = Sys.args();

        if (args[0] == "-h" || args[0] == "--help") {
            Sys.println("Usage: node build [run|export] [--godot-command=<command>] [--target=<platform>] [-debug|-release]");
            Sys.println("  run: Run Sunaba Studio");
            Sys.println("  --godot-command=<command>: Specify the Godot command to use (default: godot)");
            Sys.println("  --skip: Skip the build step");
            Sys.println("  publish: Export Sunaba Studio for the specified platform");
            Sys.println("  --skip -s: Skip the build step");
            Sys.println("  --godot-command=<command>: Specify the Godot command to use (default: godot)");
            Sys.println("  --target=<platform> -t=<platform>: Specify the target platform (default: auto-detect based on OS)");
            Sys.println("  --debug -d: Export in debug mode");
            Sys.println("  --release -r: Export in release mode");
            Sys.println("  --pkgformat=<format> -p: Specify the package format (none, nsis, deb, dmg)");
            return;
        }

        for (i in 0...args.length) {
            var arg = args[i];
            if (StringTools.startsWith(arg, "--godot-command=")) {
                godotCommand = StringTools.replace(arg, "--godot-command=", "");
                Sys.println("Using godot command: " + godotCommand);
            }
            else if (StringTools.startsWith(arg, "--target=")) {
                targetPlatform = StringTools.replace(arg, "--target=", "");
            }
            else if (arg == "--debug" || arg == "-d") {
                exportType = ExportType.debug;
            }
            else if (arg == "--release" || arg == "-r") {
                exportType = ExportType.release;
            }
            else if (StringTools.startsWith(arg, "-t=")) {
                targetPlatform = StringTools.replace(arg, "-t=", "");
            }
        }

        var currentDir = Sys.getCwd();
        if (StringTools.contains(currentDir, "\\"))
            currentDir = StringTools.replace(currentDir, "\\", "/");

        var gamepak = new Gamepak();
        gamepak.zipOutputPath = currentDir + "splashscreen.snb";
        gamepak.build(currentDir + "/Studio/Splashscreen/splash.sproj");

        var editorGamepak = new Gamepak();
        editorGamepak.zipOutputPath = currentDir + "editor.snb";
        editorGamepak.build(currentDir + "/Studio/Editor/editor.sproj");

        var dotnetRestore = Sys.command("dotnet restore Sunaba.Studio.sln");
        if (dotnetRestore != 0) {
            Sys.exit(dotnetRestore);
        }

        var dotnetBuild = Sys.command("dotnet build Sunaba.Studio.sln");
        if (dotnetBuild != 0) {
            Sys.exit(dotnetBuild);
        }

        if (args[0] == "run") {
            run();
        }
        else if (args[0] == "publish") {
            publish();
        }
    }

    public static function run() {
        var args = Sys.args();
        args.remove("run"); // Remove the "run" argument
        var argString = "";
        for (arg in args) {
            argString += arg + " ";
        }
        var result = Sys.command(godotCommand + " --path ./ " + argString);
        Sys.exit(result);
    }

    public static function setupBin() {
        if (targetPlatform == "") {
            var systemName = Sys.systemName();
            var arch = Os.arch();
            if (systemName == "Windows") {
                if (arch == "x64") {
                    targetPlatform = "windows-x86_64";
                }
                else if (arch == "ia32") {
                    targetPlatform = "windows-x86_32";
                }
                else if (arch == "arm64") {
                    targetPlatform = "windows-arm64";
                }
            }
            else if (systemName == "Mac") {
                targetPlatform = "mac-universal";
            }
            else if (systemName == "Linux") {
                if (arch == "x64") {
                    targetPlatform = "linux-x86_64";
                }
                /*else if (arch == "arm64") {
                    targetPlatform = "linux-arm64";
                }*/
            }
        }

        if (targetPlatform == "")  {
            Sys.println("Unknown target platform");
            Sys.exit(-1);
        }

        if (targetPlatform == "mac-universal") {
            targetName = "Sunaba Studio.app";
        }
        else if (StringTools.startsWith(targetPlatform, "windows")) {
            if (targetPlatform != "windows-x86_64" && targetPlatform != "windows-x86_32" && targetPlatform != "windows-arm64") {
                Sys.println("Invalid target platform: " + targetPlatform);
                Sys.exit(-1);
            }
            targetName = "Sunaba.Studio.exe";
        }
        else if (StringTools.startsWith(targetPlatform, "linux")) {
            if (targetPlatform != "linux-x86_64") {
                Sys.println("Invalid target platform: " + targetPlatform);
                Sys.exit(-1);
            }
            targetName = "sunaba-studio";
        }
        else {
            Sys.println("Invalid target platform: " + targetPlatform);
            Sys.exit(-1);
        }

        var rootPath = Sys.getCwd() + "bin";
        if (!FileSystem.exists(rootPath)) {
            FileSystem.createDirectory(rootPath);
        }

        var targetPath = rootPath + "/" + targetPlatform + "-" + exportType;
        if (!FileSystem.exists(targetPath)) {
            FileSystem.createDirectory(targetPath);
        }
    }

    public static function publish() {
        setupBin();

        Sys.println("Exporting for target platform: " + targetPlatform);
        Sys.println("Exporting for " + exportType);

        var command = godotCommand + " --path ./ --headless --editor --export-" + exportType + " \"" + targetPlatform + "\" \"./bin/" + targetPlatform + "-" + exportType + "/" + targetName + "\"";

        var result = Sys.command(command);
        if (result != 0) {
            trace("Godot export failed with code " + result);
            Sys.println(godotCommand + " exited with code " + result);
            Sys.exit(result);
        }
    }
}