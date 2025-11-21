package sunaba.studio;

import sunaba.Behavior;
import sunaba.core.native.NativeObject;
import sunaba.core.ArrayList;
import sunaba.core.native.ScriptType;
import sunaba.spatial.SpatialTransform;
import sunaba.core.TypedArray;
import sunaba.core.Color;
import sunaba.core.Signal;

class Gizmo3D extends Behavior {
    public var node: Node;

    public override function onStart() {
        node = new Node(new NativeObject("res://addons/Gizmo3DScript/gizmo3D.gd", new ArrayList(), ScriptType.gdscript));

        if (!node.isNull()) {
            var transform: SpatialTransform = getComponent(SpatialTransform);
            if (transform != null) {
                transform.node.addChild(node);
            }
        }
    }

    public var mode(get, set): Int;
    function get_mode():Int {
        return node.native.get("mode").toInt();
    }
    function set_mode(value:Int):Int {
        node.native.set("mode", value);
        return value;
    }

    public var layers(get, set): Int;
    function get_layers():Int {
        return node.native.get("layers");
    }
    function set_layers(value:Int):Int {
        node.native.set("layers", value);
        return value;
    }

    public var snapping(get, default): Bool;
    function get_snapping():Bool {
        return node.native.get("snapping");
    }

    public var message(get, default): String;
    function get_message():String {
        return node.native.get("message");
    }

    public var editing(get, default): Bool;
    function get_editing():Bool {
        return node.native.get("editing");
    }

    public var hovering(get, default): Bool;
    function get_hovering():Bool {
        return node.native.get("hovering");
    }

    public var size(get, set): Float;
    function get_size():Float {
        return node.native.get("size");
    }
    function set_size(value:Float):Float {
        node.native.set("size", value);
        return value;
    }

    public var showAxes(get, set): Bool;
    function get_showAxes():Bool {
        return node.native.get("show_axes");
    }
    function set_showAxes(value:Bool):Bool {
        node.native.set("show_axes", value);
        return value;
    }

    public var showSelectionBox(get, set): Bool;
    function get_showSelectionBox():Bool {
        return node.native.get("show_selection_box");
    }
    function set_showSelectionBox(value:Bool):Bool {
        node.native.set("show_selection_box", value);
        return value;
    }

    public var showRotationLine(get, set): Bool;
    function get_showRotationLine():Bool {
        return node.native.get("show_rotation_line");
    }
    function set_showRotationLine(value:Bool):Bool {
        node.native.set("show_rotation_line", value);
        return value;
    }

    public var opacity(get, set): Float;
    function get_opacity():Float {
        return node.native.get("opacity");
    }
    function set_opacity(value:Float):Float {
        node.native.set("opacity", value);
        return value;
    }

    public var colors(get, set): TypedArray<Color>;
    function get_colors():TypedArray<Color> {
        return node.native.get("colors");
    }
    function set_colors(value:TypedArray<Color>):TypedArray<Color> {
        node.native.set("colors", value);
        return value;
    }

    public var selectionBoxColor(get, set): Color;
    function get_selectionBoxColor():Color {
        return node.native.get("selection_box_color");
    }
    function set_selectionBoxColor(value:Color):Color {
        node.native.set("selection_box_color", value);
        return value;
    }

    public var useLocalSpace(get, set): Bool;
    function get_useLocalSpace():Bool {
        return node.native.get("use_local_space");
    }
    function set_useLocalSpace(value:Bool):Bool {
        node.native.set("use_local_space", value);
        return value;
    }

    public var rotateSnap(get, set): Float;
    function get_rotateSnap():Float {
        return node.native.get("rotate_snap");
    }
    function set_rotateSnap(value:Float):Float {
        node.native.set("rotate_snap", value);
        return value;
    }

    public var translateSnap(get, set): Float;
    function get_translateSnap():Float {
        return node.native.get("translate_snap");
    }
    function set_translateSnap(value:Float):Float {
        node.native.set("translate_snap", value);
        return value;
    }

    public var scaleSnap(get, set): Float;
    function get_scaleSnap():Float {
        return node.native.get("scale_snap");
    }
    function set_scaleSnap(value:Float):Float {
        node.native.set("scale_snap", value);
        return value;
    }

    private var _transformBegin: Signal;
    public var transformBegin(get, default): Signal;
    function get_transformBegin():Signal {
        if (_transformBegin == null) {
            _transformBegin = Signal.createFromObject(node.native, "transform_begin");
        }
        return _transformBegin;
    }

    private var _transformChanged: Signal;
    public var transformChanged(get, default): Signal;
    function get_transformChanged():Signal {
        if (_transformChanged == null) {
            _transformChanged = Signal.createFromObject(node.native, "transform_changed");
        }
        return _transformChanged;
    }

    private var _transformEnd: Signal;
    public var transformEnd(get, default): Signal;
    function get_transformEnd():Signal {
        if (_transformEnd == null) {
            _transformEnd = Signal.createFromObject(node.native, "transform_end");
        }
        return _transformEnd;
    }

    public function select(target: SpatialTransform) {
        var args = new ArrayList();
        args.append(target.node.native);
        node.native.call("select", args);
    }

    public function deselect(target: SpatialTransform) {
        var args = new ArrayList();
        args.append(target.node.native);
        node.native.call("deselect", args);
    }

    public function isSelected(target: SpatialTransform): Bool {
        var args = new ArrayList();
        args.append(target.node.native);
        return node.native.call("is_selected", args);
    }

    public function clearSelection() {
        node.native.call("clear_selection", new ArrayList());
    }

    public function getSelectedCount(): Int {
        return node.native.call("get_selected_count", new ArrayList());
    }
}