//: Playground - noun: a place where people can play

import UIKit

protocol ResultStorable: Hashable {

    associatedtype SectionKey: Hashable
    
    var storableSectionKey: SectionKey { get }
}

struct Stored {
    
    let name: String
    let family: String
    
    init(name: String, family: String) {
        self.name = name
        self.family = family
    }
}

extension Stored: ResultStorable {
    
    typealias SectionKey = String
    
    var hashValue: Int {
        return self.name.hashValue ^ self.family.hashValue
    }
    
    var storableSectionKey: SectionKey {
        return family
    }
}

func ==(lhs: Stored, rhs: Stored) -> Bool {
    
    return lhs.name == rhs.name && lhs.family == rhs.family
}

class ResultStore<K: Hashable, V: Hashable> {
    

    func putResult(result: V) {
        
    }
    
    func removeResult(result: V) {
        
    }

}

class ResultStoreView<K: Hashable, V: Hashable> {
    
    var groupBy: ((V) -> K)? = nil
    var sortBy: ((V, V) -> Bool)? = nil
    
}

class Box<T>: CustomDebugStringConvertible {

    var debugDescription: String {
        return "<Box: \(T.self)>: \(unbox)"
    }
    
    var unbox: T

    init(unbox: T) {
        self.unbox = unbox
    }
}

enum Delta<T: Equatable>: CustomDebugStringConvertible, CustomStringConvertible {
    
    var debugDescription: String {
        switch(self) {
        case let .remove(box) : return "<Delta.Remove> \(box)"
        case let .add(box) : return "<Delta.Add> \(box)"
        }
    }
    
    var description: String {
        return debugDescription
    }
    
    case remove(Box<T>)
    case add(Box<T>)
}

/**
Take a "from" `Set` and "to" `Set`, and return an array of deltas that can replayed
against `from` to produce `to`.
*/

func deltas<T: Hashable>(from: Set<T>?, to: Set<T>?) -> [Delta<T>] {
    
    var ret: [Delta<T>] = []

    if let from = from, let to = to {
        from.subtracting(to).map { ret.append(Delta.remove(Box(unbox: $0))) }
        to.subtracting(from).map { ret.append(Delta.add(Box(unbox: $0))) }
    }
    
    return ret
}

func apply<T: Equatable>(from: Set<T>?, delta: Delta<T>?) -> Set<T>? {
    var from = from
    if let
        delta = delta {
            switch(delta) {
            case let .add(box):
                from?.insert(box.unbox)
            case let .remove(box):
                from?.remove(box.unbox)
            }
    }
    return from
}

func apply<T: Equatable>(from: Set<T>?, deltas: [Delta<T>]?) -> Set<T>? {
    
    var from = from
    if from == nil {
        return nil
    }

    if let deltas = deltas {
        from = deltas.reduce(from!) {
            if let applied = apply(from: $0, delta: $1) { return applied }
            return $0
        }
    }
    
    return from
}

let s1 = Set<Int>(arrayLiteral: 1, 2, 3, 4, 5)
let s2 = Set<Int>(arrayLiteral: 4, 5, 6, 7)

