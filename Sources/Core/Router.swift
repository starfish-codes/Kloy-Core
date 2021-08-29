import Foundation

struct NamedParamaterValue {
    let name: String
    let value: String
}

public struct SegmentMatch {
    let parameterValue: NamedParamaterValue?
    
    init() { parameterValue = nil }
    
    init(name: String?, value: String?) {
        if let name = name,
           let value = value {
            parameterValue = .init(name: name, value: value)
        } else {
            parameterValue = nil
        }
    }
}

public protocol Segment {
    var stringValue: String { get }
    var path: Path { get }
    
    func match(_ string: String) -> SegmentMatch?
}

public typealias Path = [Segment]

public struct Route {
    let path: Path
    let method: HTTPMethod
}

public struct NamedParameter: Segment {
    public enum ParameterType: String {
        case Int
        case String
        case UUID
    }
    
    let name: String
    let type: ParameterType

    public init(_ name: String, type: ParameterType) {
        self.name = name
        self.type = type
    }
    
    public var stringValue: String { "{\(name): \(type)}" }
    public var path: Path { [self] }
    
    public func match(_ string: String) -> SegmentMatch? {
        switch type {
        case .Int:
            return Int(string) != nil ? SegmentMatch(name: name, value: string) : nil
        case .String:
            return SegmentMatch(name: name, value: string)
        case .UUID:
            return Foundation.UUID(uuidString: string) != nil ? SegmentMatch(name: name, value: string) : nil
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
    
    public func match(_ string: String) -> SegmentMatch? {
        self.lowercased() == string.lowercased() ? SegmentMatch() : nil
    }
}

public func route(_ method: HTTPMethod, _ segments: Segment...) -> Route {
    Route(path: segments.flatMap { $0.path }, method: method)
}

public typealias RoutedService = (Request) -> Response?

func router(route: Route, service: @escaping Service) -> RoutedService {
    { request in
        if let routedRequest = match(route, with: request) {
            return service(routedRequest)
        } else {
            return nil
            
        }
    }
}

func match(_ route: Route, with request: Request) -> Request? {
    guard route.method == request.method else { return nil }
    var routedRequest = request
    
    if let pathMatch = match(route.path, with: request.uri) {
        pathMatch.segmentMatches
            .compactMap { $0.parameterValue }
            .forEach { routedRequest.setNamedParameter(name: $0.name, value: $0.value) }
        return routedRequest
    } else {
        return nil
    }
}

struct PathMatch {
    let segmentMatches: [SegmentMatch]
}

func match(_ path: Path, with uri: String) -> PathMatch? {
    let uriParts = uri.split(separator: "/")
    
    guard uriParts.count == path.count else {
        return nil
    }
    
    let matchResult = zip(path, uriParts)
        .compactMap { $0.match(String($1)) }
    
    guard matchResult.count == path.count else {
        return nil
    }
    
    return PathMatch(segmentMatches: matchResult)
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
