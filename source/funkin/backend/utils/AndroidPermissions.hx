package funkin.backend.utils;

#if android
import android.Permissions;
#end

/**
 * Utility class to handle Android storage permissions.
 */
class AndroidPermissions {
    public static function request():Void {
        #if android
        var requestedPermissions:Array<String> = [
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE"
        ];
        
        var ungrantedPermissions:Array<String> = new Array<String>();
        for (permission in requestedPermissions) {
            if (!Permissions.getGrantedPermissions().contains(permission)) {
                ungrantedPermissions.push(permission);
            }
        }
        
        if (ungrantedPermissions.length > 0) {
            Permissions.requestPermissions(ungrantedPermissions);
            trace("Requesting Android storage permissions...");
        } else {
            trace("Storage permissions are already granted.");
        }
        #else
        trace("Skipping Android permission request: Target is not Android.");
        #end
    }
}
