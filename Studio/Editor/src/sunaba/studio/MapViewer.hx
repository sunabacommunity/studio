package sunaba.studio;

import sunaba.core.Color;
import sunaba.core.Vector2i;
import sunaba.studio.debugDraw.DebugDrawService3D;
import haxe.Json;
import sunaba.input.InputService;
import sunaba.input.InputEvent;
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
import sunaba.Key;

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
    var editButton: Button;

    public override function editorInit() {
        load("studio://MapViewer.suml");

        viewport = getNodeT(SubViewport, "vbox/container/viewport");

        reloadButton = getNodeT(Button, "vbox/toolbar/hbox/reload");
        reloadButton.pressed.add(() -> {
            buildMap();
        });
        editButton = getNodeT(Button, "vbox/toolbar/hbox/edit");
        editButton.pressed.add(() -> {
            getEditor().openTrenchbroom(io.getFilePath(filePath));
        });

        throbberParent = getNodeT(Control, "vbox/toolbar/hbox/throbber");
        throbberRect = getNodeT(TextureRect, "vbox/toolbar/hbox/throbber/textureRect");

        var throbberPath = "studio://throbber-animated";

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
        for (txtPath in throbberTxtList) {
            var txtBytes = io.loadBytes(txtPath);
            var image = new Image();
            image.loadPngFromBuffer(txtBytes);
            var imageTexture =  ImageTexture.createFromImage(image);
            throbberTextures.push(imageTexture);
            throbberMaxNumber++;
        }

        var texture = throbberTextures[0];
        if (texture != null && texture.isObjectValid()) {
            throbberRect.texture = texture;
        }
    }

    public var mapBuildCoroutine: Coroutine<()->Void> = null;

    public function openMap(path: String) {
        filePath = path;

        var name: String = path.split("/").pop();
        getEditor().setWorkspaceTabTitle(this, name);
        sceneName = name;
        
        buildMap();

        initializeEditorScene();
    }

    public function buildMap() {
        if (scene != null) {
            scene.destroy();
        }

        var texturepathsFilepath = getEditor().projectIo.pathUrl + ".texturepaths.json";
        var texturepaths: Array<String> = [];
        if (io.fileExists(texturepathsFilepath)) {
            var texturepathsJson = io.loadText(texturepathsFilepath);
            texturepaths = Json.parse(texturepathsJson);
        }

        var mapFile = new MapFile(filePath);
        for (texturepath in texturepaths) {
            mapFile.textureDirs.push(texturepath);
        }
        scene = mapFile.instantiate();
        scene.isInEditor = true;
        scene.processMode = CanvasItemProcessMode.disabled;
        viewport.addChild(scene);
        /*mapBuildCoroutine = Coroutine.create(() -> {
            mapFile.isRunningInCoroutine = true;
            
            Coroutine.yield();
            setMbcNull();
        });
        Coroutine.resume(mapBuildCoroutine);*/
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

            if (throbberTextures[lastThrobberIndex] != null && throbberTextures[lastThrobberIndex].isObjectValid())
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

        var scopeConfig = DebugDrawService3D.newScopedConfig().setViewport(viewport).setThickness(0.015);

        var tg = largeGridTransform.globalTransform;
        var tn = largeGridTransform.transform.origin;
        DebugDrawService3D.drawGrid(tg.origin, tg.basis.x, tg.basis.z, new Vector2i(250, 250), Color.rgba(0.5, 0.5, 0.5, 1), true);

        scopeConfig = scopeConfig.setThickness(0.005);
        DebugDrawService3D.drawGrid(tg.origin, tg.basis.x, tg.basis.z, new Vector2i(1000, 1000), Color.rgba(0.5, 0.5, 0.5, 1), true);

        scopeConfig = scopeConfig.setThickness(0.030);
        DebugDrawService3D.drawLine(new Vector3(1000, 0.025, 0), new Vector3(-1000, 0.025, 0), Color.rgba(1, 0, 0, 1));
        DebugDrawService3D.drawLine(new Vector3(0, 0.025, 1000), new Vector3(0, 0.025, -1000), Color.rgba(0, 0, 1, 1));
        DebugDrawService3D.drawLine(new Vector3(0, -1000, 0), new Vector3(0, 1000, 0), Color.rgba(0, 1, 0, 1));

        scopeConfig = null;

        Gc.collect();
    }

    var isReloadKeyPressed: Bool = false;

    public override function onInput(event:InputEvent) {
        if (getEditor().isControlKeyPressed() && InputService.isKeyPressed(Key.r)) {
            if (!isReloadKeyPressed) {
                isReloadKeyPressed = true;
                buildMap();
            } 
        }
        else {
            isReloadKeyPressed = false;
        }
    }
}


