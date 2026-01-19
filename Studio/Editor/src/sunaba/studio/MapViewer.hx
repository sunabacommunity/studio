package sunaba.studio;

import lua.Coroutine;
import haxe.macro.Expr.Catch;
import sunaba.spatial.MapFile;
import sunaba.core.native.NativeObject;
import sunaba.spatial.Camera;
import sunaba.studio.sceneEditor.FreeLook3D;
import sunaba.spatial.SpatialTransform;
import sunaba.core.Vector3;

class MapViewer extends EditorWidget {
    private var filePath: String;

    public var viewport: SubViewport;

    public var scene: SceneRoot;
    public var editorScene: SceneRoot;

    var sceneName: String = "";

    public override function editorInit() {
        load("studio://MapViewer.suml");

        viewport = getNodeT(SubViewport, "vbox/container/viewport");
    }

    public var mapBuildCoroutine: Coroutine<()->Void> = null;

    public function openMap(path: String) {
        filePath = path;

        var name: String = path.split("/").pop();
        getEditor().setWorkspaceTabTitle(this, name);
        sceneName = name;
        
        buildMap();

        try {
            var envRes = ResourceLoaderService.load("res://Engine/Environments/new_environment.tres");
            var environment = new Environment(envRes.native);
            var worldEnv = new Node(new NativeObject("WorldEnvironment"));
            worldEnv.native.set("environment", environment.native);
            viewport.addChild(worldEnv);

            initializeEditorScene();
        }
        catch(e) {
            trace(e.toString());
        }
    }

    public function buildMap() {
        if (scene != null) {
            scene.destroy();
        }

        var mapFile = new MapFile(filePath);
        mapBuildCoroutine = Coroutine.create(() -> {
            mapFile.isRunningInCoroutine = true;
            scene = mapFile.instantiate();
            Coroutine.yield();
            scene.isInEditor = true;
            Coroutine.yield();
            scene.processMode = CanvasItemProcessMode.disabled;
            Coroutine.yield();
            viewport.addChild(scene);
            Coroutine.yield();
        });
        Coroutine.resume(mapBuildCoroutine);
    }

    public var camera: Camera;
    public var freeLook3d: FreeLook3D;
    var largeGridTransform: SpatialTransform;
    var smallGridTransform: SpatialTransform;

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

    public override function onProcess(delta:Float) {
        if (camera == null) return;

        camera.current = true;
        freeLook3d.active = visible;

        if (mapBuildCoroutine != null) {
            if (Coroutine.status(mapBuildCoroutine) != CoroutineState.Dead) {
                Coroutine.resume(mapBuildCoroutine);
            }
            else {
                mapBuildCoroutine = null;
            }
        }
    }
}


