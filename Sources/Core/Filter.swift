// Idea for implementing the filters

precedencegroup ForwardApplication {
    associativity: left
}

//
precedencegroup BackwardApplication {
    associativity: right
    higherThan: ForwardApplication
}

//
precedencegroup ForwardComposition {
    associativity: left
    higherThan: ForwardApplication
}

precedencegroup BackwardComposition {
    associativity: right
    higherThan: BackwardApplication
}

infix operator |>: ForwardApplication

public func |> <A, B>(a: A, f: (A) -> B) -> B {
    f(a)
}

public func |> <A, B>(a: A, f: (A) async -> B) async -> B {
    await f(a)
}

public func |> <A, B>(a: A, f: (A) async throws -> B) async throws -> B {
    try await f(a)
}

public func |> <A, B>(a: A, f: (A) throws -> B) throws -> B {
    try f(a)
}

infix operator <|: BackwardApplication

public func <| <A, B>(f: (A) -> B, a: A) -> B {
    f(a)
}

public func <| <A, B>(a: A, f: (A) async -> B) async -> B {
    await f(a)
}

public func <| <A, B>(a: A, f: (A) async throws -> B) async throws -> B {
    try await f(a)
}

public func <| <A, B>(a: A, f: (A) throws -> B) throws -> B {
    try f(a)
}

infix operator >>>: ForwardComposition

// The andThen from the paper
public func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> ((A) -> C) {
    { a in
        g(f(a))
    }
}

public func >>> <A, B, C>(f: @escaping (A) async -> B, g: @escaping (B) async -> C) -> ((A) async -> C) {
    { a in
        await g(f(a))
    }
}

public func >>> <A, B, C>(f: @escaping (A) async throws -> B, g: @escaping (B) async throws -> C) -> ((A) async throws -> C) {
    { a in
        try await g(f(a))
    }
}

public func >>> <A, B, C>(f: @escaping (A) throws -> B, g: @escaping (B) throws -> C) -> ((A) throws -> C) {
    { a in
        try g(f(a))
    }
}

infix operator <<<: BackwardComposition

public func <<< <A, B, C>(f: @escaping (B) -> C, g: @escaping (A) -> B) -> ((A) -> C) {
    { a in
        f(g(a))
    }
}

public func <<< <A, B, C>(f: @escaping (A) async -> B, g: @escaping (B) async -> C) -> ((A) async -> C) {
    { a in
        await g(f(a))
    }
}

public func <<< <A, B, C>(f: @escaping (A) async throws -> B, g: @escaping (B) async throws -> C) -> ((A) async throws -> C) {
    { a in
        try await g(f(a))
    }
}

public func <<< <A, B, C>(f: @escaping (A) throws -> B, g: @escaping (B) throws -> C) -> ((A) throws -> C) {
    { a in
        try g(f(a))
    }
}
