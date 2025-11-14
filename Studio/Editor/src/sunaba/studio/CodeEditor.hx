package sunaba.studio;

import sunaba.ui.Widget;
import sunaba.ui.CodeEdit;
import sunaba.ui.Label;
import sunaba.studio.codeEditor.CodeEditorPlugin;
import sunaba.core.Callable;
import Type;
import sys.io.File;
import sunaba.input.InputService;

class CodeEditor extends EditorWidget {
    public var codeEdit: CodeEdit;

    public var lineAndColumnLabel: Label;
    public var languageLabel: Label;

    public var languageName(get, set): String;
    function get_languageName():String {
        return languageLabel.text;
    }
    function set_languageName(value:String):String {
        return this.languageLabel.text = value;
    }
    public var code(get, set): String;
    function get_code():String {
        return codeEdit.text;
    }
    function set_code(value:String):String {
        return this.codeEdit.text = value;
    }
    public var path: String;
    public var savedCode: String = "";

    public var plugin:CodeEditorPlugin;

    public override function init() {
        load("studio://CodeEditor.suml");

        codeEdit = getNodeT(CodeEdit, "vbox/codeEdit");
        lineAndColumnLabel = getNodeT(Label, "vbox/statusbar/hbox/lineAndColumnLabel");
        languageLabel = getNodeT(Label, "vbox/statusbar/hbox/languageLabel");

        codeEdit.drawControlChars = true;
        codeEdit.lineFolding = true;
    }

    public override function editorInit() {
        codeEdit.textChanged.connect(Callable.fromFunction(function() {
            var index = getIndex() - 1;
            var tabTitle = getEditor().getWorkspaceTabTitle(this);
            if (!StringTools.endsWith(tabTitle, "*")) {
                getEditor().setWorkspaceTabTitle(this, tabTitle + "*");
            } else if (code == savedCode) {
                getEditor().setWorkspaceTabTitle(this, StringTools.replace(tabTitle, "*", ""));
            }
        }));
    }

    public function openFile(path: String, pluginClass: Class<CodeEditorPlugin>) {
        path = path.split("\\").join("/");
        this.path = path;
        var fileName = path.split("/").pop();
        getEditor().setWorkspaceTabTitle(this, fileName);

        code = File.getContent(path);
        savedCode = code;
        codeEdit.clearUndoHistory();

        plugin = Type.createInstance(pluginClass, []);
        plugin.codeEditor = this;
        plugin.init();
    }

    public override function onSave() {
        if (code == savedCode)
            return;
        codeEdit.editable = false;
        File.saveContent(path, code);
        savedCode = code;
        var tabTitle = getEditor().getWorkspaceTabTitle(this);
        getEditor().setWorkspaceTabTitle(this, StringTools.replace(tabTitle, "*", ""));
    }

    public override function onProcess(deltaTime: Float) {
        if (codeEdit == null)
            return;
        if (!getEditor().isControlKeyPressed()) {
            codeEdit.editable = true;
        }

        var caretLine = codeEdit.getCaretLine(0);
        var caretColumn = codeEdit.getCaretColumn(0);
        var labelText = "Ln " + Std.string(caretLine) +", Col " + Std.string(caretColumn);
        if (lineAndColumnLabel.text != labelText) {
            lineAndColumnLabel.text = labelText;
        }
    }
    /*
    public override function onInput(event){
        if (getEditor().isControlKeyPressed()) {
            if (InputService.isKeyLabelPressed(Key.z) || InputService.isKeyLabelPressed(Key.y)) {
                codeEdit.editable = true;
            }
            else {
                codeEdit.editable = false;
            }
        }
        else {
            codeEdit.editable = true;
        }
    }
    */
}