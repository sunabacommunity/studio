package sunaba.studio.sceneEditor;

import sunaba.spatial.CharacterBoneMapper;
import sunaba.spatial.BoneAttachment;
import sunaba.spatial.Skeleton;
import sunaba.desktop.ConfirmationDialog;
import sunaba.audio.AudioStreamMP3;
import sunaba.audio.AudioStreamWAV;
import sunaba.audio.AudioStreamOggVorbis;
import sunaba.core.AABB;
import sunaba.audio.AudioStream;
import sunaba.io.IoManager;
import sunaba.spatial.mesh.BoxMesh;
import sunaba.spatial.mesh.CapsuleMesh;
import sunaba.spatial.mesh.CylinderMesh;
import sunaba.spatial.mesh.SphereMesh;
import sunaba.spatial.mesh.PlaneMesh;
import sunaba.spatial.mesh.QuadMesh;
import sunaba.spatial.mesh.MeshDisplay;
import sunaba.spatial.Camera;
import sunaba.spatial.lighting.OmniLight;
import sunaba.spatial.lighting.SpotLight;
import sunaba.spatial.lighting.DirectionalLight;
import sunaba.spatial.physics.CharacterBody;
import sunaba.spatial.physics.AnimatableBody;
import sunaba.spatial.physics.RigidBody;
import sunaba.spatial.physics.StaticBody;
import sunaba.spatial.physics.BoxShape;
import sunaba.spatial.physics.CapsuleShape;
import sunaba.spatial.physics.CylinderShape;
import sunaba.spatial.physics.SphereShape;
import sunaba.audio.AudioSource;
import sunaba.ui.VSplitContainer;
import sunaba.SizeFlags;
import sunaba.core.Vector2i;
import sunaba.core.Vector2;
import sunaba.ui.Button;
import sunaba.ui.MenuButton;
import sunaba.ui.Tree;
import sunaba.ui.TextureRect;
import sunaba.ui.Label;
import sunaba.ui.VBoxContainer;
import sunaba.ui.TreeItem;
import sunaba.ui.ScrollContainer;
import sunaba.core.Callable;
import sunaba.ui.FoldableContainer;
import sunaba.ui.HBoxContainer;
import sunaba.core.VariantType;
import sunaba.ui.LineEdit;
import sunaba.ui.SpinBox;
import sunaba.ui.CheckButton;
import haxe.Int64;
import sunaba.core.Dictionary;
import sunaba.core.Vector3;
import sunaba.core.Variant;
import sunaba.core.Vector4;
import sunaba.core.Vector3i;
import sunaba.core.Vector4i;
import sunaba.ui.CenterContainer;
import sunaba.spatial.SpatialTransform;
import sunaba.desktop.FileDialog;
import String;
import sunaba.desktop.AcceptDialog;

class SceneInspector extends EditorWidget {
    public var loadButton: Button;
    public var deleteButton: Button;
    public var createButton: Button;

    public var sceneTree: Tree;

    public var entityIcon : TextureRect;
    public var entityText: Label;
    public var entityMenuButton: MenuButton;
    public var entityPrefabButton: Button;
    public var entityVBox: VBoxContainer;

    var sceneIcon: Texture2D;
    var prefabIcon: Texture2D;
    var entityIcon16: Texture2D;

    var sceneIcon24: Texture2D;
    var prefabIcon24: Texture2D;
    var entityIcon24: Texture2D;
    var nothingEntityIcon24: Texture2D;
    var nothingEntityText: String;

    public var nothingSelected: Bool = true;

    public var mode: FileType;
    public var scene: SceneRoot;
    public var prefab: Entity;
    public var selectedEntity: Entity = null;
    public var selectedEntityIndex = -1;

    public var sceneEditor: SceneEditor = null;

    public var maxEntityIndex: Int = 0;
    public var entityIndex: Map<Int, Entity>;

    public var addEntityDialog: AcceptDialog;
    public var addEntityDialogTree: Tree;

    public var addComponentDialog: AcceptDialog;
    public var addComponentDialogTree: Tree;

