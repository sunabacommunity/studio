package sunaba.studio;

import sunaba.BaseClass;

class Plugin extends BaseClass {
    public var editor(get, default): Editor;
    function get_editor():Editor {
        return untyped __lua__("_G.editor");
    }

    public function new() {
        var __this__ = this;
        untyped __lua__("_G['plugin'] = __this__");
    }

    public function init(): Void {

    }

    public function uninit() {

    }
}