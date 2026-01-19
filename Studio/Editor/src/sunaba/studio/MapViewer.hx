package sunaba.studio;

import sunaba.ui.Button;
import sunaba.ui.TextureRect;
import sunaba.ui.Control;
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

    var throbberTextures = new Array<ImageTexture>();
    var throbberMaxNumber = 0;

    var throbberParent: Control;
    var throbberRect: TextureRect;

    var reloadButton: Button;

    public override function editorInit() {
        load("studio://MapViewer.suml");

        viewport = getNodeT(SubViewport, "vbox/container/viewport");

        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/reload");
        reloadButton.pressed.add(() -> {
            buildMap();
        });

        throbberParent = getNodeT(Control, "vbox/toolbar/hbox/throbber");
        throbberRect = getNodeT(TextureRect, "vbox/toolbar/hbox/throbber/textureRect");

        var throbberPath = "studio://throbber-animated";

        trace(io.directoryExists(throbberPath));
        trace(io.fileExists(throbberPath + "/icon0.png"));
        var throbberTxtListN = io.getFileList(throbberPath, ".png", false);
        var throbberTxtList = throbberTxtListN.toArray();
        if (OSService.getName() == "macOS") {
            for (i in 0...40) {
                var iconPath = throbberPath + "/icon" + i + ".png";
                if (io.fileExists(iconPath)) {
                    throbberTxtList.push(iconPath);
                } else {
                    trace("Throbber icon not found: " + iconPath);
                    break;
                }
            }
        }
        trace(throbberTxtList.length);
        for (txtPath in throbberTxtList) {
            var txtBytes = io.loadBytes(txtPath);
            var image = new Image();
            image.loadPngFromBuffer(txtBytes);
            var imageTexture =  ImageTexture.createFromImage(image);
            throbberTextures.push(imageTexture);
            throbberMaxNumber++;
        }

        var texture = throbberTextures[0];
        throbberRect.texture = texture;
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
            setMbcNull();
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

    public function setMbcNull() {
        mapBuildCoroutine = null;
    }

    var lastThrobberIndex = 0;

    var timeAccumulator = 1.0;
    var milisec = 0.05;

    public override function onProcess(deltaTime:Float) {
        if (camera == null) return;

        camera.current = true;
        freeLook3d.active = visible;

        timeAccumulator += deltaTime;
        if (timeAccumulator >= milisec) {
            timeAccumulator -= milisec;

            throbberRect.texture = throbberTextures[lastThrobberIndex];
            if (lastThrobberIndex == throbberMaxNumber - 1) {
                lastThrobberIndex = 0;
            }
            else {
                lastThrobberIndex++;
            }
        }

        if (mapBuildCoroutine != null) {
            if (Coroutine.status(mapBuildCoroutine) != CoroutineState.Dead) {
                throbberParent.show();
                Coroutine.resume(mapBuildCoroutine);
            }
            else {
                throbberParent.hide();
                mapBuildCoroutine = null;
            }
        }
        else {
            throbberParent.hide();
        }
    }
}


