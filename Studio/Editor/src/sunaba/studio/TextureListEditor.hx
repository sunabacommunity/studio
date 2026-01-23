package sunaba.studio;

import sunaba.desktop.FileDialog;
import sunaba.spatial.BaseTextures;
import sunaba.core.Vector2i;
import sunaba.desktop.ConfirmationDialog;
import sunaba.ui.TreeItem;
import sunaba.ui.Tree;
import sunaba.ui.Button;
import sunaba.ui.MenuButton;
import haxe.Json;
import sunaba.ui.Widget;
import sunaba.core.VariantType;

class TextureListEditor extends Widget {
    public var editor: Editor;

    var texturePathList: Array<String> = new Array();

    var addButton: MenuButton;
    var removeButton: Button;
    var tree: Tree;

    var selectedTexturePath: String = "";

    public override function init() {
        load("studio://TextureListEditor.suml");

        addButton = getNodeT(MenuButton, "vbox/topbar/hbox/add");
        removeButton = getNodeT(Button, "vbox/topbar/hbox/remove");
        tree = getNodeT(Tree, "vbox/tree");
        tree.hideRoot = true;
        
        tree.itemSelected.add(() -> {
            var item = tree.getSelected();
            selectedTexturePath = item.getText(0);
        });
        tree.nothingSelected.add(() -> {
            selectedTexturePath = "";
        });

        addButton.flat = false;
        var addButtonPopup = addButton.getPopup();
        addButtonPopup.addItem("Builtin path", 0);
        addButtonPopup.addItem("Project path", 1);
        addButtonPopup.idPressed.add((id: Int) -> {
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
                        addTexturePath(selectedItem);
                    }
                    confirmDialog.queueFree();
                });
                confirmDialog.confirmed.add(() -> {
                    trace(selectedItem);
                    if (selectedItem != null) {
                        addTexturePath(selectedItem);
                    }
                    confirmDialog.queueFree();
                });
                confirmDialog.canceled.add(() -> {
                    confirmDialog.queueFree();
                });
                confirmDialog.closeRequested.add(() -> {
                    confirmDialog.queueFree();
                });

                var baseTexturesItem = confirmDialogTree.createItem(confirmDialogTreeRoot);
                baseTexturesItem.setText(0, "Base Textures");

                var addBaseTexturePathItem = (path: String) -> {
                    var pathItem = confirmDialogTree.createItem(baseTexturesItem);
                    pathItem.setText(0, path);
                    pathItem.setMetadata(0, path);
                    pathItem.setIcon(0, editor.loadIcon("studio://icons/16/images-stack.png"));
                }

                addBaseTexturePathItem(BaseTextures.Grass3D);
                addBaseTexturePathItem(BaseTextures.Animal);
                addBaseTexturePathItem(BaseTextures.BlackAsphalt);
                addBaseTexturePathItem(BaseTextures.BlueNebula);
                addBaseTexturePathItem(BaseTextures.Box);
                addBaseTexturePathItem(BaseTextures.Brick);
                addBaseTexturePathItem(BaseTextures.Brick2);
                addBaseTexturePathItem(BaseTextures.Brick3);
                addBaseTexturePathItem(BaseTextures.BrushedAluminum);
                addBaseTexturePathItem(BaseTextures.Building);
                addBaseTexturePathItem(BaseTextures.BumpySky);
                addBaseTexturePathItem(BaseTextures.CartoonGrass);
                addBaseTexturePathItem(BaseTextures.Cloth);
                addBaseTexturePathItem(BaseTextures.CloudySky);
                addBaseTexturePathItem(BaseTextures.Colors);
                addBaseTexturePathItem(BaseTextures.Concrete);
                addBaseTexturePathItem(BaseTextures.CrateFactory);
                addBaseTexturePathItem(BaseTextures.DiamondPlate);
                addBaseTexturePathItem(BaseTextures.Dirt);
                addBaseTexturePathItem(BaseTextures.DnaLavalamp);
                addBaseTexturePathItem(BaseTextures.Electricity);
                addBaseTexturePathItem(BaseTextures.Elements);
                addBaseTexturePathItem(BaseTextures.Elements2);
                addBaseTexturePathItem(BaseTextures.Explosion);
                addBaseTexturePathItem(BaseTextures.FadingSky);
                addBaseTexturePathItem(BaseTextures.Fire);
                addBaseTexturePathItem(BaseTextures.FuzzySky);
                addBaseTexturePathItem(BaseTextures.Gem);
                addBaseTexturePathItem(BaseTextures.GradientSky);
                addBaseTexturePathItem(BaseTextures.Grass);
                addBaseTexturePathItem(BaseTextures.Grass2);
                addBaseTexturePathItem(BaseTextures.Grating);
                addBaseTexturePathItem(BaseTextures.GreenNebula);
                addBaseTexturePathItem(BaseTextures.Ground);
                addBaseTexturePathItem(BaseTextures.HazardStripes);
                addBaseTexturePathItem(BaseTextures.Ice);
                addBaseTexturePathItem(BaseTextures.LavaGlow);
                addBaseTexturePathItem(BaseTextures.Metal);
                addBaseTexturePathItem(BaseTextures.Metal2);
                addBaseTexturePathItem(BaseTextures.Misc);
                addBaseTexturePathItem(BaseTextures.MoreRoughWood);
                addBaseTexturePathItem(BaseTextures.Neon);
                addBaseTexturePathItem(BaseTextures.OldWoodPanel);
                addBaseTexturePathItem(BaseTextures.Organic);
                addBaseTexturePathItem(BaseTextures.Paper);
                addBaseTexturePathItem(BaseTextures.ParquetRough);
                addBaseTexturePathItem(BaseTextures.Pebbles);
                addBaseTexturePathItem(BaseTextures.Plant);
                addBaseTexturePathItem(BaseTextures.Plaster);
                addBaseTexturePathItem(BaseTextures.PuffySky);
                addBaseTexturePathItem(BaseTextures.PurpleNebula);
                addBaseTexturePathItem(BaseTextures.RoadTexture);
                addBaseTexturePathItem(BaseTextures.Roof);
                addBaseTexturePathItem(BaseTextures.Roof2);
                addBaseTexturePathItem(BaseTextures.Route66);
                addBaseTexturePathItem(BaseTextures.Rust);
                addBaseTexturePathItem(BaseTextures.Sand);
                addBaseTexturePathItem(BaseTextures.SandRiple);
                addBaseTexturePathItem(BaseTextures.SimpleSky);
                addBaseTexturePathItem(BaseTextures.Starfields);
                addBaseTexturePathItem(BaseTextures.Stone);
                addBaseTexturePathItem(BaseTextures.Stone2);
                addBaseTexturePathItem(BaseTextures.SwissCheese);
                addBaseTexturePathItem(BaseTextures.Terrain);
                addBaseTexturePathItem(BaseTextures.Tile);
                addBaseTexturePathItem(BaseTextures.Tile2);
                addBaseTexturePathItem(BaseTextures.Trees);
                addBaseTexturePathItem(BaseTextures.TvSignalLost);
                addBaseTexturePathItem(BaseTextures.VintageClayTile);
                addBaseTexturePathItem(BaseTextures.Wall);
                addBaseTexturePathItem(BaseTextures.Water);
                addBaseTexturePathItem(BaseTextures.Weave);
                addBaseTexturePathItem(BaseTextures.WispySky);
                addBaseTexturePathItem(BaseTextures.Wood);
                addBaseTexturePathItem(BaseTextures.Wood2);
                addBaseTexturePathItem(BaseTextures.WoodFortress);
                addBaseTexturePathItem(BaseTextures.Woven);

