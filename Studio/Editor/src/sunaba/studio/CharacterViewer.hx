package sunaba.studio;
import sunaba.spatial.SpatialTransform;
import sunaba.core.Vector3;
import sunaba.spatial.SpringArm;
import sunaba.spatial.CharacterLoader;
import sunaba.spatial.MapFile;
import sunaba.spatial.Camera;

class CharacterViewer extends EditorWidget {
    private var filePath: String;

    public var editorScene: SceneRoot;

    public var viewport: SubViewport;

    public var panLook: Entity = null;

    public var characterLoader: CharacterLoader;

    var camera: Camera = null;

    public override function editorInit() {
        load("studio://CharacterViewer.suml");

        viewport = getNodeT(SubViewport, "vbox/container/viewport");

        var mapFile = new MapFile("studio://scenes/CharacterViewer.map");
        var scene = mapFile.instantiate();
        viewport.addChild(scene);
    }

    public function openCharacter(path: String) {
        filePath = path;

        initializeEditorScene();
        trace("");
    }

    var characterEntity: Entity;

    private function initializeEditorScene() {
        editorScene = new SceneRoot();
        editorScene.name = "EditorScene";

        var panLookEntity = new Entity();
        panLookEntity.name = "PanLook";
        var panLookTransform = panLookEntity.addComponent(SpatialTransform);
        editorScene.addEntity(panLookEntity);
        panLookTransform.globalPosition = new Vector3(0, 0.787, 0);
        var springArm = panLookEntity.addComponent(SpringArm);
        springArm.springLength = 1.5;
        var panLookComponent = panLookEntity.addComponent(PanLook);
        panLook = panLookEntity;

        viewport.addChild(editorScene);
        panLookComponent.transform = panLookTransform;

        var cameraEntity = new Entity();
        cameraEntity.name = "EditorCamera";
        var cameraTransform = cameraEntity.addComponent(SpatialTransform);
        panLookEntity.addChild(cameraEntity);
        camera = cameraEntity.addComponent(Camera);
        camera.current = true;

        characterEntity = new Entity();
        characterEntity.name = "Character";
        characterEntity.addComponent(SpatialTransform);
        characterLoader = characterEntity.addComponent(CharacterLoader);
        characterLoader.path = filePath;
        editorScene.addEntity(characterEntity);
    }

    public override function onProcess(deltaTime: Float) {
        var characterEditor = getEditor().characterEditor;
        if (visible) {
            if (characterEditor.characterViewer != this) {
                characterEditor.openCharacterViewer(this);
                getEditor().setCurrentDockChlid(characterEditor);
            }
        }
    }
}