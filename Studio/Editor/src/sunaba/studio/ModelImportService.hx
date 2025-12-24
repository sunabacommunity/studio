package sunaba.studio;

import sunaba.core.Variant;
import sunaba.animation.AnimationLibrary;
import sunaba.core.ArrayList;
import sunaba.animation.Animation;
import sunaba.spatial.models.gltf.GLTFAnimation;
import sunaba.animation.AnimationPlayer;
import sunaba.spatial.lighting.SpotLight;
import sunaba.spatial.lighting.OmniLight;
import sunaba.spatial.lighting.DirectionalLight;
import sunaba.spatial.models.gltf.GLTFLight;
import sunaba.spatial.mesh.MeshLoader;
import sunaba.spatial.mesh.MeshDisplay;
import sunaba.spatial.mesh.MeshData;
import sunaba.io.DataFileType;
import sunaba.spatial.models.gltf.GLTFMesh;
import sunaba.spatial.models.gltf.GLTFCamera;
import sunaba.spatial.Camera;
import sunaba.spatial.SpatialTransform;
import sunaba.spatial.models.gltf.GLTFNode;
import lua.Coroutine;
import sunaba.core.ByteArray;
import sunaba.spatial.models.gltf.GLTFState;
import sunaba.spatial.models.gltf.GLTFDocument;
import sunaba.spatial.models.fbx.FBXState;
import sunaba.spatial.models.fbx.FBXDocument;
import sunaba.core.native.NativeReference;
import sunaba.io.IoManager;
import sunaba.io.IoInterface;

class ModelImportService {
    public static var isRunningCoroutine: Bool = false;

    private static function yeild() {
       if (isRunningCoroutine == true) {
        Coroutine.yield();
       } 
    }

