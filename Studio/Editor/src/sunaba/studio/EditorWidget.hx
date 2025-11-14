package sunaba.studio;

import sunaba.ui.Widget;
import sunaba.io.IoInterface;

class EditorWidget extends Widget {
    private  var parent: Editor;

    public function new(parent: Editor, area: EditorArea) {
        super();
        this.parent = parent;
        if (area == EditorArea.leftSidebar) {
            parent.addLeftSidebarChild(this);
        }
        else if (area == EditorArea.rightSidebar) {
            parent.addRightSidebarChild(this);
        }
        else if (area == EditorArea.workspace) {
            parent.addWorkspaceChild(this);
        }
        editorInit();
    }

    public function editorInit() {}

    public function getEditor(): Editor {
        return parent;
    }

    public function destroy() {
        onDestroy();
        queueFree();
    }

    public function onDestroy() {

    }

    public function onSave() {

    }
}