    public override function editorInit() {
        getEditor().setRightSidebarTabTitle(this, "Scene Inspector");

        componentClasses.push(SpatialTransform);
        componentClasses.push(Camera);
        componentClasses.push(MeshDisplay);
        componentClasses.push(BoxMesh);
        componentClasses.push(CapsuleMesh);
        componentClasses.push(CylinderMesh);
        componentClasses.push(SphereMesh);
        componentClasses.push(PlaneMesh);
        componentClasses.push(QuadMesh);
        componentClasses.push(OmniLight);
        componentClasses.push(SpotLight);
        componentClasses.push(DirectionalLight);
        componentClasses.push(CharacterBody);
        componentClasses.push(RigidBody);
        componentClasses.push(StaticBody);
        componentClasses.push(AnimatableBody);
        componentClasses.push(BoxShape);
        componentClasses.push(CapsuleShape);
        componentClasses.push(CylinderShape);
        componentClasses.push(SphereShape);
        componentClasses.push(AudioSource);
        componentClasses.push(Skeleton);
        componentClasses.push(BoneAttachment);
        componentClasses.push(CharacterBoneMapper);

        var iconBin = io.loadBytes("studio://icons/16_1-5x/clapperboard--pencil.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        getEditor().setRightSiderbarTabIcon(this, texture);
        customMinimumSize = new Vector2(275, 0);

        load("studio://SceneInspector.suml");

        loadButton = getNodeT(Button, "vsplit/outliner/toolbar/hbox/load");
        loadButton.pressed.add(() -> {
            openLoadPrefabDialog();
        });

        deleteButton = getNodeT(Button, "vsplit/outliner/toolbar/hbox/delete");
        deleteButton.pressed.connect(Callable.fromFunction(function() {
            deleteEntity();
        }));
        createButton = getNodeT(Button, "vsplit/outliner/toolbar/hbox/create");
        createButton.pressed.connect(Callable.fromFunction(function() {
            if (sceneEditor == null) return;
            showAddEntityTree();
        }));

        sceneTree = getNodeT(Tree, "vsplit/outliner/tree");

        entityIcon = getNodeT(TextureRect, "vsplit/entityInspector/toolbar/hbox/container/entityIcon");
        entityText = getNodeT(Label, "vsplit/entityInspector/toolbar/hbox/entityText");
        //entityMenuButton = getNodeT(MenuButton, "vsplit/entityInspector/toolbar/hbox/menuButton");
        entityPrefabButton = getNodeT(Button, "vsplit/entityInspector/toolbar/hbox/prefab");
        entityPrefabButton.hide();
        entityPrefabButton.pressed.connect(Callable.fromFunction(()->openSaveAsPrefabDialog()));

        entityVBox = getNodeT(VBoxContainer, "vsplit/entityInspector/scroll/vbox");

        nothingEntityIcon24 = getEditor().explorer.loadIcon("studio://icons/16_1-5x/question.png");
        nothingEntityText = "Nothing Selected";
        trace(nothingEntityText);

        sceneIcon = getEditor().explorer.loadIcon("studio://icons/16/clapperboard.png");
        prefabIcon = getEditor().explorer.loadIcon("studio://icons/16/block.png");
        entityIcon16 = getEditor().explorer.loadIcon("studio://icons/16/layer.png");

        sceneIcon24 = getEditor().explorer.loadIcon("studio://icons/16_1-5x/clapperboard.png");
        prefabIcon24 = getEditor().explorer.loadIcon("studio://icons/16_1-5x/block.png");
        entityIcon24 = getEditor().explorer.loadIcon("studio://icons/16_1-5x/layer.png");

        sceneTree.itemSelected.connect(Callable.fromFunction(function() {
            selectedEntity = entityIndex[selectedEntityIndex];
            if (selectedEntity != null) {
                var transform: SpatialTransform = selectedEntity.getComponent(SpatialTransform);
                if (transform != null) {
                    sceneEditor.gizmo.deselect(transform);
                }
            }
            var selectedItem = sceneTree.getSelected();

            selectedEntityIndex = selectedItem.getMetadata(0);
            refreshInspector();
            selectedEntity = entityIndex[selectedEntityIndex];
            if (selectedEntity != null) {
                var transform: SpatialTransform = selectedEntity.getComponent(SpatialTransform);
                if (transform != null) {
                    sceneEditor.gizmo.select(transform);
                }
            }
        }));
        sceneTree.itemActivated.connect(Callable.fromFunction(function() {
            var selectedItem = sceneTree.getSelected();
            if (selectedItem.getMetadata(0).toInt() != -1) {
                selectedItem.setEditable(0, true);
            }

        }));
        sceneTree.itemEdited.connect(Callable.fromFunction(function() {
            var selectedItem = sceneTree.getSelected();
            selectedItem.setEditable(0, false);
            selectedEntityIndex = selectedItem.getMetadata(0);
            selectedEntity = entityIndex[selectedEntityIndex];
            var newSelectedEntityName = selectedItem.getText(0);
            selectedEntity.name = newSelectedEntityName;
            var entityParent = selectedEntity.parent;
            var entIdx = 0;
            if (!scene.hasEntity(selectedEntity)) {
                for (i in 0...entityParent.getChildCount()) {
                    var entityParentChild = entityParent.getChild(i);
                    if (entityParentChild == selectedEntity) continue;
                    else {
                        if (entityParentChild.name == selectedEntity.name) {
                            entIdx++;
                            selectedEntity.name = newSelectedEntityName + " (" + Std.string(entIdx) + ")";
                        }
                    }
                }
            }
            else {
                for (i in 0...scene.getEntityCount()) {
                    var sceneEntity = scene.getEntity(i);
                    if (sceneEntity != selectedEntity) {
                        if (sceneEntity.name == selectedEntity.name) {
                            entIdx++;
                            selectedEntity.name = newSelectedEntityName + " (" + Std.string(entIdx) + ")";
                        }
                    }
                }
            }

            refreshSceneTree();

            for (idx in entityIndex.keys()) {
                if (entityIndex[idx] == selectedEntity) {
                    selectedEntityIndex = idx;
                    break;
                }
            }

            sceneEditor.gizmo.clear();
            refreshInspector();
            sceneEditor.checkScene();
        }));

        addEntityDialog = getNodeT(AcceptDialog, "addEntityDialog");
        addEntityDialog.contentScaleFactor = getWindow().contentScaleFactor;
        var addEntityDialogSize = addEntityDialog.size;
        addEntityDialogSize.x = Std.int(addEntityDialogSize.x * addEntityDialog.contentScaleFactor);
        addEntityDialogSize.y = Std.int(addEntityDialogSize.y * addEntityDialog.contentScaleFactor);
        addEntityDialog.size = addEntityDialogSize;
        addEntityDialog.confirmed.connect(Callable.fromFunction(function() {
            if (sceneEditor == null) return;
            createEntity();
        }));
        addEntityDialogTree = getNodeT(Tree, "addEntityDialog/vbox/tree");
        addEntityDialogTree.itemActivated.connect(Callable.fromFunction(function() {
            addEntityDialog.hide();
            if (sceneEditor == null) return;
            createEntity();
        }));

        addComponentDialog = getNodeT(AcceptDialog, "addComponentDialog");
        addComponentDialog.contentScaleFactor = getWindow().contentScaleFactor;
        addComponentDialog.size = addEntityDialogSize;
        addComponentDialog.confirmed.connect(Callable.fromFunction(function() {
            addComponentDialog.hide();
            if (sceneEditor == null) return;
            if (selectedEntity == null) return;

            addSelectedComponent();
        }));
        addComponentDialogTree = getNodeT(Tree, "addComponentDialog/vbox/tree");
        addComponentDialogTree.itemActivated.add(function() {
            addComponentDialog.hide();
            if (sceneEditor == null) return;
            if (selectedEntity == null) return;

            addSelectedComponent();
        });


        entityTemplates = new Map();

        entityTemplates["3D Entity"] = (entity: Entity) -> {
            entity.name = "Entity";
            entity.addComponent(SpatialTransform);
        };

        entityTemplates["Empty Entity"] = (entity: Entity) -> {
            entity.name = "Entity";
        };
    }

    public inline function deleteEntity() {
        if (sceneEditor == null) return;
        if (selectedEntity == null) return;

        if (selectedEntity != null) {
            var transform: SpatialTransform = selectedEntity.getComponent(SpatialTransform);
            if (transform != null) {
                sceneEditor.gizmo.deselect(transform);
            }
        }
        
        selectedEntity.destroy();
        selectedEntity = null;

        refreshSceneTree();

        selectedEntityIndex = -1;

        refreshInspector();
        sceneEditor.checkScene();
    }

    public inline function showAddEntityTree() {
        addEntityDialogTree.clear();
        addEntityDialogTree.hideRoot = true;
        var rootItem = addEntityDialogTree.createItem();

        for (templateName in entityTemplates.keys()) {
            var templateItem = addEntityDialogTree.createItem(rootItem);
            templateItem.setText(0, templateName);
            templateItem.setMetadata(0, templateName);
        }

        addEntityDialog.popupCentered();
    }

    public var componentClasses: Array<Class<Behavior>> = new Array();

    public inline function showAddComponentTree() {
        addComponentDialogTree.clear();
        addComponentDialogTree.hideRoot = true;
        var rootItem = addComponentDialogTree.createItem();
        rootItem.setMetadata(0, false);

        for (componentClass in componentClasses) {
            var className = std.Type.getClassName(componentClass);
            var componentItem = addComponentDialogTree.createItem(rootItem);
            componentItem.setText(0, className);
            componentItem.setMetadata(0, true);
        }

        addComponentDialog.popupCentered();
    }

    public inline function addSelectedComponent() {
        if (selectedEntity == null) return;

        var selectedItem = addComponentDialogTree.getSelected();
        if (selectedItem == null) return;
        if (selectedItem.getMetadata(0).toBool() != true) return;

        var componentName = selectedItem.getText(0);

        var selectedClass: Class<Behavior> = null;
        for (componentClass in componentClasses) {
            if (std.Type.getClassName(componentClass) == componentName) {
                selectedClass = componentClass;
                break;
            }
        }

        if (selectedClass != null) {
            selectedEntity.addComponentNG(selectedClass);
            refreshInspector();
        }
        else {
            Debug.error("Component not found");
        }
    }

    public inline function openLoadPrefabDialog() {
        if (selectedEntity == null) return;
        if (sceneEditor == null) return;
        var dialog = new FileDialog();
        dialog.fileMode = FileDialogMode.openFile;
        dialog.rootSubfolder = getEditor().explorer.assetsDirectory;
        dialog.currentDir = getEditor().explorer.assetsDirectory;
        dialog.currentFile = selectedEntity.name + ".vpfb";
        dialog.access = 2;
        dialog.title = "Load Prefab";
        dialog.addFilter("*.vpfb", "Prefab");
        addChild(dialog);
        dialog.hide();

        dialog.currentDir = getEditor().explorer.assetsDirectory;

        var dialogScaleFactor = getWindow().contentScaleFactor;
        dialog.contentScaleFactor = dialogScaleFactor;
        var minSize = new Vector2i(580, 460);
        minSize.x = Std.int(minSize.x * dialogScaleFactor);
        minSize.y = Std.int(minSize.y * dialogScaleFactor);
        dialog.minSize = minSize;

        dialog.fileSelected.connect(Callable.fromFunction(function(path: String) {
            var ioPath = StringTools.replace(path, getEditor().explorer.assetsDirectory, getEditor().projectIo.pathUrl);
            dialog.hide();
            dialog.queueFree();
            if (ioPath == "" || ioPath == path) {
                Debug.error("Invalid file path.", "Error saving prefab");
                return;
            }

            if (StringTools.contains(ioPath, "///"))
                ioPath = StringTools.replace(ioPath, "///", "//");

            var prefabFile = new Prefab();
            prefabFile.io = getEditor().projectIo;
            prefabFile.load(ioPath);

            var prefab = prefabFile.instance();
            if (selectedEntity != null)
                selectedEntity.addChild(prefab);
            else if (sceneEditor.prefab != null)
                sceneEditor.prefab.addChild(prefab);
            else
                scene.addEntity(prefab);
            selectedEntity = prefab;

            refreshSceneTree();
            for (idx in entityIndex.keys()) {
                if (entityIndex[idx] == selectedEntity) {
                    selectedEntityIndex = idx;
                    break;
                }
            }
            sceneEditor.gizmo.clear();
            refreshInspector();
            getEditor().explorer.buildTreeRoot();
            sceneEditor.checkScene();
        }));

        dialog.popupCentered();
    }

    public inline function createEntity() {
        var selectedItem = addEntityDialogTree.getSelected();
        if (selectedItem.isNull()) return;

        var entity = new Entity();

        var selectedItemText = selectedItem.getMetadata(0);
        if (selectedItemText.getType() == VariantType.nil) return;

        var selectedItemFunc = entityTemplates[selectedItemText];
        if (selectedItemFunc == null) return;

        selectedItemFunc(entity);

        var entityIdx = 0;
        var ogEntityName = entity.name;
        if (selectedEntity != null) {
            for (i in 0...selectedEntity.getChildCount()) {
                var selectedEntityChild = selectedEntity.getChild(i);
                if (selectedEntityChild.name == entity.name) {
                    entityIdx++;
                    entity.name = ogEntityName + " (" + Std.string(entityIdx) + ")";
                }
            }
            selectedEntity.addChild(entity);
        }
        else if (prefab != null) {
            for (i in 0...prefab.getChildCount()) {
                var prefabChild = prefab.getChild(i);
                if (prefabChild.name == entity.name) {
                    entityIdx++;
                    entity.name = ogEntityName + " (" + Std.string(entityIdx) + ")";
                }
            }
            prefab.addChild(entity);
        }
        else {
            for (i in 0...scene.getEntityCount()) {
                var sceneEntity = scene.getEntity(i);
                if (sceneEntity.name == entity.name) {
                    entityIdx++;
                    entity.name = ogEntityName + " (" + Std.string(entityIdx) + ")";
                }
            }
            scene.addEntity(entity);
        }

        refreshSceneTree();

        for (idx in entityIndex.keys()) {
            if (entityIndex[idx] == entity) {
                selectedEntityIndex = idx;
                break;
            }
        }

        if (selectedEntity != null) {
            var transform: SpatialTransform = selectedEntity.getComponent(SpatialTransform);
            if (transform != null) {
                sceneEditor.gizmo.deselect(transform);
            }
        }

        var transform: SpatialTransform = entityIndex[selectedEntityIndex].getComponent(SpatialTransform);
        if (transform != null) {
            sceneEditor.gizmo.select(transform);
        }

        refreshInspector();
        sceneEditor.checkScene();
    }

    public override function onProcess(deltaTime: Float) {
        var currentTab = getEditor().getCurrentWorkspaceChild();
        if (currentTab == null) {
            openSceneEditor(null);
            return;
        }
        else {
            if (currentTab != sceneEditor) {
                openSceneEditor(null);
                return;
            }
        }
    }

    public var entityTemplates: Map<String, (Entity)->Void>;

    public function openSaveAsPrefabDialog() {
        var dialog = new FileDialog();
        dialog.fileMode = FileDialogMode.saveFile;
        dialog.rootSubfolder = getEditor().explorer.assetsDirectory;
        dialog.currentDir = getEditor().explorer.assetsDirectory;
        dialog.currentFile = selectedEntity.name + ".vpfb";
        dialog.access = 2;
        dialog.title = "Save \"" + selectedEntity.name + "\" as prefab";
        dialog.addFilter("*.vpfb", "Prefab");
        addChild(dialog);
        dialog.hide();

        dialog.currentDir = getEditor().explorer.assetsDirectory;

        var dialogScaleFactor = getWindow().contentScaleFactor;
        dialog.contentScaleFactor = dialogScaleFactor;
        var minSize = new Vector2i(580, 460);
        minSize.x = Std.int(minSize.x * dialogScaleFactor);
        minSize.y = Std.int(minSize.y * dialogScaleFactor);
        dialog.minSize = minSize;

        dialog.fileSelected.connect(Callable.fromFunction(function(path: String) {
            var ioPath = StringTools.replace(path, getEditor().explorer.assetsDirectory, getEditor().projectIo.pathUrl);
            dialog.hide();
            dialog.queueFree();
            if (ioPath == "" || ioPath == path) {
                Debug.error("Invalid file path.", "Error saving prefab");
                return;
            }

            if (StringTools.contains(ioPath, "///"))
                ioPath = StringTools.replace(ioPath, "///", "//");

            var prefabFile = Prefab.create(selectedEntity, ioPath);
            prefabFile.save();

            refreshSceneTree();
            for (idx in entityIndex.keys()) {
                if (entityIndex[idx] == selectedEntity) {
                    selectedEntityIndex = idx;
                    break;
                }
            }
            refreshInspector();
            getEditor().explorer.buildTreeRoot();
            sceneEditor.checkScene();
        }));

        dialog.popupCentered();
    }

    public function openSceneEditor(_sceneEditor: SceneEditor) {
        if (_sceneEditor == null) {
            if (!nothingSelected) {
                nothingSelected == true;
                if (sceneEditor != null) {
                    sceneEditor.gizmo.clear();
                }
                sceneEditor = null;
                scene = null;
                prefab = null;
                sceneTree.clear();
                refreshInspector();
            }
            return;
        }
        if (_sceneEditor != sceneEditor) {
            nothingSelected = false;
            if (sceneEditor != null) {
                sceneEditor.gizmo.clear();
            }
            sceneEditor = _sceneEditor;
            scene = sceneEditor.scene;
            prefab = sceneEditor.prefab;
            mode = sceneEditor.fileType;
            selectedEntityIndex = -1;
            refreshSceneTree();        
            refreshInspector();
        }
    }

    var sceneItem: TreeItem;

    public function refreshSceneTree() {
        sceneTree.clear();
        entityIndex = new Map();
        sceneItem = sceneTree.createItem();
        sceneItem.setIcon(0, sceneIcon);
        sceneItem.setMetadata(0, -1);
        if (nothingSelected == true) {
            sceneTree.hideRoot = true;
            return;
        }
        if (mode == FileType.SceneType) {
            var sceneName = getEditor().getWorkspaceTabTitle(sceneEditor);
            sceneItem.setText(0, sceneName);
            sceneTree.hideRoot = false;
        }
        else if (mode == FileType.PrefabType) {
            sceneTree.hideRoot = true;
        }
        else {
            Debug.error("Invalid mode");
        }

        for (i in 0...scene.getEntityCount()) {
            var entity = scene.getEntity(i);
            buildEntityTree(sceneItem, entity);
        }
    }

    public function buildEntityTree(parentItem: TreeItem, entity: Entity) {
        var item = sceneTree.createItem(parentItem);
        item.setText(0, entity.name);
        entityIndex[maxEntityIndex] = entity;
        item.setMetadata(0, maxEntityIndex);
        maxEntityIndex++;
        if (entity.isPrefab()) {
            item.setIcon(0, prefabIcon);

            if (entity == prefab) {
                for (i in 0...entity.getChildCount()) {
                    var child = entity.getChild(i);
                    buildEntityTree(item, child);
                }
            }
        }
        else {
            item.setIcon(0, entityIcon16);

            for (i in 0...entity.getChildCount()) {
                var child = entity.getChild(i);
                buildEntityTree(item, child);
            }
        }
    }

    public function refreshInspector() {
        for (i in 0...entityVBox.getChildCount()) {
            var propertyGroup = entityVBox.getChild(i);
            propertyGroup.queueFree();
        }
        if (sceneEditor != null) {
            sceneEditor.checkScene();
        }
        

        entityPrefabButton.hide();

        if (nothingSelected == true || sceneEditor == null) {
            entityIcon.texture = nothingEntityIcon24;
            entityText.text = nothingEntityText;
        }
        else if (sceneEditor != null) {
            if (selectedEntityIndex != -1) {
                var selectedEntity = entityIndex[selectedEntityIndex];
                entityText.text = selectedEntity.name;
                if (selectedEntity.isPrefab()) {
                    entityIcon.texture = prefabIcon24;
                    buildComponentTree(selectedEntity);
                }
                else {
                    entityIcon.texture = entityIcon24;
                    buildComponentTree(selectedEntity);
                    entityPrefabButton.show();
                }
            }
            else if (mode == FileType.SceneType) {
                trace("");
                var sceneName = getEditor().getWorkspaceTabTitle(sceneEditor);
                trace(sceneName);
                trace(entityText.isNull());
                entityText.text = sceneName;
                trace(entityIcon.isNull());
                entityIcon.texture = sceneIcon24;

            }
            else if (mode == FileType.PrefabType) {
                entityText.text = prefab.name;
                entityIcon.texture = prefabIcon24;

                buildComponentTree(prefab);
            }
        }
    }

    public function buildComponentTree(entity: Entity) {
        for (component in entity.getConponents()) {
            var compName = component.name;
            compName = compName.split(".").pop();
            var compIconPath = component.editorIconPath;
            var compIcon = getEditor().explorer.loadIcon(compIconPath);
            var foldableContainer = new FoldableContainer();
            foldableContainer.title = compName;
            var componentVbox = new VBoxContainer();
            foldableContainer.addChild(componentVbox);
            foldableContainer.titleAlignment = HorizontalAlignment.center;
            entityVBox.addChild(foldableContainer);

            var iconTextureRect = new TextureRect();
            var iconPath = component.editorIconPath;
            trace(iconPath);
            if (iconPath == null) {
                iconPath = "studio://icons/16/lightning.png";
            }
            var icon = getEditor().explorer.loadIcon(iconPath);
            iconTextureRect.texture = icon;
            foldableContainer.addTitleBarControl(iconTextureRect);

            var deleteButton = new Button();
            var deleteIcon = getEditor().explorer.loadIcon("studio://icons/16/cross.png");
            deleteButton.icon = deleteIcon;
            deleteButton.pressed.add(() -> {
                var compType = std.Type.getClass(component);
                entity.removeComponent(compType);
                sceneEditor.gizmo.clear();
                refreshInspector();
            });
            foldableContainer.addTitleBarControl(deleteButton);

            var data = component.getData();
            var dataKeys = data.keys();
            var dataValues = data.values();
            trace(dataKeys.size());
            for (i in 0...dataKeys.size()) {
                var key = dataKeys.get(i);
                var value = dataValues.get(i);
                var propertyContainer = new HBoxContainer();
                var propertyName = new Label();
                propertyName.text = key;
                propertyName.horizontalAlignment = HorizontalAlignment.left;
                propertyName.verticalAlignment = VerticalAlignment.center;
                propertyName.customMinimumSize = new Vector2(0.0, 20.0);
                propertyName.clipText = true;
                propertyContainer.addChild(propertyName);
                propertyName.sizeFlagsHorizontal = 3;

                if (value.getType() == VariantType.string) {
                    var strLineEdit = new LineEdit();
                    strLineEdit.text = value;
                    strLineEdit.customMinimumSize = new Vector2(150.0, 20.0);
                    strLineEdit.textChanged.connect(Callable.fromFunction(function(newValue: String) {
                        var dataToEdit = component.getData();
                        dataToEdit.set(key, newValue);
                        component.setData(dataToEdit);
                        sceneEditor.checkScene();
                    }));
                    propertyContainer.addChild(strLineEdit);
                }
                else if (value.getType() == VariantType.float) {
                    var floatSpinBox = new SpinBox();
                    floatSpinBox.maxValue = 500;
                    floatSpinBox.minValue = -500;
                    floatSpinBox.allowGreater = true;
                    floatSpinBox.allowLesser = true;
                    floatSpinBox.step = 0.001;
                    floatSpinBox.value = value;
                    floatSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    floatSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                        var dataToEdit = component.getData();
                        dataToEdit.set(key, newValue);
                        component.setData(dataToEdit);
                        sceneEditor.checkScene();
                    }));
                    propertyContainer.addChild(floatSpinBox);
                }
                else if (value.getType() == VariantType.int) {
                    var intSpinBox = new SpinBox();
                    intSpinBox.maxValue = 2147483648;
                    intSpinBox.minValue = -2147483648;
                    intSpinBox.allowGreater = true;
                    intSpinBox.allowLesser = true;
                    intSpinBox.step = 1;
                    intSpinBox.value = cast value.toInt();
                    intSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    intSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                        var dataToEdit = component.getData();
                        var intValue = Std.int(newValue);
                        dataToEdit.set(key, intValue);
                        component.setData(dataToEdit);
                        sceneEditor.checkScene();
                    }));
                    propertyContainer.addChild(intSpinBox);
                }
                else if (value.getType() == VariantType.bool) {
                    var boolCheckButton = new CheckButton();
                    boolCheckButton.buttonPressed = value;
                    boolCheckButton.customMinimumSize = new Vector2(0.0, 20.0);
                    boolCheckButton.flat = true;
                    boolCheckButton.toggled.connect(Callable.fromFunction(function(newValue: Bool) {
                        var dataToEdit = component.getData();
                        dataToEdit.set(key, newValue);
                        component.setData(dataToEdit);
                        sceneEditor.checkScene();
                    }));
                    propertyContainer.addChild(boolCheckButton);
                }
                else if (value.getType() == VariantType.dictionary) {
                    var dict: Dictionary = value;
                    if (dict.has("type") && dict.has("value")) {
                        if (dict.get("type").toInt() == VariantType.vector2) {
                            var vec2: Vector2 = DataUtils.dictToVar(dict);

                            var vec2Vbox = new VBoxContainer();

                            var xSpinBox = new SpinBox();
                            xSpinBox.maxValue = 500;
                            xSpinBox.minValue = -500;
                            xSpinBox.allowGreater = true;
                            xSpinBox.allowLesser = true;
                            xSpinBox.step = 0.001;
                            xSpinBox.value = vec2.x;
                            xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            xSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec2: Vector2 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec2.x = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec2));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var xLabel = new Label();
                            xLabel.text = "x";
                            xLabel.horizontalAlignment = HorizontalAlignment.center;
                            xLabel.verticalAlignment = VerticalAlignment.center;
                            var xHBox = new HBoxContainer();
                            xHBox.addChild(xLabel);
                            xHBox.addChild(xSpinBox);
                            vec2Vbox.addChild(xHBox);


                            var ySpinBox = new SpinBox();
                            ySpinBox.maxValue = 500;
                            ySpinBox.minValue = -500;
                            ySpinBox.allowGreater = true;
                            ySpinBox.allowLesser = true;
                            ySpinBox.step = 0.001;
                            ySpinBox.value = vec2.y;
                            ySpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            ySpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec2: Vector2 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec2.y = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec2));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var yLabel = new Label();
                            yLabel.text = "y";
                            yLabel.horizontalAlignment = HorizontalAlignment.center;
                            yLabel.verticalAlignment = VerticalAlignment.center;
                            var yHBox = new HBoxContainer();
                            yHBox.addChild(yLabel);
                            yHBox.addChild(ySpinBox);
                            vec2Vbox.addChild(yHBox);

                            propertyContainer.addChild(vec2Vbox);
                        }
                        else if (dict.get("type").toInt() == VariantType.vector3) {
                            var vec3: Vector3 = DataUtils.dictToVar(dict);

                            var vec3Vbox = new VBoxContainer();

                            var xSpinBox = new SpinBox();
                            xSpinBox.maxValue = 500;
                            xSpinBox.minValue = -500;
                            xSpinBox.allowGreater = true;
                            xSpinBox.allowLesser = true;
                            xSpinBox.step = 0.001;
                            xSpinBox.value = vec3.x;
                            xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            xSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec3: Vector3 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec3.x = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec3));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var xLabel = new Label();
                            xLabel.text = "x";
                            xLabel.horizontalAlignment = HorizontalAlignment.center;
                            xLabel.verticalAlignment = VerticalAlignment.center;
                            var xHBox = new HBoxContainer();
                            xHBox.addChild(xLabel);
                            xHBox.addChild(xSpinBox);
                            vec3Vbox.addChild(xHBox);


                            var ySpinBox = new SpinBox();
                            ySpinBox.maxValue = 500;
                            ySpinBox.minValue = -500;
                            ySpinBox.allowGreater = true;
                            ySpinBox.allowLesser = true;
                            ySpinBox.step = 0.001;
                            ySpinBox.value = vec3.y;
                            ySpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            ySpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec3: Vector3 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec3.y = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec3));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var yLabel = new Label();
                            yLabel.text = "y";
                            yLabel.horizontalAlignment = HorizontalAlignment.center;
                            yLabel.verticalAlignment = VerticalAlignment.center;
                            var yHBox = new HBoxContainer();
                            yHBox.addChild(yLabel);
                            yHBox.addChild(ySpinBox);
                            vec3Vbox.addChild(yHBox);

                            var zSpinBox = new SpinBox();
                            zSpinBox.maxValue = 500;
                            zSpinBox.minValue = -500;
                            zSpinBox.allowGreater = true;
                            zSpinBox.allowLesser = true;
                            zSpinBox.step = 0.001;
                            zSpinBox.value = vec3.z;
                            zSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            zSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec3: Vector3 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec3.z = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec3));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var zLabel = new Label();
                            zLabel.text = "z";
                            zLabel.horizontalAlignment = HorizontalAlignment.center;
                            zLabel.verticalAlignment = VerticalAlignment.center;
                            var zHBox = new HBoxContainer();
                            zHBox.addChild(zLabel);
                            zHBox.addChild(zSpinBox);
                            vec3Vbox.addChild(zHBox);

                            propertyContainer.addChild(vec3Vbox);
                        }
                        else if (dict.get("type").toInt() == VariantType.vector4) {
                            var vec4: Vector4 = DataUtils.dictToVar(dict);

                            var vec4Vbox = new VBoxContainer();

                            var xSpinBox = new SpinBox();
                            xSpinBox.maxValue = 500;
                            xSpinBox.minValue = -500;
                            xSpinBox.allowGreater = true;
                            xSpinBox.allowLesser = true;
                            xSpinBox.step = 0.001;
                            xSpinBox.value = vec4.x;
                            xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            xSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.x = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var xLabel = new Label();
                            xLabel.text = "x";
                            xLabel.horizontalAlignment = HorizontalAlignment.center;
                            xLabel.verticalAlignment = VerticalAlignment.center;
                            var xHBox = new HBoxContainer();
                            xHBox.addChild(xLabel);
                            xHBox.addChild(xSpinBox);
                            vec4Vbox.addChild(xHBox);


                            var ySpinBox = new SpinBox();
                            ySpinBox.maxValue = 500;
                            ySpinBox.minValue = -500;
                            ySpinBox.allowGreater = true;
                            ySpinBox.allowLesser = true;
                            ySpinBox.step = 0.001;
                            ySpinBox.value = vec4.y;
                            ySpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            ySpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.y = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var yLabel = new Label();
                            yLabel.text = "y";
                            yLabel.horizontalAlignment = HorizontalAlignment.center;
                            yLabel.verticalAlignment = VerticalAlignment.center;
                            var yHBox = new HBoxContainer();
                            yHBox.addChild(yLabel);
                            yHBox.addChild(ySpinBox);
                            vec4Vbox.addChild(yHBox);

                            var zSpinBox = new SpinBox();
                            zSpinBox.maxValue = 500;
                            zSpinBox.minValue = -500;
                            zSpinBox.allowGreater = true;
                            zSpinBox.allowLesser = true;
                            zSpinBox.step = 0.001;
                            zSpinBox.value = vec4.z;
                            zSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            zSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.z = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var zLabel = new Label();
                            zLabel.text = "z";
                            zLabel.horizontalAlignment = HorizontalAlignment.center;
                            zLabel.verticalAlignment = VerticalAlignment.center;
                            var zHBox = new HBoxContainer();
                            zHBox.addChild(zLabel);
                            zHBox.addChild(zSpinBox);
                            vec4Vbox.addChild(zHBox);

                            var wSpinBox = new SpinBox();
                            wSpinBox.maxValue = 500;
                            wSpinBox.minValue = -500;
                            wSpinBox.allowGreater = true;
                            wSpinBox.allowLesser = true;
                            wSpinBox.step = 0.001;
                            wSpinBox.value = vec4.w;
                            wSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            wSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4 = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.z = newValue;
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var wLabel = new Label();
                            wLabel.text = "w";
                            wLabel.horizontalAlignment = HorizontalAlignment.center;
                            wLabel.verticalAlignment = VerticalAlignment.center;
                            var wHBox = new HBoxContainer();
                            wHBox.addChild(zLabel);
                            wHBox.addChild(wSpinBox);
                            vec4Vbox.addChild(wHBox);

                            propertyContainer.addChild(vec4Vbox);
                        }
                        else if (dict.get("type").toInt() == VariantType.vector2i) {
                            var vec2: Vector2i = DataUtils.dictToVar(dict);

                            var vec2Vbox = new VBoxContainer();

                            var xSpinBox = new SpinBox();
                            xSpinBox.maxValue = 500;
                            xSpinBox.minValue = -500;
                            xSpinBox.allowGreater = true;
                            xSpinBox.allowLesser = true;
                            xSpinBox.step = 1;
                            xSpinBox.value = vec2.x;
                            xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            xSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec2: Vector2i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec2.x = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec2));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var xLabel = new Label();
                            xLabel.text = "x";
                            xLabel.horizontalAlignment = HorizontalAlignment.center;
                            xLabel.verticalAlignment = VerticalAlignment.center;
                            var xHBox = new HBoxContainer();
                            xHBox.addChild(xLabel);
                            xHBox.addChild(xSpinBox);
                            vec2Vbox.addChild(xHBox);


                            var ySpinBox = new SpinBox();
                            ySpinBox.maxValue = 500;
                            ySpinBox.minValue = -500;
                            ySpinBox.allowGreater = true;
                            ySpinBox.allowLesser = true;
                            ySpinBox.step = 1;
                            ySpinBox.value = vec2.y;
                            ySpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            ySpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec2: Vector2i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec2.y = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec2));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var yLabel = new Label();
                            yLabel.text = "y";
                            yLabel.horizontalAlignment = HorizontalAlignment.center;
                            yLabel.verticalAlignment = VerticalAlignment.center;
                            var yHBox = new HBoxContainer();
                            yHBox.addChild(yLabel);
                            yHBox.addChild(ySpinBox);
                            vec2Vbox.addChild(yHBox);

                            propertyContainer.addChild(vec2Vbox);
                        }
                        else if (dict.get("type").toInt() == VariantType.vector3i) {
                            var vec3: Vector3i = DataUtils.dictToVar(dict);

                            var vec3Vbox = new VBoxContainer();

                            var xSpinBox = new SpinBox();
                            xSpinBox.maxValue = 500;
                            xSpinBox.minValue = -500;
                            xSpinBox.allowGreater = true;
                            xSpinBox.allowLesser = true;
                            xSpinBox.step = 1;
                            xSpinBox.value = vec3.x;
                            xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            xSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec3: Vector3i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec3.x = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec3));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var xLabel = new Label();
                            xLabel.text = "x";
                            xLabel.horizontalAlignment = HorizontalAlignment.center;
                            xLabel.verticalAlignment = VerticalAlignment.center;
                            var xHBox = new HBoxContainer();
                            xHBox.addChild(xLabel);
                            xHBox.addChild(xSpinBox);
                            vec3Vbox.addChild(xHBox);


                            var ySpinBox = new SpinBox();
                            ySpinBox.maxValue = 500;
                            ySpinBox.minValue = -500;
                            ySpinBox.allowGreater = true;
                            ySpinBox.allowLesser = true;
                            ySpinBox.step = 1;
                            ySpinBox.value = vec3.y;
                            ySpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            ySpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec3: Vector3i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec3.y = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec3));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var yLabel = new Label();
                            yLabel.text = "y";
                            yLabel.horizontalAlignment = HorizontalAlignment.center;
                            yLabel.verticalAlignment = VerticalAlignment.center;
                            var yHBox = new HBoxContainer();
                            yHBox.addChild(yLabel);
                            yHBox.addChild(ySpinBox);
                            vec3Vbox.addChild(yHBox);

                            var zSpinBox = new SpinBox();
                            zSpinBox.maxValue = 500;
                            zSpinBox.minValue = -500;
                            zSpinBox.allowGreater = true;
                            zSpinBox.allowLesser = true;
                            zSpinBox.step = 1;
                            zSpinBox.value = vec3.z;
                            zSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            zSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec3: Vector3i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec3.z = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec3));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var zLabel = new Label();
                            zLabel.text = "z";
                            zLabel.horizontalAlignment = HorizontalAlignment.center;
                            zLabel.verticalAlignment = VerticalAlignment.center;
                            var zHBox = new HBoxContainer();
                            zHBox.addChild(zLabel);
                            zHBox.addChild(zSpinBox);
                            vec3Vbox.addChild(zHBox);

                            propertyContainer.addChild(vec3Vbox);
                        }
                        else if (dict.get("type").toInt() == VariantType.vector4i) {
                            var vec4: Vector4i = DataUtils.dictToVar(dict);

                            var vec4Vbox = new VBoxContainer();

                            var xSpinBox = new SpinBox();
                            xSpinBox.maxValue = 500;
                            xSpinBox.minValue = -500;
                            xSpinBox.allowGreater = true;
                            xSpinBox.allowLesser = true;
                            xSpinBox.step = 1;
                            xSpinBox.value = vec4.x;
                            xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            xSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.x = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var xLabel = new Label();
                            xLabel.text = "x";
                            xLabel.horizontalAlignment = HorizontalAlignment.center;
                            xLabel.verticalAlignment = VerticalAlignment.center;
                            var xHBox = new HBoxContainer();
                            xHBox.addChild(xLabel);
                            xHBox.addChild(xSpinBox);
                            vec4Vbox.addChild(xHBox);


                            var ySpinBox = new SpinBox();
                            ySpinBox.maxValue = 500;
                            ySpinBox.minValue = -500;
                            ySpinBox.allowGreater = true;
                            ySpinBox.allowLesser = true;
                            ySpinBox.step = 1;
                            ySpinBox.value = vec4.y;
                            ySpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            ySpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.y = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var yLabel = new Label();
                            yLabel.text = "y";
                            yLabel.horizontalAlignment = HorizontalAlignment.center;
                            yLabel.verticalAlignment = VerticalAlignment.center;
                            var yHBox = new HBoxContainer();
                            yHBox.addChild(yLabel);
                            yHBox.addChild(ySpinBox);
                            vec4Vbox.addChild(yHBox);

                            var zSpinBox = new SpinBox();
                            zSpinBox.maxValue = 500;
                            zSpinBox.minValue = -500;
                            zSpinBox.allowGreater = true;
                            zSpinBox.allowLesser = true;
                            zSpinBox.step = 1;
                            zSpinBox.value = vec4.z;
                            zSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            zSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.z = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var zLabel = new Label();
                            zLabel.text = "z";
                            zLabel.horizontalAlignment = HorizontalAlignment.center;
                            zLabel.verticalAlignment = VerticalAlignment.center;
                            var zHBox = new HBoxContainer();
                            zHBox.addChild(zLabel);
                            zHBox.addChild(zSpinBox);
                            vec4Vbox.addChild(zHBox);

                            var wSpinBox = new SpinBox();
                            wSpinBox.maxValue = 500;
                            wSpinBox.minValue = -500;
                            wSpinBox.allowGreater = true;
                            wSpinBox.allowLesser = true;
                            wSpinBox.step = 1;
                            wSpinBox.value = vec4.w;
                            wSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                            wSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                                var dataToEdit = component.getData();
                                var vec4: Vector4i = DataUtils.dictToVar(dataToEdit.get(key));
                                vec4.z = Std.int(newValue);
                                dataToEdit.set(key, DataUtils.varToDict(vec4));
                                component.setData(dataToEdit);
                                sceneEditor.checkScene();
                            }));
                            var wLabel = new Label();
                            wLabel.text = "w";
                            wLabel.horizontalAlignment = HorizontalAlignment.center;
                            wLabel.verticalAlignment = VerticalAlignment.center;
                            var wHBox = new HBoxContainer();
                            wHBox.addChild(zLabel);
                            wHBox.addChild(wSpinBox);
                            vec4Vbox.addChild(wHBox);

                            propertyContainer.addChild(vec4Vbox);
                        }
                        else if (dict.get("type").toInt() == VariantType.object) {
                            var resDict: Dictionary = dict.get("value");
                            var classType: String = resDict.get("class");
                            trace(classType);
                            if (classType == "Texture2D" || classType == "ImageTexture" || classType == "AudioStream" || classType == "AudioStreamOggVorbis" || classType == "AudioStreamWAV" || classType == "AudioStreamMP3") {
                                var resHbox = new HBoxContainer();
                                var respath: String = resDict.get("path");
                            
                                var resLineEdit = new LineEdit();
                                resLineEdit.sizeFlagsHorizontal = 3;
                                resLineEdit.text = respath;
                                resLineEdit.customMinimumSize = new Vector2(0.0, 20.0);
                                var setPathFunction = (newPath: String) -> {
                                    var dataToEdit = component.getData();
                                    var vDict: Dictionary = dataToEdit.get(key);
                                    var resToEdit: Dictionary = vDict.get("value");
                                    resToEdit.set("path", newPath);
                                    if (resToEdit.has("properties")) {
                                        resToEdit.erase("properties");
                                    }
                                    if (StringTools.endsWith(newPath, ".ogg")) {
                                        resToEdit.set("class", "AudioStreamOggVorbis");
                                    }
                                    else if (StringTools.endsWith(newPath, ".wav")) {
                                        resToEdit.set("class", "AudioStreamWAV");
                                    }
                                    else if (StringTools.endsWith(newPath, ".mp3")) {
                                        resToEdit.set("class", "AudioStreamMP3");
                                    }
                                    vDict.set("value", resToEdit);
                                    dataToEdit.set(key, vDict);
                                    component.setData(dataToEdit);
                                    resLineEdit.text = newPath;
                                    respath = newPath;
                                    sceneEditor.checkScene();
                                };
                                resLineEdit.textSubmitted.add(setPathFunction);

                                var resFileButton = new MenuButton();
                                if (classType == "Texture2D" 
                                ||  classType == "ImageTexture") {
                                    resFileButton.icon = getEditor().loadIcon("studio://icons/16/folder-open-image.png");
                                }
                                else if (classType == "AudioStream" 
                                     ||  classType == "AudioStreamOggVorbis" 
                                     ||  classType == "AudioStreamWAV" 
                                     ||  classType == "AudioStreamMP3") {
                                    resFileButton.icon = getEditor().loadIcon("studio://icons/16/folder-open-document-music.png");
                                }
                                else {
                                    resFileButton.icon = getEditor().loadIcon("studio://icons/16/folder-open-document.png");
                                }
                                resFileButton.customMinimumSize = new Vector2(20.0, 20.0);
                                var resFileButtonPopup = resFileButton.getPopup();
                                resFileButtonPopup.addItem("Builtin path", 0);
                                resFileButtonPopup.addItem("Project path", 1);
                                resFileButtonPopup.idPressed.add((id: Int) -> {
                                    if (id == 0) {
                                        var confirmDialog = new ConfirmationDialog();
                                        confirmDialog.contentScaleFactor = getWindow().contentScaleFactor;
                                        confirmDialog.minSize = new Vector2i(
                                            Std.int(450 * confirmDialog.contentScaleFactor), 
                                            Std.int(350 * confirmDialog.contentScaleFactor)
                                        );
                                        confirmDialog.title = "Select Builtin Path";
                
                                        var confirmDialogTree = new Tree();
                                        confirmDialogTree.hideRoot = true;
                                        var confirmDialogTreeRoot = confirmDialogTree.createItem();

                                        var selectedItem: String = null;
                                        confirmDialogTree.itemSelected.add(() -> {
                                            var selected = confirmDialogTree.getSelected();
                                            var selectedMetadata = selected.getMetadata(0);
                                            if (selectedMetadata.getType() == VariantType.string) {
                                                selectedItem = selectedMetadata;
                                            }
                                            else {
                                            selectedItem = null;
                                            }
                                        });
                                        confirmDialogTree.itemActivated.add(() -> {
                                            var selected = confirmDialogTree.getSelected();
                                            var selectedMetadata = selected.getMetadata(0);
                                            if (selectedMetadata.getType() == VariantType.string) {
                                                selectedItem = selectedMetadata;
                                            }
                                            else {
                                                selectedItem = null;
                                            }
                                            trace(selectedItem);
                                            if (selectedItem != null) {
                                                setPathFunction(selectedItem);
                                            }
                                            confirmDialog.queueFree();
                                        });
                                        confirmDialog.confirmed.add(() -> {
                                            trace(selectedItem);
                                            if (selectedItem != null) {
                                                setPathFunction(selectedItem);
                                            }
                                            confirmDialog.queueFree();
                                        });
                                        confirmDialog.canceled.add(() -> {
                                            confirmDialog.queueFree();
                                        });
                                        confirmDialog.closeRequested.add(() -> {
                                            confirmDialog.queueFree();
                                        });

                                        

                                        var recurseDirFunc: (String, TreeItem, ?String)->Void;

                                        var createFileEntry = (path: String, parent: TreeItem) -> {
                                            var fileItem = confirmDialogTree.createItem(parent);
                                            fileItem.setText(0, path.split("/").pop());
                                            fileItem.setMetadata(0, path);
                                            if (StringTools.startsWith(classType, "AudioStream")) {
                                                fileItem.setIcon(0, getEditor().loadIcon("studio://icons/16/folder-open-document-music.png"));
                                            }
                                            else if (StringTools.contains(classType, "Texture")) {
                                                fileItem.setIcon(0, getEditor().loadIcon("studio://icons/16/folder-open-image.png"));
                                            }
                                            else if (StringTools.contains(classType, "Texture")) {
                                                fileItem.setIcon(0, getEditor().loadIcon("studio://icons/16/folder-open-document.png"));
                                            }
                                        };

                                        recurseDirFunc = (dirpath: String, parent: TreeItem, ?name: String) -> {
                                            var dirItem = confirmDialogTree.createItem(parent);
                                            if (name == null) {
                                                dirItem.setText(0, dirpath.split("/").pop());
                                            }
                                            else {
                                                dirItem.setText(0, name);
                                            }
                                            dirItem.setIcon(0, getEditor().loadIcon("studio://icons/16/folder-horizontal.png"));
                                            dirItem.collapsed = true;

                                            var dirs = io.getFileList(dirpath, "/", false);
                                            Sys.println(JSON.stringify(dirs));
                                            for (i in 0...dirs.size()) {
                                                var subPath: String = dirs.get(i);
                                                trace(subPath);
                                                recurseDirFunc(subPath, dirItem);
                                            }

                                            var vorbisFiles = io.getFileList(dirpath, ".ogg", false);
                                            for (j in 0...vorbisFiles.size()) {
                                                var filePath = vorbisFiles.get(j); 
                                                createFileEntry(filePath, dirItem);
                                            }

                                            var mp3Files = io.getFileList(dirpath, ".mp3", false);
                                            for (j in 0...mp3Files.size()) {
                                                var filePath = mp3Files.get(j); 
                                                createFileEntry(filePath, dirItem);
                                            }

                                            var wavFiles = io.getFileList(dirpath, ".wav", false);
                                            for (j in 0...wavFiles.size()) {
                                                var filePath = wavFiles.get(j); 
                                                createFileEntry(filePath, dirItem);
                                            }
                                        };

                                        if (StringTools.startsWith(classType, "AudioStream")) {
                                            recurseDirFunc("basesfx://", null, "Base Sound Effects");
                                        }


                                        confirmDialog.addChild(confirmDialogTree);
                                        addChild(confirmDialog);
                                        confirmDialog.popupCentered();
                                    }
                                    else if (id == 1) {
                                        var dialog = new FileDialog();
                                        dialog.fileMode = FileDialogMode.openFile;
                                        dialog.rootSubfolder = getEditor().explorer.assetsDirectory;
                                        dialog.currentDir = getEditor().explorer.assetsDirectory;
                                        if (respath != "?") {
                                            dialog.currentFile = respath.split("/").pop();
                                        }
                                        dialog.access = 2;

                                        if (classType == "Texture2D" || classType == "ImageTexture") {
                                            dialog.title = "Open Texture";
                                            dialog.addFilter("*.bmp, *.dds, *.jpg, *.jpeg, *.ktx, *.png, *.svg, *.tga, *.webp", "Texture");
                                        }
                                        else if (key == "stream" || classType == "AudioStream" || classType == "AudioStreamOggVorbis" || classType == "AudioStreamWAV" || classType == "AudioStreamMP3") {
                                            dialog.title = "Open Audio File";
                                            dialog.addFilter("*.ogg, *.mp3, *.wav", "Audio File");
                                        }
                                        addChild(dialog);
                                        dialog.hide();

                                        dialog.currentDir = getEditor().explorer.assetsDirectory;

                                        var dialogScaleFactor = getWindow().contentScaleFactor;
                                        dialog.contentScaleFactor = dialogScaleFactor;
                                        var minSize = new Vector2i(580, 460);
                                        minSize.x = Std.int(minSize.x * dialogScaleFactor);
                                        minSize.y = Std.int(minSize.y * dialogScaleFactor);
                                        dialog.minSize = minSize;

                                        dialog.fileSelected.add((newPath: String) -> {
                                            var realPath = getEditor().projectIo.getFileUrl(newPath);
                                            setPathFunction(realPath);
                                            dialog.queueFree();
                                        });
                                
                                        dialog.popupFileDialog();
                                    }
                                });


                                resHbox.addChild(resLineEdit);
                                resHbox.addChild(resFileButton);
                                resHbox.customMinimumSize = new Vector2(150.0, 20.0);
                                propertyContainer.addChild(resHbox);
                            }
                            else {
                                var resButton = new Button();
                                resButton.text = "Edit";
                                resButton.customMinimumSize = new Vector2(150.0, 20.0);
                                resButton.pressed.add(() -> {
                                    getEditor().resourceInspector.openResource(dict, false, key, selectedEntity);
                                });

                                propertyContainer.addChild(resButton);
                            }
                        }
                    }
                    else if (dict.has("path") && dict.has("classType")) {
                            var resButton = new Button();
                            resButton.text = "Edit";
                            resButton.customMinimumSize = new Vector2(150.0, 20.0);
                            resButton.pressed.add(() -> {
                                getEditor().resourceInspector.openScriptableObject(dict, key, selectedEntity);
                            });

                            propertyContainer.addChild(resButton);
                    }
                }

                componentVbox.addChild(propertyContainer);
                propertyContainer.customMinimumSize = new Vector2(0.0, 20.0);
            }
        }

        var centerContainer = new CenterContainer();
        centerContainer.customMinimumSize = new Vector2(0.0, 50.0);

        if ((entity.isPrefab() && entity != selectedEntity && entity != prefab) == false) {
            var button = new Button();
            button.text = "Add Component";
            button.customMinimumSize = new Vector2(200.0, 0.0);
            button.alignment = HorizontalAlignment.center;
            button.pressed.add(() -> {
                showAddComponentTree();
            });

            centerContainer.addChild(button);
        }
        
        entityVBox.addChild(centerContainer);
        sceneEditor.checkScene();
    }
}