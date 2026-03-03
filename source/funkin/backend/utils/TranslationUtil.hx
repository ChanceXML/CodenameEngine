package funkin.backend.utils;

import funkin.backend.assets.TranslatedAssetLibrary;
import funkin.backend.assets.ModsFolder;
import openfl.utils.Assets;
import haxe.xml.Access;
import haxe.io.Path;
import funkin.mobile.DebugLogger;
import funkin.backend.utils.translations.FormatUtil;

@:allow(funkin.backend.assets.TranslatedAssetLibrary)
final class TranslationUtil {

	public static var stringMap(default, set):Map<String, IFormatInfo> = [];
	public static var alternativeStringMap(default, set):Map<String, IFormatInfo> = [];
	public static var config:Map<String, String> = [];

	public static var curLanguage(get, set):String;
	public static var curLanguageName(get, set):String;
	public static var isDefaultLanguage(get, never):Bool;
	public static var isLanguageLoaded(get, never):Bool;

	public static var foundLanguages:Array<String> = [];

	private static inline var LANG_FOLDER:String = "assets/languages";

	private static var nameMap:Map<String, String> = [];
	private static var langConfigs:Map<String, Map<String, String>> = [];

	private static function get_curLanguage():String
		return Options.language;

	private static function set_curLanguage(value:String):String
		return Options.language = value;

	private static function get_curLanguageName():String
		return getLanguageName(Options.language);

	private static function set_curLanguageName(value:String):String
		return Options.language = getLanguageFromName(value);

	private static function get_isDefaultLanguage():Bool
		return Options.language == Flags.DEFAULT_LANGUAGE;

	private static function get_isLanguageLoaded():Bool
		return Lambda.count(stringMap) > 0 || isShowingMissingIds();

	private static function set_stringMap(value:Map<String, IFormatInfo>):Map<String, IFormatInfo> {
		if (value == null) value = [];
		return stringMap = value;
	}

	private static function set_alternativeStringMap(value:Map<String, IFormatInfo>):Map<String, IFormatInfo> {
		if (value == null) value = [];
		return alternativeStringMap = value;
	}

	public static function findAllLanguages():Void {
		#if TRANSLATIONS_SUPPORT
		foundLanguages = [];
		nameMap = getDefaultNameMap();
		langConfigs = getDefaultLangConfigs();

		var folders:Array<String> = [];

		for (file in Assets.list()) {
			if (!file.startsWith(LANG_FOLDER + "/")) continue;
			var parts = file.split("/");
			if (parts.length >= 3) {
				var lang = parts[2];
				if (!folders.contains(lang))
					folders.push(lang);
			}
		}

		for (lang in folders) {
			if (!isAllowed(lang)) continue;
			var config = getDefaultConfig(lang);
			nameMap.set(lang, config["name"]);
			langConfigs.set(lang, config);
			foundLanguages.push(lang + "/" + config["name"]);
		}

		var defaultName = Flags.DEFAULT_LANGUAGE + "/" + getLanguageName(Flags.DEFAULT_LANGUAGE);
		if (!foundLanguages.contains(defaultName))
			foundLanguages.insert(0, defaultName);

		if (!nameMap.exists(curLanguage))
			curLanguage = Flags.DEFAULT_LANGUAGE;
		#end
	}

	public static function setLanguage(?name:String):Void {
		#if TRANSLATIONS_SUPPORT
		if (name == null) name = curLanguage;
		if (!langConfigs.exists(name)) name = Flags.DEFAULT_LANGUAGE;

		if (curLanguage != name)
			curLanguage = name;

		for (mod in ModsFolder.getLoadedModsLibs(false))
			if (mod is TranslatedAssetLibrary)
				cast(mod, TranslatedAssetLibrary).langFolder = name;

		config = getConfig(name);
		stringMap = loadLanguage(name);

		alternativeStringMap =
			(name == Flags.DEFAULT_LANGUAGE ||
			config.get("showMissingIds").getDefault("false") == "true")
			? []
			: loadLanguage(Flags.DEFAULT_LANGUAGE);
		#end
	}

