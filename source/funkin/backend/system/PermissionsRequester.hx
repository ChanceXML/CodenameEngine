package funkin.backend.utils;

#if android
import lime.system.System;
#end

class PermissionRequester
{
    public static function requestStoragePermissions():Void
    {
        #if android
        System.requestPermission("android.permission.WRITE_EXTERNAL_STORAGE");
        System.requestPermission("android.permission.READ_EXTERNAL_STORAGE");
        #end
    }
}