                confirmDialog.addChild(confirmDialogTree);
                addChild(confirmDialog);
                confirmDialog.popupCentered();
            }
            else if (id == 1) {
                var fileDialog = new FileDialog();
                fileDialog.fileMode = FileDialogMode.openDir;
                fileDialog.rootSubfolder = editor.explorer.assetsDirectory;
                fileDialog.currentDir = editor.explorer.assetsDirectory;
                fileDialog.access = 2;
                fileDialog.title = "Open Project Texture Path";
                addChild(fileDialog);
                fileDialog.hide();

                fileDialog.currentDir = editor.explorer.assetsDirectory;

                var fileDialogScaleFactor = getWindow().contentScaleFactor;
                fileDialog.contentScaleFactor = fileDialogScaleFactor;
                fileDialog.minSize = new Vector2i(
                    Std.int(580 * fileDialogScaleFactor), 
                    Std.int(460 * fileDialogScaleFactor)
                );

                fileDialog.dirSelected.add((path: String) -> {
                    fileDialog.hide();
                    fileDialog.queueFree();
                    if (path == "") {
                        return;
                    }
                    var ioPath = editor.projectIo.getFileUrl(path);
                    
                    addTexturePath(ioPath);
                });

                fileDialog.popupCentered();
            }
        });

        removeButton.pressed.add(() -> {
            if (selectedTexturePath != "") {
                removeTexturePath(selectedTexturePath);
                selectedTexturePath = "";
            }
        });
    }

    public override function onReady() {
        var texturePathListPath = getJsonPath();
        if (editor.projectIo.fileExists(texturePathListPath)) {
            var texturePathListJson = editor.projectIo.loadText(texturePathListPath);
            texturePathList = Json.parse(texturePathListJson);
        }

        refresh();
    }

    inline function addTexturePath(path: String) {
        texturePathList.push(path);
        save();
        refresh();
    }

    inline function removeTexturePath(path: String) {
        texturePathList.remove(path);
        save();
        refresh();
    }

    inline function refresh() {
        tree.clear();

        var treeRoot = tree.createItem();

        for (texturePath in texturePathList) {
            var treeItem = tree.createItem(treeRoot);
            treeItem.setText(0, texturePath);
            treeItem.setIcon(0, editor.loadIcon("studio://icons/16/images-stack.png"));
        }
    }

    inline function getJsonPath() {
        var pathUrl = editor.projectIo.pathUrl;
        return pathUrl + ".texturepaths.json";
    }

    inline function save() {
        var texturePathListJson = Json.stringify(texturePathList, null, "\t");
        var texturePathListPath = getJsonPath();
        editor.projectIo.saveText(texturePathListPath, texturePathListJson);
    }
}