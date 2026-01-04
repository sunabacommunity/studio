package sunaba.studio;

import sunaba.ui.OptionButton;
import sunaba.core.Vector2;

class ResourceInspector extends EditorWidget {
    public override function editorInit() {
        load("studio://ResourceInspector.suml");
        getEditor().setRightSiderbarTabIcon(this, getEditor().loadIcon("studio://icons/16_1-5x/document--pencil.png"));
        customMinimumSize = new Vector2(275, 0);
    }
}