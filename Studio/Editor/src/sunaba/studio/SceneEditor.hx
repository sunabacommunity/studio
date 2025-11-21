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
import sunaba.core.Dictionary;
import sunaba.studio.debugDraw.DebugDrawService3D;
import sunaba.core.Vector2i;
import sunaba.core.Color;

class SceneEditor extends EditorWidget {
    private var filePath: String;

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
    public var prefab: Entity;
    public var editorScene: SceneRoot;

    public var savedSceneJson: String;

    var sceneName: String = "";

    var largeGridTransform: SpatialTransform;
    var smallGridTransform: SpatialTransform;

    public override function editorInit() {
        load("studio://SceneEditor.suml");

        selectButton = getNodeT(Button, "vbox/toolbar/hbox/select");
        moveButton = getNodeT(Button, "vbox/toolbar/hbox/move");
        rotateButton = getNodeT(Button, "vbox/toolbar/hbox/rotate");
        scaleButton = getNodeT(Button, "vbox/toolbar/hbox/scale");

        viewport = getNodeT(SubViewport, "vbox/container/viewport");
    }

    public function openScene(path: String) {
        fileType = FileType.SceneType;
        filePath = path;

        var name: String = path.split("/").pop();
        getEditor().setWorkspaceTabTitle(this, name);
        sceneName = name;

        var sceneJson = io.loadText(path);
        var sceneData = JSON.parseString(sceneJson);
        sceneJson = JSON.stringify(sceneData);
        savedSceneJson = sceneJson;
        savedSceneJsonInitialized = true;

        var sceneFile = new SceneFile();
        sceneFile.io = getEditor().projectIo;
        sceneFile.load(path);
        Sys.println(sceneFile.getData());


        scene = sceneFile.instance();
        trace(scene.getEntityCount());
        scene.processMode = CanvasItemProcessMode.disabled;
        processMode = CanvasItemProcessMode.always;
        viewport.addChild(scene);

        var envRes = ResourceLoaderService.load("res://Engine/Environments/new_environment.tres");
        var environment = new Environment(envRes.native);
        var worldEnv = new Node(new NativeObject("WorldEnvironment"));
        worldEnv.native.set("environment", environment.native);
        viewport.addChild(worldEnv);
        initializeEditorScene();
        checkScene();
        intializeCameraList();
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

        var largeGridEntity = new Entity();
        largeGridEntity.name = "LargeGrid";
        largeGridTransform = largeGridEntity.addComponent(SpatialTransform);
        editorScene.addEntity(largeGridEntity);
        largeGridTransform.scale = new Vector3(1000, 1, 1000);

        var smallGridEntity = new Entity();
        smallGridEntity.name = "LargeGrid";
        smallGridTransform = smallGridEntity.addComponent(SpatialTransform);
        editorScene.addEntity(smallGridEntity);
        smallGridTransform.scale = new Vector3(10, 1, 10);
    }

    public var cameraList: Array<Camera>;

    public function intializeCameraList(): Void {
        cameraList = [];
        if (scene != null) {
            for (i in 0...scene.getEntityCount()) {
                var entity = scene.getEntity(i);
                checkCamera(entity);
            }
        }
    }

    private function checkCamera(entity: Entity) {
        if (entity.getComponent(Camera) != null) {
            cameraList.push(entity.getComponent(Camera));
        }
        for (i in 0...entity.getChildCount()) {
            var child = entity.getChild(i);
            checkCamera(child);
        }
    }

    public override function onProcess(deltaTime: Float) {
        if (camera == null) return;

        camera.current = true;
        freeLook3d.active = visible;

        if (visible) {
            var sceneInspector = getEditor().sceneInspector;
            if (sceneInspector.sceneEditor != this) {
                sceneInspector.openSceneEditor(this);
            }
        }

        var scopeConfig = DebugDrawService3D.newScopedConfig().setViewport(viewport).setThickness(0.015);

        var tg = largeGridTransform.globalTransform;
        var tn = largeGridTransform.transform.origin;
        DebugDrawService3D.drawGrid(tg.origin, tg.basis.x, tg.basis.z, new Vector2i(250, 250), Color.rgba(0.5, 0.5, 0.5, 1), true);
        for (camera in cameraList) {
            DebugDrawService3D.drawCameraFrustum(camera, Color.rgba(1, 1, 0, 1));
        }

        scopeConfig = scopeConfig.setThickness(0.005);
        DebugDrawService3D.drawGrid(tg.origin, tg.basis.x, tg.basis.z, new Vector2i(1000, 1000), Color.rgba(0.5, 0.5, 0.5, 1), true);

        scopeConfig = scopeConfig.setThickness(0.030);
        DebugDrawService3D.drawLine(new Vector3(1000, 0.025, 0), new Vector3(-1000, 0.025, 0), Color.rgba(1, 0, 0, 1));
        DebugDrawService3D.drawLine(new Vector3(0, 0.025, 1000), new Vector3(0, 0.025, -1000), Color.rgba(0, 0, 1, 1));
        DebugDrawService3D.drawLine(new Vector3(0, -1000, 0), new Vector3(0, 1000, 0), Color.rgba(0, 1, 0, 1));

        scopeConfig = null;

        trace("");
        Gc.collect();
    }

    private var savedSceneJsonInitialized: Bool = false;

    public function checkScene() {
        getEditor().setWorkspaceTabTitle(this, sceneName);
        if (fileType == FileType.SceneType) {
            var sceneFile = SceneFile.create(scene);
            var sceneData = sceneFile.getData();
            var sceneJson = JSON.stringify(sceneData);
            if (!savedSceneJsonInitialized) {
                savedSceneJson = sceneJson;
                savedSceneJsonInitialized = true;
                return;
            }
            if (savedSceneJson != sceneJson) {
                getEditor().setWorkspaceTabTitle(this, sceneName + "*");
            }
            else {
                getEditor().setWorkspaceTabTitle(this, sceneName);
            }
        }
    }

    public override function onSave() {
        var sceneFile = SceneFile.create(scene);
        var sceneData = sceneFile.getData();
        var sceneJson = JSON.stringify(sceneData);
        if (savedSceneJson == sceneJson) return;
        savedSceneJson = sceneJson;
        sceneFile.save(filePath);
        checkScene();
    }

    public override function onDestroy() {
        var sceneInspector = getEditor().sceneInspector;
        if (sceneInspector.sceneEditor == this) {
            sceneInspector.openSceneEditor(null);
        }
    }
}