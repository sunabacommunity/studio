using Godot;

namespace Sunaba.Engine;

[GlobalClass]
public partial class ConfirmationDialogPlus : ConfirmationDialog
{
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
            var icon = GD.Load<Texture2D>("res://Engine/Theme/cross-circle.png");
            if (_type == 1)
            {
                icon = GD.Load<Texture2D>("res://Engine/Theme/exclamation.png");
            }
            else if (_type == 2)
            {
                icon = GD.Load<Texture2D>("res://Engine/Theme/information.png");
            }

            if (iconRect != null)
            {
                iconRect.Texture = icon;
            }
        }
    }

    private TextureRect iconRect;
    
    private HBoxContainer _hBoxContainer;
    
    public Label Label;

    [Export]
    public string Text
    {
        get => Label.Text;
        set => Label.Text = value;
    }
    
    public ConfirmationDialogPlus()
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
        iconRect = _hBoxContainer.GetNode<TextureRect>("IconHolder/Icon");
    }
    
    public override void _Ready()
    {
        var displayScale = DisplayServer.ScreenGetScale(CurrentScreen);
        if (OS.GetName() != "macOS")
        {
            var dpi = DisplayServer.ScreenGetDpi(CurrentScreen);
            displayScale = dpi * 0.01f;
        }
        ContentScaleFactor = displayScale;
        Size = new Vector2I((int)(Size.X * displayScale), (int)(Size.Y * displayScale));
        MinSize = new Vector2I((int)(MinSize.X * displayScale), (int)(MinSize.Y * displayScale));
    }
    
    public void SetIconType(int i)
    {
        Type = i;
    }
}