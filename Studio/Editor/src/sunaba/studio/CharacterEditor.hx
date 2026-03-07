package sunaba.studio;

import sunaba.core.Vector2;
import sunaba.ui.ItemList;
import sunaba.ui.OptionButton;
import sunaba.ui.HSlider;
import sunaba.ui.HBoxContainer;
import sunaba.ui.Control;

class CharacterEditor extends EditorWidget {
    public var characterViewer: CharacterViewer = null;

    private var vbox: Control = null;

    public override function editorInit() {
        load("studio://CharacterEditor.suml");

        vbox = getNodeT(Control, "vbox");
        vbox.hide();

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
        vbox.show();
    }
}