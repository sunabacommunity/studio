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
import sunaba.core.Dictionary;
import sunaba.core.Vector3;
import sunaba.core.Variant;
import sunaba.core.Vector4;
import sunaba.core.Vector3i;
import sunaba.core.Vector4i;
import sunaba.ui.CenterContainer;

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
        if (sceneEditor != null) {
            sceneEditor.checkScene();
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
                        sceneEditor.checkScene();
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
                        sceneEditor.checkScene();
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
                    }
                }

                componentVbox.addChild(propertyContainer);
                propertyContainer.customMinimumSize = new Vector2(0.0, 20.0);
            }
        }

        var centerContainer = new CenterContainer();
        centerContainer.customMinimumSize = new Vector2(0.0, 50.0);

        var button = new Button();
        button.text = "Add Component";
        button.customMinimumSize = new Vector2(200.0, 0.0);
        button.alignment = HorizontalAlignment.center;

        centerContainer.addChild(button);
        entityVBox.addChild(centerContainer);
        sceneEditor.checkScene();
    }
}