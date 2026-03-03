package funkin.backend.utils;

import funkin.backend.assets.TranslatedAssetLibrary;
import funkin.backend.assets.ModsFolder;
import openfl.utils.Assets;
import haxe.xml.Access;
import haxe.io.Path;
import funkin.mobile.DebugLogger;
import funkin.backend.utils.translations.FormatUtil;

/**
 * Translation utility
 */
@:allow(funkin.backend.assets.TranslatedAssetLibrary)
final class TranslationUtil {

    public static var stringMap(default, set):Map<String, IFormatInfo> = [];
    public static var alternativeStringMap(default, set):Map<String, IFormatInfo> = [];
    public static var config:Map<String, String> = [];
    public static var curLanguage(get, set):String;
    public static var foundLanguages:Array<String> = [];

    private static inline var LANG_FOLDER:String = "assets/languages";
    private static var nameMap:Map<String, String> = [];
    private static var langConfigs:Map<String, Map<String, String>> = [];

    public static function findAllLanguages():Void {
        #if TRANSLATIONS_SUPPORT
        try {
            foundLanguages = [];
            nameMap = [Flags.DEFAULT_LANGUAGE => Flags.DEFAULT_LANGUAGE_NAME];
            langConfigs = [Flags.DEFAULT_LANGUAGE => getDefaultConfig(Flags.DEFAULT_LANGUAGE)];

            var seen = new Map<String, Bool>();

            for (file in Assets.list()) {
                if (file == null || !file.startsWith(LANG_FOLDER)) continue;

                try {
                    var parts = file.split("/");
                    if (parts.length < 4) continue;

                    var lang = parts[2];
                    if (seen.exists(lang)) continue;
                    if (!isAllowed(lang)) continue;

                    seen.set(lang, true);

                    var config = getDefaultConfig(lang);
                    var configPath = LANG_FOLDER + "/" + lang + "/config.ini";

                    if (Assets.exists(configPath)) {
                        try {
                            var c = IniUtil.parseAsset(configPath);
                            for (i => v in c)
                                for (key => value in v)
                                    config[key] = value;
                        } catch(e:Dynamic) {
                            DebugLogger.log("Failed parsing config.ini for " + lang + ": " + Std.string(e));
                        }
                    }

                    var langName = config.exists("name") ? config["name"] : lang;
                    nameMap.set(lang, langName);
                    langConfigs.set(lang, config);
                    foundLanguages.push(lang + "/" + langName);

                } catch(e:Dynamic) {
                    DebugLogger.log("Error processing asset file: " + file + " -> " + Std.string(e));
                }
            }

            var defaultName = Flags.DEFAULT_LANGUAGE + "/" + getLanguageName(Flags.DEFAULT_LANGUAGE);
            if (foundLanguages.contains(defaultName)) foundLanguages.remove(defaultName);
            foundLanguages.insert(0, defaultName);

            if (!nameMap.exists(curLanguage)) curLanguage = Flags.DEFAULT_LANGUAGE;

            DebugLogger.log("Found languages: " + foundLanguages.join(", "));
        } catch (e:Dynamic) {
            DebugLogger.log("Unexpected error in findAllLanguages(): " + Std.string(e));
        }
        #end
    }

    public static function setLanguage(?name:String):Void {
        #if TRANSLATIONS_SUPPORT
        if (name == null) name = curLanguage;
        if (!langConfigs.exists(name)) name = Flags.DEFAULT_LANGUAGE;
        if (!langConfigs.exists(name)) name = foundLanguages.length > 0 ? foundLanguages[0].split("/")[0] : Flags.DEFAULT_LANGUAGE;

        if (curLanguage != name) {
            DebugLogger.log("Changing language to: " + name);
            curLanguage = name;
        } else {
            DebugLogger.log("Language already set to: " + name);
        }

        for(mod in ModsFolder.getLoadedModsLibs(false))
            if(mod is TranslatedAssetLibrary)
                cast(mod, TranslatedAssetLibrary).langFolder = name;

        config = getConfig(name);
        stringMap = loadLanguage(name);
        alternativeStringMap = (name == Flags.DEFAULT_LANGUAGE || config.get("showMissingIds").getDefault("false") == "true") ? [] : loadLanguage(Flags.DEFAULT_LANGUAGE);
        #end
    }

