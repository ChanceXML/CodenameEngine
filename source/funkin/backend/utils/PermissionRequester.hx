package funkin.backend.utils;

#if android
import openfl.utils.JNI;
#end

class PermissionRequester
{
    public static function requestStoragePermissions():Void
    {
        #if android
        try
        {
            var requestPerms = JNI.createStaticMethod(
                "org.haxe.lime.GameActivity",
                "requestPermissions",
                "(Ljava/lang/String;)V"
            );

            requestPerms("android.permission.WRITE_EXTERNAL_STORAGE");
            requestPerms("android.permission.READ_EXTERNAL_STORAGE");
        }
        catch (e:Dynamic)
        {
            trace("Permission request failed: " + e);
        }
        #end
    }
}
