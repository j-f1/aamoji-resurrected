//
//  AamojiInserter.swift
//  aamoji
//
//  Created by Nate Parrott on 5/19/15.
//  Copyright (c) 2015 Nate Parrott. All rights reserved.
//

import Cocoa
import SQLite

let ReplacementsKey = "NSUserDictionaryReplacementItems"
let ReplacementOnKey = "on"
let ReplacementShortcutKey = "replace"
let ReplacementReplaceWithKey = "with"

class AamojiInserter: NSObject {
    
    var inserted: Bool? {
        get {
            if let replacements = _defaults.array(forKey: ReplacementsKey) as? [[String: Any]] {
                for replacement in replacements {
                    if let shortcut = replacement[ReplacementShortcutKey] as? String {
                        if _allShortcuts.contains(shortcut) {
                            return true
                        }
                    }
                }
                return false
            } else {
                return nil
            }
        }
        set(insertOpt) {
            if let insert = insertOpt {
                if _defaults.array(forKey: ReplacementsKey) != nil {
                    if insert {
                        _insertReplacements()
                    } else {
                        _deleteReplacements()
                    }
                    /*let withoutAamoji = replacements.filter({ !self._replacementBelongsToAamoji($0) })
                    let newReplacements: [[NSObject: NSObject]] = insert ? (withoutAamoji + aamojiEntries()) : withoutAamoji
                    var globalDomain = _defaults.persistentDomainForName(NSGlobalDomain)!
                    globalDomain[ReplacementsKey] = newReplacements
                    _defaults.setPersistentDomain(globalDomain, forName: NSGlobalDomain)
                    _defaults.synchronize()*/
                }
            }
        }
    }
    
    private func _insertReplacements() {
        // make the change in sqlite:
        let db = try! Connection(_pathForDatabase())
        var pk = ((try? db.scalar("SELECT max(Z_PK) FROM 'ZUSERDICTIONARYENTRY'")) as? Int64) ?? 0
        let timestamp = Int64(NSDate().timeIntervalSince1970)
        for entry in aamojiEntries() {
            pk += 1
            let replace = entry[ReplacementShortcutKey] as! String
            let with = entry[ReplacementReplaceWithKey] as! String
            try! db.run("INSERT INTO 'ZUSERDICTIONARYENTRY' VALUES(?,1,1,0,0,0,0,?,NULL,NULL,NULL,NULL,NULL,?,?,NULL)", [pk, timestamp, with, replace])
        }
        
        // make the change in nsuserdefaults:
        let existingReplacementEntries = _defaults.array(forKey: ReplacementsKey) as! [[String: Any]]
        _setReplacementsInUserDefaults(existingReplacementEntries + aamojiEntries())
    }
    
    private func _deleteReplacements() {
        // make the change in sqlite:
        let db = try! Connection(_pathForDatabase())
        for entry in aamojiEntries() {
            let shortcut = entry[ReplacementShortcutKey] as! String
            try! db.run("DELETE FROM 'ZUSERDICTIONARYENTRY' WHERE ZSHORTCUT = ?", [shortcut])
        }
        
        // make the change in nsuserdefaults:
        let existingReplacementEntries = _defaults.array(forKey: ReplacementsKey) as! [[String: Any]]
        let withoutAamojiEntries = existingReplacementEntries.filter({ !self._allShortcuts.contains($0[ReplacementShortcutKey] as! String) })
        _setReplacementsInUserDefaults(withoutAamojiEntries)
    }
    
    private func _pathForDatabase() -> String {
        let library = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!)
        let container1 = library.appendingPathComponent("Dictionaries/CoreDataUbiquitySupport")
        let contents = try! FileManager.default.contentsOfDirectory(atPath: container1.path)
        let userName = NSUserName()
        let matchingDirname = contents.filter({ $0.starts(with: userName) }).first!
        let container2 = container1.appendingPathComponent(matchingDirname).appendingPathComponent("UserDictionary")
        // find the active icloud directory first, then fall back to local:
        var subdir = "local"
        for child in try! FileManager.default.contentsOfDirectory(atPath: container2.path) {
            let containerDir = container2.appendingPathComponent(child).appendingPathComponent("container")
            if FileManager.default.fileExists(atPath: containerDir.path) {
                subdir = child
            }
        }
        let path = container2.appendingPathComponent(subdir).appendingPathComponent("store/UserDictionary.db")
        return path.path
    }
    
    private func _setReplacementsInUserDefaults(_ replacements: [[String: Any]]) {
        var globalDomain = _defaults.persistentDomain(forName: UserDefaults.globalDomain)!
        globalDomain[ReplacementsKey] = replacements
        _defaults.setPersistentDomain(globalDomain, forName: UserDefaults.globalDomain)
        _defaults.synchronize()
    }
    
    private lazy var _allShortcuts: Set<String> = {
        let entries = self.aamojiEntries()
        return Set(entries.map({ $0[ReplacementShortcutKey] as! String }))
    }()
    
    func aamojiEntries() -> [[String: Any]] {
        let emojiInfoJson = try! Data(contentsOf: Bundle.main.url(forResource: "emoji", withExtension: "json")!)
        let emojiInfo = try! JSONSerialization.jsonObject(with: emojiInfoJson) as! [[String: AnyObject]]
        
        var emojiByShortcut = [String: String]()
        var emojiShortcutPrecendences = [String: Double]()
        
        for emojiDict in emojiInfo {
            if let emoji = emojiDict["emoji"] as? String {
                for (shortcutUnprocessed, precedence) in _shortcutsAndPrecedencesForEmojiInfoEntry(emojiDict) {
                    if let shortcut = _processShortcutIfAllowed(shortcutUnprocessed) {
                        let existingPrecedence = emojiShortcutPrecendences[shortcut] ?? 0
                        if precedence > existingPrecedence {
                            emojiByShortcut[shortcut] = emoji
                            emojiShortcutPrecendences[shortcut] = precedence
                        }
                    }
                }
            }
        }
        
        let entries = Array(emojiByShortcut.keys).map() {
            (shortcut) -> [String: Any] in
            let emoji = emojiByShortcut[shortcut]!
            return [ReplacementOnKey: 1, ReplacementShortcutKey: "aa" + shortcut, ReplacementReplaceWithKey: emoji]
        }
        
        return entries
    }
    
    private func _shortcutsAndPrecedencesForEmojiInfoEntry(_ entry: [String: AnyObject]) -> [(String, Double)] {
        var results = [(String, Double)]()
        if let aliases = entry["aliases"] as? [String] {
            for alias in aliases {
                results.append((alias, 4))
                let cleaned = alias.replacingOccurrences(of: #"[^a-z]"#, with: "", options: .regularExpression)
                if cleaned != alias {
                    results.append((cleaned, 3))
                }
            }
        }
        if let description = entry["description"] as? String {
            let words = description.split(separator: " ")
            if let firstWord = words.first {
                results.append((String(firstWord), 2))
            }
            for word in words {
                results.append((String(word), 1))
            }
        }
        if let tags = entry["tags"] as? [String] {
            for tag in tags {
                results.append((tag, 1.5))
            }
        }
        return results
    }
    
    private var _allowedCharsInShortcutStrings = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_:")
    private func _processShortcutIfAllowed(_ shortcut: String) -> String? {
        let lowered = shortcut.lowercased()
        if lowered.containsOnlyCharactersFromSet(set: _allowedCharsInShortcutStrings) {
            return lowered
        } else {
            return nil
        }
    }
    
    private var _defaults = UserDefaults()
}
