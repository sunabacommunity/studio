package sunaba.studio;

import sunaba.spatial.Headwear;
import sunaba.ui.TreeItem;
import sunaba.core.native.NativeObject;
import sunaba.core.Vector2i;
import sunaba.spatial.FaceTextureData;
import sunaba.spatial.Clothing;
import sunaba.core.Vector2;
import sunaba.ui.ItemList;
import sunaba.ui.OptionButton;
import sunaba.ui.HSlider;
import sunaba.ui.HBoxContainer;
import sunaba.ui.Control;
import sunaba.ui.ColorPickerButton;
import sunaba.ui.LineEdit;
import sunaba.ui.SpinBox;
import sunaba.ui.Tree;
import sunaba.ui.VBoxContainer;
import sunaba.desktop.PopupMenu;
import sunaba.spatial.BodyType;
import sunaba.spatial.CharacterData;
import sunaba.ui.ColorPicker;
import sunaba.core.Color;
import sunaba.ui.TabContainer;
import sunaba.ui.Button;
import sunaba.core.Variant;

class CharacterEditor extends EditorWidget {
    public var characterViewer: CharacterViewer = null;
    
    public  var data(get, set): CharacterData;
    function get_data():CharacterData {
        return characterViewer.data;
    }
    function set_data(value:CharacterData):CharacterData {
        return characterViewer.data = value;
    }


    private var vbox: Control = null;
    private var tabs: TabContainer;

    private var nameLineEdit: LineEdit;
    private var descLineEdit: LineEdit;
    private var bodyTypeOptionButton: OptionButton;
    private var bodyTypeOptionPopup(get, default): PopupMenu;
    inline function get_bodyTypeOptionPopup(): PopupMenu {
        return bodyTypeOptionButton.getPopup();
    }
    private var skinColorButton: ColorPickerButton;
    private var skinColorPicker(get, default): ColorPicker;
    function get_skinColorPicker():ColorPicker {
        return skinColorButton.getPicker();
    }

    private var maleArmVBox: VBoxContainer;
    private var maleArmSpinBox: SpinBox;
    private var maleArmHSlider: HSlider;
    private var femaleChestVBox: VBoxContainer;
    private var femaleChestSpinBox: SpinBox;
    private var femaleChestHSlider: HSlider;
    private var legSpinBox: SpinBox;
    private var legHSlider: HSlider;

    private var faceItemList: ItemList;
    private var headwearItemList: ItemList;
    private var headwearTree: Tree;
    private var clothingItemList: ItemList;
    private var clothingTree: Tree;
    private var dressItemList: ItemList;
    private var dressControl: Control;

