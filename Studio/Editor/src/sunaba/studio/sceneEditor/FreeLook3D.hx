package sunaba.studio.sceneEditor;

import sunaba.Behavior;
import sunaba.spatial.SpatialTransform;
import sunaba.core.Vector3;
import sunaba.input.InputService;
import sunaba.input.InputEvent;
import sunaba.core.Reference;
import sunaba.input.InputEventMouseMotion;
import sunaba.input.InputEventMouseButton;

class FreeLook3D extends Behavior {
    public var transform: SpatialTransform;

    var sensitivity = 3.0;
    var controllerSensitivity = 20.0;
    var defaultVelocity = 5.0;
    var speedScale = 1.17;
    var boostSpeedMultiplier = 3.0;
    var maxSpeed = 1000.0;
    var minSpeed = 0.2;

    var velocity: Float = 5.0;

    var initialPosition: Vector3;
    var initialRotation: Vector3;

    public  var active = true;

    var isJoystickActive = false;

    var speedToggle = false;

    public override function onInit() {
        sensitivity = 3.0;
        defaultVelocity = 5.0;
        boostSpeedMultiplier = 3.0;
        speedScale = 1.17;
        minSpeed = 0.2;
        maxSpeed = 1000.0;
    }

    public override function onStart() {
        transform = getComponent(SpatialTransform);

        velocity = defaultVelocity;
        if (transform == null) return;
        initialPosition = transform.globalPosition;
        initialRotation = transform.globalRotation;
    }

    public override function onInput(event: InputEvent) {
        if (!active) return;
        if (transform == null) {
            transform = getComponent(SpatialTransform);

            if (transform == null) {
                trace("Transform is null");
                return;
            }
        }

        if (event.native.isClass("InputEventMouseButton")) {
            var eventMouseButton = Reference.castTo(event, InputEventMouseButton);
            var buttonIndex = eventMouseButton.buttonIndex;
            if (buttonIndex == MouseButton.right) {
                if (eventMouseButton.pressed == true) {
                    InputService.mouseMode = MouseMode.captured;
                }
                else {
                    InputService.mouseMode = MouseMode.visible;
                }
            }
            else if (buttonIndex == MouseButton.wheelUp) {
                velocity = Clamp(velocity * speedScale, minSpeed, maxSpeed);
            }
            else if (buttonIndex == MouseButton.wheelDown) {
                velocity = Clamp(velocity / speedScale, minSpeed, maxSpeed);
            }
        }
        else if (!InputService.isMouseButtonPressed(MouseButton.right)) {
            if (InputService.isKeyPressed(Key.alt)) {
                InputService.mouseMode = MouseMode.captured;
            }
            else {
                InputService.mouseMode = MouseMode.visible;
            }
        }

        if (InputService.mouseMode == MouseMode.captured) {
            if (event.native.isClass("InputEventMouseMotion")) {
                var eventMouseMotion = Reference.castTo(event, InputEventMouseMotion);
                var rotation = transform.rotation;
                rotation.y -= eventMouseMotion.relative.x / 1000 * this.sensitivity;
                rotation.x -= eventMouseMotion.relative.y / 1000 * this.sensitivity;
                rotation.x = Clamp(rotation.x, Math.PI / -2.0, Math.PI / 2.0);
                transform.rotation = rotation;
            }
        }
        /*if (event.native.isClass("InputEventJoypadMotion")) {
            var rotation = transform.rotation;
            rotation.y -= InputService.getJoyAxis(0, JoyAxis.rightX) / 1000 * controllerSensitivity;
            rotation.x -= InputService.getJoyAxis(0, JoyAxis.rightY) / 1000 * controllerSensitivity;
            rotation.x = Clamp(rotation.x, Math.PI / -2.0, Math.PI / 2.0);
            transform.rotation = rotation;
            isJoystickActive = true;
        }
        else isJoystickActive = false;*/

        //if (event.native.isClass("InputEventJoypadButton"))
        //    if (InputService.isJoyButtonPressed(0, JoyButton.dpadUp))
        //        velocity = Clamp(velocity * speedScale, minSpeed, maxSpeed);
        //    else if (InputService.isJoyButtonPressed(0, JoyButton.dpadDown))
        //        velocity = Clamp(velocity / speedScale, minSpeed, maxSpeed);


    }

    public override function onUpdate(deltaTime: Float) {
        if (!active) return;
        if (transform == null) {
            transform = getComponent(SpatialTransform);

            if (transform == null) {
                trace("Transform is null");
                return;
            }
        }
        else {
            if (initialPosition == null) initialPosition = transform.globalPosition;
            if (initialRotation == null) initialRotation = transform.globalRotation;
        }

        var direction = new Vector3(
            getAxis(InputService.isPhysicalKeyPressed(Key.d), InputService.isPhysicalKeyPressed(Key.a)),
            getAxis(InputService.isPhysicalKeyPressed(Key.e), InputService.isPhysicalKeyPressed(Key.q)),
            getAxis(InputService.isPhysicalKeyPressed(Key.s), InputService.isPhysicalKeyPressed(Key.w))
        ).normalized();

        var joypadDirection = new Vector3(
            Math.round(InputService.getJoyAxis(0, JoyAxis.leftX)),
            getCombinedAxis(InputService.getJoyAxis(0, JoyAxis.triggerRight), InputService.getJoyAxis(0, JoyAxis.triggerLeft)),
            Math.round(InputService.getJoyAxis(0, JoyAxis.leftY))
        ).normalized();

        if (InputService.isJoyButtonPressed(0, JoyButton.leftStick))
            speedToggle = !speedToggle;

        var offset = new Vector3(0, 0, 0);

        if (speedToggle && isJoystickActive) {
            offset.x = joypadDirection.x * velocity * deltaTime * boostSpeedMultiplier;
            offset.y = joypadDirection.y * velocity * deltaTime * boostSpeedMultiplier;
            offset.z = joypadDirection.z * velocity * deltaTime * boostSpeedMultiplier;
        }
        else if (isJoystickActive) {
            offset.x = joypadDirection.x * velocity * deltaTime;
            offset.y = joypadDirection.y * velocity * deltaTime;
            offset.z = joypadDirection.z * velocity * deltaTime;
        }
        else if (InputService.isPhysicalKeyPressed(Key.shift)) {
            offset.x = direction.x * velocity * deltaTime * boostSpeedMultiplier;
            offset.y = direction.y * velocity * deltaTime * boostSpeedMultiplier;
            offset.z = direction.z * velocity * deltaTime * boostSpeedMultiplier;
        }
        else if (velocity != null) {
            offset.x = direction.x * velocity * deltaTime;
            offset.y = direction.y * velocity * deltaTime;
            offset.z = direction.z * velocity * deltaTime;
        }

        transform.translate(offset);

        if (InputService.isPhysicalKeyPressed(Key.shift) && InputService.isKeyPressed(Key.r))
            reset();
        if (InputService.isJoyButtonPressed(0, JoyButton.start))
            reset();
    }

    public inline function reset() {
        transform.globalPosition = initialPosition;
        transform.globalRotation = initialRotation;
    }

    public inline function getAxis(bool1: Bool, bool2: Bool) : Float {
        var float1: Float = bool1 ? 1.0 : 0.0;
        var float2: Float = bool2 ? 1.0 : 0.0;
        return float1 - float2;
    }

    public inline function getCombinedAxis(axis1: Float, axis2: Float) : Float {
        return axis1 - axis2;
    }

    inline function Clamp<T:Float>(value:T, min:T, max:T):T {
        return if (value < min) min else if (value > max) max else value;
    }
}