    public static function inport(srcPath: String, destPath: String, binaryFile: Bool = false, ?io: IoInterface): Void {
        if (io == null) {
            var ioNative: NativeReference = untyped __lua__("_G.__ioManager");
            io = new IoManager(ioNative);
        }

        if (srcPath == null || srcPath == "") {
            return;
        }

        if (!StringTools.endsWith(destPath, ".smdl") && binaryFile == false)
            destPath += ".smdl";
        if (!StringTools.endsWith(destPath, ".smdl.dat") && binaryFile == true) {
            if (StringTools.endsWith(destPath, ".smdl"))
                destPath += ".dat";
            else 
                destPath += ".smdl.dat";
        }

        var destPathArray = destPath.split("\\").join("/").split("/");
        var modelName = destPathArray[destPathArray.length - 1].split(".")[0];
        destPathArray = destPathArray.slice(0, destPathArray.length);
        var destDir = destPathArray.join("/");
        if (!StringTools.endsWith(destDir, "/"))
            destDir += "/";
        

        yeild();

        var isIoPath: Bool = false;
        if (StringTools.endsWith(srcPath, "://"))
            isIoPath = true;

        var modelBuffer: ByteArray = null;
        if (isIoPath)
            modelBuffer = io.loadBytes(srcPath);
        yeild();

        if (StringTools.endsWith(srcPath, ".gltf") && isIoPath) {
            Debug.warn("This is a '.gltf' file, it is recomended to use the '.glb' file format");
        }

        var modelDocument: GLTFDocument = null;
        var modelState: GLTFState = null;
        yeild();

        if (StringTools.endsWith(srcPath, ".glb") || StringTools.endsWith(srcPath, ".gltf")) {
            modelState = new GLTFState();
            modelDocument = new GLTFDocument();
            yeild();

            if (isIoPath && modelBuffer != null) {
                modelDocument.appendFromBuffer(modelBuffer, "", modelState);
            }
            else {
                modelDocument.appendFromFile(srcPath, modelState);
            }
        }
        else if (StringTools.endsWith(srcPath, ".fbx")) {
            modelState = new FBXState();
            modelDocument = new FBXDocument();
            yeild();

            if (isIoPath && modelBuffer != null) {
                modelDocument.appendFromBuffer(modelBuffer, "", modelState);
            }
            else {
                modelDocument.appendFromFile(srcPath, modelState);
            }
        }
        yeild();

        if (modelDocument != null && modelState != null) {
            var imageFormat = modelDocument.imageFormat;
            var fileExtension: String = "";
            if (imageFormat == "PNG") {
                fileExtension = ".png";
            } 
            else if (imageFormat == "JPEG") {
                fileExtension = ".jpg";
            }
            else if (imageFormat == "Lossless WebP" || imageFormat == "Lossy WebP") {
                fileExtension = ".webp";
            }
            var modelTextures = modelState.getTextures();
            var modelImages = modelState.getImages();
            var lossyQuality = modelDocument.lossyQuality;
            yeild();
            if (imageFormat != "None") {
                for (i in 0...modelTextures.size()) {
                    var modelTexture = new ImageTexture(modelTextures.get(i));
                    if (modelTexture.native.isClass("ImageTexture")) {
                        var image = modelTexture.getImage();
                        if (!image.isObjectValid()) {
                            throw "Model import error: image could not be found";
                        }
                        yeild();

                        var textureName = modelName + i + fileExtension;
                        if (i == 0)
                            textureName = modelName + fileExtension;

                        var texturePath = destDir + textureName;

                        modelTexture.native.set("asset_path", texturePath);
                        yeild();

                        if (imageFormat == "PNG") {
                            var png = image.savePngToBuffer();
                            io.saveBytes(texturePath, png);
                        }
                        else if (imageFormat == "JPEG") {
                            var jpeg = image.saveJpgToBuffer(lossyQuality);
                            io.saveBytes(texturePath, jpeg);
                        }
                        else if (imageFormat == "Lossless WebP") {
                            var webp = image.saveWebpToBuffer(false, lossyQuality);
                            io.saveBytes(texturePath, webp);
                        }
                        else if (imageFormat == "Lossy WebP") {
                            var webp = image.saveWebpToBuffer(true, lossyQuality);
                            io.saveBytes(texturePath, webp);
                        }
                    }
                    yeild();
                }
            }
            yeild();
            

            var scene = new SceneRoot();
            var nodes = modelState.getNodes();
            var rootNodes = modelState.rootNodes;
            yeild();

            var rootEntity: Entity = null;
            
            trace("");
            trace(rootNodes.size());
            trace(nodes.size());
            if (rootNodes.size() == 0 && nodes.size() != 0) {
                var node = new GLTFNode(nodes.get(0));
                yeild();

                rootEntity = createEntity(modelDocument, modelState, node);
                yeild();
                scene.addEntity(rootEntity);
            }
            else if (rootNodes.size() > 0) {
                if (rootNodes.size() != 1) {
                    rootEntity = new Entity();
                    rootEntity.name = modelName;
                    rootEntity.addComponent(SpatialTransform);
                    yeild();
                }
                for (i in 0...rootNodes.size() + 1) {
                    var nodeIdx = rootNodes.get(i);
                    if (nodeIdx == null)
                        continue;
                    var node = new GLTFNode(nodes.get(nodeIdx));
                    yeild();

                    var entity = createEntity(modelDocument, modelState, node);
                    yeild();
                    if (rootEntity != null) {
                        rootEntity.addChild(entity);
                        yeild();
                    }
                    else {
                        scene.addEntity(entity);
                        yeild();
                        rootEntity = entity;
                    }
                }
            }
            yeild();

            if (rootEntity != null) {
                if (modelState.createAnimations == true) {
                    var animationPlayer = rootEntity.addComponent(AnimationPlayer);
                    importAnimations(modelDocument, modelState, animationPlayer);
                }

                var prefab = Prefab.create(rootEntity, destPath);
                yeild();
                var fileType = DataFileType.json;
                if (binaryFile == true) {
                    fileType = DataFileType.msgPack;
                }
                prefab.save(null, fileType);
                yeild();
            }

            scene.destroy();
            yeild();
        }
    }

