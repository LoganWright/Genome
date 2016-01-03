//
//  Initializers.swift
//  Genome
//
//  Created by Logan Wright on 9/19/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

// MARK: MappableObject Initialization

// TODO: Move to Foundation Specific
// TODO: Make other direction
extension Json {
    public static func from(dictionary: JSON) throws -> Json {
        var mutable: [String : Json] = [:]
        try dictionary.forEach { key, value in
            mutable[key] = try .from(value)
        }
        
        return .from(mutable)
    }
    
//    public static func from<T : JSONConvertibleType>(anything: T) throws -> Json {
//        return try anything.jsonRepresentation()
//    }
    
    public static func from(anything: AnyObject) throws -> Json {
        switch anything {
        case let x as String:
            return .from(x)
        case let x as JSONConvertibleType:
            return try x.jsonRepresentation()
        default:
            print("asdf: \(anything.dynamicType)")
            return .NullValue
            // TODO:
        }
    }
    
}

public extension MappableObject {
    
    /**
    This is the designated mapped instance creator.  All mapped
    instance calls should funnel through here.
    
    :param: js      the json to use when mapping the object
    :param: context the context to use in the mapping
    
    :returns: an initialized instance based on the given map
    */
    static func mappedInstance(js: Json, context: Json = .ObjectValue([:])) throws -> Self {
        let map = Map(json: js, context: context)
        var instance = try newInstance(map)
        try instance.sequence(map)
        return instance
    }
    
    static func mappedInstance(js: JSON, context: JSON = [:]) throws -> Self {
        let map = Map(json: try .from(js), context: try .from(context))
        var instance = try newInstance(map)
        try instance.sequence(map)
        return instance
    }
}

public extension Array where Element : MappableObject {
    /**
    Use this method to initialize an array of objects from a json array
    
    :example: let foods = [Food].mappedInstance(jsonArray)
    
    :param: js      the array of json
    :param: context the context to use when mapping the individual objects
    
    :returns: an array of objects initialized from the json array in the provided context
    */
    static func mappedInstance(js: Json, context: Json = .ObjectValue([:])) throws -> Array {
        let array = js.arrayValue ?? [js]
        return try array.map { try Element.mappedInstance($0, context: context) }
    }
}

public extension Array where Element : JSONConvertibleType {
    // TODO: Should this take only `[Json]` for clarity? instead?
    public static func newInstance(json: Json, context: Json = .ObjectValue([:])) throws -> Array {
        let array = json.arrayValue ?? [json]
        return try newInstance(array, context: context)
    }
    
    public static func newInstance(json: [Json], context: Json = .ObjectValue([:])) throws -> Array {
        return try json.map { try Element.newInstance($0, context: context) }
    }
}

public extension Set where Element : MappableObject {
    /**
     Use this method to initialize a set of objects from a json array
     
     :example: let foods = Set<Food>.mappedInstance(jsonArray)
     
     :param: js      the array of json
     :param: context the context to use when mapping the individual objects
     
     :returns: a set of objects initialized from the json array in the provided context
     */
    
    public static func newInstance(json: Json, context: Json) throws -> Set {
        guard case let .ArrayValue(array) = json else {
            throw Lazy.Error("Not an array ...")
        }
        return Set<Element>(try array.map { try Element.newInstance($0, context: context) })
    }
}
