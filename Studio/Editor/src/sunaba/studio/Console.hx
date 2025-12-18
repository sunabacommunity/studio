package sunaba.studio;

import sunaba.ui.ScrollContainer;
import sunaba.core.Signal;
import sunaba.core.TypedArray;
import sunaba.core.native.NativeObject;
import sunaba.core.StringArray;
import sunaba.ui.RichTextLabel;
import sunaba.ui.LineEdit;
import sunaba.ShellConsole;
import sunaba.ui.OptionButton;
import sunaba.core.Callable;


class Console extends EditorWidget {
    private var output: RichTextLabel;
	private var input: LineEdit;

	private var console: ShellConsole;

	private var mode = ConsoleLineEditMode.command;

    public override function editorInit() {
        load("studio://Console.suml");

        var txt: String = "";
		mode = ConsoleLineEditMode.command;

		output = getNodeT(RichTextLabel, "vbox/panel/output");
		output.selectionEnabled = true;
		output.contextMenuEnabled = true;
		output.bbcodeEnabled = true;
        output.scrollActive = true;
        output.scrollFollowing = true;
		var outputColor = output.getThemeColor('default_color');
		var i = getNode("vbox/input");
		if (i == null) {
			trace("Input element not found in ConsoleWidget");
			return;
		}
		input = getNodeT(LineEdit, "vbox/hbox/input");

		var option = getNodeT(OptionButton, "vbox/hbox/option");
		option.addItem("Command Mode", ConsoleLineEditMode.command);
		option.addItem("Code Mode", ConsoleLineEditMode.code);
		option.itemSelected.add((id: Int) -> {
			if (id != ConsoleLineEditMode.command && id != ConsoleLineEditMode.code)
				Debug.error("Invalid Mode");
			mode = id;
			if (id == ConsoleLineEditMode.command)
				input.placeholderText = "Enter console commands here...";
			else if (id == ConsoleLineEditMode.code)
				input.placeholderText = "Enter shell code here...";
		});
		console = new ShellConsole();
		console.io = io;
		console.print.add(function(log: String) {
			txt += log + "\n";
			output.parseBbcode("[code]" + txt + "[/code]");
			output.scrollFollowing = true;
		});
		input.textSubmitted.add(function(text: String) {
			if (text != "") {
				try {
					if (mode == ConsoleLineEditMode.code)
						console.eval(text);
					else if (mode == ConsoleLineEditMode.command)
						console.cmd(text);
				}
				catch(e) {
					txt = txt + '[color=red]Error: ' + e + '[/color]\n';
					output.parseBbcode('[code]' + txt + '[/code]');
				}
				input.clear();
			}
		});
		console.addCommand("echo", (args) -> {
			if (args.length > 0) {
				var text = args.join(" ");
				Sys.println(text);
			} else {
				Sys.println("Usage: echo <text>");
			}
			return 0;
		});

        var rootNode: NativeObject = untyped __lua__("_G.__rootNode");
        var outputTa: TypedArray<String> = rootNode.get("output");
        var output = outputTa.toArray();
        for (line in output) {
            console.log(line);
        }

        var onPrint: Signal = Signal.createFromObject(rootNode, "on_print");
        onPrint.add(function(line: String) {
            console.log(line);
        });

        getEditor().setDockTabTitle(this, "Console");
        getEditor().setDockTabIcon(this, getEditor().loadIcon("studio://icons/16/terminal.png"));
    }

    public function log(...messages: String) {
        var finalMsg : Array<String> = [];
        for (msg in messages) {
            finalMsg.push(msg);
        }
        var finalMsgStr = finalMsg.join(" ");
        console.log(finalMsgStr);
    }

    public function addCommand(name: String, func: Array<String>->Int) {
        console.addCommand(name, func);
    }

	public function evalCmd(command: String) {
		console.cmd(command);
	}

    public function evalCode(code: String) {
        console.eval(code);
    }
}

enum abstract ConsoleLineEditMode(Int) from Int to Int {
	var command = 0;
	var code = 1;	
}