package sunaba.studio.codeEditor;

import sunaba.ui.CodeEdit;
import sunaba.core.ArrayList;
import sunaba.core.native.NativeObject;

class LspBridge extends Node {
    public var editor(get, set): CodeEdit;
    function get_editor() {
        return new CodeEdit(native.get("Editor"));
    }
    function set_editor(value: CodeEdit) {
        native.set("Editor", value.native);
        return value;
    }

    public var haxePath(get, set): String;
    function get_haxePath() {
        return native.get("haxePath");
    }
    function set_haxePath(value: String) {
        native.set("haxePath", value);
        return value;
    }

    public var hxmlPath(get, set): String;
    function get_hxmlPath() {
        return native.get("hxmlPath");
    }
    function set_hxmlPath(value: String) {
        native.set("hxmlPath", value);
        return value;
    }

    public var codePath(get, set): String;
    function get_codePath() {
        return native.get("codePath");
    }
    function set_codePath(value: String) {
        native.set("codePath", value);
        return value;
    }


    public override function nativeInit(?_native:NativeObject) {
        if  (_native == null) {
            _native = new NativeObject("res://Studio/LspBridge.cs", new ArrayList(), 2);
        }
        native = _native;
    }

    public function startServer(exePath: String, arguments: String = "") {
        var args = new ArrayList();
        args.append(exePath);
        args.append(arguments);
        native.call("StartServer", args);
    }
}