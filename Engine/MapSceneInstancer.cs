using Godot;

namespace Sunaba.Engine;

public partial class MapSceneInstancer: RefCounted
{
    public Node3D Instantiate()
    {
        var scene = ResourceLoader.Load<PackedScene>("res://Engine/MapNode.tscn");
        return scene.Instantiate<Node3D>();
    }
}