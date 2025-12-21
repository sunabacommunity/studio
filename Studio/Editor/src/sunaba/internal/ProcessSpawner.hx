package sunaba.internal;

import sunaba.core.TypedArray;
import sunaba.core.StringArray;
import sunaba.core.native.ScriptType;
import sunaba.core.ArrayList;
import sunaba.core.native.NativeObject;
import sunaba.Node;

class ProcessSpawner extends Node {
    public override function nativeInit(?_native:NativeObject) {
        if (_native == null) {
            _native = new NativeObject("res://Engine/ProcessSpawner.cs", new ArrayList(), ScriptType.csharp);
        }
        native = _native;
    }

    public function spawn(cmdName: String, args: TypedArray<String>) {
        var spawnArgs = new ArrayList();
        spawnArgs.append(cmdName);
        spawnArgs.append(args);
        native.call("Spawn", spawnArgs);
    }
}