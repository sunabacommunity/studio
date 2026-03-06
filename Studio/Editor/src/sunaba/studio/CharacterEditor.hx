package sunaba.studio;

class CharacterEditor extends EditorWidget {
    public override function editorInit() {
        load("studio://CharacterEditor.suml");

        getEditor().setDockTabTitle(this, "Character Editor");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/toilet-male-edit.png"));
    }
}