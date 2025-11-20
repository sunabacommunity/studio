package sunaba.studio.debugDraw;

import sunaba.core.native.NativeObject;
import sunaba.core.native.NativeReference;
import sunaba.core.Color;
import sunaba.core.ArrayList;
import sunaba.core.Vector3;
import sunaba.core.TypedArray;
import sunaba.core.Transform3D;
import sunaba.core.Quaternion;
import sunaba.spatial.Camera;
import sunaba.core.Vector2i;
import sunaba.core.Plane;
import sunaba.Viewport;
import sunaba.core.Variant;

class DebugDrawService3D {
    private static var obj: NativeObject;

    public static function getObj(): NativeObject {
        if (obj == null) {
            obj = NativeObject.getService("DebugDraw3D");
        }
        return obj;
    }


    public static var config(get, set): DebugDrawService3DConfig;

    static function get_config():DebugDrawService3DConfig {
        return new DebugDrawService3DConfig(getObj().get("config"));
    }

    static function set_config(value:DebugDrawService3DConfig):DebugDrawService3DConfig {
        getObj().set("config", value.getRef());
        return value;
    }


    public static var debugEnabled(get, set): Bool;

    static function get_debugEnabled():Bool {
        return getObj().get("debug_enabled");
    }

    static function set_debugEnabled(value:Bool):Bool {
        getObj().set("debug_enabled", value);
        return value;
    }


    public static var emptyColor(get, set): Color;

    static function get_emptyColor():Color {
        return getObj().get("empty_color");
    }

    static function set_emptyColor(value:Color):Color {
        getObj().set("empty_color", value);
        return value;
    }


    public static function clearAll() {
        getObj().call("clearAll", new ArrayList());
    }

    public static function drawAabbAb(a: Vector3, b: Vector3, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(a);
        args.append(b);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_aabb_ab", args);
    }

