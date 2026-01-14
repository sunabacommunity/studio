package sunaba.studio;

import sunaba.ui.CheckBox;
import sunaba.core.Vector4i;
import sunaba.core.Vector3i;
import sunaba.core.Vector2i;
import sunaba.core.Vector4;
import sunaba.core.Vector3;
import sunaba.ui.CheckButton;
import sunaba.ui.SpinBox;
import sunaba.ui.LineEdit;
import sunaba.ui.Label;
import sunaba.ui.HBoxContainer;
import sunaba.core.Dictionary;
import sunaba.ui.VBoxContainer;
import sunaba.ui.Button;
import sunaba.ui.OptionButton;
import sunaba.core.Vector2;
import sunaba.core.VariantType;

class ResourceInspector extends EditorWidget {
    public var resourceList: Map<Int, Dictionary> = new Map();
    public var scriptableObjectList: Map<Int, Dictionary> = new Map();
    public var assetEntities: Map<Int, Entity> = new Map();
    public var assetParentResources: Map<Int, Dictionary> = new Map();
    public var assetParentObjects: Map<Int, Dictionary> = new Map();
    public var assetNames: Map<Int, String> = new Map();

    private var objectIndex: Int = -1;

    private var selectedIndex: Int = -1;

    public var saveButton: Button;
    public var closeButton: Button;

    public var currentResourceButton: OptionButton;

    public var inspectorVbox: VBoxContainer;

    public override function editorInit() {
        load("studio://ResourceInspector.suml");
        getEditor().setRightSiderbarTabIcon(this, getEditor().loadIcon("studio://icons/16_1-5x/document--pencil.png"));
        customMinimumSize = new Vector2(275, 0);

        saveButton = getNodeT(Button, "vbox/toolbar/hbox/save");
        closeButton = getNodeT(Button, "vbox/toolbar/hbox/close");

        currentResourceButton = getNodeT(OptionButton, "vbox/currentResource");
        currentResourceButton.itemSelected.add((idx: Int) -> {
            for (key in resourceList.keys()) {
                if (key == idx) {
                    selectedIndex = idx;
                    buildInspectorFromResource();
                    return;
                }
            }
            for (key in scriptableObjectList.keys()) {
                if (key == idx) {
                    selectedIndex = idx;
                    buildInspectorFromObject();
                    return;
                }
            }
        });

        inspectorVbox = getNodeT(VBoxContainer, "vbox/scroll/vbox");
    }

    public function openResource(res: Dictionary, parentDictIsResource: Bool = false, ?name: String, ?entity: Entity, ?parentAsset: Dictionary) {
        var listContainsResource = false;
        for (index in resourceList.keys()) {
            if (JSON.stringify(resourceList[index]) == JSON.stringify(res)) {
                if (assetNames[index] != name) {
                    if (entity != null) {
                        if (assetEntities[index] != entity) {
                            continue;
                        }
                    }
                    else if (parentAsset != null) {
                        if (parentDictIsResource == true) {
                            if (JSON.stringify(assetParentResources[selectedIndex]) != JSON.stringify(parentAsset)) {
                                continue;
                            }
                        }
                        else {
                            if (JSON.stringify(assetParentObjects[selectedIndex]) != JSON.stringify(parentAsset)) {
                                continue;
                            }
                        }
                    }
                }
                listContainsResource = true;
                selectedIndex = index;
                break;
            }
        }
        if (listContainsResource == false) {
            objectIndex++;
            resourceList[objectIndex] = res;
            selectedIndex = objectIndex;
            
            if (entity != null) {
                assetEntities[objectIndex] = entity;
            }
            if (parentAsset != null) {
                if (parentDictIsResource == true) {
                    assetParentResources[selectedIndex] = parentAsset;
                }
                else {
                    assetParentObjects[selectedIndex] = parentAsset;
                }
            }

            var className = "Resource " + Std.string(objectIndex);
            if (res.get("value").toDictionary().get("path").toString() != "?") {
                className = res.get("value").toDictionary().get("path");
            }
            else if (res.get("value").toDictionary().get("class").getType() == VariantType.string){
                className += " (" +  res.get("value").toDictionary().get("class").toString() + ")";
            }
            if (name != null) {
                className = name;
            }
            assetNames[objectIndex] = className;
            currentResourceButton.addItem(className, objectIndex);
            currentResourceButton.selected = objectIndex;
        }

        getEditor().setCurrentRightSidebarChild(this);
        buildInspectorFromResource();
    }

