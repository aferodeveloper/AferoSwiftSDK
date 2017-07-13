//: Playground - noun: a place where people can play

import UIKit
import Foundation
import Darwin
import Afero

let defaults: [String: Any] = ["hi": "there"]

let rules: [[String: Any]] = [
    [
        "match": "*",
        "apply": [
            "hint": "",
            "barColor": "#00FF00",
            "moo": "doo"
        ]
    ],
    [
        "match": "0",
        "attributeId": 100,
        "apply": [
            "hint": "Discharged",
            "barColor": "#FF0000"
        ]
    ],
    [
        "attributeId": 200,
        "match": "1...15",
        "apply": [
            "hint": "Low Battery",
            "tintColor": "red",
            "barColor": "#FF0000"
        ]
    ],
]

typealias AttributeDict = [Int: AttributeValue]

let a: AttributeDict = [
    100: 100,
    200: 15,
    300: "Hi Joe!",
    400: 100,
]

struct AttributeMap: AttributeIdentifierSubscriptable {

    typealias Key = Int
    typealias Value = AttributeValue

    let atts: AttributeDict

    init(_ attributes: AttributeDict) {
        atts = attributes
    }
    subscript(key: Int?) -> Value? {
        if let key = key {
            return atts[key]
        }
        return nil
    }
}

let processor: (AttributeMap)->[String: Any] = DisplayRulesProcessor.MakeProcessor(
    ["hi!": "joe!"] as [String: Any],
    rules: rules,
    operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
    bitwiseXform: { (value: AttributeValue) -> Int? in return value.intValue }
)


let atts = AttributeMap(a)
processor(atts)
