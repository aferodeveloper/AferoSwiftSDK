//: Playground - noun: a place where people can play

import Cocoa

//
//  DisplayRulesProcessor.swift
//  iTokui
//
//  Created by Justin Middleton on 5/7/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import Darwin

// MARK: Non-ary (is that a word?) Boolean Operators

private func False<T>() -> (T) -> Bool { return { Void in false } }
private func True<T>() -> (T) -> Bool { return { Void in true } }

// MARK: Equality

private func Equals<T: Equatable>(value: T) -> (T) -> Bool {
    return { $0 == value }
}

// MARK: Range operators

private func InClosedRange<T: Comparable>(lowerBound: T, upperBound: T) -> (T) -> Bool {
    return { (lowerBound <= $0) && ($0 <= upperBound) }
}

private func InLeftOpenRange<T: Comparable>(lowerBound: T, upperBound: T) -> (T) -> Bool {
    return { (lowerBound < $0) && ($0 <= upperBound) }
}

private func InRightOpenRange<T: Comparable>(lowerBound: T, upperBound: T) -> (T) -> Bool {
    return { (lowerBound <= $0) && ($0 < upperBound) }
}

private func InFullOpenRange<T: Comparable>(lowerBound: T, upperBound: T) -> (T) -> Bool {
    return { (lowerBound < $0) && ($0 < upperBound) }
}

// MARK: Bitwise Operators

private protocol BitwiseOperable { }

private func BitwiseAnd(value: Int) -> (Int) -> Bool {
    return { 0 != ($0 & value) }
}

private func BitwiseXor(value: Int) -> (Int) -> Bool {
    return { 0 != ($0 ^ value) }
}

// MARK: FlipFlop

func Allow<T>(f: (T)->Bool) -> (T)->Bool {
    return f
}

func Negate<T>(f: (T)->Bool) -> (T)->Bool {
    return { !f($0) }
}

// MARK: Combinators

func CombineAnd<T>(lhs: (T)->Bool, rhs: (T)->Bool) -> (T) -> Bool {
    return { lhs($0) && rhs($0) }
}

func CombineOr<T>(lhs: (T)->Bool, rhs: (T)->Bool) -> (T) -> Bool {
    return { lhs($0) || rhs($0) }
}

func CombineXor<T>(lhs: (T)->Bool, rhs: (T)->Bool) -> (T) -> Bool {
    return {
        let l = lhs($0)
        let r = rhs($0)
        return (l || r) && !(l && r)
    }
}

func IntCombine(oper: String, lhs: String, rhs: String) -> (Int) -> Bool {
    
    var comb: ((Int)->Bool, (Int)->Bool) -> (Int) -> Bool = {
        _, _ in False()
    }
    
    switch(oper) {
        
    case "||":
        comb = CombineOr
    case "&&":
        comb = CombineAnd
    case "^":
        comb = CombineXor
    default: break
        
    }
    
    return comb(Matcher(lhs), Matcher(rhs))
}

// MARK: Matcher Parsing

extension NSRegularExpression {
    
    /**
    Get all substring matches as an array of strings.
    */
    func substringMatches(string: String, options: NSMatchingOptions = NSMatchingOptions(), var range: NSRange! = nil) -> [String] {
        range = range ?? NSMakeRange(0, (string as NSString).length)
        
        var i = 0
        
        if let result = firstMatchInString(string, options: options, range: range) {
            var ret : [String] = []
            
            for (var i = 1; i < result.numberOfRanges; i++) {
                let match = (string as NSString).substringWithRange(result.rangeAtIndex(i))
                print("got a match: \(match)")
                ret.append(match)
            }
            
            return ret
        }
        return []
    }
    
}

extension String {
    
    func toDecimalInt() -> Int? {
        if (hasPrefix("0x")) {
            return Int(strtoul(self, nil, 16))
        }
        return toInt()
    }
}


