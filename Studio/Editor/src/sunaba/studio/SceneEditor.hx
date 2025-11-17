package sunaba.studio;

import sunaba.ui.SpinBox;
import sunaba.SubViewport;
import sunaba.ui.Button;
import sunaba.studio.sceneEditor.FileType;
import sunaba.SceneFile;
import sunaba.SceneRoot;
import sunaba.core.native.NativeObject;
import sunaba.spatial.SpatialTransform;
import sunaba.spatial.Camera;
import sunaba.spatial.mesh.BoxMesh;
import sunaba.spatial.mesh.MeshDisplay;
import sunaba.spatial.mesh.PrimitiveMesh;
import sunaba.studio.sceneEditor.FreeLook3D;
import sunaba.core.Vector3;

class SceneEditor extends EditorWidget {

    public var selectButton: Button;
    public var moveButton: Button;
    public var rotateButton: Button;
    public var scaleButton: Button;

    public var translateSpinBox: SpinBox;
    public var rotateSpinBox: SpinBox;
    public var scaleSpinBox: SpinBox;

    public var viewport: SubViewport;

    public var fileType: FileType;

    public var scene: SceneRoot;
    public var editorScene: SceneRoot;

    public override function init() {
        load("studio://SceneEditor.suml");

        selectButton = getNodeT(Button, "vbox/toolbar/hbox/select");
        moveButton = getNodeT(Button, "vbox/toolbar/hbox/move");
        rotateButton = getNodeT(Button, "vbox/toolbar/hbox/rotate");
        scaleButton = getNodeT(Button, "vbox/toolbar/hbox/scale");

        viewport = getNodeT(SubViewport, "vbox/container/viewport");
    }

    public function openScene(path: String) {
        fileType = FileType.SceneType;

        var sceneFile = new SceneFile();
        sceneFile.io = getEditor().projectIo;
        sceneFile.load(path);
        Sys.println(sceneFile.getData());

        scene = sceneFile.instance();
        trace(scene.getEntityCount());
        scene.processMode = CanvasItemProcessMode.disabled;
        viewport.addChild(scene);

        var envRes = ResourceLoaderService.load("res://Engine/Environments/new_environment.tres");
        var environment = new Environment(envRes.native);
        var worldEnv = new Node(new NativeObject("WorldEnvironment"));
        worldEnv.native.set("environment", environment.native);
        viewport.addChild(worldEnv);
        initializeEditorScene();
    }

    public function openPrefab(path: String) {

    }

    public var camera: Camera;
    public var freeLook3d: FreeLook3D;

    public function initializeEditorScene() {
        editorScene = new SceneRoot();
        editorScene.name = "EditorScene";

        var cameraEntity = new Entity();
        cameraEntity.name = "EditorCamera";
        var cameraTransform = cameraEntity.addComponent(SpatialTransform);
        editorScene.addEntity(cameraEntity);
        cameraTransform.position = new Vector3(4, 4, 4);
        cameraTransform.rotation = new Vector3(30.8, -30.8, 0);
        camera = cameraEntity.addComponent(Camera);
        camera.current = true;
        freeLook3d = cameraEntity.addComponent(FreeLook3D);

        viewport.addChild(editorScene);
        freeLook3d.onStart();
        freeLook3d.transform = cameraTransform;
    }

    public override function onProcess(deltaTime: Float) {
        if (camera == null) return;

        camera.current = true;
        freeLook3d.active = visible;
    }
}