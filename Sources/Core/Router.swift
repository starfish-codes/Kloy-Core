public protocol Segment {
    var stringValue: String { get }
    var path: Path { get }
}

public typealias Path = [Segment]

public struct Route {
    let path: Path
    let method: HTTPMethod
}

public enum Parameter: String, Segment {
    case Int
    case String
    case UUID
    
    public var stringValue: String { "{param, type.: \(self)}" }
    public var path: Path { [self] }
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
}

public func route(_ method: HTTPMethod, _ segments: Segment...) -> Route {
    Route(path: segments, method: method)
}

public typealias RoutedService = (Request) -> Response?

func router(route: Route, service: @escaping Service) -> RoutedService {
    { request in
        if match(route: route, request: request) {
            return service(request)
        } else {
            return nil
            
        }
    }
}

func match(route: Route, request: Request) -> Bool {
    return route.method == request.method && String(from: route.path) == request.uri
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
