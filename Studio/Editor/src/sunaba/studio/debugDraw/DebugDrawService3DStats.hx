package sunaba.studio.debugDraw;

import sunaba.core.native.NativeReference;

class DebugDrawService3DStats {
    private var ref: NativeReference;

    public function new(?_ref: NativeReference) {
        if (_ref == null) {
            ref = new NativeReference("DebugDraw3DStats");
        }
        else {
            ref = _ref;
        }
    }

    public function getRef() {
        return ref;
    }


    public var createdScopedConfigs(get, set): Int;

    function get_createdScopedConfigs():Int {
        return ref.get("created_scoped_configs");
    }


    function set_createdScopedConfigs(value:Int):Int {
        ref.set("created_scoped_configs", value);
        return value;
    }


    public var instances(get, set): Int;

    function get_instances():Int {
        return ref.get("instances");
    }

    function set_instances(value:Int):Int {
        ref.set("instances", value);
        return value;
    }


    public var instancesPhysics(get, set): Int;

    function get_instancesPhysics():Int {
        return ref.get("instances_physics");
    }

    function set_instancesPhysics(value:Int):Int {
        ref.set("instancesPhysics", value);
        return value;
    }


    public var lines(get, set): Int;

    function get_lines():Int {
        return ref.get("lines");
    }

    function set_lines(value:Int):Int {
        ref.set("lines", value);
        return value;
    }


    public var linesPhysics(get, set): Int;

    function get_linesPhysics():Int {
        return ref.get("lines_physics");
    }

    function set_linesPhysics(value:Int):Int {
        ref.set("lines_physics", value);
        return value;
    }


    public var nodesLabel3dExists(get, set): Int;

    function get_nodesLabel3dExists():Int {
        return ref.get("nodes_label3d_exists");
    }

    function set_nodesLabel3dExists(value:Int):Int {
        ref.set("node_label3d_exists", value);
        return value;
    }


    public var nodesLabel3dExistsPhysics(get, set): Int;

    function get_nodesLabel3dExistsPhysics():Int {
        return ref.get("nodes_label3d_exists_physics");
    }

    function set_nodesLabel3dExistsPhysics(value:Int):Int {
        ref.set("nodes_label3d_exists_physics", value);
        return value;
    }


    public var nodesLabel3dExistsTotal(get, set): Int;

    function get_nodesLabel3dExistsTotal():Int {
        return ref.get("nodes_label3d_exists_total");
    }

    function set_nodesLabel3dExistsTotal(value:Int):Int {
        ref.set("nodes_label3d_exists_total", value);
        return value;
    }


    public var nodesLabel3dVisible(get, set): Int;

    function get_nodesLabel3dVisible():Int {
        return ref.get("nodes_label3d_visible");
    }

    function set_nodesLabel3dVisible(value:Int):Int {
        ref.set("nodes_label3d_visible", value);
        return value;
    }


    public var nodesLabel3dVisiblePhysics(get, set): Int;

    function get_nodesLabel3dVisiblePhysics():Int {
        return ref.get("nodes_label3d_visible_physics");
    }

    function set_nodesLabel3dVisiblePhysics(value:Int):Int {
        ref.set("nodes_label3d_visible_physics", value);
        return value;
    }


    public var orphanScopedConfigs(get, set): Int;

    function get_orphanScopedConfigs():Int {
        return ref.get("orphan_scoped_configs");
    }

    function set_orphanScopedConfigs(value:Int):Int {
        ref.set("orphan_scoped_configs", value);
        return value;
    }


    public var timeCullingInstancesUsec(get, set): Int;

    function get_timeCullingInstancesUsec():Int {
        return ref.get("time_culling_instances_usec");
    }

    function set_timeCullingInstancesUsec(value:Int):Int {
        ref.set("time_culling_instances_usec", value);
        return value;
    }


    public var timeCullingLinesUsec(get, set): Int;

    function get_timeCullingLinesUsec():Int {
        return ref.get("time_culling_lines_usec");
    }

    function set_timeCullingLinesUsec(value:Int):Int {
        ref.set("time_culling_lines_usec", value);
        return value;
    }


    public var timeFillingBuffersInstancesPhysicsUsec(get, set): Int;

    function get_timeFillingBuffersInstancesPhysicsUsec():Int {
        return ref.get("time_filling_buffers_instance_physics_usec");
    }

    function set_timeFillingBuffersInstancesPhysicsUsec(value:Int):Int {
        ref.set("time_filling_buffers_instance_physics_usec", value);
        return value;
    }


    public var timeFillingBuffersInstancesUsec(get, set): Int;

    function get_timeFillingBuffersInstancesUsec():Int {
        return ref.get("time_filling_buffers_instance_usec");
    }

    function set_timeFillingBuffersInstancesUsec(value:Int):Int {
        ref.set("time_filling_buffers_instance_usec", value);
        return value;
    }


    public var timeFillingBuffersLinesPhysicsUsec(get, set): Int;

    function get_timeFillingBuffersLinesPhysicsUsec():Int {
        return ref.get("time_filling_buffers_lines_physics_usec");
    }

    function set_timeFillingBuffersLinesPhysicsUsec(value:Int):Int {
        ref.set("time_filling_buffers_lines_physics_usec", value);
        return value;
    }


    public var timeFillingBuffersLinesUsec(get, set): Int;

    function get_timeFillingBuffersLinesUsec():Int {
        return ref.get("time_filling_buffers_lines_usec");
    }

    function set_timeFillingBuffersLinesUsec(value:Int):Int {
        ref.set("time_filling_buffers_lines_usec", value);
        return value;
    }


    public var totalGeometry(get, set): Int;

    function get_totalGeometry():Int {
        return ref.get("total_geometry");
    }

    function set_totalGeometry(value:Int):Int {
        ref.set("total_geometry", value);
        return value;
    }


    public var totalTimeCullingUsec(get, set): Int;

    function get_totalTimeCullingUsec():Int {
        return ref.get("total_time_culling_usec");
    }

    function set_totalTimeCullingUsec(value:Int):Int {
        ref.set("total_time_culling_usec", value);
        return value;
    }


    public var totalTimeFillingBuffersUsec(get, set): Int;

    function get_totalTimeFillingBuffersUsec():Int {
        return ref.get("total_time_filling_buffers_usec");
    }

    function set_totalTimeFillingBuffersUsec(value:Int):Int {
        ref.set("total_time_filling_buffers_usec", value);
        return value;
    }


    public var totalTimeSpentUsec(get, set): Int;

    function get_totalTimeSpentUsec():Int {
        return ref.get("total_time_spent_usec");
    }

    function set_totalTimeSpentUsec(value:Int):Int {
        ref.set("total_time_spent_usec", value);
        return value;
    }


    public var totalVisible(get, set): Int;

    function get_totalVisible():Int {
        return ref.get("total_visible");
    }

    function set_totalVisible(value:Int):Int {
        ref.set("total_visible", value);
        return value;
    }


    public var visibleInstances(get, set): Int;

    function get_visibleInstances():Int {
        return ref.get("visible_instances");
    }

    function set_visibleInstances(value:Int):Int {
        ref.set("visible_instances", value);
        return value;
    }


    public var visibleLines(get, set): Int;

    function get_visibleLines():Int {
        return ref.get("visible_lines");
    }

    function set_visibleLines(value:Int):Int {
        ref.set("visible_lines", value);
        return value;
    }
}