    public static function loadLanguage(lang:String):Map<String, IFormatInfo> {
        #if TRANSLATIONS_SUPPORT
        FormatUtil.clear();
        var leMap:Map<String, IFormatInfo> = [];
        var translations:Array<TranslationPair> = [];
        final NODE_NAMES = ["text", "trans", "lang", "string", "str"];

        function parseXml(xml:Access, prefix:String = "") {
            for (node in xml.elements) {
                if (node.name == "group") parseXml(node, prefix + (node.has.prefix ? node.att.prefix : ""));
                else if (NODE_NAMES.contains(node.name)) translations.push({prefix: prefix, node: node});
            }
        }

        for (file in Assets.list()) {
            if (!file.startsWith(LANG_FOLDER + "/" + lang)) continue;
            if (Path.extension(file).toLowerCase() != "xml") continue;

            try {
                var xml = new Access(Xml.parse(Assets.getText(file)));
                if (!xml.hasNode.language) {
                    DebugLogger.log("Missing <language> root in: " + file);
                    continue;
                }
                parseXml(xml.node.language);
            } catch (e:Dynamic) {
                DebugLogger.log("Failed parsing XML: " + file + " -> " + Std.string(e));
            }
        }

        for (pair in translations) {
            var node = pair.node;
            if (!node.has.id) {
                DebugLogger.log("<${node.name}> node missing ID in file for language " + lang);
                continue;
            }
            var id = pair.prefix + node.att.id;
            if (leMap.exists(id)) continue;

            var value:String = node.has.string ? node.att.string : node.innerData;
            if (node.getAtt("notrim").getDefault("true") != "true") value = value.trim();
            value = value.replace("\\n","\n").replace("\r","");
            leMap.set(id, FormatUtil.get(value));
        }

        return leMap;
        #else
        return [];
        #end
    }

    public static inline function get(?id:String, ?params:Array<Dynamic>, ?def:String):String
        return getRaw(id, def).format(params);

    public static inline function getRaw(id:String, ?def:String):IFormatInfo {
        #if TRANSLATIONS_SUPPORT
        for (map in [stringMap, alternativeStringMap]) if (map.exists(id)) return map.get(id);
        #end
        return def != null ? FormatUtil.get(def) : FormatUtil.getStr("{" + id + "}");
    }

    public static function raw2Id(str:String):String {
        str = str.trim().toLowerCase();
        return [for(i => s in str.split(" "))
            i != 0 ? s.charAt(0).toUpperCase() + s.substr(1) : s
        ].join("");
    }

    public static function getLanguageName(lang:String):String {
        return nameMap.exists(lang) ? nameMap.get(lang) : lang;
    }

    public static function getLanguageFromName(name:String):String {
        for (key => val in nameMap) if (val == name) return key;
        return name;
    }

    public static function getConfig(lang:String):Map<String,String> {
        return langConfigs.exists(lang) ? langConfigs.get(lang) : getDefaultConfig(lang);
    }

    private static inline function getDefaultConfig(name:String):Map<String,String> {
        return ["name" => getLanguageName(name), "credits" => "", "version" => "1.0.0"];
    }

    private static inline function isAllowed(lang:String):Bool {
        return (!Flags.BLACKLISTED_LANGUAGES.contains(lang)) &&
               (Flags.WHITELISTED_LANGUAGES.length == 0 || Flags.WHITELISTED_LANGUAGES.contains(lang));
    }
}

@:structInit
class TranslationPair {
    public var prefix:String;
    public var node:Access;
}
