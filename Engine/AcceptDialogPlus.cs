using System;
using Godot;

namespace Sunaba.Engine;

[GlobalClass]
public partial class AcceptDialogPlus : AcceptDialog
{
    [Flags]
    public enum TypeEnum
    {
        Error,
        Warning,
        Info,
    }
    
    private int _type = (int)TypeEnum.Info;
    [Export(PropertyHint.Enum, "Error,Warning,Info")]
    public int Type
    {
        get => _type;
        set
        {
            _type = value;
            var oldHbox = _hBoxContainer;
            var oldText = Text;
            PackedScene boxScene = GD.Load<PackedScene>("res://Engine/ErrorBox.tscn");
            if (_type == (int)TypeEnum.Warning)
            {
                boxScene = GD.Load<PackedScene>("res://Engine/WarnBox.tscn");
            }
            else if (_type == (int)TypeEnum.Info)
            {
                boxScene = GD.Load<PackedScene>("res://Engine/InfoBox.tscn");
            }
            else
            {
                return;
            }

            _hBoxContainer = (HBoxContainer)boxScene.Instantiate<HBoxContainer>();
            AddChild(_hBoxContainer);
            oldHbox.QueueFree();
            Label = (Label)_hBoxContainer.GetNode("Label");
            Text = oldText;
        }
    }
    
    private HBoxContainer _hBoxContainer;
    
    public Label Label;

    [Export]
    public string Text
    {
        get => Label.Text;
        set => Label.Text = value;
    }
    
    public AcceptDialogPlus()
    {
        PackedScene boxScene = GD.Load<PackedScene>("res://Engine/ErrorBox.tscn");
        if (_type == (int)TypeEnum.Warning)
        {
            boxScene = GD.Load<PackedScene>("res://Engine/WarnBox.tscn");
        }
        else if (_type == (int)TypeEnum.Info)
        {
            boxScene = GD.Load<PackedScene>("res://Engine/InfoBox.tscn");
        }
        else
        {
            return;
        }

        _hBoxContainer = (HBoxContainer)boxScene.Instantiate<HBoxContainer>();
        AddChild(_hBoxContainer);
        Label = (Label)_hBoxContainer.GetNode("Label");
    }
}