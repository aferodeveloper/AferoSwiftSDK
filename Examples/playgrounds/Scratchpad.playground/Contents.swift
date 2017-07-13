//: Playground - noun: a place where people can play

import UIKit

enum State {
    case a
    case b
    
    mutating func transition() {
        switch self {
        case .a: self = .b
        case .b: self = .a
        }
    }
}

class Foo {

    var state: State = .a {
        didSet {
            print("New state: \(state)")
        }
    }
    
}

let f = Foo()

f.state.transition()
f.state.transition()


// See http://stackoverflow.com/questions/36322336/positive-nsdecimalnumber-returns-unexpected-64-bit-integer-values

Int64.max
Int64.max

let n = NSDecimalNumber(value: false)
let m = NSDecimalNumber(value: true).boolValue

// clamp(ivalue: 9.374999403953555456 minValue: -40 maxValue: 50 vlong: -9 cval: -9): -9

//let v = NSDecimalNumber(double: 9.821426272392280064)
let v = NSDecimalNumber(string: "9.821426272392280061")
v
v.intValue
v.int64Value

NSDecimalNumber(value: v.doubleValue).intValue



let v2 = NSDecimalNumber(string: "9.821426272392280060")
v2
v2.intValue
v2.int64Value

let v3 = NSDecimalNumber(value: 9.64286)
v3
v3.intValue
v3.int64Value

protocol Moopy {
    var i: Int { get }
}

struct m1: Moopy {
    var i: Int { return 1 }
}

class m2: Moopy {
    var i: Int { return 2 }
}

enum m3: Moopy {
    
    case flarg
    
    var i: Int { return 3 }
}

var moopyArr: [Moopy] = []

moopyArr.append(m1())
moopyArr.append(m2())
moopyArr.append(m3.flarg)

moopyArr


struct ScaleTypes: OptionSet {
    
    typealias RawValue = UInt
    
    private var value: RawValue = 0
    
    // MARK: NilLiteralConvertible
    
    init(nilLiteral: Void) {
        self.value = 0
    }
    
    // MARK: RawLiteralConvertible
    
    init(rawValue: RawValue) {
        self.value = rawValue
    }
    
    static func fromRaw(raw: UInt) -> ScaleTypes {
        return self.init(rawValue: raw)
    }
    
    init(bitIndex: UInt) {
        self.init(rawValue: 0x01 << bitIndex)
    }
    
    var rawValue: RawValue { return self.value }
    
    
    // MARK: BooleanType
    
    var boolValue: Bool {
        return value != 0
    }
    
    // MARK: BitwiseOperationsType
    
    static var allZeros: ScaleTypes {
        return self.init(rawValue: 0)
    }
    
    // MARK: Actual values
    
    static func fromMask(raw: UInt) -> ScaleTypes {
        return self.init(rawValue: raw)
    }
    
    /// No mode
    
    static var None: ScaleTypes { return allZeros }
    
    static var Nominal: ScaleTypes { return self.init(rawValue: 1) }
    static var Ordinal: ScaleTypes { return self.init(rawValue: 3) }
    static var Interval: ScaleTypes { return self.init(rawValue: 7) }
    
}

let nominal = ScaleTypes.Nominal
let ordinal = ScaleTypes.Ordinal
let interval = ScaleTypes.Interval

interval.contains(nominal)
interval.contains(ordinal)
interval.contains(interval)

ordinal.contains(interval)
ordinal.contains(ordinal)
ordinal.contains(nominal)

nominal.contains(interval)
nominal.contains(ordinal)
nominal.contains(nominal)

interval.intersection(ordinal).rawValue

Int64.max
Int64.min



