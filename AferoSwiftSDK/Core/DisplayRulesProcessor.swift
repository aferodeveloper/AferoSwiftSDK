//
//  DisplayRulesProcessor.swift
//  iTokui
//
//  Created by Justin Middleton on 5/7/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack
import Darwin

public typealias DisplayRule = [String: Any]
public typealias DisplayRules = [DisplayRule]

infix operator ++ { associativity right }

func ++<A>(a: AnyIterator<A>, b: AnyIterator<A>) -> AnyIterator<A> {
    return AnyIterator { return a.next() ?? b.next() }
}

/// Perform a merge of two dicts-of-dicts (e.g. [String: [String: Any]])
func ++<K,V>(a: Dictionary<K, Dictionary<K,V>>, b: Dictionary<K, Dictionary<K,V>>) -> Dictionary<K, Dictionary<K,V>> {
    
    let ret = b.reduce(a) {
        curr, next in
        var ret = curr
        let cv = ret[next.key] ?? [:]
        ret[next.key] = cv ++ next.value
        return ret
    }
    
    return ret
}

func ++<A>
    (a: A, b: AnyIterator<A.Iterator.Element>) -> AnyIterator<A.Iterator.Element> where A: Sequence {
    
    var aGen = a.makeIterator()
    return  AnyIterator { aGen.next() } ++ b
}

func ++<A>(a: A, b: A) -> AnyIterator<A.Iterator.Element> where A: Sequence {
    var bgen = b.makeIterator()
    
    return a ++ AnyIterator { bgen.next() }
}

func ++<A>(a: A, b: A) -> Array<A.Iterator.Element> where A: Sequence {
    var bgen = b.makeIterator()
    
    return Array(a ++ AnyIterator { bgen.next() })
}

func ++<K, V>(a: Dictionary<K, V>, b: Dictionary<K, V>) -> Dictionary<K, V> {
    var bgen = b.makeIterator()
    return Dictionary(generator: a ++ AnyIterator { bgen.next() } )
}

extension Dictionary {
    
    /**
     Create a dictionary by unrolling the given generator. In combination with
     the ``++`` concatenation operator, this allows dictionaries to be composed like:
     
     let d = ["foo": "bar"] ++ ["mook": "meep"] ++ ["banana": "plaintain"]
     
     Values to the right overwrite values from the left, so given:
     
     let d = ["foo": "bar"] ++ ["mook": "meep"] ++ ["foo": "barbar"]
     
     ``d`` would equal ``["foo": "barbar", "mook": "meep"]``
     */
    
    init<A: IteratorProtocol>(generator gen: A) where A.Element == Element {
        self.init()
        var lgen = gen
        while let (key, value) = lgen.next() {
            self[key] = value
        }
    }
}

extension Bool: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self = (value != 0)
    }
    
    public init(floatLiteral value: FloatLiteralType) {
        self = (value != 0)
    }
}

// MARK: Matcher Parsing

extension NSRegularExpression {
    
    /**
     Get all substring matches as an array of strings.
     */
    func substringMatches(_ string: String, options: NSRegularExpression.MatchingOptions = NSRegularExpression.MatchingOptions(), range: NSRange! = nil) -> [String] {
        
        let lrange = range ?? NSMakeRange(0, (string as NSString).length)
        
        if let result = firstMatch(in: string, options: options, range: lrange) {
            var ret : [String] = []
            
            for i in 1 ..< result.numberOfRanges {
                let match = (string as NSString).substring(with: result.rangeAt(i))
                ret.append(match)
            }
            
            return ret
        }
        return []
    }
    
}

public func ++<T, K, V>(lhs: @escaping ((T)->[K: V]), rhs: @escaping ((T)->[K: V])) -> ((T)->[K: V]) {
    return {
        v in return lhs(v) ++ rhs(v)
    }
}

public typealias Token = String

open class DisplayRulesProcessor {
    
    static let TAG = "DisplayRulesProcessor"
    
    // MARK: Non-ary (is that a word?) Boolean Operators
    
    fileprivate class func False<T>() -> (T) -> Bool {
        return {
            Void in false
        }
    }
    fileprivate class func True<T>() -> (T) -> Bool {
        return {
            Void in true
        }
    }
    