    public override function editorInit() {
        load("studio://CharacterEditor.suml");

        vbox = getNodeT(Control, "vbox");
        vbox.hide();
        tabs = getNodeT(TabContainer, "vbox/tabs");

        faceTextureIndex = new Map();
        headwearIndex = new Map();
        clothingIndex = new Map();

        nameLineEdit = getNodeT(LineEdit, "vbox/tabs/Body/hbox/vbox/name/lineEdit");
        nameLineEdit.textChanged.add((newText: String) -> {
            data.name = newText;
        });
        descLineEdit = getNodeT(LineEdit, "vbox/tabs/Body/hbox/vbox/desc/lineEdit");
        descLineEdit.textChanged.add((newText: String) -> {
            data.desc = newText;
        });
        bodyTypeOptionButton = getNodeT(OptionButton, "vbox/tabs/Body/hbox/vbox/bodyType/optionButton");
        bodyTypeOptionButton.itemSelected.add((index: Int) -> {
            data.bodyType = index;
            if (data.bodyType == BodyType.male) {
                maleArmVBox.visible = true;
                femaleChestVBox.visible = false;
                tabs.setTabDisabled(4, true);
            }
            else {
                maleArmVBox.visible = false;
                femaleChestVBox.visible = true;
                tabs.setTabDisabled(4, false);
            }
        });
        bodyTypeOptionPopup.addItem("Male", BodyType.male);
        bodyTypeOptionPopup.addItem("Female", BodyType.female);
        skinColorButton = getNodeT(ColorPickerButton, "vbox/tabs/Body/hbox/vbox/skinColor/colorButton");
        skinColorButton.colorChanged.add((color: Variant) -> {
            data.skinTone = color;
        });
        skinColorPicker.addPreset(Color.html("#ffdbac"));
        skinColorPicker.addPreset(Color.html("#f1c27d"));
        skinColorPicker.addPreset(Color.html("#e0ac69"));
        skinColorPicker.addPreset(Color.html("#c68642"));
        skinColorPicker.addPreset(Color.html("#8d5524"));

        maleArmVBox = getNodeT(VBoxContainer, "vbox/tabs/Body/hbox/vbox2/arm");
        maleArmSpinBox = getNodeT(SpinBox, "vbox/tabs/Body/hbox/vbox2/arm/spinbox");
        maleArmSpinBox.minValue = 0.0;
        maleArmSpinBox.maxValue = 1.0;
        maleArmSpinBox.step = 0.01;
        maleArmSpinBox.valueChanged.add((value: Float) -> {
            data.maleArmThickness = value;
            maleArmHSlider.value = value;
        });
        maleArmHSlider = getNodeT(HSlider, "vbox/tabs/Body/hbox/vbox2/arm/hslider");
        maleArmHSlider.minValue = 0.0;
        maleArmHSlider.maxValue = 1.0;
        maleArmHSlider.step = 0.01;
        maleArmHSlider.valueChanged.add((value: Float) -> {
            data.maleArmThickness = value;
            maleArmSpinBox.value = value;
        });
        femaleChestVBox = getNodeT(VBoxContainer, "vbox/tabs/Body/hbox/vbox2/chest");
        femaleChestSpinBox = getNodeT(SpinBox, "vbox/tabs/Body/hbox/vbox2/chest/spinbox");
        femaleChestSpinBox.minValue = 0.0;
        femaleChestSpinBox.maxValue = 1.0;
        femaleChestSpinBox.step = 0.01;
        femaleChestSpinBox.valueChanged.add((value: Float) -> {
            data.femaleChestSize = value;
            femaleChestHSlider.value = value;
        });
        femaleChestHSlider = getNodeT(HSlider, "vbox/tabs/Body/hbox/vbox2/chest/hslider");
        femaleChestHSlider.minValue = 0.0;
        femaleChestHSlider.maxValue = 1.0;
        femaleChestHSlider.step = 0.01;
        femaleChestHSlider.valueChanged.add((value: Float) -> {
            data.femaleChestSize = value;
            femaleChestSpinBox.value = value;
        });
        legSpinBox = getNodeT(SpinBox, "vbox/tabs/Body/hbox/vbox2/legs/spinbox");
        legSpinBox.minValue = 0.0;
        legSpinBox.maxValue = 1.0;
        legSpinBox.step = 0.01;
        legSpinBox.valueChanged.add((value: Float) -> {
            data.legThickness = value;
            legHSlider.value = value;
        });
        legHSlider = getNodeT(HSlider, "vbox/tabs/Body/hbox/vbox2/legs/hslider");
        legHSlider.minValue = 0.0;
        legHSlider.maxValue = 1.0;
        legHSlider.step = 0.01;
        legHSlider.valueChanged.add((value: Float) -> {
            data.legThickness = value;
            legSpinBox.value = value;
        });

        faceItemList = getNodeT(ItemList, "vbox/tabs/Face/itemList");
        faceItemList.fixedIconSize = new Vector2i(64, 64);
        faceItemList.maxColumns = 0;
        faceItemList.iconMode = 0;
        faceItemList.fixedColumnWidth = 160;
        headwearItemList = getNodeT(ItemList, "vbox/tabs/Headwear/hbox/itemList");
        headwearItemList.fixedIconSize = new Vector2i(64, 64);
        headwearItemList.maxColumns = 0;
        headwearItemList.iconMode = 0;
        headwearItemList.fixedColumnWidth = 160;
        headwearTree = getNodeT(Tree, "vbox/tabs/Headwear/hbox/tree");
        clothingItemList = getNodeT(ItemList, "vbox/tabs/Clothes/hbox/itemList");
        clothingItemList.fixedIconSize = new Vector2i(64, 64);
        clothingItemList.maxColumns = 0;
        clothingItemList.iconMode = 0;
        clothingItemList.fixedColumnWidth = 160;
        clothingTree = getNodeT(Tree, "vbox/tabs/Clothes/hbox/tree");
        dressItemList = getNodeT(ItemList, "vbox/tabs/Dress/itemList");
        dressItemList.fixedIconSize = new Vector2i(64, 64);
        dressItemList.maxColumns = 0;
        dressItemList.iconMode = 0;
        dressItemList.fixedColumnWidth = 160;
        dressControl = getNodeT(Control, "vbox/tabs/Dress");

        faceItemList.itemSelected.add((index: Int) -> {
            var faceTexture = faceTextureIndex[index];
            data.faceTexture = faceTexture;
        });
        
        headwearItemList.itemActivated.add((index: Int) -> {
            var headwear = headwearIndex[index];
            data.headwearList.push(headwear);
            refresh();
        });

        headwearTree.buttonClicked.add((itemNative: NativeObject, column: Int, id: Int, mouseButtonIdx: Int) -> {
            var item = new TreeItem(itemNative);
            if (column == 0) {
                if (id == 0) {
                    if (mouseButtonIdx == 1) {
                        var headwearMetadata: Int = item.getMetadata(0);
                        data.headwearList.remove(data.headwearList[headwearMetadata]);
                        refresh();
                    }
                }
            }
        });
        
        clothingItemList.itemActivated.add((index: Int) -> {
            var clothing = clothingIndex[index];
            data.clothes.push(clothing);
            refresh();
        });

        clothingTree.buttonClicked.add((itemNative: NativeObject, column: Int, id: Int, mouseButtonIdx: Int) -> {
            var item = new TreeItem(itemNative);
            if (column == 0) {
                if (id == 0) {
                    if (mouseButtonIdx == 1) {
                        var clothingMetadata: Int = item.getMetadata(0);
                        data.clothes.remove(data.clothes[clothingMetadata]);
                        refresh();
                    }
                }
            }
        });

        var applyButton = getNodeT(Button, "vbox/hbox/apply");
        applyButton.pressed.add(() -> {
            characterViewer.apply();
        });

        var minimumSize = customMinimumSize;
        minimumSize.y = 315;
        customMinimumSize = minimumSize;

        getEditor().setDockTabTitle(this, "Character Editor");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/toilet-male-edit.png"));
    }

