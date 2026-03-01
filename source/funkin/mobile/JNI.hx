package funkin.mobile;

#if android
import lime.system.JNI;

class CodenameJNI #if (lime >= "8.0.0") implements JNISafety #end {

    public static inline var SDL_ORIENTATION_UNKNOWN:Int = 0;
    public static inline var SDL_ORIENTATION_LANDSCAPE:Int = 1;
    public static inline var SDL_ORIENTATION_LANDSCAPE_FLIPPED:Int = 2;
    public static inline var SDL_ORIENTATION_PORTRAIT:Int = 3;
    public static inline var SDL_ORIENTATION_PORTRAIT_FLIPPED:Int = 4;

    public static inline function setOrientation(width:Int, height:Int, resizeable:Bool, hint:String):Dynamic {
        return setOrientation_jni(width, height, resizeable, hint);
    }

    public static inline function getCurrentOrientationAsString():String {
        return switch (getCurrentOrientation_jni()) {
            case SDL_ORIENTATION_PORTRAIT: "Portrait";
            case SDL_ORIENTATION_LANDSCAPE: "LandscapeRight";
            case SDL_ORIENTATION_PORTRAIT_FLIPPED: "PortraitUpsideDown";
            case SDL_ORIENTATION_LANDSCAPE_FLIPPED: "LandscapeLeft";
            default: "Unknown";
        }
    }

    public static inline function isScreenKeyboardShown():Bool {
        return isScreenKeyboardShown_jni();
    }

    public static inline function clipboardHasText():Bool {
        return clipboardHasText_jni();
    }

    public static inline function clipboardGetText():String {
        return clipboardGetText_jni();
    }

    public static inline function clipboardSetText(text:String):Void {
        return clipboardSetText_jni(text);
    }

    public static inline function manualBackButton():Void {
        return manualBackButton_jni();
    }

    public static inline function setActivityTitle(title:String):Bool {
        return setActivityTitle_jni(title);
    }

    @:noCompletion private static var setOrientation_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'setOrientation', '(IIZLjava/lang/String;)V'
    );

    @:noCompletion private static var getCurrentOrientation_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'getCurrentOrientation', '()I'
    );

    @:noCompletion private static var isScreenKeyboardShown_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'isScreenKeyboardShown', '()Z'
    );

    @:noCompletion private static var clipboardHasText_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'clipboardHasText', '()Z'
    );

    @:noCompletion private static var clipboardGetText_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'clipboardGetText', '()Ljava/lang/String;'
    );

    @:noCompletion private static var clipboardSetText_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'clipboardSetText', '(Ljava/lang/String;)V'
    );

    @:noCompletion private static var manualBackButton_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'manualBackButton', '()V'
    );

    @:noCompletion private static var setActivityTitle_jni:Dynamic = JNI.createStaticMethod(
        'org/libsdl/app/SDLActivity', 'setActivityTitle', '(Ljava/lang/String;)Z'
    );
}
#end
