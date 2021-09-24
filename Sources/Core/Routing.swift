import Foundation

/// Definition of a service that considers routing, i.e. the service
/// will return an `Response?` (Optional) instead of the standard signature.
public typealias RoutedService = (Request) -> Response?

// MARK: - Path

/// A `Path` is an array of `Segments` which are relating to the elements in a
/// URI that are separated with "/".
public typealias Path = [Segment]

/// Represents all matches along a path.
public struct PathMatch {
    let segmentMatches: [SegmentMatch]
}

/// Matches a `Path` against a URI string.
///
/// - parameters:
///     - path: The path to match
///     - uri: The URI to match
/// - returns: A `PathMatch` in case of a successful match
func matchURI(_ routePath: Path, with uriPath: Path) -> PathMatch? {
    guard uriPath.count == routePath.count else {
        return nil
    }
    
    let matchResult = zip(routePath, uriPath)
        .compactMap { $0.match($1.stringValue) }
    
    guard matchResult.count == routePath.count else {
        return nil
    }
    
    return PathMatch(segmentMatches: matchResult)
}

/// This protocol introduces an interface to allow for different
/// types of segments in a path.
///
/// Each `Path` consists of `Segments`, e.g. the path `/api/v1/test`
/// consists of the three segments `api`, `v1`, and `test`.
public protocol Segment {
    
    /// representation of the segment as a `String`
    var stringValue: String { get }
    
    /// A `Segment` can be read as a `Path` again.
    ///
    /// This allows for nested segments, e.g. `"/v1/api"`.
    var path: Path { get }
    
    /// Tries to match the segment against a string, which was extracted from an URI.
    ///
    /// - parameters:
    ///     - string: The subject to match against.
    /// - returns: The `SegmentMatch` as result.
    func match(_ string: String) -> SegmentMatch?
}

extension String: Segment {
    
    public var stringValue: String { self }
    
    public var path: Path { self.split(separator: "/").map { String($0) } }
    
    public func match(_ string: String) -> SegmentMatch? {
        self.lowercased() == string.lowercased() ? SegmentMatch() : nil
    }
}

/// Typed implementation of a Segment that represents a named parameter in an URI.
/// The parameters can be used to dynamically match against parts of the URI.
///
///     // declares a parameter segment with the name `some_id` of type Int.
///     let param = NamedParameter("some_id", ParameterType.Int)
///
/// The segment will only match in case the type constraint is fulfilled.
public struct Parameter: Segment, Equatable {
    
    /// Supported types for named parameters in URI.
    /// The `ParameterType.String` will match anything.
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
            return UUID(uuidString: string) != nil ? SegmentMatch(name: name, value: string) : nil
        }
    }
}

public struct SegmentMatch {
    struct ParameterValue {
        let name: String
        let value: String
    }
    
    let parameterValue: ParameterValue?
    
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


// MARK: - Route

/// Data type holding to represent a `Route` in the system.
/// It is made up from a `HTTPMethod` and a `Path`.
public struct Route {
    let path: Path
    let method: HTTPMethod
}

/// Bundle a `HTTPMethod` and an arbitrary amount of segments into a `Route`.
///
///     // Route for GET /api/v1/books
///     let route = route(.GET, "api", "v1", "books")
///
/// - parameters:
///     - method: The HTTP verb or method for the route.
///     - segments: List of segments to describe the corresponding URI
/// - returns: The corresponding `Route`.
public func route(_ method: HTTPMethod, _ segments: Segment...) -> Route {
    Route(path: segments.flatMap { $0.path }, method: method)
}


// MARK: - Router

/// Connect a `Route` and a `Service` to build a `RoutedService`.
///
///     let bookService = ...
///     let bookRoute = route(.GET, "api/v1/books", NamedParameter("id", ParameterType.Int))
///
///     let routedService = bookRoute ~> bookService
///
/// - parameters:
///     - route: The exact route that points to the service
///     - service: A service that handles the call to the route
/// - returns: A routed service that will respond to matching calls.
public func ~> (route: Route, service: @escaping Service) -> RoutedService {
    { request in
        if let routedRequest = matchRequest(route, with: request) {
            return service(routedRequest)
        } else { return nil }
    }
}
infix operator ~>

// Try to match a route with a request. In case the match was successful,
// a copy of the request is returned and all named parameters are resolved
// and stored in the request.
func matchRequest(_ route: Route, with request: Request) -> Request? {
    guard route.method == request.method else { return nil }
    var routedRequest = request
    
    if let pathMatch = matchURI(route.path, with: request.routeContextPath) {
        pathMatch.segmentMatches
            .compactMap { $0.parameterValue }
            .forEach { routedRequest.setParameter(name: $0.name, value: $0.value) }
        return routedRequest
    } else {
        return nil
    }
}

/// Convert list of `RoutedServices` into a standard `Service`
/// by adding an HTTP 404 default route.
///
///     let router = routed(indexRoute ~> indexService,
///                         createRoute ~> createService)
///
/// - parameters:
///     - routes: A list of `RoutedServices` which will be combined in sequence.
/// - returns: A service that will consider the RoutedServices in sequence
///            and will return HTTP 404 response if no route matches the Request.
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

public func routed(_ segment: Segment, _ services: Service...) -> Service {
    { request in
        var newRequest = request
        if newRequest.shiftRouteContext(by: segment) != nil {
            let combined = services.reduce({ _ in Response(status: .notFound, headers: [], version: request.version, body: .empty)}, <|>)
            return combined(newRequest)
        } else {
            return Response(status: .notFound, headers: [], version: request.version, body: .empty)
        }
    }
}

public func routed(_ parameter: Parameter, _ services: Service...) -> Service {
    { request in
        let segment = request.path[request.routeContextIndex]
        let match = parameter.match(segment.stringValue)
        if (match != nil){
            let combined = services.reduce({ _ in Response(status: .notFound, headers: [], version: request.version, body: .empty)}, <|>);
            let service = routed(segment, combined );
            return service(request)
        }
        else {
            return Response(status: .notFound, headers: [], version: request.version, body: .empty)
        }
    }
}

public func <|>(left: @escaping Service, right: @escaping Service) -> Service {
    { request in
        let leftResponse = left(request)
        if leftResponse.status != .notFound {
            return leftResponse
        } else {
            return right(request)
        }
    }
}


/// Combines two `RoutedServices` with a short circuited or logic.
///
///     let indexRouter = indexRoute ~> indexService
///     let createRouter = createRoute ~> createService
///
///     let combined = indexRoute <|> createRoute
///
/// - parameters:
///     - left: the first `RoutedService` to match
///     - right: the second service to match
/// - returns: A new `RoutedService` which has combined the two routes.
/// The left service is matched first, in case the match is not successful the right route is matched.
public func <|> (left: @escaping RoutedService, right: @escaping RoutedService) -> RoutedService {
    { request in
        if let lhs = left(request) {
            return lhs
        } else {
            return right(request)
        }
    }
}
infix operator <|>

// MARK: - Auxillary

/// Make UUID also compatible to `LosslessStringConvertible`
extension UUID: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}
