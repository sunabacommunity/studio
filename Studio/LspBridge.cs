using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Godot;
using OmniSharp.Extensions.LanguageServer.Client;
using OmniSharp.Extensions.LanguageServer.Protocol;
using OmniSharp.Extensions.LanguageServer.Protocol.Client;
using OmniSharp.Extensions.LanguageServer.Protocol.Client.Capabilities;
using OmniSharp.Extensions.LanguageServer.Protocol.Document;
using OmniSharp.Extensions.LanguageServer.Protocol.Models;
using OmniSharp.Extensions.LanguageServer.Protocol.Window;

namespace Sunaba.Studio;

public partial class LspBridge : Node
{
    public Godot.CodeEdit Editor;
    private ILanguageClient _lsp;
    private Process _server;
    private CancellationTokenSource _cts = new();

    public override async void _Ready()
    {
        // 1. Create client
        _lsp = LanguageClient.Create(o =>
        {
            o.WithInput(_server.StandardOutput.BaseStream)
                .WithOutput(_server.StandardInput.BaseStream)
                .OnPublishDiagnostics(OnDiagnostics)
                .OnShowMessage(OnShowMessage);
            
            o.WithCapability(new CompletionCapability
            {
                CompletionItem = new()
                {
                    SnippetSupport = true,
                    DocumentationFormat = new Container<MarkupKind>(MarkupKind.Markdown)
                }
            });
        });
        await _lsp.Initialize(_cts.Token);

        // 3. Wire Godot events
        Editor.TextChanged += OnTextChanged;
    }

    private void StartServer(string exePath, string arguments = "")
    {
        var psi = new ProcessStartInfo
        {
            FileName = exePath,
            Arguments = arguments,
            RedirectStandardInput  = true,
            RedirectStandardOutput = true,
            UseShellExecute = false
        };
        _server = Process.Start(psi);
    }

    // Document sync with debounce
    private async void OnTextChanged()
    {
        _cts.Cancel();
        _cts = new();
        try
        {
            await Task.Delay(500, _cts.Token);
            var uri = DocumentUri.FromFileSystemPath(
                ProjectSettings.GlobalizePath("res://Main.cs"));

            // 0.19.9 uses OptionalVersionedTextDocumentIdentifier
            _lsp.TextDocument.DidChangeTextDocument(new DidChangeTextDocumentParams
            {
                TextDocument = new OptionalVersionedTextDocumentIdentifier
                {
                    Uri = uri,
                    Version = 1
                },
                ContentChanges = new[] {
                    new TextDocumentContentChangeEvent { Text = Editor.Text }
                }
            });
        }
        catch (OperationCanceledException) { /* user typed again */ }
    }

    // Diagnostics → underline spans (Godot 4.2 does not have built-in squiggles)
    private void OnDiagnostics(PublishDiagnosticsParams p)
    {
        // Editor.RemoveAllSyntaxHighlights();          // Godot 4.2 API
        foreach (var d in p.Diagnostics)
        {
            int line   = (int)d.Range.Start.Line;
            int from   = (int)d.Range.Start.Character;
            int to     = (int)d.Range.End.Character;
            // We simulate squiggles by setting a red underline highlight
            // Editor.AddSyntaxHighlight(
            //     new Godot.SyntaxHighlighter
            //     {
            //         Line = line,
            //         StartColumn = from,
            //         EndColumn   = to,
            //         Color       = Colors.Red
            //     });
            /*Editor.AddSyntaxHighlight(
                        new CodeHighlighter()
                        {
                            Line = line,
                            StartColumn = from,
                            EndColumn   = to,
                            Color       = Colors.Red
                        });*/
        }
    }

    // Manual completion trigger (Ctrl+Space wired in input map)
    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_completion") && Editor.HasFocus())
            _ = RequestCompletionAsync();
    }

    private async Task RequestCompletionAsync()
    {
        var caret  = Editor.GetCaretColumn();   // 0-based column
        var line   = Editor.GetCaretLine();     // 0-based line
        var uri    = DocumentUri.FromFileSystemPath(
            ProjectSettings.GlobalizePath("res://Main.cs"));

        var items = await _lsp.TextDocument.RequestCompletion(
            new CompletionParams
            {
                TextDocument = new TextDocumentIdentifier { Uri = uri },
                Position     = new Position(line, caret)
            });

        ShowCompletionPopup(items);
    }

    private void ShowCompletionPopup(CompletionList list)
    {
        var popup = GetNode<PopupPanel>("CompletionPopup");
        popup.Visible = false;
        foreach (Node n in popup.GetChildren()) n.QueueFree();

        var vbox = new VBoxContainer();
        popup.AddChild(vbox);

        foreach (var item in list.Items ?? Array.Empty<CompletionItem>())
        {
            var lbl = new Label { Text = item.Label };
            lbl.GuiInput += (ev) =>
            {
                if (ev is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
                    InsertCompletion(item);
            };
            vbox.AddChild(lbl);
        }

        var gpos = Editor.GetViewport().GetMousePosition(); // near cursor
        popup.Position = (Vector2I)gpos;
        popup.Size     = new Vector2I(300, 200);
        popup.Show();
    }

    private void InsertCompletion(CompletionItem item)
    {
        GetNode<PopupPanel>("CompletionPopup").Hide();
        Editor.InsertTextAtCaret(item.InsertText ?? item.Label);
    }

    private void OnShowMessage(ShowMessageParams m) => GD.Print("[LSP] " + m.Message);

    public override void _ExitTree()
    {
        _cts.Cancel();
        _lsp?.Dispose();
        _server?.Kill();
    }
}