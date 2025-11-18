package sunaba.studio.sceneEditor;

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

class SceneInspector extends EditorWidget {
    public var loadButton: Button;
    public var deleteButton: Button;
    public var createButton: MenuButton;

    public var sceneTree: Tree;

    public var entityIcon : TextureRect;
    public var entityText: Label;
    public var entityMenuButton: MenuButton;
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

    public override function editorInit() {
        getEditor().setRightSidebarTabTitle(this, "Scene Inspector");

        var iconBin = io.loadBytes("studio://icons/16_1-5x/clapperboard--pencil.png");
        var iconImage = new Image();
        iconImage.loadPngFromBuffer(iconBin);
        var texture = ImageTexture.createFromImage(iconImage);
        getEditor().setRightSiderbarTabIcon(this, texture);
        customMinimumSize = new Vector2(275, 0);

        load("studio://SceneInspector.suml");

        loadButton = getNodeT(Button, "vsplit/outliner/toolbar/hbox/load");
        deleteButton = getNodeT(Button, "vsplit/outliner/toolbar/hbox/delete");
        createButton = getNodeT(MenuButton, "vsplit/outliner/toolbar/hbox/create");

        sceneTree = getNodeT(Tree, "vsplit/outliner/tree");

        entityIcon = getNodeT(TextureRect, "vsplit/entityInspector/toolbar/hbox/container/entityIcon");
        entityText = getNodeT(Label, "vsplit/entityInspector/toolbar/hbox/entityText");
        entityMenuButton = getNodeT(MenuButton, "vsplit/entityInspector/toolbar/hbox/menuButton");
        entityMenuButton.hide();

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
            var selectedItem = sceneTree.getSelected();
            selectedEntityIndex = selectedItem.getMetadata(0);
            refreshInspector();
        }));
    }

    public override function onProcess(deltaTime: Float) {
        var currentTab = getEditor().getCurrentWorkspaceChild();
        if (currentTab == null) {
            openSceneEditor(null);
            return;
        }
        else {
        }
    }

    public function openSceneEditor(_sceneEditor: SceneEditor) {
        if (_sceneEditor == null) {
            if (!nothingSelected) {
                nothingSelected == true;
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

            if (entity == selectedEntity) {
                for (i in 0...entity.getChildCount()) {
                    var child = entity.getChild(i);
                    buildEntityTree(item, entity);
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

        entityMenuButton.hide();

        if (nothingSelected == true || sceneEditor == null) {
            entityIcon.texture = nothingEntityIcon24;
            entityText.text = nothingEntityText;
        }
        else if (sceneEditor != null) {
            if (selectedEntityIndex != -1) {
                var selectedEntity = entityIndex[selectedEntityIndex];
                entityText.text = selectedEntity.name;
                if (selectedEntity.isPrefab())
                    entityIcon.texture = prefabIcon24;
                else {
                    entityIcon.texture = entityIcon24;
                    buildComponentTree(selectedEntity);
                    entityMenuButton.show();
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

                entityMenuButton.show();
                buildComponentTree(prefab);
            }
        }
    }

    public function buildComponentTree(entity: Entity) {
        if (entity.isPrefab() && entity != selectedEntity)
            return;

        for (component in entity.getConponents()) {
            var compName = component.name;
            compName = compName.split(".").pop();
            var compIconPath = component.editorIconPath;
            var compIcon = getEditor().explorer.loadIcon(compIconPath);
            var foldableContainer = new FoldableContainer();
            foldableContainer.title = compName;
            var componentVbox = new VBoxContainer();
            foldableContainer.addChild(componentVbox);
            entityVBox.addChild(foldableContainer);

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
                    }));
                    propertyContainer.addChild(strLineEdit);
                }
                else if (value.getType() == VariantType.float) {
                    var floatSpinBox = new SpinBox();
                    floatSpinBox.maxValue = 3.40282347e+38;
                    floatSpinBox.minValue = -3.40282347e+38;
                    floatSpinBox.step = 0.001;
                    floatSpinBox.value = value;
                    floatSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    floatSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                        var dataToEdit = component.getData();
                        dataToEdit.set(key, newValue);
                        component.setData(dataToEdit);
                    }));
                    propertyContainer.addChild(floatSpinBox);
                }
                else if (value.getType() == VariantType.int) {
                    var intSpinBox = new SpinBox();
                    intSpinBox.maxValue = 2147483648;
                    intSpinBox.minValue = -2147483648;
                    intSpinBox.step = 1;
                    intSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    intSpinBox.valueChanged.connect(Callable.fromFunction(function(newValue: Float) {
                        var dataToEdit = component.getData();
                        var intValue = Std.int(newValue);
                        dataToEdit.set(key, intValue);
                        component.setData(dataToEdit);
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
                    }));
                    propertyContainer.addChild(boolCheckButton);
                }

                componentVbox.addChild(propertyContainer);
                propertyContainer.customMinimumSize = new Vector2(0.0, 20.0);
            }
        }
    }
}