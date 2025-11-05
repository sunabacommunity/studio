package sunaba.studio;

enum abstract EditorArea(Int) from Int to Int {
    var leftSidebar = 0;
    var rightSidebar = 1;
    var workspace = 2;
}