    // MARK: Equality
    
    fileprivate class func Equals<T: Equatable>(_ value: T) -> (T?) -> Bool {
        return {
            if let oper = $0 {
                return oper ~== value
            }
            return false
        }
    }
    
    // MARK: Range operators
    
    fileprivate class func InClosedRange<T: Comparable>(_ lowerBound: T, upperBound: T) -> (T?) -> Bool {
        return {
            if let oper = $0 {
                return (lowerBound <= oper) && (oper <= upperBound)
            }
            return false
        }
    }
    
    fileprivate class func InLeftOpenRange<T: Comparable>(_ lowerBound: T, upperBound: T) -> (T?) -> Bool {
        return { if let oper = $0 {
            return (lowerBound < oper) && (oper <= upperBound)
            }
            return false
        }
    }
    
    fileprivate class func InRightOpenRange<T: Comparable>(_ lowerBound: T, upperBound: T) -> (T?) -> Bool {
        return {
            if let oper = $0 {
                return (lowerBound <= oper) && (oper < upperBound)
            }
            return false
        }
    }
    
    fileprivate class func InFullOpenRange<T: Comparable>(_ lowerBound: T, upperBound: T) -> (T?) -> Bool {
        return {
            if let oper = $0 {
                return (lowerBound < oper) && (oper < upperBound)
            }
            return false
        }
    }
    
    // MARK: Bitwise Operators
    
    fileprivate class func BitwiseAnd<T, U: Integer>(_ value: T, xform: @escaping (T)->U?) -> (T?) -> Bool {
        return {
            if let
                oper = $0,
                let lhs = xform(oper),
                let rhs = xform(value) {
                return (lhs & rhs) != 0
            }
            return false
        }
    }
    
    fileprivate class func BitwiseXor<T, U: Integer>(_ value: T, xform: @escaping (T)->U?) -> (T?) -> Bool {
        return {
            if let
                oper = $0,
                let lhs = xform(oper),
                let rhs = xform(value) {
                return (lhs ^ rhs) != 0
            }
            return false
        }
    }
    
    // MARK: FlipFlop
    
    fileprivate class func Allow<T>(_ f: @escaping (T)->Bool) -> (T)->Bool {
        return f
    }
    
    fileprivate class func Negate<T>(_ f: @escaping (T)->Bool) -> (T)->Bool {
        return { !f($0) }
    }
    
    // MARK: Combinators
    
    fileprivate class func CombineAnd<T>(_ lhs: @escaping (T)->Bool, rhs: @escaping (T)->Bool) -> (T) -> Bool {
        return { lhs($0) && rhs($0) }
    }
    
    fileprivate class func CombineOr<T>(_ lhs: @escaping (T)->Bool, rhs: @escaping (T)->Bool) -> (T) -> Bool {
        return { lhs($0) || rhs($0) }
    }
    
    fileprivate class func CombineXor<T>(_ lhs: @escaping (T)->Bool, rhs: @escaping (T)->Bool) -> (T) -> Bool {
        return {
            let l = lhs($0)
            let r = rhs($0)
            return (l || r) && !(l && r)
        }
    }
    
    /**
     Given an operation token and two operand tokens, along with corresponding value transforms, produce
     a compound Matcher which evaluates the `lhs` and `rhs` operands independently and returns the result
     of applying `oper` to each of them.
     
     - parameter oper: The operand token: `||` for inclusive-OR, `&&` for AND, and `^` for exclusive-OR.
     - parameter lhs: a match expression
     - parameter rhs: a match expression
     - parameter operandXform: A function which maps `String` tokens to the expected operand type `T`.
     - parameter integerOptionalXform: An optional function which maps operand type `T` to a type `U` that conforms to `BitwiseOperationsType`
     
     - returns: A matcher representing the according logical combination of `lhs` and `rhs` matchers.
     */
    