    private inline function buildInspectorFromResource() {
        for (i in 0...inspectorVbox.getChildCount()) {
            var inspectorVboxChild = inspectorVbox.getChild(i);
            inspectorVboxChild.queueFree();
        }

        if (selectedIndex == -1) return;
        
        if (resourceList[selectedIndex] == null) {
            return;
        }

        var resourceData = resourceList[selectedIndex];
        var resourceDataValue: Dictionary = resourceData.get("value");

        var properties: Dictionary = resourceDataValue.get("properties");

        var propertyNames = properties.keys();
        for (i in 0...propertyNames.size()) {
            var propertyName = propertyNames.get(i);
            var propertyValue: Dictionary = properties.get(propertyName);

            if (propertyValue.has("type") && propertyValue.has("value")) {
                var propertyContainer = new HBoxContainer();
                var propertyLabel = new Label();
                propertyLabel.text = propertyName;
                propertyLabel.horizontalAlignment = HorizontalAlignment.left;
                propertyLabel.verticalAlignment = VerticalAlignment.center;
                propertyLabel.customMinimumSize = new Vector2(0.0, 20.0);
                propertyLabel.clipText = true;
                propertyContainer.addChild(propertyLabel);
                propertyLabel.sizeFlagsHorizontal = 3;

                var propertyType: Int = propertyValue.get("type");
                if (propertyType == VariantType.string) {
                    var strLineEdit = new LineEdit();
                    strLineEdit.text = propertyValue.get("value");
                    strLineEdit.customMinimumSize = new Vector2(150.0, 20.0);
                    strLineEdit.textChanged.add((newValue: String) -> {
                        propertyValue.set("value", newValue);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
                    propertyContainer.addChild(strLineEdit);
                }
                else if (propertyType == VariantType.float) {
                    var floatSpinBox = new SpinBox();
                    floatSpinBox.maxValue = 500;
                    floatSpinBox.minValue = -500;
                    floatSpinBox.allowGreater = true;
                    floatSpinBox.allowLesser = true;
                    floatSpinBox.step = 0.001;
                    floatSpinBox.value = propertyValue.get("value");
                    floatSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    floatSpinBox.valueChanged.add((newValue: Float) -> {
                        propertyValue.set("value", newValue);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
                    propertyContainer.addChild(floatSpinBox);
                }
                else if (propertyType == VariantType.int) {
                    var intSpinBox = new SpinBox();
                    intSpinBox.maxValue = 2147483648;
                    intSpinBox.minValue = -2147483648;
                    intSpinBox.allowGreater = true;
                    intSpinBox.allowLesser = true;
                    intSpinBox.step = 1;
                    intSpinBox.value = cast propertyValue.get("value").toInt();
                    intSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    intSpinBox.valueChanged.add((newValue: Float) -> {
                        propertyValue.set("value", Std.int(newValue));
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
                    propertyContainer.addChild(intSpinBox);
                }
                else if (propertyType == VariantType.bool) {
                    var boolCheckBox = new CheckBox();
                    boolCheckBox.buttonPressed = propertyValue.get("value");
                    boolCheckBox.customMinimumSize = new Vector2(0.0, 20.0);
                    boolCheckBox.flat = true;
                    boolCheckBox.toggled.add((newValue: Bool) -> {
                        propertyValue.set("value", newValue);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
                    propertyContainer.addChild(boolCheckBox);
                }
                else if (propertyType == VariantType.vector2) {
                    var vec2: Vector2 = DataUtils.dictToVar(propertyValue.get("value"));

                    var vec2Vbox = new VBoxContainer();

                    var xSpinBox = new SpinBox();
                    xSpinBox.maxValue = 500;
                    xSpinBox.minValue = -500;
                    xSpinBox.allowGreater = true;
                    xSpinBox.allowLesser = true;
                    xSpinBox.step = 0.001;
                    xSpinBox.value = vec2.x;
                    xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    xSpinBox.valueChanged.add((newValue: Float) -> {
                        vec2.x = newValue;
                        propertyValue = DataUtils.varToDict(vec2);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    ySpinBox.valueChanged.add((newValue: Float) -> {
                        vec2.y = newValue;
                        propertyValue = DataUtils.varToDict(vec2);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                else if (propertyType == VariantType.vector3) {
                    var vec3: Vector3 = DataUtils.dictToVar(propertyValue.get("value"));

                    var vec3Vbox = new VBoxContainer();

                    var xSpinBox = new SpinBox();
                    xSpinBox.maxValue = 500;
                    xSpinBox.minValue = -500;
                    xSpinBox.allowGreater = true;
                    xSpinBox.allowLesser = true;
                    xSpinBox.step = 0.001;
                    xSpinBox.value = vec3.x;
                    xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    xSpinBox.valueChanged.add((newValue: Float) -> {
                        vec3.x = newValue;
                        propertyValue = DataUtils.varToDict(vec3);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    ySpinBox.valueChanged.add((newValue: Float) -> {
                        vec3.y = newValue;
                        propertyValue = DataUtils.varToDict(vec3);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    zSpinBox.valueChanged.add((newValue: Float) -> {
                        vec3.z = newValue;
                        propertyValue = DataUtils.varToDict(vec3);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                else if (propertyType == VariantType.vector4) {
                    var vec4: Vector4 = DataUtils.dictToVar(propertyValue.get("value"));

                    var vec4Vbox = new VBoxContainer();

                    var xSpinBox = new SpinBox();
                    xSpinBox.maxValue = 500;
                    xSpinBox.minValue = -500;
                    xSpinBox.allowGreater = true;
                    xSpinBox.allowLesser = true;
                    xSpinBox.step = 0.001;
                    xSpinBox.value = vec4.x;
                    xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    xSpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.x = newValue;
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    ySpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.y = newValue;
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    zSpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.z = newValue;
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    wSpinBox.value = vec4.z;
                    wSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    wSpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.z = newValue;
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
                    var wLabel = new Label();
                    wLabel.text = "w";
                    wLabel.horizontalAlignment = HorizontalAlignment.center;
                    wLabel.verticalAlignment = VerticalAlignment.center;
                    var wHBox = new HBoxContainer();
                    wHBox.addChild(wLabel);
                    wHBox.addChild(wSpinBox);
                    vec4Vbox.addChild(zHBox);

                    propertyContainer.addChild(vec4Vbox);
                }
                else if (propertyType == VariantType.vector2i) {
                    var vec2: Vector2i = DataUtils.dictToVar(propertyValue.get("value"));

                    var vec2Vbox = new VBoxContainer();

                    var xSpinBox = new SpinBox();
                    xSpinBox.maxValue = 500;
                    xSpinBox.minValue = -500;
                    xSpinBox.allowGreater = true;
                    xSpinBox.allowLesser = true;
                    xSpinBox.step = 1;
                    xSpinBox.value = vec2.x;
                    xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    xSpinBox.valueChanged.add((newValue: Float) -> {
                        vec2.x = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec2);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    ySpinBox.valueChanged.add((newValue: Float) -> {
                        vec2.y = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec2);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                else if (propertyType == VariantType.vector3i) {
                    var vec3: Vector3i = DataUtils.dictToVar(propertyValue.get("value"));

                    var vec3Vbox = new VBoxContainer();

                    var xSpinBox = new SpinBox();
                    xSpinBox.maxValue = 500;
                    xSpinBox.minValue = -500;
                    xSpinBox.allowGreater = true;
                    xSpinBox.allowLesser = true;
                    xSpinBox.step = 1;
                    xSpinBox.value = vec3.x;
                    xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    xSpinBox.valueChanged.add((newValue: Float) -> {
                        vec3.x = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec3);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    ySpinBox.valueChanged.add((newValue: Float) -> {
                        vec3.y = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec3);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    zSpinBox.valueChanged.add((newValue: Float) -> {
                        vec3.z = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec3);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                else if (propertyType == VariantType.vector4i) {
                    var vec4: Vector4i = DataUtils.dictToVar(propertyValue.get("value"));

                    var vec4Vbox = new VBoxContainer();

                    var xSpinBox = new SpinBox();
                    xSpinBox.maxValue = 500;
                    xSpinBox.minValue = -500;
                    xSpinBox.allowGreater = true;
                    xSpinBox.allowLesser = true;
                    xSpinBox.step = 1;
                    xSpinBox.value = vec4.x;
                    xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    xSpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.x = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    ySpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.y = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    zSpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.z = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
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
                    wSpinBox.value = vec4.z;
                    wSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                    wSpinBox.valueChanged.add((newValue: Float) -> {
                        vec4.z = Std.int(newValue);
                        propertyValue = DataUtils.varToDict(vec4);
                        properties.set(propertyName, propertyValue);
                        resourceDataValue.set("properties", properties);
                        resourceData.set("value", resourceDataValue);
                        resourceList[selectedIndex] = resourceData;
                    });
                    var wLabel = new Label();
                    wLabel.text = "w";
                    wLabel.horizontalAlignment = HorizontalAlignment.center;
                    wLabel.verticalAlignment = VerticalAlignment.center;
                    var wHBox = new HBoxContainer();
                    wHBox.addChild(wLabel);
                    wHBox.addChild(wSpinBox);
                    vec4Vbox.addChild(zHBox);

                    propertyContainer.addChild(vec4Vbox);
                }

                inspectorVbox.addChild(propertyContainer);
            }
        }
    }

    public function openScriptableObject(sobj: Dictionary, ?name: String, ?entity: Entity, ?parentObject: Dictionary) {
        var listContainsObject = false;
        for (index in scriptableObjectList.keys()) {
            if (JSON.stringify(scriptableObjectList[index]) == JSON.stringify(sobj)) {
                if (assetNames[index] != name) {
                    if (entity != null) {
                        if (assetEntities[index] != entity) {
                            continue;
                        }
                    }
                    else if (parentObject != null) {
                        if (JSON.stringify(assetParentObjects[selectedIndex]) != JSON.stringify(parentObject)) {
                            continue;
                        }
                    }
                }
                listContainsObject = true;
                selectedIndex = index;
                break;
            }
        }
        if (listContainsObject == false) {
            objectIndex++;
            scriptableObjectList[objectIndex] = sobj;
            selectedIndex = objectIndex;
            if (entity != null) {
                assetEntities[objectIndex] = entity;
            }
            if (parentObject != null) {
                assetParentObjects[selectedIndex] = parentObject;
            }

            var className = "Scriptable Object " + Std.string(objectIndex);
            if (sobj.get("path").toString() != "?") {
                className = sobj.get("path");
            }
            else if (sobj.get("classType").getType() == VariantType.string){
                className += " (" +  sobj.get("classType").toString() + ")";
            }
            if (name  != null) {
                className = name;
            }
            assetNames[objectIndex] = className;
            currentResourceButton.addItem(className, objectIndex);
            currentResourceButton.selected = objectIndex;
        }

        getEditor().setCurrentRightSidebarChild(this);
        buildInspectorFromObject();
    }

    private inline function buildInspectorFromObject() {
        for (i in 0...inspectorVbox.getChildCount()) {
            var inspectorVboxChild = inspectorVbox.getChild(i);
            inspectorVboxChild.queueFree();
        }

        if (selectedIndex == -1) return;

        if (scriptableObjectList[selectedIndex] == null) {
            return;
        }

        var objectData = scriptableObjectList[selectedIndex];
        
        var propertyNames = objectData.keys();
        for (i in 0...propertyNames.size()) {
            var propertyName = propertyNames.get(i);
            var propertyValue = objectData.get(propertyName);

            var propertyContainer = new HBoxContainer();
            var propertyLabel = new Label();
            propertyLabel.text = propertyName;
            propertyLabel.horizontalAlignment = HorizontalAlignment.left;
            propertyLabel.verticalAlignment = VerticalAlignment.center;
            propertyLabel.customMinimumSize = new Vector2(0.0, 20.0);
            propertyLabel.clipText = true;
            propertyContainer.addChild(propertyLabel);
            propertyLabel.sizeFlagsHorizontal = 3;

            if (propertyValue.getType() == VariantType.string) {
                var strLineEdit = new LineEdit();
                strLineEdit.text = propertyValue;
                strLineEdit.customMinimumSize = new Vector2(150.0, 20.0);
                strLineEdit.textChanged.add((newValue: String) -> {
                    objectData.set(propertyName, newValue);
                    scriptableObjectList[selectedIndex] = objectData;
                });
                propertyContainer.addChild(strLineEdit);
            }
            else if (propertyValue.getType() == VariantType.float) {
                var floatSpinBox = new SpinBox();
                floatSpinBox.maxValue = 500;
                floatSpinBox.minValue = -500;
                floatSpinBox.allowGreater = true;
                floatSpinBox.allowLesser = true;
                floatSpinBox.step = 0.001;
                floatSpinBox.value = propertyValue;
                floatSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                floatSpinBox.valueChanged.add((newValue: Float) -> {
                    objectData.set(propertyName, newValue);
                    scriptableObjectList[selectedIndex] = objectData;
                });
                propertyContainer.addChild(floatSpinBox);
            }
            else if (propertyValue.getType() == VariantType.int) {
                var floatSpinBox = new SpinBox();
                floatSpinBox.maxValue = 2147483648;
                floatSpinBox.minValue = -2147483648;
                floatSpinBox.allowGreater = true;
                floatSpinBox.allowLesser = true;
                floatSpinBox.step = 0.001;
                floatSpinBox.value = propertyValue.toInt();
                floatSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                floatSpinBox.valueChanged.add((newValue: Float) -> {
                    objectData.set(propertyName, Std.int(newValue));
                    scriptableObjectList[selectedIndex] = objectData;
                });
                propertyContainer.addChild(floatSpinBox);
            }
            else if (propertyValue.getType() == VariantType.bool) {
                var boolCheckBox = new CheckBox();
                boolCheckBox.buttonPressed = propertyValue;
                boolCheckBox.customMinimumSize = new Vector2(0.0, 20.0);
                boolCheckBox.flat = true;
                boolCheckBox.toggled.add((newValue: Bool) -> {
                    objectData.set(propertyName, newValue);
                    scriptableObjectList[selectedIndex] = objectData;
                });
                propertyContainer.addChild(boolCheckBox);
            }
            else if (propertyValue.getType() == VariantType.dictionary) {
                var propertyDict: Dictionary = propertyValue;
                if (propertyDict.has("type") && propertyDict.has("value")) {
                    var propertyDictType = propertyDict.get("type").toInt();
                    var propertyDictValue = propertyDict.get("value");
                    if (propertyDictType == VariantType.vector2) {
                        var vec2: Vector2 = DataUtils.dictToVar(propertyDict);

                        var vec2Vbox = new VBoxContainer();

                        var xSpinBox = new SpinBox();
                        xSpinBox.maxValue = 500;
                        xSpinBox.minValue = -500;
                        xSpinBox.allowGreater = true;
                        xSpinBox.allowLesser = true;
                        xSpinBox.step = 0.001;
                        xSpinBox.value = vec2.x;
                        xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                        xSpinBox.valueChanged.add((newValue: Float) -> {
                            vec2.x = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec2));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        ySpinBox.valueChanged.add((newValue: Float) -> {
                            vec2.y = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec2));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                    else if (propertyDictType == VariantType.vector3) {
                        var vec3: Vector3 = DataUtils.dictToVar(propertyDict);

                        var vec3Vbox = new VBoxContainer();

                        var xSpinBox = new SpinBox();
                        xSpinBox.maxValue = 500;
                        xSpinBox.minValue = -500;
                        xSpinBox.allowGreater = true;
                        xSpinBox.allowLesser = true;
                        xSpinBox.step = 0.001;
                        xSpinBox.value = vec3.x;
                        xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                        xSpinBox.valueChanged.add((newValue: Float) -> {
                            vec3.x = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec3));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        ySpinBox.valueChanged.add((newValue: Float) -> {
                            vec3.y = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec3));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        zSpinBox.valueChanged.add((newValue: Float) -> {
                            vec3.z = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec3));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                    else if (propertyDictType == VariantType.vector4) {
                        var vec4: Vector4 = DataUtils.dictToVar(propertyDict);

                        var vec4Vbox = new VBoxContainer();

                        var xSpinBox = new SpinBox();
                        xSpinBox.maxValue = 500;
                        xSpinBox.minValue = -500;
                        xSpinBox.allowGreater = true;
                        xSpinBox.allowLesser = true;
                        xSpinBox.step = 0.001;
                        xSpinBox.value = vec4.x;
                        xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                        xSpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.x = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        ySpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.y = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        zSpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.z = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        wSpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.w = newValue;
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
                        var wLabel = new Label();
                        wLabel.text = "w";
                        wLabel.horizontalAlignment = HorizontalAlignment.center;
                        wLabel.verticalAlignment = VerticalAlignment.center;
                        var wHBox = new HBoxContainer();
                        wHBox.addChild(wLabel);
                        wHBox.addChild(wSpinBox);
                        vec4Vbox.addChild(wHBox);

                        propertyContainer.addChild(vec4Vbox);
                    }
                    else if (propertyDictType == VariantType.vector2i) {
                        var vec2: Vector2i = DataUtils.dictToVar(propertyDict);

                        var vec2Vbox = new VBoxContainer();

                        var xSpinBox = new SpinBox();
                        xSpinBox.maxValue = 500;
                        xSpinBox.minValue = -500;
                        xSpinBox.allowGreater = true;
                        xSpinBox.allowLesser = true;
                        xSpinBox.step = 1;
                        xSpinBox.value = vec2.x;
                        xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                        xSpinBox.valueChanged.add((newValue: Float) -> {
                            vec2.x = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec2));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        ySpinBox.valueChanged.add((newValue: Float) -> {
                            vec2.y = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec2));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                    else if (propertyDictType == VariantType.vector3i) {
                        var vec3: Vector3i = DataUtils.dictToVar(propertyDict);

                        var vec3Vbox = new VBoxContainer();

                        var xSpinBox = new SpinBox();
                        xSpinBox.maxValue = 500;
                        xSpinBox.minValue = -500;
                        xSpinBox.allowGreater = true;
                        xSpinBox.allowLesser = true;
                        xSpinBox.step = 1;
                        xSpinBox.value = vec3.x;
                        xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                        xSpinBox.valueChanged.add((newValue: Float) -> {
                            vec3.x = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec3));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        ySpinBox.valueChanged.add((newValue: Float) -> {
                            vec3.y = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec3));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        zSpinBox.valueChanged.add((newValue: Float) -> {
                            vec3.z = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec3));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                    else if (propertyDictType == VariantType.vector4i) {
                        var vec4: Vector4i = DataUtils.dictToVar(propertyDict);

                        var vec4Vbox = new VBoxContainer();

                        var xSpinBox = new SpinBox();
                        xSpinBox.maxValue = 500;
                        xSpinBox.minValue = -500;
                        xSpinBox.allowGreater = true;
                        xSpinBox.allowLesser = true;
                        xSpinBox.step = 1;
                        xSpinBox.value = vec4.x;
                        xSpinBox.customMinimumSize = new Vector2(150.0, 20.0);
                        xSpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.x = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        ySpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.y = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        zSpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.z = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
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
                        wSpinBox.valueChanged.add((newValue: Float) -> {
                            vec4.w = Std.int(newValue);
                            objectData.set(propertyName, DataUtils.varToDict(vec4));
                            scriptableObjectList[selectedIndex] = objectData;
                        });
                        var wLabel = new Label();
                        wLabel.text = "w";
                        wLabel.horizontalAlignment = HorizontalAlignment.center;
                        wLabel.verticalAlignment = VerticalAlignment.center;
                        var wHBox = new HBoxContainer();
                        wHBox.addChild(wLabel);
                        wHBox.addChild(wSpinBox);
                        vec4Vbox.addChild(wHBox);

                        propertyContainer.addChild(vec4Vbox);
                    }
                    else if (propertyDictType == VariantType.object) {
                        var resButton = new Button();
                        resButton.text = "Edit";
                        resButton.customMinimumSize = new Vector2(150.0, 20.0);
                        resButton.pressed.add(() -> {
                            openResource(propertyDict, false, propertyName, null, objectData);
                        });

                        propertyContainer.addChild(resButton);
                    }
                }
                else if (propertyDict.has("path") && propertyDict.has("classType")) {
                    var resButton = new Button();
                    resButton.text = "Edit";
                    resButton.customMinimumSize = new Vector2(150.0, 20.0);
                    resButton.pressed.add(() -> {
                        openScriptableObject(propertyDict, propertyName, null, objectData);
                    });

                    propertyContainer.addChild(resButton);
                }
            }
        }
    }
}