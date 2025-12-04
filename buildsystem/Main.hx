import sys.FileSystem;
import sys.io.File;
import js.node.Os;
import haxe.io.BytesInput;
import haxe.zip.Reader;
import haxe.io.Bytes;
import haxe.zip.Entry;
import js.node.Http;
import js.node.Https;
import js.node.Url;
import js.node.buffer.Buffer;
import haxe.http.HttpNodeJs;
import sys.io.Process;

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

        if (args[0] == "libupdate") {
            var filepath = FileSystem.absolutePath(args[1]);
            if (!StringTools.endsWith(filepath, ".zip")) {
                Sys.println("Invalid File");
                Sys.exit(-1);
            }
            var filebytes = File.getBytes(filepath);
            extractArchiveV2(filebytes);
            return;
        }

        var skipbuild: Bool = false;

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
            else if (arg == "--skip") {
                skipbuild = true;
            }
            else if (StringTools.startsWith(arg, "--pkgformat=")) {
                packageFormat = StringTools.replace(arg, "--pkgformat=", "");
                trace(packageFormat);
            }
        }

        var currentDir = Sys.getCwd();
        if (StringTools.contains(currentDir, "\\"))
            currentDir = StringTools.replace(currentDir, "\\", "/");

        if (!skipbuild) {
            var gamepak = new Gamepak();
            gamepak.zipOutputPath = currentDir + "splashscreen.snb";
            gamepak.build(currentDir + "/Studio/Splashscreen/splash.sproj");

            var editorGamepak = new Gamepak();
            editorGamepak.zipOutputPath = currentDir + "editor.snb";
            editorGamepak.build(currentDir + "/Studio/Editor/editor.sproj");

            buildSunabaLibZip();
            buildSunabaStudioLibZip();
            buildGamepakLibZip();

            var dotnetRestore = Sys.command("dotnet restore Sunaba.Studio.sln");
            if (dotnetRestore != 0) {
                Sys.exit(dotnetRestore);
            }

            var dotnetBuild = Sys.command("dotnet build Sunaba.Studio.sln");
            if (dotnetBuild != 0) {
                Sys.exit(dotnetBuild);
            }
        }

        if (args[0] == "run") {
            run();
        }
        else if (args[0] == "publish") {
            publish();
        }

        if (packageFormat == PackageFormat.nsis) {
            buildNsis();
        }
        else if (packageFormat == PackageFormat.dmg) {
            exportDmg();
        } else if (packageFormat == PackageFormat.zip) {
            exportZip();
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

    public static function extractArchiveV2(bytes:Bytes) {
        if (bytes.length == 0) {
            trace("Download failed: empty archive");
            return;
        }
        var cwd = Sys.getCwd();
        var input = new BytesInput(bytes);
        var entries = Reader.readZip(input);
        if (!FileSystem.exists(cwd + "/lib/")) {
            FileSystem.createDirectory(cwd + "/lib/");
        }
        for (entry in entries) {
            var entryPath = cwd + "/lib/" + entry.fileName;
            if (StringTools.contains(entryPath, "\\")) {
                entryPath = StringTools.replace(entryPath, "\\", "/");
            }
            if (StringTools.endsWith(entryPath, "/") || StringTools.endsWith(entryPath, "\\") || !StringTools.contains(entryPath, ".")) {
                Sys.println("Creating Directory: " + entryPath);
                FileSystem.createDirectory(entryPath);
                continue;
            }
            var stringArray = entryPath.split("/");
            var baseDir:String = "";
            for (i in 0...stringArray.length - 1) {
                baseDir += stringArray[i] + "/";
                checkDir(baseDir);
            }
            Sys.println("Updating File: " + entryPath);
            var entryBytes = entry.data;
            File.saveBytes(entryPath, entryBytes);
        }
    }

    public static function checkDir(path:String) {
		if (!FileSystem.exists(path)) {
			Sys.println("Creating Directory: " + path);
			FileSystem.createDirectory(path);
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

    public static function buildNsis() {
        var nsisCommand = "makensis";
        if (Sys.systemName() == "Windows") {
            if (Sys.command(nsisCommand + " /VERSION") != 0) {
                Sys.println("NSIS is not installed or not found in PATH.");
                Sys.exit(-1);
            }
        } else if (Sys.systemName() == "Linux" || Sys.systemName() == "Mac") {
            nsisCommand = "makensis";
            if (Sys.command(nsisCommand + " -VERSION") != 0) {
                Sys.println("NSIS is not installed or not found in PATH.");
                Sys.exit(-1);
            }
        }

        var cwd = Sys.getCwd();

        if (!StringTools.endsWith(cwd, "/") && !StringTools.endsWith(cwd, "\\")) {
            cwd += "/";
        }

        var nsisScript = cwd + "studio.x86_64.nsi";
        if (exportType == ExportType.debug) {
            nsisScript = cwd + "studio.x86_64.debug.nsi";
        }

        if (Sys.systemName() == "Windows") {
            cwd = StringTools.replace(cwd, "/", "\\");
        }

        var command = nsisCommand + " " + nsisScript;
        trace("Running NSIS command: " + command);
        var result = Sys.command(command);
        if (result != 0) {
            Sys.println("NSIS installer creation failed with code " + result);
            Sys.exit(result);
        }

        Sys.println("NSIS installer created at: " + Sys.getCwd() + "/bin");
    }

    public static function exportZip() {
        var zipPath = Sys.getCwd() + "bin/" + targetPlatform + "-" + exportType + ".zip";
        var binPath = Sys.getCwd() + "bin/" + targetPlatform + "-" + exportType + "/";
        if (!FileSystem.exists(binPath)) {
            Sys.println("Export directory does not exist: " + binPath);
            Sys.exit(-1);
        }
        var output = new haxe.io.BytesOutput();
        var zipWriter = new haxe.zip.Writer(output);
        var entries:haxe.ds.List<haxe.zip.Entry> = new haxe.ds.List();
        for (file in FileSystem.readDirectory(binPath)) {
            if (FileSystem.isDirectory(file)) {
                continue; // Skip directories
            }
            var relativePath = StringTools.replace(file, binPath, "");
            Sys.println("Writing file to zip: " + relativePath);
            var fileBytes = File.getBytes(binPath + file);
            if (fileBytes == null) {
                Sys.println("Failed to read file: " + file);
                continue;
            }

            var entry:haxe.zip.Entry = {
                fileName: relativePath,
                fileSize: fileBytes.length,
                fileTime: Date.now(),
                dataSize: fileBytes.length,
                data: fileBytes,
                crc32: null,  // Proper CRC32 calculation
                compressed: false,
                extraFields: null
            };
            entries.push(entry);
        }
        zipWriter.write(entries);
        var zipBytes = output.getBytes();
        File.saveBytes(zipPath, zipBytes);
    }

    public static function exportDmg() {
        var applicationsFolder = "/Applications/";
        Sys.command("ln -s /Applications/ " + Sys.getCwd() + "/bin/" + targetPlatform + "-" + exportType + "/Applications");
        Sys.command("hdiutil create -volname 'Sunaba Studio' -srcfolder 'bin/"
        + targetPlatform
        + "-"
        + exportType
        + "' -ov -format UDZO 'bin/sunaba-studio-"
        + exportType
        + ".dmg'");
        Sys.println("DMG package created at: bin/sunaba-studio-" + exportType + ".dmg");
        var dmgPath = Sys.getCwd() + "bin/sunaba-studio-" + exportType + ".dmg";
        if (!FileSystem.exists(dmgPath)) {
            Sys.println("DMG package creation failed.");
            Sys.exit(-1);
        } else {
            Sys.println("DMG package created successfully at: " + dmgPath);
        }
    }

    public static function buildSunabaStudioLibZip() {
        Sys.command("haxelib dev sunaba-studio ./Studio/Editor/");

        var child_process = js.node.ChildProcess;
        var fs = js.node.Fs;

        try {
            // Use Node's child_process.execSync
            var output = child_process.execSync('haxelib path sunaba-studio', {
                encoding: 'utf8'
            });

            // First line of output contains the library path
            var libpath = StringTools.trim((output:String).split("\n")[0]);
            if (libpath == "") {
                Sys.println("Could not find sunaba-studio library path");
                Sys.exit(-1);
            }

            if (!fs.existsSync(libpath)) {
                Sys.println("Library path does not exist: " + libpath);
                Sys.exit(-1);
            }

            if (!StringTools.endsWith(libpath, "/")) {
                libpath += "/";
            }

            trace("Sunaba lib path: " + libpath);

            // Create zip file of the lib directory
            var zipOutput = new haxe.io.BytesOutput();
            var zipWriter = new haxe.zip.Writer(zipOutput);
            var entries = new List<haxe.zip.Entry>();

            function addFilesToZip(dir:String) {
                var files = fs.readdirSync(dir);
                for (file in files) {
                    var fullPath = dir + file;
                    var stats = fs.statSync(fullPath);

                    if (stats.isDirectory()) {
                        addFilesToZip(fullPath + "/");
                    } else {
                        if (StringTools.endsWith(fullPath, ".zip")) continue;
                        var fileBytes = File.getBytes(fullPath);

                        var relativePath = StringTools.replace(fullPath, libpath, "");

                        var entry:Entry = {
                            fileName: relativePath,
                            fileSize: fileBytes.length,
                            fileTime: Date.fromTime(stats.mtime.getTime()),
                            dataSize: fileBytes.length,
                            data: fileBytes,
                            crc32: null,  // Proper CRC32 calculation
                            compressed: false,
                            extraFields: null
                        };
                        entries.add(entry);
                    }
                }
            }

            addFilesToZip(libpath);
            zipWriter.write(entries);

            var zipBytes = zipOutput.getBytes();
            var cwd = js.Node.process.cwd();
            if (!StringTools.endsWith(cwd, "/")) {
                cwd += "/";
            }

            var zipPath = cwd + "sunaba-studio-api.zip";
            File.saveBytes(zipPath, zipBytes);

            Sys.println("Created sunaba-studio library zip at: " + zipPath);

        } catch (e:Dynamic) {
            Sys.println("Failed to create sunaba-studio library zip: " + e);
            Sys.exit(-1);
        }
    }

    public static function buildSunabaLibZip() {
        var child_process = js.node.ChildProcess;
        var fs = js.node.Fs;

        try {
            // Use Node's child_process.execSync
            var output = child_process.execSync('haxelib path libsunaba', {
                encoding: 'utf8'
            });

            // First line of output contains the library path
            var libpath = StringTools.trim((output:String).split("\n")[0]);
            if (libpath == "") {
                Sys.println("Could not find sunaba library path");
                Sys.exit(-1);
            }

            if (!fs.existsSync(libpath)) {
                Sys.println("Library path does not exist: " + libpath);
                Sys.exit(-1);
            }

            if (!StringTools.endsWith(libpath, "/")) {
                libpath += "/";
            }

            trace("Sunaba lib path: " + libpath);

            // Create zip file of the lib directory
            var zipOutput = new haxe.io.BytesOutput();
            var zipWriter = new haxe.zip.Writer(zipOutput);
            var entries = new List<haxe.zip.Entry>();

            function addFilesToZip(dir:String) {
                var files = fs.readdirSync(dir);
                for (file in files) {
                    var fullPath = dir + file;
                    var stats = fs.statSync(fullPath);

                    if (stats.isDirectory()) {
                        addFilesToZip(fullPath + "/");
                    } else {
                        if (StringTools.endsWith(fullPath, ".zip")) continue;
                        var fileBytes = File.getBytes(fullPath);

                        var relativePath = StringTools.replace(fullPath, libpath, "");

                        var entry:Entry = {
                            fileName: relativePath,
                            fileSize: fileBytes.length,
                            fileTime: Date.fromTime(stats.mtime.getTime()),
                            dataSize: fileBytes.length,
                            data: fileBytes,
                            crc32: null,  // Proper CRC32 calculation
                            compressed: false,
                            extraFields: null
                        };
                        entries.add(entry);
                    }
                }
            }

            addFilesToZip(libpath);
            zipWriter.write(entries);

            var zipBytes = zipOutput.getBytes();
            var cwd = js.Node.process.cwd();
            if (!StringTools.endsWith(cwd, "/")) {
                cwd += "/";
            }

            var zipPath = cwd + "libsunaba.zip";
            File.saveBytes(zipPath, zipBytes);

            Sys.println("Created sunaba library zip at: " + zipPath);

        } catch (e:Dynamic) {
            Sys.println("Failed to create sunaba library zip: " + e);
            Sys.exit(-1);
        }
    }

    public static function buildGamepakLibZip() {
        var child_process = js.node.ChildProcess;
        var fs = js.node.Fs;

        try {
            // Use Node's child_process.execSync
            var output = child_process.execSync('haxelib path gamepak', {
                encoding: 'utf8'
            });

            // First line of output contains the library path
            var libpath = StringTools.trim((output:String).split("\n")[0]);
            if (libpath == "") {
                Sys.println("Could not find gamepak library path");
                Sys.exit(-1);
            }

            if (!fs.existsSync(libpath)) {
                Sys.println("Library path does not exist: " + libpath);
                Sys.exit(-1);
            }

            if (!StringTools.endsWith(libpath, "/")) {
                libpath += "/";
            }

            trace("Gamepak lib path: " + libpath);

            // Create zip file of the lib directory
            var zipOutput = new haxe.io.BytesOutput();
            var zipWriter = new haxe.zip.Writer(zipOutput);
            var entries = new List<haxe.zip.Entry>();

            function addFilesToZip(dir:String) {
                var files = fs.readdirSync(dir);
                for (file in files) {
                    var fullPath = dir + file;
                    var stats = fs.statSync(fullPath);

                    if (stats.isDirectory()) {
                        addFilesToZip(fullPath + "/");
                    } else {
                        if (StringTools.endsWith(fullPath, ".zip")) continue;
                        var fileBytes = File.getBytes(fullPath);

                        var relativePath = StringTools.replace(fullPath, libpath, "");

                        var entry:Entry = {
                            fileName: relativePath,
                            fileSize: fileBytes.length,
                            fileTime: Date.fromTime(stats.mtime.getTime()),
                            dataSize: fileBytes.length,
                            data: fileBytes,
                            crc32: null,  // Proper CRC32 calculation
                            compressed: false,
                            extraFields: null
                        };
                        entries.add(entry);
                    }
                }
            }

            addFilesToZip(libpath);
            zipWriter.write(entries);

            var zipBytes = zipOutput.getBytes();
            var cwd = js.Node.process.cwd();
            if (!StringTools.endsWith(cwd, "/")) {
                cwd += "/";
            }

            var zipPath = cwd + "gamepak.zip";
            File.saveBytes(zipPath, zipBytes);

            Sys.println("Created gamepak library zip at: " + zipPath);

        } catch (e:Dynamic) {
            Sys.println("Failed to create gamepak library zip: " + e);
            Sys.exit(-1);
        }
    }
}