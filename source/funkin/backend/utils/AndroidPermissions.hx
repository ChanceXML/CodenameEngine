package funkin.backend.utils;

#if android
import android.Permissions;
#end

class AndroidPermissions {
    public static function request():Void {
        #if android
        var permissions:Array<String> = [
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE"
        ];

        var toRequest:Array<String> = [];
        var granted = Permissions.getGrantedPermissions();
        
        for (p in permissions) {
            if (!granted.contains(p)) {
                toRequest.push(p);
            }
        }

        if (toRequest.length > 0) {
            Permissions.requestPermissions(toRequest);
        }
        #end
    }
}
