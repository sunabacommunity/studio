package sunaba.studio;

import sunaba.spatial.Skeleton;
import sunaba.spatial.Skin;
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
import sunaba.core.VariantType;

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

            var gdscene = modelDocument.generateScene(modelState);
            yeild();
            

            var scene = new SceneRoot();
            var nodes = modelState.getNodes();
            var rootNodes = modelState.rootNodes;
            yeild();

            var rootEntity: Entity = createEntity(modelDocument, modelState, gdscene);
            yeild();
            
            yeild();
            if (modelState.createAnimations == true) {
                yeild();
                var animationPlayer = rootEntity.addComponent(AnimationPlayer);
                yeild();
                importAnimations(modelDocument, modelState, animationPlayer, gdscene);
                yeild();
            }
            yeild();

            var prefab = Prefab.create(rootEntity, destPath);
            yeild();
            var fileType = DataFileType.json;
            yeild();
            if (binaryFile == true) {
                yeild();
                fileType = DataFileType.msgPack;
                yeild();
            }
            yeild();
            prefab.save(null, fileType);
            yeild();

            scene.destroy();
            yeild();
            gdscene.queueFree();
            yeild();
        }
    }

    private static inline function importAnimations(document: GLTFDocument, state: GLTFState, animationPlayer: AnimationPlayer, gdscene: Node) {
        var animPlayerNode: Node = null;
        yeild();
        for (i in 0...gdscene.getChildCount()) {
            yeild();
            var node = gdscene.getChild(i);
            yeild();
            if (node.native.isClass("AnimationPlayer")) {
                yeild();
                animPlayerNode = node;
            }
            yeild();
        }
        yeild();
        if (animPlayerNode != null) {
            yeild();
            var animationList : ArrayList = animPlayerNode.native.call("get_animation_list", new ArrayList());
            yeild();
            var modelAnimationLibrary = new AnimationLibrary();
            yeild();
            for (i in 0...animationList.size()) {
                yeild();
                var animationName: String = animationList.get(i);
                yeild();
                var getAnimationArgs : Array<Variant> = [animationName];
                yeild();
                var animation = new Animation(animPlayerNode.native.call("get_animation", getAnimationArgs));
                yeild();
                modelAnimationLibrary.addAnimation(animationName, animation);
                yeild();
            }
            yeild();
            animationPlayer.addAnimationLibrary(state.sceneName, modelAnimationLibrary);
            yeild();
        }
        yeild();
    }

    private static function createEntity(document: GLTFDocument, state: GLTFState, gdnode: Node): Entity {
        if (document == null) {
            throw 'ModelImporter: document could not be found';
            return null;
        }
        if (state == null) {
            throw 'ModelImporter: state could not be found';
            return null;
        }
        if (gdnode == null) {
            throw 'ModelImporter: Node could not be found';
            return null;
        }
        
        var entity = new Entity();
        yeild();
        entity.name = gdnode.name;
        yeild();
        var transform = entity.addComponent(SpatialTransform);
        yeild();
        if (!gdnode.getParent().isNull()) {
            yeild();
            gdnode.getParent().removeChild(gdnode);
            yeild();
        }
        yeild();
        transform.node = gdnode;
        yeild();

        if (gdnode.native.isClass("Camera3D")) {
            yeild();
            var camera = entity.addComponent(Camera);
            yeild();
            camera.node = gdnode;
            yeild();
        }

        if (gdnode.native.isClass("MeshInstance3D")) {
            yeild();
            var node = getGltfNodeFromGodotNode(document, state, gdnode);
            if (node != null) {
                yeild();
                var meshes = state.getMeshes();
                yeild();
                var mesh = new GLTFMesh(meshes.get(node.mesh));
                yeild();

                var meshData = MeshData.fromImporterMesh(mesh.mesh);
                yeild();

                var meshDisplay = entity.addComponent(MeshDisplay);
                yeild();
                meshDisplay.skeleton = gdnode.native.get("skeleton");
                yeild();
                if (gdnode.native.get("skin").getType() == VariantType.object) {
                    yeild();
                    if (gdnode.native.get("skin").toNativeReference().isValid()) {
                        yeild();
                        meshDisplay.skin = new Skin(gdnode.native.get("skin"));
                        yeild();
                    }
                    yeild();
                }
                yeild();

                var meshLoader = entity.addComponent(MeshLoader);
            yeild();
            meshLoader.meshData = meshData;
            yeild();
            }
        }
        yeild();

        if (gdnode.native.getClass() == "DirectionalLight3D") {
            yeild();
            var directionalLight = entity.addComponent(DirectionalLight);
            yeild();
            directionalLight.node.queueFree();
            yeild();
            directionalLight.node = gdnode;
            yeild();
        }
        else if (gdnode.native.getClass() == "OmniLight3D") {
            yeild();
            var omniLight = entity.addComponent(OmniLight);
            yeild();
            omniLight.node.queueFree();
            yeild();
            omniLight.node = gdnode;
            yeild();
        }
        else if (gdnode.native.getClass() == "SpotLight3D") {
            yeild();
            var spotLight = entity.addComponent(SpotLight);
            yeild();
            spotLight.node.queueFree();
            yeild();
            spotLight.node = gdnode;
            yeild();
        }

        if (gdnode.native.isClass("Skeleton3D")) {
            var skeletonComponent = entity.addComponent(Skeleton);
            yeild();
            skeletonComponent.node = gdnode;
            yeild();
            entity.node = gdnode;
            yeild();
        }
        yeild();
         
        yeild();
        for (childIdx in 0...gdnode.getChildCount()) {
            yeild();
            var childNode = gdnode.getChild(childIdx); 
            yeild();
            var child = createEntity(document, state, childNode);
            yeild();
            entity.addChild(child);
            yeild();
        }
        yeild();

        return entity;
    }

    public static function getGltfNodeFromGodotNode(document: GLTFDocument, state: GLTFState, gdnode: Node, node: GLTFNode = null): GLTFNode {
        var nodes = state.getNodes();
        yeild();
        if (node != null) {
            yeild();
            if (node.isNull()) {
                yeild();
                return null;
            }
            yeild();
            if (node.originalName == gdnode.name) {
                yeild();
                return node;
            }
            yeild();
            var children = node.children.toArray();
            yeild();
            for (childIdx in children) {
                yeild();
                trace(childIdx);
                yeild();
                var childNode = new GLTFNode(nodes.get(childIdx));
                yeild();
                if (childNode.isNull()) {
                    yeild();
                    continue;
                }
                yeild();
                var result = getGltfNodeFromGodotNode(document, state, gdnode, childNode);
                yeild();
                if (result != null) {
                    yeild();
                    return result;
                }
                yeild();
            }
            yeild();
        }
        else {
            trace(gdnode.name);
            yeild();
            var rootNodes = state.rootNodes;
            var nodes = state.getNodes();
            if (rootNodes.size() == 0) {
                yeild();
                for (i in 0...nodes.size() + 1) {
                    yeild();
                    var nodeIdx = nodes.get(i);
                    trace(nodeIdx);
                    yeild();
                    if (nodeIdx == null)
                        continue;
                    yeild();
                    var rootNode = new GLTFNode(nodes.get(nodeIdx));
                    yeild();
                    if (rootNode.isNull()) {
                        yeild();
                        continue;
                    }
                    yeild();
                    var result = getGltfNodeFromGodotNode(document, state, gdnode, rootNode);
                    yeild();
                    if (result != null) {
                        yeild();
                        return result;
                    }
                    yeild();
                }
                yeild();
            }
            else {
                yeild();
                for (i in 0...rootNodes.size() + 1) {
                    yeild();
                    var nodeIdx = rootNodes.get(i);
                    trace(nodeIdx);
                    yeild();
                    if (nodeIdx == null)
                        continue;
                    yeild();
                    var rootNode = new GLTFNode(nodes.get(nodeIdx));
                    yeild();
                    if (rootNode.isNull()) {
                        yeild();
                        continue;
                    }
                    yeild();
                    var result = getGltfNodeFromGodotNode(document, state, gdnode, rootNode);
                    yeild();
                    if (result != null) {
                        yeild();
                        return result;
                    }
                    yeild();
                }
                yeild();
                for (i in 0...nodes.size() + 1) {
                    yeild();
                    var nodeIdx = nodes.get(i);
                    trace(nodeIdx);
                    yeild();
                    if (nodeIdx == null)
                        continue;
                    yeild();
                    var rootNode = new GLTFNode(nodes.get(nodeIdx));
                    yeild();
                    if (rootNode.isNull()) {
                        yeild();
                        continue;
                    }
                    yeild();
                    var result = getGltfNodeFromGodotNode(document, state, gdnode, rootNode);
                    yeild();
                    trace(result != null);
                    if (result != null) {
                        yeild();
                        return result;
                    }
                    yeild();
                }
                yeild();
            }
            yeild();
        }
        yeild();
        return null;
    }
}