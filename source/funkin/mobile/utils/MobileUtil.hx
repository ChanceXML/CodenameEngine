package funkin.mobile.utils;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end

#if android
import lime.system.System;
import extension.androidtools.os.Build.VERSION;
import extension.androidtools.os.Environment;
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
#end

class StorageUtil
{
	#if sys

	public static function getStorageDirectory():String
	{
		#if android
		var dir:String = System.applicationStorageDirectory;

		if (dir == null || dir == "")
			dir = "/storage/emulated/0/Android/data/";

		dir = Path.addTrailingSlash(dir);

		return dir;
		#else
		return Path.addTrailingSlash(Sys.getCwd());
		#end
	}

	#if android

	public static function getExternalStorageDirectory():String
	{
		var root:String = Environment.getExternalStorageDirectory();

		if (root == null || root == "")
			root = "/storage/emulated/0/";

		root = Path.addTrailingSlash(root);

		var finalPath:String = root + ".CodenameEngine/";
		return finalPath;
	}

	public static function getModsPath():String
	{
		var internalPath:String = getStorageDirectory();
		var externalPath:String = getExternalStorageDirectory();

		var externalFile:String = internalPath + "external.txt";
		var useExternal:Bool = false;

		if (FileSystem.exists(externalFile))
		{
			try
			{
				var content:String = File.getContent(externalFile);
				if (content != null)
				{
					content = content.trim().toLowerCase();
					if (content == "true")
						useExternal = true;
				}
			}
			catch (e:Dynamic)
			{
				useExternal = false;
			}
		}

		if (useExternal)
			return externalPath;
		else
			return internalPath;
	}

	public static function requestPermissions():Void
	{
		var sdk:Int = VERSION.SDK_INT;

		if (sdk >= 33)
		{
			Permissions.requestPermissions([
				"android.permission.READ_MEDIA_IMAGES",
				"android.permission.READ_MEDIA_VIDEO",
				"android.permission.READ_MEDIA_AUDIO"
			]);
		}
		else
		{
			Permissions.requestPermissions([
				"android.permission.READ_EXTERNAL_STORAGE",
				"android.permission.WRITE_EXTERNAL_STORAGE"
			]);
		}

		if (!Environment.isExternalStorageManager())
		{
			Settings.requestSetting("android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
		}

		ensureDirectoryExists(getStorageDirectory());
		ensureDirectoryExists(getExternalStorageDirectory());
	}

	private static function ensureDirectoryExists(path:String):Void
	{
		if (path == null || path == "")
			return;

		if (!FileSystem.exists(path))
		{
			try
			{
				FileSystem.createDirectory(path);
			}
			catch (e:Dynamic)
			{
			}
		}
	}

	#end
	#end
}