    public function openCharacterViewer(viewer: CharacterViewer) {
        characterViewer = viewer;
        if (characterViewer == null) {
            vbox.hide();
            return;
        }

        refresh();

        vbox.show();
    }

    public var faceTextureIndex: Map<Int, FaceTextureData>;

    public var headwearIndex: Map<Int, Headwear>;

    public var clothingIndex: Map<Int, Clothing>;

    public function refresh() {
        nameLineEdit.text = data.name;
        descLineEdit.text = data.desc;
        bodyTypeOptionButton.selected = data.bodyType;
        skinColorButton.color = data.skinTone;

        maleArmSpinBox.value = data.maleArmThickness;
        maleArmHSlider.value = data.maleArmThickness;
        femaleChestSpinBox.value = data.femaleChestSize;
        femaleChestHSlider.value = data.femaleChestSize;
        legSpinBox.value = data.legThickness;
        legHSlider.value = data.legThickness;

        if (data.bodyType == BodyType.male) {
            maleArmVBox.visible = true;
            femaleChestVBox.visible = false;
            tabs.setTabDisabled(4, true);
        }
        else {
            maleArmVBox.visible = false;
            femaleChestVBox.visible = true;
            tabs.setTabDisabled(4, false);
        }

        var faceTextureList = io.getFileListAll(".ftd");
        var faceTextureList2 = io.getFileListAll(".ftd.dat");
        for (i in 0...faceTextureList2.size()) {
            var faceTexturePath = faceTextureList2.get(i);
            faceTextureList.append(faceTexturePath);
        }
        faceItemList.clear();
        for (i in 0...faceTextureList.size()) {
            var faceTexturePath = faceTextureList.get(i);
            var faceTextureData = new FaceTextureData();
            faceTextureData.load(faceTexturePath);

            var item = faceItemList.addItem(faceTextureData.name, faceTextureData.texture, true);
            faceTextureIndex[item] = faceTextureData;
        }

        var headwearList = io.getFileListAll(".vhw");
        var headwearList2 = io.getFileListAll(".vhw.dat");
        for (i in 0...headwearList2.size()) {
            var headwearPath = headwearList2.get(i);
            headwearList.append(headwearPath);
        }
        headwearItemList.clear();
        for (i in 0...headwearList.size()) {
            var headwearPath = headwearList.get(i);
            var headwearData = new Headwear();
            headwearData.load(headwearPath);

            var item = headwearItemList.addItem(headwearData.name, getEditor().loadIcon("studio://icons/16_2x/snowman-hat.png"), true);
            headwearIndex[item] = headwearData;
        }
        headwearTree.clear();
        headwearTree.hideRoot = true;
        var headwearTreeRoot = headwearTree.createItem();
        for (headwearData in data.headwearList) {
            var item = headwearTree.createItem(headwearTreeRoot);
            item.setText(0, headwearData.name);
            item.setMetadata(0, getEditor().loadIcon("studio://icons/16/cross.png"));
            item.addButton(0, getEditor().loadIcon("studio://icons/16/cross.png"));
        }

        var clothingList = io.getFileListAll(".vclt");
        var clothingList2 = io.getFileListAll(".vclt.dat");
        for (i in 0...clothingList2.size()) {
            var clothingPath = clothingList2.get(i);
            clothingList.append(clothingPath);
        }
        clothingItemList.clear();
        for (i in 0...clothingList.size()) {
            var clothingPath = clothingList.get(i);
            var clothingData = new Clothing();
            clothingData.load(clothingPath);

            var item = clothingItemList.addItem(clothingData.name, clothingData.texture, true);
            clothingIndex[item] = clothingData;
        }
        clothingTree.clear();
        clothingTree.hideRoot = true;
        var clothingTreeRoot = clothingTree.createItem();
        for (clothingItem in data.clothes) {
            var item = clothingTree.createItem(clothingTreeRoot);
            item.setText(0, clothingItem.name);
            item.setMetadata(0, data.clothes.indexOf(clothingItem));
            item.addButton(0, getEditor().loadIcon("studio://icons/16/cross.png"));
        }
    }
}