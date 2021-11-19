//Idea for implementing the filters

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

public func |> <A,B>(a:A, f:(A)->B) -> B {
    return f(a);
}

infix operator <|: BackwardApplication

public func <| <A,B>(f:(A) -> B, a: A) -> B {
    return f(a);
}

infix operator >>>: ForwardComposition

//The andThen from the paper
public func >>> <A,B,C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> ((A) -> C) {
    return { a in
        g(f(a))
    }
}

infix operator <<<: BackwardComposition

public func <<< <A,B,C>(f: @escaping (B) -> C, g: @escaping (A) -> B) -> ((A) -> C) {
    return { a in
        f(g(a))
    }
}



