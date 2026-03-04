package funkin.mobile.utils;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end

#if android
import lime.system.System;
#end

class StorageUtil
{
	#if sys

	public static function getStorageDirectory():String
		return #if android Path.addTrailingSlash(AndroidContext.getExternalFilesDir()) #else Sys.getCwd() #end;

	#if android

	public static function getExternalStorageDirectory():String
		return Path.addTrailingSlash(AndroidEnvironment.getExternalStorageDirectory()) + ".CodenameEngine/";

	public static function getModsPath():String
	{
		final externalFile = System.applicationStorageDirectory + "external.txt";
		final externalStatus = FileSystem.exists(externalFile) ? File.getContent(externalFile) : "false";
		return externalStatus == "true" ? getExternalStorageDirectory() : getStorageDirectory();
	}

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions([
				"READ_MEDIA_IMAGES",
				"READ_MEDIA_VIDEO",
				"READ_MEDIA_AUDIO",
				"READ_MEDIA_VISUAL_USER_SELECTED"
			]);
		else
			AndroidPermissions.requestPermissions([
				"READ_EXTERNAL_STORAGE",
				"WRITE_EXTERNAL_STORAGE"
			]);

		if (!AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting("MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");

		if (!FileSystem.exists(getStorageDirectory()))
			FileSystem.createDirectory(getStorageDirectory());

		if (!FileSystem.exists(getExternalStorageDirectory()))
			FileSystem.createDirectory(getExternalStorageDirectory());
	}

	#end
	#end
}
