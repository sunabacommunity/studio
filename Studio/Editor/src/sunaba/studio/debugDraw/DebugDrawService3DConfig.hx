package sunaba.studio.debugDraw;

import sunaba.core.native.NativeReference;
import sunaba.core.Color;

class DebugDrawService3DConfig {
    private var ref: NativeReference;

    public function new(?_ref: NativeReference) {
        if (_ref == null) {
            ref = new NativeReference("DebugDraw3DConfig");
        }
        else {
            ref = _ref;
        }
    }

    public function getRef() {
        return ref;
    }


    public var forceUseCameraFromScene(get, set): Bool;

    function get_forceUseCameraFromScene():Bool {
        return ref.get("force_use_camera_from_scene");
    }

    function set_forceUseCameraFromScene(value:Bool):Bool {
        ref.set("force_use_camera_from_scene", value);
        return value;
    }


    public var freeze3dRender(get, set): Bool;

    function get_freeze3dRender():Bool {
        return ref.get("freeze_3d_render");
    }

    function set_freeze3dRender(value:Bool):Bool {
        ref.set("freeze_3d_render", value);
        return value;
    }


    public var frustumLengthScale(get, set): Float;

    function get_frustumLengthScale():Float {
        return ref.get("frustum_length_scale");
    }

    function set_frustumLengthScale(value:Float):Float {
        ref.set("frustum_length_scale", value);
        return value;
    }


    public var geometryRenderLayers(get, set): Int;

    function get_geometryRenderLayers():Int {
        return ref.get("geometry_render_layers");
    }

    function set_geometryRenderLayers(value:Int):Int {
        ref.set("geometry_render_layers", value);
        return value;
    }


    public var lineAfterHitColor(get, set): Color;

    function get_lineAfterHitColor():Color {
        return ref.get("line_after_hit_color");
    }

    function set_lineAfterHitColor(value:Color):Color {
        ref.set("line_after_hit_color", value);
        return value;
    }


    public var lineHitColor(get, set): Color;

    function get_lineHitColor():Color {
        return ref.get("line_hit_color");
    }

    function set_lineHitColor(value:Color):Color {
        ref.set("line_hit_color", value);
        return value;
    }


    public var useFrustumCulling(get, set): Bool;

    function get_useFrustumCulling():Bool {
        return ref.get("use_frustum_culling");
    }

    function set_useFrustumCulling(value:Bool):Bool {
        ref.set("use_frustum_culling", value);
        return value;
    }


    public var visibleInstanceBounds(get, set): Bool;

    function get_visibleInstanceBounds():Bool {
        return ref.get("visible_instance_bounds");
    }

    function set_visibleInstanceBounds(value:Bool):Bool {
        ref.set("visible_instance_bounds", value);
        return value;
    }
}