    public static function drawArrow(a: Vector3, b: Vector3, ?color: Color, ?arrowSize: Float, ?isAbsoluteSize: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(a);
        args.append(b);
        if (color != null) {
            args.append(color);
        }
        if (arrowSize != null) {
            args.append(arrowSize);
        }
        if (isAbsoluteSize != null) {
            args.append(isAbsoluteSize);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_arrow", args);
    }

    public static function drawArrowPath(path: TypedArray<Vector3>, ?color: Color, ?arrowSize: Float, ?isAbsoluteSize: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(path);
        if (color != null) {
            args.append(color);
        }
        if (arrowSize != null) {
            args.append(arrowSize);
        }
        if (isAbsoluteSize != null) {
            args.append(isAbsoluteSize);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_arrow_path", args);
    }

    public static function drawArrowRay(origin: Vector3, direction: Vector3, length: Float, ?color: Color, ?arrowSize: Float, ?isAbsoluteSize: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(origin);
        args.append(direction);
        args.append(length);
        if (color != null) {
            args.append(color);
        }
        if (arrowSize != null) {
            args.append(arrowSize);
        }
        if (isAbsoluteSize != null) {
            args.append(isAbsoluteSize);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_arrow_ray", args);
    }

    public static function drawArrowhead(transform: Transform3D, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_arrowhead", args);
    }

    public static function drawBox(position: Vector3, rotation: Quaternion, size: Vector3, ?color: Color, ?isBoxCentered: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(position);
        args.append(rotation);
        args.append(size);
        if (color != null) {
            args.append(color);
        }
        if (isBoxCentered != null) {
            args.append(isBoxCentered);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_box", args);
    }

    public static function drawBoxAb(a: Vector3, b: Vector3, ?up: Vector3, ?color: Color, ?isAbDiagonal: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(a);
        args.append(b);
        if (up != null) {
            args.append(up);
        }
        if (color != null) {
            args.append(color);
        }
        if (isAbDiagonal != null) {
            args.append(isAbDiagonal);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_box_ab", args);
    }

    public static function drawBoxXf(transform: Transform3D, ?color: Color, ?isBoxCentered: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        if (color != null) {
            args.append(color);
        }
        if (isBoxCentered != null) {
            args.append(isBoxCentered);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_box_xf", args);
    }

    public static function drawCameraFrustum(camera: Camera, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(camera.node);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_camera_frustum", args);
    }

    public static function drawCameraFrustumPlanes(cameraFrustum: ArrayList, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(cameraFrustum);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_camera_frustum_planes", args);
    }

    public static function drawCylinder(transform: Transform3D, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_cylinder", args);
    }

    public static function drawCylinderAb(a: Vector3, b: Vector3, ?radius: Float, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(a);
        args.append(b);
        if (radius != null) {
            args.append(radius);
        }
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_cylinder_ab", args);
    }

    public static function drawGizmo(transform: Transform3D, ?color: Color, ?isCentered: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        if (color != null) {
            args.append(color);
        }
        if (isCentered != null) {
            args.append(isCentered);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_gizmo", args);
    }

    public static function drawGrid(origin: Vector3, xSize: Vector3, ySize: Vector3, subdivision: Vector2i, ?color: Color, ?isCentered: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(origin);
        args.append(xSize);
        args.append(ySize);
        args.append(subdivision);
        if (color != null) {
            args.append(color);
        }
        if (isCentered != null) {
            args.append(isCentered);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_grid", args);
    }

    public static function drawGridXf(transform: Transform3D, subdivision: Vector2i, ?color: Color, ?isCentered: Bool, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        args.append(subdivision);
        if (color != null) {
            args.append(color);
        }
        if (isCentered != null) {
            args.append(isCentered);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_grid_xf", args);
    }

    public static function drawLine(a: Vector3, b: Vector3, ?color: Color, ?duration: Float) {
        var args =  new ArrayList();
        args.append(a);
        args.append(b);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_line", args);
    }

    public static function drawLineHit(start: Vector3, end: Vector3, hit: Vector3, isHit: Bool, ?hitSize: Float, ?hitColor: Color, ?afterHitColor: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(start);
        args.append(end);
        args.append(hit);
        args.append(isHit);
        if (hitSize != null) {
            args.append(hitSize);
        }
        if (hitColor != null) {
            args.append(hitColor);
        }
        if (afterHitColor != null) {
            args.append(afterHitColor);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_line_hit", args);
    }

    public static function drawLineHitOffset(start: Vector3, end: Vector3, isHit: Bool, ?unitOffsetOfHit: Float, ?hitSize: Float, ?hitColor: Color, ?afterHitColor: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(start);
        args.append(end);
        args.append(isHit);
        if (unitOffsetOfHit != null) {
            args.append(unitOffsetOfHit);
        }
        if (hitSize != null) {
            args.append(hitSize);
        }
        if (hitColor != null) {
            args.append(hitColor);
        }
        if (afterHitColor != null) {
            args.append(afterHitColor);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_line_hit_offset", args);
    }

    public static function drawLinePath(path: TypedArray<Vector3>, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(path);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_line_path", args);
    }

    public static function drawLines(lines: TypedArray<Vector3>, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(lines);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_lines", args);
    }

    public static function drawPlane(planes: Variant, ?color: Color, ?anchorPoint: Vector3, ?duration: Float) {
        var args = new ArrayList();
        args.append(planes);
        if (color != null) {
            args.append(color);
        }
        if (anchorPoint != null) {
            args.append(anchorPoint);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_plane", args);
    }

    public static function drawPointPath(path: TypedArray<Vector3>, ?type: Variant, ?size: Float, ?pointsColor: Color, ?linesColor: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(path);
        if (type != null) {
            args.append(type);
        }
        if (size != null) {
            args.append(size);
        }
        if (pointsColor != null) {
            args.append(pointsColor);
        }
        if (linesColor != null) {
            args.append(linesColor);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_point_path", args);
    }

    public static function drawPoints(points: TypedArray<Vector3>, ?type: Variant, ?size: Float, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(points);
        if (type != null) {
            args.append(type);
        }
        if (size != null) {
            args.append(size);
        }
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_points", args);
    }

    public static function drawPosition(transform: Transform3D, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_position", args);
    }

    public static function drawRay(origin: Vector3, direction: Vector3, length: Float, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(origin);
        args.append(direction);
        args.append(length);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_ray", args);
    }

    public static function drawSphere(position: Vector3, ?radius: Float, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(position);
        if (radius != null) {
            args.append(radius);
        }
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_sphere", args);
    }

    public static function drawSphereXf(transform: Transform3D, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(transform);
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_sphere_xf", args);
    }

    public static function drawSquare(position: Vector3, ?size: Float, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(position);
        if (size != null) {
            args.append(size);
        }
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_square", args);
    }

    public static function drawText(position: Vector3, text: String, ?size: Int, ?color: Color, ?duration: Float) {
        var args = new ArrayList();
        args.append(position);
        args.append(text);
        if (size != null) {
            args.append(size);
        }
        if (color != null) {
            args.append(color);
        }
        if (duration != null) {
            args.append(duration);
        }
        getObj().call("draw_text", args);
    }

    public static function getRenderStats() {
        var renderStats: NativeReference = getObj().call("get_render_stats", new ArrayList());
        return new DebugDrawService3DStats(renderStats);
    }

    public static function getRenderStatsForWorls(viewport: Viewport) {
        var args = new ArrayList();
        args.append(viewport.native);
        var renderStats: NativeReference = getObj().call("get_render_stats_for_world", args);
        return new DebugDrawService3DStats(renderStats);
    }

    public static function newScopedConfig() {
        var scopedConfig: NativeReference = getObj().call("new_scoped_config", new ArrayList());
        return new DebugDrawService3DScopeConfig(scopedConfig);
    }

    public static function regenerateGeometryMeshes() {
        getObj().call("regenerate_geometry_meshes", new ArrayList());
    }

    public static function scopedConfig() {
        var scopedConfig: NativeReference = getObj().call("scoped_config", new ArrayList());
        return new DebugDrawService3DScopeConfig(scopedConfig);
    }
}