    private static inline function importAnimations(document: GLTFDocument, state: GLTFState, animationPlayer: AnimationPlayer) {
        var gdscene = document.generateScene(state);

        var animPlayerNode: Node = null;
        for (i in 0...gdscene.getChildCount()) {
            var node = gdscene.getChild(i);
            if (node.native.isClass("AnimationPlayer")) {
                animPlayerNode = node;
            }
        }
        if (animPlayerNode != null) {
            var animationList : ArrayList = animPlayerNode.native.call("get_animation_list", new ArrayList());
            var modelAnimationLibrary = new AnimationLibrary();
            for (i in 0...animationList.size()) {
                var animationName: String = animationList.get(i);
                var getAnimationArgs : Array<Variant> = [animationName];
                var animation = new Animation(animPlayerNode.native.call("get_animation", getAnimationArgs));
                modelAnimationLibrary.addAnimation(animationName, animation);
            }
            animationPlayer.addAnimationLibrary(state.sceneName, modelAnimationLibrary);
        }
    }

    private static function createEntity(document: GLTFDocument, state: GLTFState, node: GLTFNode): Entity {
        if (document == null) {
            throw 'ModelImporter: document could not be found';
            return null;
        }
        if (state == null) {
            throw 'ModelImporter: state could not be found';
            return null;
        }
        if (node == null) {
            throw 'ModelImporter: GLTFNode could not be found';
            return null;
        }
        
        var entity = new Entity();
        yeild();
        entity.name = node.originalName;
        yeild();
        var transform = entity.addComponent(SpatialTransform);
        yeild();
        transform.position = node.position;
        yeild();
        transform.quaternion = node.rotation;
        yeild();
        transform.scale = node.scale;
        yeild();

        if (node.camera != -1) {
            var cameras = state.getCameras();
            yeild();
            var modelCamera: GLTFCamera = new GLTFCamera(cameras.get(node.camera));
            yeild();
            var camera = entity.addComponent(Camera);
            yeild();
            camera.node = modelCamera.toNode();
            yeild();
        }

        if (node.mesh  != -1) {
            var meshes = state.getMeshes();
            yeild();
            var mesh = new GLTFMesh(meshes.get(node.mesh));
            yeild();

            var meshData = MeshData.fromImporterMesh(mesh.mesh);
            yeild();

            entity.addComponent(MeshDisplay);
            yeild();

            var meshLoader = entity.addComponent(MeshLoader);
            yeild();
            meshLoader.meshData = meshData;
            yeild();
        }
        yeild();

        if (node.light != -1) {
            var lights = state.getLights();
            yeild();
            var light = new GLTFLight(lights.get(node.light));
            yeild();
            var lightNode = light.toNode();
            yeild();
            if (lightNode.native.getClass() == "DirectionalLight3D") {
                yeild();
                var directionalLight = entity.addComponent(DirectionalLight);
                yeild();
                directionalLight.node = lightNode;
                yeild();
            }
            else if (lightNode.native.getClass() == "OmniLight3D") {
                yeild();
                var omniLight = entity.addComponent(OmniLight);
                yeild();
                omniLight.node = lightNode;
                yeild();
            }
            else if (lightNode.native.getClass() == "SpotLight3D") {
                yeild();
                var spotLight = entity.addComponent(SpotLight);
                yeild();
                spotLight.node = lightNode;
                yeild();
            }
            yeild();
        }
        yeild();
        
        var children = node.children.toArray();
        yeild();
        var nodes = state.getNodes();
        yeild();
        for (childIdx in children) {
            var childNode = new GLTFNode(nodes.get(childIdx));
            yeild();
            var child = createEntity(document, state, childNode);
            yeild();
            entity.addChild(child);
            yeild();
        }
        yeild();

        return entity;
    }
}