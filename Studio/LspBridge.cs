using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Godot;
using Newtonsoft.Json.Linq;
using OmniSharp.Extensions.LanguageServer.Client;
using OmniSharp.Extensions.LanguageServer.Protocol;
using OmniSharp.Extensions.LanguageServer.Protocol.Client;
using OmniSharp.Extensions.LanguageServer.Protocol.Client.Capabilities;
using OmniSharp.Extensions.LanguageServer.Protocol.Document;
using OmniSharp.Extensions.LanguageServer.Protocol.Models;
using OmniSharp.Extensions.LanguageServer.Protocol.Window;
using OmniSharp.Extensions.LanguageServer.Protocol.Workspace;

namespace Sunaba.Studio;

public partial class LspBridge : Node
{
    public Godot.CodeEdit Editor;
    private ILanguageClient _lsp;
    private Process _server;
    private CancellationTokenSource _cts = new();
    private List<string> _completionInserts = new();
    
    public string haxePath = "haxe"; // Set this to your Haxe executable path
    public string hxmlPath = "build.hxml"; // Set this to your haxe-ls.xml path

    public string codePath;

    public override async void _Ready()
    {
        // 1. Create client
        _lsp = LanguageClient.Create(o =>
        {
            o.WithInput(_server.StandardOutput.BaseStream)
                .WithOutput(_server.StandardInput.BaseStream)
                .OnPublishDiagnostics(OnDiagnostics)
                .OnShowMessage(OnShowMessage);
            
            o.InitializationOptions = new
            {
                hxmlPath
            };
            
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

        // Set LSP settings
        _lsp.Workspace.DidChangeConfiguration(new DidChangeConfigurationParams
        {
            Settings = JObject.FromObject(new
            {
                haxe = new
                {
                    executable = haxePath
                }
                // Add other settings as needed
            })
        });

        // 3. Wire Godot events
        Editor.TextChanged += OnTextChanged;
        Editor.CodeCompletionRequested += () =>
        {
            _ = RequestCompletionAsync();
        };
    }

    public void StartServer(string exePath, string arguments = "")
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
            var uri = DocumentUri.FromFileSystemPath(
                codePath);

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
        Editor.RequestCodeCompletion();
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

    private async Task RequestCompletionAsync()
    {
        var caret  = Editor.GetCaretColumn();   // 0-based column
        var line   = Editor.GetCaretLine();     // 0-based line
        var uri    = DocumentUri.FromFileSystemPath(
            codePath);

        var items = await _lsp.TextDocument.RequestCompletion(
            new CompletionParams
            {
                TextDocument = new TextDocumentIdentifier { Uri = uri },
                Position     = new Position(line, caret)
            });

        _completionInserts.Clear();
        //Editor.CancelCodeCompletion();
        foreach (var item in items.Items ?? Array.Empty<CompletionItem>())
        {
            var kind = MapCompletionKind(item.Kind);
            Editor.AddCodeCompletionOption((CodeEdit.CodeCompletionKind)kind, item.Label, item.InsertText ?? item.Label);
            _completionInserts.Add(item.InsertText ?? item.Label);
        }
    }

    private void OnCodeCompletionSelected(int index)
    {
        if (index >= 0 && index < _completionInserts.Count)
        {
            Editor.InsertTextAtCaret(_completionInserts[index]);
        }
    }

    private int MapCompletionKind(CompletionItemKind? kind)
    {
        return kind switch
        {
            CompletionItemKind.Text => 0, // PlainText
            CompletionItemKind.Method => 2, // Function
            CompletionItemKind.Function => 2, // Function
            CompletionItemKind.Constructor => 11, // Class
            CompletionItemKind.Field => 5, // Member
            CompletionItemKind.Variable => 4, // Variable
            CompletionItemKind.Class => 11, // Class
            CompletionItemKind.Interface => 11, // Class
            CompletionItemKind.Module => 11, // Class
            CompletionItemKind.Property => 5, // Member
            CompletionItemKind.Unit => 0, // PlainText
            CompletionItemKind.Value => 7, // Constant
            CompletionItemKind.Enum => 6, // Enum
            CompletionItemKind.Keyword => 1, // Keyword
            CompletionItemKind.Snippet => 12, // Snippet
            CompletionItemKind.Color => 13, // Color
            CompletionItemKind.File => 9, // FilePath
            CompletionItemKind.Reference => 8, // NodePath
            CompletionItemKind.Folder => 10, // Directory
            CompletionItemKind.EnumMember => 6, // Enum
            CompletionItemKind.Constant => 7, // Constant
            CompletionItemKind.Struct => 11, // Class
            CompletionItemKind.Event => 3, // Signal
            CompletionItemKind.Operator => 0, // PlainText
            CompletionItemKind.TypeParameter => 11, // Class
            _ => 0 // PlainText
        };
    }

    private void OnShowMessage(ShowMessageParams m) => GD.Print("[LSP] " + m.Message);

    public override void _ExitTree()
    {
        _cts.Cancel();
        _lsp?.Dispose();
        _server?.Kill();
    }
}