    fileprivate class func Combine<T: Comparable, U: Integer>(
        _ oper: Token,
        lhs: Token,
        rhs: Token,
        operandXform: (Token)->T,
        integerOptionalXform: @escaping ((T)->U?)
        ) -> (T?) -> Bool {
        
        var comb: (@escaping (T?)->Bool, @escaping (T?)->Bool) -> (T?) -> Bool = {
            _, _ in self.False()
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
        
        let lhsMatcher: (T?)->Bool = Matcher(lhs, operandXform: operandXform, integerOptionalXform: integerOptionalXform)
        let rhsMatcher: (T?)->Bool = Matcher(rhs, operandXform: operandXform, integerOptionalXform: integerOptionalXform)
        
        return comb(lhsMatcher, rhsMatcher)
    }
    
    /**
     Given an expression and a means to transform `String` tokens into the expected operand type `T`,
     return a function which will evaluate values of the operand type and return whether or not they match
     the given expression.
     
     - parameter expr: The expression to match, as a single string.
     - parameter operandXform: A function which maps `String` tokens to the expected operand type `T`.
     - parameter integerOptionalXform: An optional function which maps operand type `T` to a type `U` that conforms to `BitwiseOperationsType`
     
     - returns: A function which takes a value of type `T` and returns whether or not the given expression matches.
     */
    
    open class func Matcher<T: Comparable, U: Integer>(
        _ expr: String,
        operandXform: (Token)->T,
        integerOptionalXform: @escaping ((T)->U?)
        ) -> (T?) -> Bool {
        
        var lexpr = expr
        
        var wrap: (@escaping (T?)->Bool) -> ((T?)->Bool) = Allow
        
        let negate: Bool = lexpr.hasPrefix("!")
        if (negate) {
            lexpr = (lexpr as NSString).substring(from: 1)
            wrap = Negate
        }
        
        if (lexpr == "*") {
            return wrap(True())
        }
        
        var tokens: [String] = []
        
        // Handle subexpressions.
        
        let subExpressionPattern = try! NSRegularExpression(pattern: "^\\((.*)\\)(\\|\\||\\&\\&|\\^)\\((.*)\\)$", options: [])
        tokens = subExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 3) {
            let combined: (T?)->Bool = Combine(tokens[1], lhs: tokens[0], rhs: tokens[2], operandXform: operandXform, integerOptionalXform: integerOptionalXform)
            return wrap(combined)
        }
        
        // Int Equality
        
        let intExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)$", options: [])
        tokens = intExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 1) {
            let equals: (T?)->Bool = Equals(operandXform(tokens[0]))
            return wrap(equals)
        }
        
        // Range Operations
        
        let closedRangeCommaExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+),(0x\\d+|\\d+)$", options: [])
        tokens = closedRangeCommaExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 2) {
            let lhs = operandXform(tokens[0])
            let rhs = operandXform(tokens[1])
            return wrap(InClosedRange(lhs, upperBound: rhs))
        }
        
        let closedRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)\\.\\.\\.(0x\\d+|\\d+)$", options: [])
        tokens = closedRangeExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 2) {
            let lhs = operandXform(tokens[0])
            let rhs = operandXform(tokens[1])
            return wrap(InClosedRange(lhs, upperBound: rhs))
        }
        
        let leftOpenRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)<\\.\\.(0x\\d+|\\d+)$", options: [])
        tokens = leftOpenRangeExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 2) {
            let lhs = operandXform(tokens[0])
            let rhs = operandXform(tokens[1])
            return wrap(InLeftOpenRange(lhs, upperBound: rhs))
        }
        
        let rightOpenRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)\\.\\.<(0x\\d+|\\d+)$", options: [])
        tokens = rightOpenRangeExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 2) {
            let lhs = operandXform(tokens[0])
            let rhs = operandXform(tokens[1])
            return wrap(InRightOpenRange(lhs, upperBound: rhs))
        }
        
        let fullOpenRangeExpressionPattern = try! NSRegularExpression(pattern: "^(0x\\d+|\\d+)<\\.<(0x\\d+|\\d+)$", options: [])
        tokens = fullOpenRangeExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 2) {
            let lhs = operandXform(tokens[0])
            let rhs = operandXform(tokens[1])
            return wrap(InFullOpenRange(lhs, upperBound: rhs))
        }
        
        // Bitwise operations
        
        let bitwiseAndExpressionPattern = try! NSRegularExpression(pattern: "^\\&(0x\\d+|\\d+)$", options: [])
        tokens = bitwiseAndExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 1) {
            return wrap(BitwiseAnd(operandXform(tokens[0]), xform: integerOptionalXform))
        }
        
        let bitwiseXorExpressionPattern = try! NSRegularExpression(pattern: "^\\^(0x\\d+|\\d+)$", options: [])
        tokens = bitwiseXorExpressionPattern.substringMatches(lexpr)
        if (tokens.count == 1) {
            return wrap(BitwiseXor(operandXform(tokens[0]), xform: integerOptionalXform))
        }
        
        // Everything else
        
        return wrap(Equals(operandXform(lexpr)))
        
    }
    
    /**
     Given a dictionary, produce a function which takes a dictionary as input, and overlays the dictionary provided in `source`.
     
     - parameter source: The dictionary which, upon execution of the produced function, will be overlaid upon the input dictionary prior to return.
     - returns: A function which applies the above transformation.
     */
    
    open class func Applier(_ source: [String: Any]) -> ([String: Any]) -> [String: Any] {
        return {
            (target: [String: Any]) -> [String: Any] in
            
            var rTarget = target
            
            DDLogVerbose("APPLY: source: \(String(describing: source)) target: \(String(describing: rTarget))", tag: TAG)
            
            for (key, value) in source {
                
                // First, check to see if our source dict val is a dictionary.
                // If it's not, it's just going to overwrite the target val.
                guard let srcDictVal = value as? [String: Any] else {
                    rTarget[key] = value
                    continue
                }
                
                // We've established that the value coming from the source is
                // a dictionary; what about the target dict val? If it's
                // not a dictionary, go ahead and replace it.
                guard let rTargDictVal = rTarget[key] as? [String: Any] else {
                    rTarget[key] = srcDictVal
                    continue
                }
                
                // Oh, we have two dictionaries. Merge them.
                rTarget[key] = rTargDictVal ++ srcDictVal
            }
            
            DDLogVerbose("APPLY (complete): source: \(String(describing: source)) target: \(String(describing: rTarget))", tag: TAG)
            
            return rTarget
        }
    }
    
    /**
     Given a function which evaluates operand `V` according to some criteria and returns `true` or `false`, and a function which
     transforms the values of an input context `C`, produce a function which takes an operand of type `T` and a starting context `C`, performs
     the given transformation on context if the operand evaluates to `true`, and returns either the transformed or unmodified context.
     
     - parameter match: A fuction which maps an opearand of type `V` to `true` or `false`
     - parameter apply: A function which takes a context `C` on input and produces a transformed context `C` on output.
     
     - returns: A function which takes an operand `V` and context `C`, and produces a context if the operand
     evaluates to true according to the function provided in `match`.
     */
    
    open class func Rule<V, T>(
        _ match: @escaping (V?)->Bool,
        apply: @escaping (T)->T
        ) -> ((V?, T)->T) {
        
        return {
            value, target in
            
            if (match(value)) {
                
                DDLogVerbose("RULE (MATCHED): (\(V.self, T.self))->\(T.self) value: \(String(reflecting: value)) target: \(target)", tag: TAG)
                
                return apply(target)
            }
            
            DDLogVerbose("RULE (MISSED): (\(V.self, T.self))->\(T.self) value: \(String(reflecting: value)) target: \(target)", tag: TAG)
            
            return target
        }
    }
    
    /**
     Given a function that produces a value (`fetch`), a function which interrogates
     the value and returns a boolean (`match`), and a function which applies changes to input
     and returns output, return a function which:
     
     1. Accepts a context `C` and a target `T`
     2. Fetches the the expected value `V?` by passing `C` to the fetch function.
     2. Evaluates the resulting `V?` according to the match
     3. Applies the transformation `(T)->T` and returns the transformed value if the match in (3) was positive,
     or simply returns the unchanged input value if the match was negative.
     
     - parameter fetch: A function which takes the context being evaluated and returns a value that will in turn be passed to the `match` function.
     - parameter match: A fuction which maps an opearand of type `T` to `true` or `false`
     - parameter apply: A function which takes a dictionary on input and produces a transformed dictionary on output.
     
     - returns: the function described above
     */
    
    
    open class func Rule<C, V, T>(
        _ fetch: @escaping ((C)->V?),
        match: @escaping (V?)->Bool,
        apply: @escaping (T)->T
        ) -> ((C?, T)->T) {
        
        return {
            source, target in
            
            if let source = source {
                
                let value = fetch(source)
                
                if (match(value)) {
                    
                    DDLogVerbose("RULE (MATCHED): (\(C.self, T.self))->\(T.self) source: \(String(reflecting: source)) value: \(String(reflecting: value)) target: \(target)", tag: TAG)
                    let ret = apply(target)
                    //                        DDLogDebug("ret: \(ret)", tag: TAG)
                    return ret
                }
            }
            
            DDLogVerbose("RULE (MISSED): (\(C.self, T.self))->\(T.self) source: \(String(reflecting: source)) target: \(target)", tag: TAG)
            
            return target
        }
    }
    
    /**
     Given a dictionary of starting values, and an array of rules, return a function which evaluates a single argument/operand of type `C` according to the rules
     and outputs the resulting dictionary.
     
     - parameter initial: A `T` that represents the initial values for rule processing.
     - parameter rules: An array of functions which take context type `C` and target type `T`, and produce a possibly transformed `C`s.
     
     - returns: A function wich evaluates an operand of type `C` against successive rules, passing the output from one to the input of the next.
     */
    
    open class func Processor<R: Sequence, C: Hashable, T>(
        
        _ initial: T,
        rules: R
        
        ) -> (C?) -> T where R.Iterator.Element == ((C?, T) -> T) {
        
        return {
            value in
            var workingSet = initial
            
            if let value = value {
                //                DDLogDebug("PROCESSOR: (\(C.self))->\(T.self) value: \(value) initial: \(workingSet)", tag: TAG)
                
                for rule in rules {
                    workingSet = rule(value, workingSet)
                }
                
            }
            
            return workingSet
        }
    }
    
    // MARK: - Public
    
    /**
     Given a dictionary representing a rule, and a couple of required transforms, return a function which
     evaluates its arguments according to the provided rules, and outputs corresponding dictionary.
     
     - parameter ruleDict: A dictionary with `match` and `apply` keys, mapping to a match expression and an apply dictionary, respectively.
     - parameter operandXform: A transform from a String to operand type `T`
     - parameter integerOptionalXform: A transform from operand type `T` to bitwiseOperable type `U`. For integer types, this should just be the identity transform.
     
     - returns: A function which takes a single operand `T` as input, and returns a `[String: Any]` that's a result of evaluating the operand against the given rules.
     */
    
    class func MakeRule<T: Hashable & Comparable, U: Integer>(
        
        _ ruleDict: [String: Any],
        operandXform: (String)->T,
        integerOptionalXform: @escaping (T)->U?
        
        ) -> ((T?, [String: Any]) -> [String: Any]) {
        
        if let match = ruleDict["match"] as? String {
            if let apply = ruleDict["apply"] as? [String: Any] {
                return Rule(Matcher(match, operandXform: operandXform, integerOptionalXform: integerOptionalXform), apply: Applier(apply))
            }
        }
        return Rule(Matcher("*", operandXform: operandXform, integerOptionalXform: integerOptionalXform), apply: Applier([:]))
    }
    
    /**
     Given a dictionary representing a rule, and a couple of required transforms, return a function which
     evaluates its arguments according to the provided rules, and outputs corresponding dictionary.
     
     - parameter ruleDict: A dictionary with `match` and `apply` keys, mapping to a match expression and an apply dictionary, respectively. Optionally, an `attribute` key can be provided; if available, it will be used
     to dereference the specific attribute when the result is passed a context.
     - parameter operandXform: A transform from a String to operand type `T`
     - parameter integerOptionalXform: A transform from operand type `T` to bitwiseOperable type `U`. For integer types, this should just be the identity transform.
     
     - returns: A function which takes a single operand `T` as input, and returns a `[String: Any]` that's a result of evaluating the operand against the given rules.
     */
    
    class func MakeRule<K: Hashable, C: Hashable & SafeSubscriptable, T: Comparable, U: Integer>(
        
        _ ruleDict: [String: Any],
        operandXform: (String)->T,
        integerOptionalXform: @escaping (T)->U?
        
        ) -> ((C?, [String: Any]) -> [String: Any]) where C.Value == T, C.Key == K {
        
        let matcher = DisplayRulesProcessor.Matcher(
            ruleDict["match"] as? String ?? "*",
            operandXform: operandXform,
            integerOptionalXform: integerOptionalXform
        )
        
        let applier = Applier(
            ruleDict["apply"] as? [String: Any] ?? [:]
        )
        
        let attribute = ruleDict["attributeId"] as? K
        
        return Rule(
            {
                (context: C) -> T? in
                
                let ret = context[safe: attribute]
                
                var attrDesc = "<nil>"
                if let attribute = attribute {
                    attrDesc = String(reflecting: attribute)
                }
                
                var attrVal = "<nil>"
                if let ret = ret {
                    attrVal = String(describing: ret)
                }
                
                DDLogVerbose("****** RULE: fetch attribute:\(attrDesc)) value: \(attrVal)", tag: TAG)
                return ret
        },
            match: matcher,
            apply: applier
        )
    }
    
    /**
     Given a dictionary of defaults, an array of rules dicts, and a couple of required transforms, return a function which
     evaluates its arguments according to the provided rules in succession, and outputs corresponding dictionary.
     
     - parameter initial: A `[String: Any]` that represents the initial values of the dictionary. If no rules match a given value, for example, this dictionary will be returned.
     - parameter rules: An array of dictionaries, each representing a rule (with `match` and `apply` keys, mapping to a match expression and an apply dictionary).
     - parameter operandXform: A transform from a String to operand type `T`
     - parameter integerOptionalXform: A transform from operand type `T` to bitwiseOperable type `U`. For integer types, this should just be the identity transform.
     
     - returns: A function which takes a single operand `T` as input, and returns a `[String: Any]` that's a result of evaluating the operand against the given rules.
     */
    
    open class func MakeProcessor<T: Hashable & Comparable, U: Integer>(
        
        _ initial: [String: Any],
        rules: DisplayRules,
        operandXform: @escaping (String)->T,
        integerOptionalXform: @escaping (T)->U?
        
        ) -> (T?)->[String: Any] {
        
        return Processor(
            initial,
            rules: rules.map() { self.MakeRule($0, operandXform: operandXform, integerOptionalXform: integerOptionalXform) })
    }
    
    /**
     Given a dictionary of defaults, an array of rules dicts, and a couple of required transforms, return a function which
     evaluates its arguments according to the provided rules in succession, and outputs corresponding dictionary.
     
     - parameter initial: A `[String: Any]` that represents the initial values of the dictionary. If no rules match a given value, for example, this dictionary will be returned.
     - parameter rules: An array of dictionaries, each representing a rule (with `match` and `apply` keys, mapping to a match expression and an apply dictionary).
     - parameter operandXform: A transform from a String to operand type `T`
     - parameter integerOptionalXform: A transform from operand type `T` to bitwiseOperable type `U`. For integer types, this should just be the identity transform.
     
     - returns: A function which takes a single operand `T` as input, and returns a `[String: Any]` that's a result of evaluating the operand against the given rules.
     */
    
    open class func MakeProcessor<
        K: Hashable,
        C: Hashable & SafeSubscriptable,
        T: Comparable,
        U: Integer>(
        
        _ initial: [String: Any],
        rules: DisplayRules,
        operandXform: @escaping (String)->T,
        integerOptionalXform: @escaping (T)->U?
        
        ) -> (C?)->[String: Any]
        where C.Value == T, C.Key == K {
            
            return Processor(
                initial,
                rules: rules.map() { self.MakeRule($0, operandXform: operandXform, integerOptionalXform: integerOptionalXform)
            })
    }
    
}
