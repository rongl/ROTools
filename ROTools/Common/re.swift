//
//  re.swift
//  ROTools
//
//  Created by RonGL on 15/11/13.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Foundation



class RegexObject {
    typealias Flag = NSRegularExpressionOptions
    
    var isValid: Bool {
        return regex != nil
    }
    
    let pattern: String
    
    private let regex: NSRegularExpression?
    
    var nsRegex: NSRegularExpression? {
        return regex
    }
    
    var flags: Flag {
        return regex?.options ?? []
    }
    
    var groups: Int {
        return regex?.numberOfCaptureGroups ?? 0
    }
    
    required init(pattern: String, flags: Flag = [])  {
        self.pattern = pattern
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: flags)
        } catch let error as NSError {
            self.regex = nil
            debugPrint(error)
        }
    }
    
    func search(string: String, _ pos: Int = 0, _ endpos: Int? = nil, options: NSMatchingOptions = []) -> MatchObject? {
        guard let regex = regex else {
            return nil
        }
        let start = pos > 0 ?pos :0
        let end = endpos ?? string.characters.count
        let length = max(0, end - start)
        let range = NSRange(location: start, length: length)
        if let match = regex.firstMatchInString(string, options: options, range: range) {
            return MatchObject(string: string, match: match)
        }
        return nil
    }
    
    func match(string: String, _ pos: Int = 0, _ endpos: Int? = nil) -> MatchObject? {
        return search(string, pos, endpos, options: [.Anchored])
    }
    
    func split(string: String, _ maxsplit: Int = 0) -> [String?] {
        guard let regex = regex else {
            return []
        }
        var splitsLeft = maxsplit == 0 ? Int.max : (maxsplit < 0 ? 0 : maxsplit)
        let range = NSRange(location: 0, length: string.characters.count)
        var results = [String?]()
        var start = string.startIndex
        var end = string.startIndex
        regex.enumerateMatchesInString(string, options: [], range: range) { result, _, stop in
            if splitsLeft <= 0 {
                stop.memory = true
                return
            }
            
            guard let result = result where result.range.length > 0 else {
                return
            }
            
            end = string.startIndex.advancedBy(result.range.location)
            results.append(string[start..<end])
            if regex.numberOfCaptureGroups > 0 {
                results += MatchObject(string: string, match: result).groups()
            }
            splitsLeft--
            start = end.advancedBy(result.range.length)
        }
        if start <= string.endIndex {
            results.append(string[start..<string.endIndex])
        }
        return results
    }
    
    func findall(string: String, _ pos: Int = 0, _ endpos: Int? = nil) -> [String] {
        return finditer(string, pos, endpos).map { $0.group()! }
    }
    
    func finditer(string: String, _ pos: Int = 0, _ endpos: Int? = nil) -> [MatchObject] {
        guard let regex = regex else {
            return []
        }
        let start = pos > 0 ?pos :0
        let end = endpos ?? string.characters.count
        let length = max(0, end - start)
        let range = NSRange(location: start, length: length)
        return regex.matchesInString(string, options: [], range: range).map { MatchObject(string: string, match: $0) }
    }
    
    func sub(repl: String, _ string: String, _ count: Int = 0) -> String {
        return subn(repl, string, count).0
    }
    
    func subn(repl: String, _ string: String, _ count: Int = 0) -> (String, Int) {
        guard let regex = regex else {
            return (string, 0)
        }
        let range = NSRange(location: 0, length: string.characters.count)
        let mutable = NSMutableString(string: string)
        let maxCount = count == 0 ? Int.max : (count > 0 ? count : 0)
        var n = 0
        var offset = 0
        regex.enumerateMatchesInString(string, options: [], range: range) { result, _, stop in
            if maxCount <= n {
                stop.memory = true
                return
            }
            if let result = result {
                n++
                let resultRange = NSRange(location: result.range.location + offset, length: result.range.length)
                let lengthBeforeReplace = mutable.length
                regex.replaceMatchesInString(mutable, options: [], range: resultRange, withTemplate: repl)
                offset += mutable.length - lengthBeforeReplace
            }
        }
        return (mutable as String, n)
    }
}


final class MatchObject {
    let string: String
    let match: NSTextCheckingResult
    
    init(string: String, match: NSTextCheckingResult) {
        self.string = string
        self.match = match
    }
    
    func expand(template: String) -> String {
        guard let regex = match.regularExpression else {
            return ""
        }
        return regex.replacementStringForResult(match, inString: string, offset: 0, template: template)
    }
    
    func group(index: Int = 0) -> String? {
        guard let range = span(index) where range.startIndex < string.endIndex else {
            return nil
        }
        return string[range]
    }
    
    func group(indexes: [Int]) -> [String?] {
        return indexes.map { group($0) }
    }
    
    func groups(defaultValue: String) -> [String] {
        return (1..<match.numberOfRanges).map { group($0) ?? defaultValue }
    }
    
    func groups() -> [String?] {
        return (1..<match.numberOfRanges).map { group($0) }
    }
    
    func span(index: Int = 0) -> Range<String.Index>? {
        if index >= match.numberOfRanges {
            return nil
        }
        let nsrange = match.rangeAtIndex(index)
        
        if nsrange.location == NSNotFound {
            return string.endIndex..<string.endIndex
        }
        let startIndex = string.startIndex.advancedBy(nsrange.location)
        let endIndex = startIndex.advancedBy(nsrange.length)
        return startIndex..<endIndex
    }
}

class re {
    
    static func search(pattern: String, _ string: String, flags: RegexObject.Flag = []) -> MatchObject? {
        return re.compile(pattern, flags: flags).search(string)
    }
    
    static func compile(pattern: String, flags: RegexObject.Flag = []) -> RegexObject  {
        return RegexObject(pattern: pattern, flags: flags)
    }
}
