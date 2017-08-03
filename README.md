
<p align="center">
  <img src="/Images/GenomeBanner.png" width=800></img>
</p>

Welcome to Genome 3.0. This library seeks to satisfy the following goals:

- [x] Data Type Agnostic
- [x] Failure Driven
- [x] Nested Mapping
- [x] Collection Mapping
- [x] Simple and Consistent
- [x] Two-Way Serialization
- [x] Transforms
- [x] Type Safety
- [x] Constants (`let`)
- [x] Full Linux Support
- [x] Struct Friendly
- [x] Inheritance Friendly
- [x] Core Data and Persistence Compatible

## Node

Genome is built on top of [Node](https://github.com/vapor/node) as opposed to JSON directly. This makes it easy for Genome to work with any data type through little effort.

All mapping operations are built as sugar on top of Node's core.

## Optimized For JSON

Works great w/ JSON out of the box by default:

```swift
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    guard let data = data else { return }
    do {
        let model = try Model(node: data)
        completion(model)
    } catch {
        completion(error)
    }
}
task.resume()
```

If your data is nested, you can use Node to take it further.

```swift
let json = try rawJSONData.makeNode()
guard let items = json["root", "items"] else { return }
let models = try [Item](node: items)
```

You'll notice above that we used initialized an array, this is all perfectly great w/ Genome.

> If you're working on Linux with SwiftPM, it is highly recommended to use a type-safe JSON library like [this one](https://github.com/vapor/json).

### To JSON

We can create our JSON Data the same way:

```swift
let jsonData = try Data(node: item)
api.post(jsonData) { response in ... }
```

### Building Project

All future development of Cocoapods will be done on with SwiftPM. Cocoapods and Carthage support are intended to be maintained, but are not used in development. Here are some useful commands

```bash
# make xcode project
swift package generate-xcodeproj
# build project
swift build
# test project
swift test
```

### SwiftPM

To use SwiftPM, add this to your `Package.swift`

```swift
.Package(url: "https://github.com/LoganWright/Genome.git", majorVersion: 3)
```

### Cocoapods

```ruby
pod 'Genome', '~> 3.0'
```

### Carthage

```
github "LoganWright/Genome"
```

### Table Of Contents

* [Quick Start](#quick-start)
* [Node](#node)
* [Inheritance](#inheritance)
* [NodeConvertibleType](#nodeconvertibletype)
* [Instantiation](#instantiation)
* [Alamofire](#alamofire)
* [Core Data](#core-data)
* [Logging](#logging)

### Quick Start

Let's take the following hypothetical JSON

```swift
[
    "name" : "Rover",
    "nickname" : "RoRo", // Optional Value
    "type" : "dog"
]
```

Here's how we might create the model for this


```swift
enum PetType: String {
    case dog
    case cat
    case unknown
}

struct Pet: MappableObject {
    let name: String
    let type: PetType
    let nickname: String?

    init(map: Map) throws {
        name = try map.extract("name")
        nickname = try map.extract("nickname")
        type = try map.extract("type") { PetType(rawValue: $0) ?? .unknown }
    }

    func sequence(map: Map) throws {
        try name ~> map["name"]
        try type ~> map["type"].transformToNode { $0.rawValue }
        try nickname ~> map["nickname"]
    }
}
```

Once that's done, we can build like so:

```swift
let pet = try Pet(node: json)
```

It will also work with collections:

```swift
let pets = try [Pet](node: jsonArray)
```

### NASA Photo

Let's build a simple example that fetches NASA's photo of the day. Please note that this is a synchronous API, and it makes use of Data for brevity. It is advisable to use an asynchronous and proper HTTP Client like URLSession.

```swift
struct Photo: BasicMappable {
    private(set) var title: String = ""
    private(set) var mediaType: String = ""
    private(set) var explanation: String = ""
    private(set) var concepts: [String] = []

    private(set) var imageUrl: NSURL!

    mutating func sequence(_ map: Map) throws {
        try title <~ map["title"]
        try mediaType <~ map ["media_type"]
        try explanation <~ map["explanation"]
        try concepts <~ map["concepts"]
        try imageUrl <~ map["url"]
            .transformFromNode { NSURL(string: $0) }
    }
}

struct NASA {
    static let url = URL(string: "https://api.nasa.gov/planetary/apod?concept_tags=True&api_key=DEMO_KEY")!

    static func fetchPhoto() throws -> Photo {
        let data = try Data(contentsOf: NASA.url)
        return try Photo(node: data)
    }
}
```

Now we can call like this:

```swift
let photo = try NASA.fetchPhoto()
```

> WARNING: Please read first paragraph regarding synchronicity and api.

### `MappableObject`

This is one of the core protocol options for this library.  It will be the go to for most standard mapping operations.

It has two requirements

#### `init(map: Map) throws`

This is the initializer you will use to map your object.  You may call this manually if you like, but if you use any of the built in convenience initializers, this will be called automatically.  Otherwise, if you need to initialize a `Map`, use:

```swift
let map = Map(node: someNode, in: someContext)
```

It has two main requirements

#### `sequence(map: Map) throws`

The `sequence` function is called in two main situations. It is marked `mutating` because it will modify values on `fromNode` operations.  If however, you're only using sequence for `toNode`, nothing will be mutated and one can remove the `mutating` keyword. (as in the above example)

##### FromNode

When mapping to Node w/ any of the convenience initializer.  After instantiating the object, `sequence` will be called.  This allows objects that don't initialize constants or objects that use the two-way operator to complete their mapping.

> If you are initializing w/ `init(map: Map)` directly, you will be responsible for calling `sequence` manually if your object requires it.

It is marked `mutating` because it will modify values.

`Note, if you're only mapping to Node, nothing will be mutated.`

##### ToNode

When accessing an objects `makeNode()`, the sequence operation will be called to collect the values into a `Node` package.

### `~>`

This is one of the main operations used in this library.  The `~` symbolizes a connection, and the `<` and `>` respectively symbol a flow of value.  When declared as `~>` it symbolizes that mapping only happens from value, to Node.

You could also use the following:

| Operator | Directions | Example | Mutates |
|:---:|:---:|:---:|:---:|
|`<~>`| To and From Node | `try name <~> map["name"]` | ✓ |
|`~>`| To Node Only | `try clientId ~> map["client_id"]` | 𝘅 |
|`<~`| From Node Only | `try updatedAt <~ map["updated_at"]` | ✓ |

### `transform`

Genome provides various options for transforming values.  These are type-safe and will be checked by the compiler.

These are chainable, like the following:

```swift
try type <~> map["type"]
    .transformFromNode {
        return PetType(rawValue: $0)
    }
    .transformToNode {
        return $0.rawValue
    }
```

>Note: At the moment, transforms require absolute optionality conformance in some situations. ie, Optionals get Optionals, ImplicitlyUnwrappedOptionals get ImplicitlyUnwrappedOptionals, etc.

#### `fromNode`

When using `let` constants, you will need to call a transformer that sets the value instantly.  In this case, you will call `fromNode` and pass any closure that takes a `NodeConvertibleType` (a standard Node type) and returns a value.

#### `transformFromNode`

Use this if you need to transform the node input to accomodate your type.  In our example above, we need to convert the raw node to our associated enum.  This can also be appended to mappings for the `<~` operator.

#### `transformToNode`

Use this if you need to transform the given value to something more suitable for data.  This can also be appended to mappings for the `~>` operator.

### `try`

Why is the `try` keyword on every line!  Every mapping operation is failable if not properly specified.  It's better to deal with these possibilities, head first.  

For example, if the property being set is non-optional, and `nil` is found in the `Node`, the operation should throw an error that can be easily caught.

# More Concepts

Some of the different functionality available in Genome

The way that Genome is constructed, you should never have to deal w/ `Node` beyond deserializing and serializing for your web services.  It can still be used directly if desired.

## Inheritance

Genome is most suited to `final` classes and structures, but it does support Inheritance.  Unfortunately, due to some limitations surrounding generics, protocols, and `Self` it requires some extra effort.

### `Object`

The `Object` type is provided by the library to satisfy most inheritance based mapping operations.  Simply subclass `Object` and you're good to go:

```swift
class MyClass : Object {}
```

> Note: If you're using `Realm`, or another library that has also used `Object`, don't forget that these are module namespaced in Swift.  If that's the case, you should declare your class: `class MyClass : Genome.Object {}`

### `BasicMappable`

In order to support flexible customization, Genome provides various mapping options for protocols.  Your object can conform to any of the following.  Although each of these initializers is marked with `throws`, it is not necessary for your initializer to `throw` if it is guaranteed to succeed.  In that case, you can omit the `throws` keyword safely.

| Protocol | Required Initializer |
|:---|:---|
| BasicMappable | `init() throws` |
| MappableObject | `init(map: Map) throws` |

These are all just convenience protocols, and ultimately all derive from `MappableBase`.  If you wish to define your own implementation, the rest of the library's functionality will still apply.

### `NodeConvertibleType`

This is the true root of the library.  Even `MappableBase` mentioned above inherits from this core type.  It has two requirements:

```swift
public protocol NodeConvertibleType {
    init(node: Node, in context: Context) throws
    func makeNode(context: Context) throws -> Node
}
```

All basic types such as `Int`, `String`, etc. conform to this protocol which allows ultimate flexibility in defining the library.  It also paves the way to much fewer overloads going forward when collections of `NodeConvertible` can also conform to it.

## Instantiation

If you are using the standard instantiation scheme established in the library, you will likely initialize with this function.

```swift
public init(node: Node, in context: Context = EmptyNode) throws
```

Now we can easily create an object safely:

```swift
do {
    let rover = try Pet(node: nodeRover)
    print(rover)
} catch {
    print(error)
}
```

If all we care about is whether or not we were able to create an object, we can also do the following:

```swift
let rover = try? Pet(node: nodeRover)
print(rover) // Rover is type: `Pet?`
```

### Context

`Context` is defined as an empty protocol that any object you might need access to can conform to and passed within.

### Foundation

If you're using `Foundation`, you can transform `Any`, `[String: Any]`, and `[Any]` types by making them into a Node first. `Node(any: yourTypeHere)`.

### CollectionTypes

You can instantiate collections directly w/o mapping as well:

```swift
let people = try [People](node: someNode)
```

#### Core Data

If you wish to use `CoreData`, instead of subclassing `NSManagedObject`, subclass `ManagedObject`.

Happy Mapping!
