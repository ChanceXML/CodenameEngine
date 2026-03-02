package funkin.backend.system;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.ui.FlxSoundTray;
import funkin.backend.assets.AssetSource;
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.ModsFolder;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.system.framerate.SystemInfo;
import funkin.backend.system.modules.*;
import funkin.backend.utils.ThreadUtil;
import funkin.editors.SaveWarning;
import funkin.options.PlayerSettings;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.utils.AssetLibrary;
import sys.FileSystem;
import sys.io.File;

#if android
import lime.system.JNI;
#end

class Main extends Sprite
{
	public static var instance:Main;

	public static var modToLoad:String = null;
	public static var forceGPUOnlyBitmapsOff:Bool = #if desktop false #else true #end;
	public static var noTerminalColor:Bool = false;
	public static var verbose:Bool = false;

	public static var scaleMode:FunkinRatioScaleMode;
	public static var framerateSprite:Framerate;

	var gameWidth:Int = 1280;
	var gameHeight:Int = 720;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var game:FunkinGame;

	public static var timeSinceFocus(get, never):Float;
	public static var time:Int = 0;

	public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;
	@:dox(hide) public static function execAsync(func:Void->Void) ThreadUtil.execAsync(func);

	public static var noCwdFix:Bool = false;

	#if android
	@:noCompletion private static var getExternalFilesDir_jni:Dynamic = 
		JNI.createStaticMethod("org/libsdl/app/SDLActivity", "getExternalFilesDir", "()Ljava/lang/String;");
	@:noCompletion private static var getObbDir_jni:Dynamic =
		JNI.createStaticMethod("org/libsdl/app/SDLActivity", "getObbDir", "()Ljava/lang/String;");
	@:noCompletion private static var getSDK_INT:Dynamic =
		JNI.createStaticField("android/os/Build$VERSION", "SDK_INT", "I");
	#end

	public static function preInit() {
		funkin.backend.utils.NativeAPI.registerAsDPICompatible();
		funkin.backend.system.CommandLineHandler.parseCommandLine(Sys.args());
		fixWorkingDirectory();
	}

	public function new()
	{
		super();
		instance = this;
		CrashHandler.init();

		addChild(game = new FunkinGame(gameWidth, gameHeight, MainState, Options.framerate, Options.framerate, skipSplash, startFullscreen));

		addChild(framerateSprite = new Framerate());
		SystemInfo.init();
	}

	private static function getTimer():Int {
		return time = Lib.getTimer();
	}

	public static function fixWorkingDirectory():Void {
		#if windows
		if (!noCwdFix && !FileSystem.exists('manifest/default.json')) {
			Sys.setCwd(haxe.io.Path.directory(Sys.programPath()));
		}
		#elseif android
		var sdkVersion:Int = getSDK_INT();
		var dir:String = sdkVersion > 30 ? getObbDir_jni() : getExternalFilesDir_jni();
		Sys.setCwd(haxe.io.Path.addTrailingSlash(dir));
		#elseif ios || switch
		Sys.setCwd(haxe.io.Path.addTrailingSlash(openfl.filesystem.File.applicationStorageDirectory.nativePath));
		#end
	}

	public static function loadGameSettings() {
		WindowUtils.init();
		SaveWarning.init();
		MemoryUtil.init();

		FunkinCache.init();
		Paths.assetsTree = new AssetsLibraryList();

		ShaderResizeFix.init();
		Logs.init();
		Paths.init();

		hscript.Interp.importRedirects = funkin.backend.scripting.Script.getDefaultImportRedirects();

		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.init();
		#end

		var lib = new AssetLibrary();
		@:privateAccess lib.__proxy = Paths.assetsTree;
		Assets.registerLibrary("default", lib);

		PlayerSettings.init();
		Options.load();

		FlxG.fixedTimestep = false;
		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();

		Conductor.init();
		AudioSwitchFix.init();
		EventManager.init();
		FlxG.signals.focusGained.add(onFocus);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.signals.postStateSwitch.add(onStateSwitchPost);
		FlxG.signals.postUpdate.add(onUpdate);

		FlxG.mouse.useSystemCursor = true;

		ModsFolder.init();
		#if MOD_SUPPORT
		if (FileSystem.exists("mods/autoload.txt"))
			modToLoad = File.getContent("mods/autoload.txt").trim();
		ModsFolder.switchMod(modToLoad.getDefault(Options.lastLoadedMod));
		#end

		initTransition();
	}

	public static function refreshAssets() @:privateAccess {
		FunkinCache.instance.clearSecondLayer();

		var game = FlxG.game;
		var daSndTray = Type.createInstance(funkin.menus.ui.FunkinSoundTray, []);
		var index:Int = game.numChildren - 1;

		if(game.soundTray != null)
		{
			var newIndex:Int = game.getChildIndex(game.soundTray);
			if(newIndex != -1) index = newIndex;
			game.removeChild(game.soundTray);
			game.soundTray.__cleanup();
		}

		game.addChildAt(game.soundTray = daSndTray, index);
	}

	public static function initTransition():Void {
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, 0xFF000000, 1, new FlxPoint(0, -1),
			{asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, 0xFF000000, 0.7, new FlxPoint(0, 1),
			{asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}

	public static function onFocus():Void {
		_tickFocused = FlxG.game.ticks;
	}

	private static function onStateSwitch():Void {
		scaleMode.resetSize();
	}

	public static function onUpdate():Void {
		if (PlayerSettings.solo.controls.DEV_CONSOLE)
			NativeAPI.allocConsole();

		if (PlayerSettings.solo.controls.FPS_COUNTER)
			Framerate.debugMode = (Framerate.debugMode + 1) % 3;
	}

	private static function onStateSwitchPost():Void {
		@:privateAccess {
			for (length => pool in openfl.display3D.utils.UInt8Buff._pools)
				for (b in pool.clear())
					b.destroy();
			openfl.display3D.utils.UInt8Buff._pools.clear();
		}
		MemoryUtil.clearMajor();
	}

	private static var _tickFocused:Float = 0;
	public static function get_timeSinceFocus():Float {
		return (FlxG.game.ticks - _tickFocused) / 1000;
	}
}
