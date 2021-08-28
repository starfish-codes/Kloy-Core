import Foundation

public protocol Segment {
    var stringValue: String { get }
    var path: Path { get }
    
    func match(_ string: String) -> Bool
}

public typealias Path = [Segment]

public struct Route {
    let path: Path
    let method: HTTPMethod
}

public struct NamedParam: Segment {
    public enum ParamType: String {
        case Int
        case String
        case UUID
    }
    
    let name: String
    let type: ParamType

    public init(_ name: String, type: ParamType) {
        self.name = name
        self.type = type
    }
    
    public var stringValue: String { "{\(name): \(type)}" }
    public var path: Path { [self] }
    
    public func match(_ string: String) -> Bool {
        switch type {
        case .Int:
            return Int(string) != nil
        case .String:
            return true
        case .UUID:
            return Foundation.UUID(uuidString: string) != nil
        }
    }
}

extension String {
    init(from path: Path) {
        let fullPath = path
            .flatMap { $0.path }
            .map { $0.stringValue }
            .joined(separator: "/")
        self.init("/\(fullPath)" )
    }
    
    init(from route: Route) {
        let path = String(from: route.path)
        let method = route.method.rawValue.uppercased()
        self.init("\(method) \(path)")
    }
}

extension String: Segment {
    public var stringValue: String { self }
    
    public var path: Path { self.split(separator: "/").map { String($0) } }
    
    public func match(_ string: String) -> Bool {
        self.lowercased() == string.lowercased()
    }
}

public func route(_ method: HTTPMethod, _ segments: Segment...) -> Route {
    Route(path: segments.flatMap { $0.path }, method: method)
}

public typealias RoutedService = (Request) -> Response?

func router(route: Route, service: @escaping Service) -> RoutedService {
    { request in
        if match(route, with: request) {
            return service(request)
        } else {
            return nil
            
        }
    }
}

func match(_ route: Route, with request: Request) -> Bool {
    return
        route.method == request.method && match(route.path, with: request.uri)
}

func match(_ path: Path, with uri: String) -> Bool {
    let uriParts = uri.split(separator: "/")
    
    guard uriParts.count == path.count else {
        return false
    }
    
    return zip(path, uriParts)
        .map { $0.match(String($1)) }
        .reduce(true, { $0 && $1 })
}

infix operator ~>
public func ~> (route: Route, service: @escaping Service) -> RoutedService {
    router(route: route, service: service)
}

infix operator <|>
public func <|> (left: @escaping RoutedService, right: @escaping RoutedService) -> RoutedService {
    { request in
        if let lhs = left(request) {
            return lhs
        } else {
            return right(request)
        }
    }
}

public func routed(_ routes: RoutedService...) -> Service {
    let combined = routes.reduce({ request in nil }, <|>)
    return { request in
        if let result = combined(request) {
            return result
        } else {
            return Response(status: .notFound, headers: [], version: request.version, body: .empty)
        }
    }
}
