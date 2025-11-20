package sunaba.studio.debugDraw;

import sunaba.core.native.NativeReference;
import sunaba.core.Color;
import sunaba.core.Transform3D;
import sunaba.Viewport;
import sunaba.core.ArrayList;
import sunaba.Font;
import sunaba.Resource;
import sunaba.core.Reference;

class DebugDrawService3DScopeConfig {
    private var ref: NativeReference;

    public function new(?_ref: NativeReference) {
        if (_ref == null) {
            ref = new NativeReference("DebugDraw3DScopeConfig");
        }
        else {
            ref = _ref;
        }
    }

    public function getRef() {
        return ref;
    }

    public function getCenterBrightness(): Float {
        return ref.call("get_center_brightness", new ArrayList());
    }

    public function getPlaneSize(): Float {
        return ref.call("get_plane_size", new ArrayList());
    }

    public function getTextFont(): Font {
        var res: Resource = new Resource(ref.call("get_text_font", new ArrayList()));
        var font: Font = Reference.castTo(res, Font);
        return font;
    }

    public function getTextOutlineColor(): Color {
        return ref.call("get_text_outline_color", new ArrayList());
    }

    public function getTextOutlineSize(): Int {
        return ref.call("get_text_outline_size", new ArrayList());
    }

    public function getThickness(): Float {
        return ref.call("get_thickness", new ArrayList());
    }

    public function getTransform(): Transform3D {
        return ref.call("get_transform", new ArrayList());
    }

    public function getViewport(): Viewport {
        return new Viewport(ref.call("get_viewport", new ArrayList()));
    }

    public function isHdSphere(): Bool {
        return ref.call("is_hd_sphere", new ArrayList());
    }

    public function isNoDepthTest(): Bool {
        return ref.call("is_no_depth_test", new ArrayList());
    }

    public function setCenterBrightness(value: Float): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_center_brightness", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setHdSphere(value: Bool): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_hd_sphere", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setNoDepthTest(value: Bool): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_no_depth_test", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setPlaneSize(value: Float): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_plane_size", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setTextFont(value: Font): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value.native);
        var nativeReference: NativeReference = ref.call("set_text_font", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setTextOutlineColor(value: Color): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_text_outline_color", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setTextOutlineSize(value: Int) {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_text_outline_size", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setThickness(value: Float): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_thickness", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setTransform(value: Transform3D) : DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value);
        var nativeReference: NativeReference = ref.call("set_transform", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }

    public function setViewport(value: Viewport): DebugDrawService3DScopeConfig {
        var args = new ArrayList();
        args.append(value.native);
        var nativeReference: NativeReference = ref.call("set_viewport", args);
        return new DebugDrawService3DScopeConfig(nativeReference);
    }
}