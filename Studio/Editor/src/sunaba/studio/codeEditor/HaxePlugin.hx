package sunaba.studio.codeEditor;

import sunaba.core.Color;
import sunaba.ui.CodeHighlighter;

class HaxePlugin extends CodeEditorPlugin {
    var reservedWords : Array<String> = [
        "abstract",
        "break",
        "case",
        "catch",
        "class",
        "continue",
        "default",
        "do",
        "dynamic",
        "else",
        "enum",
        "extends",
        "extern",
        "false",
        "final",
        "for",
        "from",
        "function",
        "if",
        "implements",
        "import",
        "in",
        "inline",
        "interface",
        "macro",
        "new",
        "null",
        "override",
        "package",
        "private",
        "protected",
        "public",
        "return",
        "static",
        "super",
        "switch",
        "this",
        "throw",
        "to",
        "true",
        "try",
        "typedef",
        "untyped",
        "using",
        "var",
        "while",
    ];

    var functionNames : Array<String> = [
        "trace"
    ];

    public override function init() {
        highlighter = new CodeHighlighter();
        codeEditor.codeEdit.syntaxHighlighter = highlighter;


        highlighter.numberColor = Color.code("#df7aff");
        highlighter.symbolColor = Color.code("#9a9a9a");
        highlighter.functionColor = Color.code("#83cdff");
        highlighter.memberVariableColor = Color.code("#00cebe");
        highlighter.addKeywordColor("extern", Color.code("#9f6eff"));
        highlighter.addKeywordColor("typedef", Color.code("#9f6eff"));
        highlighter.addKeywordColor("class", Color.code("#5195ff"));
        highlighter.addKeywordColor("abstract", Color.code("#5195ff"));
        highlighter.addKeywordColor("extends", Color.code("#5195ff"));
        highlighter.addKeywordColor("interface", Color.code("#5195ff"));
        highlighter.addKeywordColor("enum", Color.code("#5195ff"));
        highlighter.addKeywordColor("function", Color.code("#5195ff"));
        highlighter.addKeywordColor("var", Color.code("#5195ff"));
        highlighter.addKeywordColor("new", Color.code("#5195ff"));
        highlighter.addKeywordColor("macro", Color.code("#5195ff"));
        highlighter.addKeywordColor("import", Color.code("#9f6eff"));
        highlighter.addKeywordColor("package", Color.code("#9f6eff"));
        highlighter.addKeywordColor("using", Color.code("#9f6eff"));
        highlighter.addKeywordColor("from", Color.code("#9f6eff"));
        highlighter.addKeywordColor("to", Color.code("#9f6eff"));
        highlighter.addKeywordColor("in", Color.code("#9f6eff"));
        highlighter.addKeywordColor("return", Color.code("#ff9d00"));
        highlighter.addKeywordColor("break", Color.code("#ff9d00"));
        highlighter.addKeywordColor("continue", Color.code("#ff9d00"));
        highlighter.addKeywordColor("if", Color.code("#ff9d00"));
        highlighter.addKeywordColor("else", Color.code("#ff9d00"));
        highlighter.addKeywordColor("switch", Color.code("#ff9d00"));
        highlighter.addKeywordColor("case", Color.code("#ff9d00"));
        highlighter.addKeywordColor("default", Color.code("#ff9d00"));
        highlighter.addKeywordColor("while", Color.code("#ff9d00"));
        highlighter.addKeywordColor("do", Color.code("#ff9d00"));
        highlighter.addKeywordColor("for", Color.code("#ff9d00"));
        highlighter.addKeywordColor("try", Color.code("#ff9d00"));
        highlighter.addKeywordColor("catch", Color.code("#ff9d00"));
        highlighter.addKeywordColor("throw", Color.code("#ff9d00"));
        highlighter.addKeywordColor("null", Color.code("#ff5fae"));
        highlighter.addKeywordColor("true", Color.code("#ff9d00"));
        highlighter.addKeywordColor("false", Color.code("#ff9d00"));
        highlighter.addKeywordColor("this", Color.code("#ff9d00"));
        highlighter.addKeywordColor("super", Color.code("#ff9d00"));
        highlighter.addKeywordColor("untyped", Color.code("#9f6eff"));
        highlighter.addKeywordColor("dynamic", Color.code("#9f6eff"));
        highlighter.addKeywordColor("override", Color.code("#9f6eff"));
        highlighter.addKeywordColor("implements", Color.code("#ff9d00"));
        highlighter.addKeywordColor("private", Color.code("#9f6eff"));
        highlighter.addKeywordColor("protected", Color.code("#9f6eff"));
        highlighter.addKeywordColor("public", Color.code("#9f6eff"));
        highlighter.addKeywordColor("static", Color.code("#9f6eff"));
        highlighter.addKeywordColor("trace", Color.code("#ff8080"));
        highlighter.addColorRegion("/*", "*/", Color.code("#9bda7b"), false);
        highlighter.addColorRegion("//", "", Color.code("#9bda7b"), true);
        highlighter.addColorRegion("\"", "\"", Color.code("#9bda7b"), false);
        highlighter.addColorRegion("'", "'", Color.code("#9bda7b"), false);

        codeEditor.languageName = "Haxe";
    }
}