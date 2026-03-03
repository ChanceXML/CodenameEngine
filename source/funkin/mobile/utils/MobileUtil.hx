package funkin.mobile.utils;

#if android
import extension.androidtools.os.Build.VERSION;
import extension.androidtools.os.Environment;
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
#end

import lime.system.System;
import openfl.Assets;
import haxe.io.Bytes;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class MobileUtil {

    public static function getPermissions():Void {
        #if android
        try {
            if (VERSION.SDK_INT >= 30) {
                if (!Environment.isExternalStorageManager()) {
                    Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
                }
            } else {
                Permissions.requestPermissions([
                    'READ_EXTERNAL_STORAGE',
                    'WRITE_EXTERNAL_STORAGE'
                ]);
            }
        } catch (e:Dynamic) {
            trace('Permission request error: $e');
        }
        #end
    }
}
