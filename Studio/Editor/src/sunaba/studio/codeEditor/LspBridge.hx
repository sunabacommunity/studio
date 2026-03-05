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
        native.set("Editor", value);
        return editor;
    }
    public override function nativeInit(?_native:NativeObject) {
        if  (_native == null) {
            _native = new NativeObject("res://Studio/LspBridge.cs", new ArrayList(), 2);
        }
    }

    public function startServer(exePath: String, arguments: String = "") {
        var args = new ArrayList();
        args.append(exePath);
        args.append(arguments);
        native.call("StartServer", args);
    }
}