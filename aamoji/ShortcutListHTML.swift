//
//  AamojiInserter+HTML.swift
//  aamoji
//
//  Created by Nate Parrott on 5/19/15.
//  Copyright (c) 2015 Nate Parrott. All rights reserved.
//

import Foundation

let ReplacementShortcutKey = "replace"
let ReplacementReplaceWithKey = "with"
let ReplacementOnKey = "on"

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
        return ["shortcut": "aa" + shortcut, "phrase": emoji]
//        return [ReplacementOnKey: 1, ReplacementShortcutKey: "aa" + shortcut, ReplacementReplaceWithKey: emoji]
    }
    
    return entries
}

public func shortcutListHTML() -> String {
    let template = try! String(contentsOf: Bundle.main.url(forResource: "ShortcutListTemplate", withExtension: "html")!)
    
    var shortcutsForEmoji = [String: [String]]()
    for entry in aamojiEntries() {
        let emoji = entry["phrase"] as! String
        let shortcut = entry["shortcut"] as! String
        shortcutsForEmoji[emoji] = (shortcutsForEmoji[emoji] ?? []) + [shortcut]
    }
    
    var html = ""
    for (emoji, shortcuts) in shortcutsForEmoji {
        let allShortcuts = shortcuts.joined(separator: ", ")
        html += "<li><span class='emoji'>\(emoji)</span> \(allShortcuts)</li>\n"
    }
    
    return template.replacingOccurrences(of: "<!--SHORTCUTS-->", with: html)
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