	public static function loadLanguage(lang:String):Map<String, IFormatInfo> {
		#if TRANSLATIONS_SUPPORT
		FormatUtil.clear();
		var leMap:Map<String, IFormatInfo> = [];
		final NODE_NAMES = ["text", "trans", "lang", "string", "str"];

		for (file in Assets.list()) {
			if (!file.startsWith(LANG_FOLDER + "/" + lang)) continue;
			if (Path.extension(file).toLowerCase() != "xml") continue;

			try {
				var xml = new Access(Xml.parse(Assets.getText(file)));
				if (!xml.hasNode.language) continue;

				for (node in xml.node.language.elements) {
					if (!NODE_NAMES.contains(node.name)) continue;
					if (!node.has.id) continue;

					var id = node.att.id;
					if (leMap.exists(id)) continue;

					var value = node.has.string ? node.att.string : node.innerData;
					value = value.trim().replace("\\n","\n").replace("\r","");
					leMap.set(id, FormatUtil.get(value));
				}
			} catch (e:Dynamic) {
				DebugLogger.log("Failed parsing XML: " + file);
			}
		}

		return leMap;
		#else
		return [];
		#end
	}

	public static inline function translate(id:String, ?args:Array<Dynamic>):String
		return get(id, args);

	public static inline function translateDiff(?id:String, ?params:Array<Dynamic>):String
		return get("diff." + id.toLowerCase(), params, id);

	public static function exists(id:String):Bool {
		#if TRANSLATIONS_SUPPORT
		return stringMap.exists(id) || alternativeStringMap.exists(id);
		#else
		return false;
		#end
	}

	public static function get(?id:String, ?params:Array<Dynamic>, ?def:String):String
		return getRaw(id, def).format(params);

	public static function getRaw(id:String, ?def:String):IFormatInfo {
		#if TRANSLATIONS_SUPPORT
		if (stringMap.exists(id))
			return stringMap.get(id);
		if (alternativeStringMap.exists(id))
			return alternativeStringMap.get(id);
		#end
		return def != null
			? FormatUtil.get(def)
			: FormatUtil.getStr("{" + id + "}");
	}

	public static function raw2Id(str:String):String {
		str = str.trim().toLowerCase();
		return [for(i => s in str.split(" "))
			i != 0 ? s.charAt(0).toUpperCase() + s.substr(1) : s
		].join("");
	}

	public static function getLanguageName(lang:String):String
		return nameMap.exists(lang) ? nameMap.get(lang) : lang;

	public static function getLanguageFromName(name:String):String {
		for (key => val in nameMap)
			if (val == name) return key;
		return name;
	}

	public static function getConfig(lang:String):Map<String,String>
		return langConfigs.exists(lang)
			? langConfigs.get(lang)
			: getDefaultConfig(lang);

	private static inline function isShowingMissingIds():Bool
		return Lambda.count(alternativeStringMap) > 0;

	private static inline function getDefaultNameMap():Map<String,String>
		return [Flags.DEFAULT_LANGUAGE => Flags.DEFAULT_LANGUAGE];

	private static inline function getDefaultLangConfigs():Map<String,Map<String,String>>
		return [Flags.DEFAULT_LANGUAGE => getDefaultConfig(Flags.DEFAULT_LANGUAGE)];

	private static inline function getDefaultConfig(name:String):Map<String,String>
		return ["name" => name, "credits" => "", "version" => "1.0.0"];

	private static inline function isAllowed(lang:String):Bool {
		return (!Flags.BLACKLISTED_LANGUAGES.contains(lang)) &&
			   (Flags.WHITELISTED_LANGUAGES.length == 0 ||
				Flags.WHITELISTED_LANGUAGES.contains(lang));
	}
}
