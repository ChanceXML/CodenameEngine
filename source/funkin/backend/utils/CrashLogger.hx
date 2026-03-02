package funkin.backend.utils;

import sys.io.File;
import sys.FileSystem;
import openfl.Lib;
import haxe.CallStack;
import haxe.io.Path;

class CrashLogger
{
    public static function init():Void
    {
        #if android
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR,
            onCrash
        );
        #end
    }

    static function onCrash(e:openfl.events.UncaughtErrorEvent):Void
    {
        try
        {
            var errorMessage:String = "";

            if (Std.isOfType(e.error, String))
                errorMessage = e.error;
            else
                errorMessage = Std.string(e.error);

            var stack = CallStack.toString(CallStack.exceptionStack());

            var fullLog =
                "=== Codename Engine Crash Log ===\n\n" +
                "Error:\n" + errorMessage + "\n\n" +
                "Stack:\n" + stack + "\n";

            var basePath = "/storage/emulated/0/.CodenameEngine-v1.0.1/logs/";

            if (!FileSystem.exists(basePath))
                FileSystem.createDirectory(basePath);

            var fileName = basePath + "crash_" + Date.now().getTime() + ".txt";

            File.saveContent(fileName, fullLog);
        }
        catch (err:Dynamic)
        {
            trace("Failed to write crash log: " + err);
        }
    }
}
