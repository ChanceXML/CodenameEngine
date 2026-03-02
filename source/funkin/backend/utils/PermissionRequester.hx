package funkin.backend.utils;

#if android
import lime.app.Application;
#end

class PermissionRequester
{
    public static function requestStoragePermissions():Void
    {
        #if android
        try
        {
            var perms = [
                "android.permission.WRITE_EXTERNAL_STORAGE",
                "android.permission.READ_EXTERNAL_STORAGE"
            ];

            Application.current.window.requestPermissions(perms);
        }
        catch (e:Dynamic)
        {
            trace("Permission request failed: " + e);
        }
        #end
    }
}
