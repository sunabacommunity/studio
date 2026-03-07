package sunaba.studio;
import sunaba.spatial.SpatialTransform;
import sunaba.input.InputEvent;
import sunaba.input.InputService;
import sunaba.core.Reference;
import sunaba.input.InputEventMouseMotion;

class PanLook extends Behavior {
    public var transform: SpatialTransform;

    public var mouseSensitivity: Float = 0.1;

    public override function onStart() {
        mouseSensitivity = 0.1;
    }

    public override function onInput(event: InputEvent) {
        if (event.native.isClass("InputEventMouseMotion")) {
            if (InputService.isMouseButtonPressed(MouseButton.left) || InputService.isMouseButtonPressed(MouseButton.right)) {
                var mouseMotionEvent = Reference.castTo(event, InputEventMouseMotion);
                var mouseAxis = mouseMotionEvent.relative;
                var rotation = transform.rotation;
                rotation.y -= mouseAxis.x * mouseSensitivity * .01;
                rotation.x = Clamp(rotation.x - mouseAxis.y * mouseSensitivity * .01, -1.5, 1.5);
                transform.rotation = rotation;
            }
        }
    }

    public override function onUpdate(deltaTime: Float) {
        var rotation = transform.rotation;
        rotation.z = 0;
        transform.rotation = rotation;
    }

    inline function Clamp<T:Float>(value:T, min:T, max:T):T {
        return if (value < min) min else if (value > max) max else value;
    }
}