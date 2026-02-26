package sunaba.studio;

import haxe.io.Input;
import sunaba.input.InputService;
import sunaba.input.InputEvent;
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
import sunaba.core.Callable;
import sunaba.Prefab;
import sunaba.UndoRedo;
import sunaba.VariantHolder;

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

    public var gizmo: Gizmo3D;

    public var undoRedo: UndoRedo;
    private var valueHolder: VariantHolder;

    private var _gizmoMode: GizmoToolMode = GizmoToolMode.all;
    public var gizmoMode(get, set): GizmoToolMode;
    function get_gizmoMode():GizmoToolMode {
        return _gizmoMode;
    }
    function set_gizmoMode(value:GizmoToolMode):GizmoToolMode {
        if (gizmo != null) {
            gizmo.mode = value;
        }
        return this._gizmoMode = value;
    }

    public override function editorInit() {
        load("studio://SceneEditor.suml");
        undoRedo = new UndoRedo();
        valueHolder = new VariantHolder();

        selectButton = getNodeT(Button, "vbox/toolbar/hbox/select");
        selectButton.pressed.connect(Callable.fromFunction(function() {
            gizmoMode = GizmoToolMode.all;
        }));
        moveButton = getNodeT(Button, "vbox/toolbar/hbox/move");
        moveButton.pressed.connect(Callable.fromFunction(function() {
            gizmoMode = GizmoToolMode.move;
        }));
        rotateButton = getNodeT(Button, "vbox/toolbar/hbox/rotate");
        rotateButton.pressed.connect(Callable.fromFunction(function() {
            gizmoMode = GizmoToolMode.rotate;
        }));
        scaleButton = getNodeT(Button, "vbox/toolbar/hbox/scale");
        scaleButton.pressed.connect(Callable.fromFunction(function() {
            gizmoMode = GizmoToolMode.scale;
        }));

        translateSpinBox = getNodeT(SpinBox, "vbox/toolbar2/hbox/translateSpinBox");
        translateSpinBox.valueChanged.connect(Callable.fromFunction(function(value: Float) {
            if (gizmo != null) {
                gizmo.translateSnap = value;
            }
        }));
        rotateSpinBox = getNodeT(SpinBox, "vbox/toolbar2/hbox/rotateSpinBox");
        rotateSpinBox.valueChanged.connect(Callable.fromFunction(function(value: Float) {
            if (gizmo != null) {
                gizmo.rotateSnap = value;
            }
        }));
        scaleSpinBox = getNodeT(SpinBox, "vbox/toolbar2/hbox/scaleSpinBox");
        scaleSpinBox.valueChanged.connect(Callable.fromFunction(function(value: Float) {
            if (gizmo != null) {
                gizmo.scaleSnap = value;
            }
        }));

        viewport = getNodeT(SubViewport, "vbox/container/viewport");
    }

    public function openScene(path: String) {
        fileType = FileType.SceneType;
        filePath = path;

        var name: String = path.split("/").pop();
        getEditor().setWorkspaceTabTitle(this, name);
        sceneName = name;

        var sceneJson = "";
        var sceneData = io.loadData(path);
        sceneJson = JSON.stringify(sceneData);
        savedSceneJson = sceneJson;
        savedSceneJsonInitialized = true;

        var sceneFile = new SceneFile();
        sceneFile.io = getEditor().projectIo;
        sceneFile.load(path);


        scene = sceneFile.instance();
        scene.isInEditor = true;
        trace(scene.getEntityCount());
        scene.processMode = CanvasItemProcessMode.disabled;
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
        fileType = FileType.PrefabType;
        filePath = path;

        var name: String = path.split("/").pop();
        getEditor().setWorkspaceTabTitle(this, name);
        sceneName = name;

        var sceneJson = "";
        var sceneData = io.loadData(path);
        sceneJson = JSON.stringify(sceneData);
        savedSceneJson = sceneJson;
        savedSceneJsonInitialized = true;

        var prefabFile = new Prefab();
        prefabFile.io = getEditor().projectIo;
        prefabFile.load(path);

        scene = new SceneRoot();
        scene.isInEditor = true;
        scene.io = getEditor().projectIo;
        scene.processMode = CanvasItemProcessMode.disabled;
        prefab = prefabFile.instance();
        scene.addEntity(prefab);
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

        var gizmoEntity = new Entity();
        gizmoEntity.name = "EditorGizmo";
        var gizmoTransform = gizmoEntity.addComponent(SpatialTransform);
        editorScene.addEntity(gizmoEntity);
        gizmo = gizmoEntity.addComponent(Gizmo3D);

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

        gizmoMode = GizmoToolMode.all;
        gizmo.transformChanged.connect(Callable.fromFunction(function(mode: Int, value: Vector3) {
            var sceneInspector = getEditor().sceneInspector;
            if (sceneInspector.sceneEditor == this) {
                sceneInspector.refreshInspector();
                checkScene();
            }
        }));
        translateSpinBox.value = gizmo.translateSnap;
        rotateSpinBox.value = gizmo.rotateSnap;
        scaleSpinBox.value = gizmo.scaleSnap;
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
                getEditor().setCurrentRightSidebarChild(sceneInspector);
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

        Gc.collect();
    }

    public override function onInput(event:InputEvent) {
        if (visible) {
            if (getEditor().isControlKeyPressed()) {
                if (InputService.isKeyPressed(Key.z)) {
                    if (InputService.isKeyPressed(Key.shift)) {
                        onRedo();
                    }
                    else {
                        onUndo();
                    }
                }
            }
            
        }
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
        else if (fileType == FileType.PrefabType) {
            var prefabFile = Prefab.create(prefab, filePath);
            var prefabData = prefabFile.getData();
            var prefabJson = JSON.stringify(prefabData);
            if (!savedSceneJsonInitialized) {
                savedSceneJson = prefabJson;
                savedSceneJsonInitialized = true;
                return;
            }
            if (savedSceneJson != prefabJson) {
                getEditor().setWorkspaceTabTitle(this, sceneName + "*");
            }
            else {
                getEditor().setWorkspaceTabTitle(this, sceneName);
            }
        }
    }

    public override function onSave() {
        if (fileType == FileType.SceneType) {
            var sceneFile = SceneFile.create(scene);
            var sceneData = sceneFile.getData();
            var sceneJson = JSON.stringify(sceneData);
            if (savedSceneJson == sceneJson) return;
            savedSceneJson = sceneJson;
            sceneFile.save(filePath);
            checkScene();
        }
        else if (fileType == FileType.PrefabType) {
            var prefabFile = Prefab.create(prefab, filePath);
            var prefabData = prefabFile.getData();
            var prefabJson = JSON.stringify(prefabData);
            if (savedSceneJson == prefabJson) return;
            savedSceneJson = prefabJson;
            prefabFile.save(filePath);
            checkScene();
        }
    }

    public function commitChange() {
        undoRedo.createAction("");
        var value: Dictionary = valueHolder.value;
        if (fileType == FileType.SceneType) {
            var sceneFile = SceneFile.create(scene);
            var sceneData = sceneFile.getData();
            undoRedo.addDoProperty(valueHolder, "value", sceneData);
        }
        else if (fileType == FileType.PrefabType) {
            var prefabFile = Prefab.create(prefab, filePath);
            var prefabData = prefabFile.getData();
            undoRedo.addDoProperty(valueHolder, "value", prefabData);
        }
        undoRedo.addUndoProperty(valueHolder, "value", value);
        undoRedo.commitAction();
    }

    public override function onUndo() {
        undoRedo.undo();
        reloadSceneFromValue();
    }

    public override function onRedo() {
        undoRedo.redo();
        reloadSceneFromValue();
    }

    private inline function reloadSceneFromValue() {
        var data: Dictionary = valueHolder.value;
        scene.destroy();
        if (fileType == FileType.SceneType) {
            var sceneFile = new SceneFile();
            sceneFile.setData(data);
            sceneFile.path = filePath;
            scene = sceneFile.instance();
            scene.isInEditor = true;
            trace(scene.getEntityCount());
            scene.processMode = CanvasItemProcessMode.disabled;
            viewport.addChild(scene);
        }
        else if (fileType == FileType.PrefabType) {
            var prefabFile = new Prefab();
            prefabFile.setData(data);
            prefabFile.path = filePath;
            scene = new SceneRoot();
            scene.isInEditor = true;
            scene.io = getEditor().projectIo;
            scene.processMode = CanvasItemProcessMode.disabled;
            prefab = prefabFile.instance();
            scene.addEntity(prefab);
            viewport.addChild(scene);
        }

        intializeCameraList();
        checkScene();
        if (visible) {
            getEditor().sceneInspector.openSceneEditor(this);
        }
        gizmo.clear();
    }

    public override function onDestroy() {
        undoRedo.free();
        valueHolder.free();
        var sceneInspector = getEditor().sceneInspector;
        if (sceneInspector.sceneEditor == this) {
            sceneInspector.openSceneEditor(null);
        }
    }
}