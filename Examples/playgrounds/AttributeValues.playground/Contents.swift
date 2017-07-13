//: # AttributeValue Playground
//:
//: A few examples o fhow AttributeValues can be used. See also `TypeTests.swift`.

import UIKit
import Afero

//: ## `AttributeValue` Types
//:
//: ### Boolean attribute values
//:
//: `AttributeValue` supports a single `Boolean` type, `.Boolean(Bool)`.
//: To create one, Pass a `Bool` to the initializer to create an `AttributeValue
//: representing` a `Bool`.

let v2 = AttributeValue(true) // result is AttributeValue.Bool(true)

//: AttributeValue also conforms to BooleanLiteralConvertible, so you can declare
//: a value's type as AttributeValue, and assign a boolean literal to it:

let v1: AttributeValue = true // Result is also AttributeValue.Bool(true)

//: `AttributeValues`s are `Equatable` (actually, `Hashable`), so equivalence
//: can be checked between two AttributeValues:

v1 == v2

//: Since they're both `BooleanLiteralConvertible` and `Equatable`, they can be
//: compared against boolean literals.

v1 == true                   // True; v1 (and v2) were instantiated from `true`
v1 == false                  // False, because of same
AttributeValue(false) == false  // True!

//: ### Integer Attribute Values
//:
//: `AttributeValue`s can represent integers of multiple types:
//:
//: #### Signed Integers
//: * `.SignedInt64(Int)`: A long (64-bit) signed integer. Maps to the builtin `Int` type.
//: * `.SignedInt32(Int32)`: A 32-bit signed integer type. Maps to builtin `Int32` type.
//: * `.SignedInt16(Int16)`: A 16-bit signed integer type. Maps to builtin `Int16` type.
//: * `.SignedInt8(Int8)`: A 8-bit signed integer type. Maps to builtin `Int8` type.
//:
//: #### Unsigned Integers
//: * `UnsignedInt64(UInt)`: A long (64-bit) signed integer. Maps to the builtin `Int` type.
//: * `UnsignedInt32(UInt32)`: A 32-bit signed integer type. Maps to builtin `Int32` type.
//: * `UnsignedInt16(UInt16)`: A 16-bit signed integer type. Maps to builtin `Int16` type.
//: * `UnsignedInt8(Uint8)`: A 8-bit signed integer type. Maps to builtin `Int8` type.
//:
//: As with `.Boolean(Bool)`, you can create an integral `AttributeValue` in multiple ways:

let i1 = AttributeValue(1)               // .SignedInt64(1)
let i2 = AttributeValue(Int32(1))        // .SignedInt32(1)
let i3 = AttributeValue(Int16(1))        // .SignedInt16(1)

//: We can also create with an integer literal. Using this style,
//: we always get a .SignedInt64(Int):

let i4: AttributeValue = 1

//: We can now test equivalence:

i1 == i1   // True, same value
i1 == i2   // False, types are different
i1 == i3   // Ditto
i1 == i4   // True; literal-initialized integral `AttributeValue`s are `.SignedInt64(Int)`s

//: ### Floating-point AttributeValues
//:
//: `AttributeValue` supports two floating-point types:
//:
//: * `.Float32(Float)`: a 32-bit floating-point number, internally represented by a native `Swift.Float`.
//: * `.Float64(Double)`: a 64-bit floating-point number, internally represented by a native `Swift.Double`.
//:
//: Unless explicitly requested, AttributeValue defaults to `.Float64(Double)`
//: for floating-point types. We can create floating-point `AttributeValue`s in a number of ways:

let f1 = AttributeValue(3.0)          // `.Float64(Double)`
let f2 = AttributeValue(Float(3.0))   // `.Float32(Float)`
let f3 = AttributeValue(Double(3.0))  // `.Float64(Double)`
let f4: AttributeValue = 3.0          // `.Float64(Double)`

f1 == f2   // False; not the same type.
f1 == f3   // True; both `.Float64(Double)`.
f1 == f4   // True; both `.Float64(Double)`.

//: ### Strings
//:
//: `AttributeValue` supports UTF-8 strings with the `.UTF8S(String)` member:

let s1 = AttributeValue("Kiban")
let s2 = AttributeValue.utf8S("Kiban")
let s3: AttributeValue = "Kiban"
let s4: AttributeValue = "Tokui"

s1 == s2  // True; both "Kiban"
s1 == s3  // True; both "Kiban"
s1 == s4  // False; different strings

//: ### RawBytes
//:
//: In addition to numeric and string types, AttributeValue supports a `.RawBytes([UInt8])` type.

let b1 = AttributeValue([0x6A, 0x6F, 0x65, 0x62, 0x72, 0x69, 0x74, 0x74] as [UInt8])
let b2: AttributeValue = [0x73, 0x6B, 0x72, 0x6F, 0x6C, 0x6C]
let b3: AttributeValue = [0x73, 0x6B, 0x72, 0x6F, 0x6C, 0x6C]

b1 == b1
b1 == b2
b2 == b2
b2 == b3

//: ## Properties
//:
//: `AttributeValue`s support a number of properties. The most basic of these
//: is `byteArray`, which provides the type-appropriate binary encoding for the
//: value:
//: 
//: * For .Boolean(Bool), a one-byte wide `[UInt8]`. Values will be
//: `[0x01]` for `true`, or `[0x00]` for `false`.
//: * For Integral types, a `[UInt8]` sized per the type, in little-endian byte order.
//: * For Floating types, a `[Uint8]` containing the [IEEE-754](http://en.wikipedia.org/wiki/IEEE_floating_point) encoded value
//: * For String types, the actual UTF8-encoded string.
//: * For RawBytes, the actual bytes.

b1.byteArray.count // 8 bytes
v1.byteArray.count  // 1-byte (Boolean)

//: Both `.byteArray` and `.hexString` are readonly.
//:
//: AttributeValue contains a number of type-specific methods to unwrap and coerce
//: primitive values. For example, an integerValue can be extracted from an integral type:

i1.intValue    // returns 1

//: The `.xValue` properties return optionals, and if the requested type differs
//: from the native type, an attempt will be made to coerce.

i1.doubleValue // returns 1.0

AttributeValue("2.002")?.doubleValue // returns 2.002 as a Double
AttributeValue("false")?.boolValue   // Returns false
AttributeValue("true")?.boolValue    // Returns true
AttributeValue(false)?.intValue      // Returns 0
AttributeValue(true)?.intValue       // Returns 1
AttributeValue(1)?.boolValue         // Returns true

//: This convertiblity enables some comparability among different `AttributeValue` types:

let two: AttributeValue = 2.0
let two_oh_two: AttributeValue = "2.02"

two < two_oh_two
two > two_oh_two




