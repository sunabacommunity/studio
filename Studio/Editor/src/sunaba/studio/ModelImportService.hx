package sunaba.studio;

import sunaba.io.DataFileType;
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

        if (!StringTools.endsWith(destPath, ".smdl"))
            destPath += ".smdl";

        var destPathArray = destPath.split("\\").join("/").split("/");
        var modelName = destPathArray[destPathArray.length].split(".")[0];
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

            var rootEntity: Entity = null;
            if (rootNodes.size() > 1) {
                rootEntity = new Entity();
                rootEntity.name = modelName;
                rootEntity.addComponent(SpatialTransform);
            }
            for (i in 0...rootNodes.size()) {
                var nodeIdx = rootNodes.get(i);
                var node = new GLTFNode(nodes.get(nodeIdx));

                var entity = createEntity(modelDocument, modelState, node);
                if (rootEntity != null) {
                    rootEntity.addChild(entity);
                }
                else {
                    scene.addEntity(entity);
                    rootEntity = entity;
                }
            }

            if (rootEntity != null) {
                var prefab = Prefab.create(rootEntity, destPath);
                prefab.save(DataFileType.msgPack);
            }
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
        entity.name = node.originalName;
        var transform = entity.addComponent(SpatialTransform);
        transform.position = node.position;
        transform.quaternion = node.rotation;
        transform.scale = node.scale;

        if (node.camera != -1) {
            var cameras = state.getCameras();
            var modelCamera: GLTFCamera = new GLTFCamera(cameras.get(node.camera));
            var camera = entity.addComponent(Camera);
            camera.node = modelCamera.toNode();
        }
        
        var children = node.children.toArray();
        var nodes = state.getNodes();
        for (childIdx in children) {
            var childNode = new GLTFNode(nodes.get(childIdx));
            var child = createEntity(document, state, childNode);
            entity.addChild(child);
        }

        return entity;
    }
}