func Matcher(var expr: String) -> (Int)->Bool {
    
    var wrap: ((Int)->Bool) -> ((Int)->Bool) = Allow
    
    let negate: Bool = expr.hasPrefix("!")
    if (negate) {
        expr = (expr as NSString).substringFromIndex(1)
        wrap = Negate
    }
    
    if (expr == "*") {
        print("Matched '*'")
        return wrap(True())
    }
    
    var matches: [String] = []
    
    // Handle subexpressions.
    
    let subExpressionPattern = try! NSRegularExpression(pattern: "^\\((.*)\\)(\\|\\||\\&\\&|\\^)\\((.*)\\)$", options: [])
    matches = subExpressionPattern.substringMatches(expr)
    if (matches.count == 3) {
        return wrap(IntCombine(matches[1], lhs: matches[0], rhs: matches[2]))
    }
    
    let intExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)$", options: [])
    matches = intExpressionPattern.substringMatches(expr)
    if (matches.count == 1) {
        return wrap(Equals(matches[0].toDecimalInt()!))
    }
    
    let closedRangeCommaExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+),(0x\\d+|\\d+)$", options: [])
    matches = closedRangeCommaExpressionPattern.substringMatches(expr)
    if (matches.count == 2) {
        let lhs = matches[0].toDecimalInt()!
        let rhs = matches[1].toDecimalInt()!
        return wrap(InClosedRange(lhs, upperBound: rhs))
    }
    
    let closedRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)\\.\\.\\.(0x\\d+|\\d+)$", options: [])
    matches = closedRangeExpressionPattern.substringMatches(expr)
    if (matches.count == 2) {
        let lhs = matches[0].toDecimalInt()!
        let rhs = matches[1].toDecimalInt()!
        return wrap(InClosedRange(lhs, upperBound: rhs))
    }
    
    let leftOpenRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)<\\.\\.(0x\\d+|\\d+)$", options: [])
    matches = leftOpenRangeExpressionPattern.substringMatches(expr)
    if (matches.count == 2) {
        let lhs = matches[0].toDecimalInt()!
        let rhs = matches[1].toDecimalInt()!
        return wrap(InLeftOpenRange(lhs, upperBound: rhs))
    }
    
    let rightOpenRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)\\.\\.<(0x\\d+|\\d+)$", options: [])
    matches = rightOpenRangeExpressionPattern.substringMatches(expr)
    if (matches.count == 2) {
        let lhs = matches[0].toDecimalInt()!
        let rhs = matches[1].toDecimalInt()!
        return wrap(InRightOpenRange(lhs, upperBound: rhs))
    }
    
    let fullOpenRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)<\\.<(0x\\d+|\\d+)$", options: [])
    matches = fullOpenRangeExpressionPattern.substringMatches(expr)
    if (matches.count == 2) {
        let lhs = matches[0].toDecimalInt()!
        let rhs = matches[1].toDecimalInt()!
        return wrap(InFullOpenRange(lhs, upperBound: rhs))
    }
    
    let bitwiseAndExpressionPattern = try! NSRegularExpression(pattern: "^\\&(0x\\d+|\\d+)$", options: [])
    matches = bitwiseAndExpressionPattern.substringMatches(expr)
    if (matches.count == 1) {
        let value = matches[0].toDecimalInt()!
        return wrap(BitwiseAnd(value))
    }
    
    let bitwiseXorExpressionPattern = try! NSRegularExpression(pattern: "^\\^(0x\\d+|\\d+)$", options: [])
    matches = bitwiseXorExpressionPattern.substringMatches(expr)
    if (matches.count == 1) {
        let value = matches[0].toDecimalInt()!
        return wrap(BitwiseAnd(value))
    }
    
    return False()
}

func Applier(source: [String: Any]) -> ([String: Any]) -> [String: Any] {
    return {
        (var target: [String: Any]) -> [String: Any] in
        for (key, value) in source {
            target[key] = value
        }
        return target
    }
}

func Rule<T>(match: (T)->Bool, apply: ([String: Any])->[String: Any]) -> ((T, [String: Any])->[String: Any]) {
    return {
        value, target in
        print("value: \(value)")
        if (match(value)) {
            print("matched value!")
            return apply(target)
        }
        return target
    }
}

func Processor<T>(defaults: [String: Any], rules: Array<(T, [String: Any])->[String: Any]>) -> (T)->[String: Any] {
    return {
        value in
        var workingSet = defaults
        for rule in rules {
            workingSet = rule(value, workingSet)
        }
        return workingSet
    }
}

func makeRule(ruleDict: [String: Any]) -> ((Int, [String: Any]) -> [String: Any]) {
    if let match = ruleDict["match"] as? String {
        if let apply = ruleDict["apply"] as? [String: Any] {
            return Rule(Matcher(match), apply: Applier(apply))
        }
    }
    return Rule(Matcher("*"), apply: Applier([:]))
}

func makeProcessor(defaults: [String: Any], rules: [[String: Any]]) -> (Int)->[String: Any] {
    return Processor(defaults, rules: rules.map() { makeRule($0) })
}

let defaults = ["hi": "there"]

let rules: [[String: Any]] = [
    [
        "match": "*",
        "apply": [
            "hint": "",
            "barColor": "#00FF00"
        ]
    ],
    [
        "match": "0",
        "apply": [
            "hint": "Discharged",
            "barColor": "#FF0000"
        ]
    ],
    [
        "match": "1...15",
        "apply": [
            "hint": "Low Battery",
            "tintColor": "red",
            "barColor": "#FF0000"
        ]
    ],
    [
        "match": "16...35",
        "apply": [
            "barColor": "#FFFF00",
            "sounds": [
                "quack",
                "moof",
                "I fart in your general direction."
            ]
        ]
    ],
    [
        "match": "16...99",
        "apply": [
            "hint": "Sufficient Charge"
        ]
    ],
    [
        "match": "0x32",
        "apply": [
            "hint": "Half Charged"
        ]
    ],
    [
        "match": "100",
        "apply": [
            "hint": "Charged",
            "admonishment": "You are amazing."
        ]
    ],
    [
        "match": "101",
        "apply": [
            "hint": "Charging",
            "externalPower": true
        ]
    ],
    [
        "match": "102",
        "apply": [
            "hint": "Fully charged",
            "externalPower": true
        ]
    ],
    [
        "match": "&0x02",
        "apply": [
            "also": "My 2-bit is set."
        ]
    ],
    [
        "match": "(&0x02)&&(!&0x01)",
        "apply": [
            "also": "My 2-bit is set, but my 1-isn't."
        ]
    ],
    [
        "match": "((&0x02)&&(3...12))||(20...30)",
        "apply": [
            "also": "2-bit set and betwen 3 and 12 (inclusive), or between 20 and 30(inclusive)"
        ]
    ],
]

let processor = makeProcessor(defaults, rules: rules)
processor(0)
processor(9)
processor(10)
processor(15)
processor(29)
processor(30)
processor(50)

