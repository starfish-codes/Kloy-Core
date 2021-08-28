import Foundation
import Core

// Routing

func notFound(from req: Request) -> Response {
    Response(status: .notFound, headers: [], version: req.version, body: .empty)
}

let testRequest = Request(method: .Get,
                          uri: "/test",
                          body: .empty)

func testService(req: Request) -> Response {
    Response(status: .ok,
             headers: [],
             version: req.version,
             body: .init(from: "test")!)
}

let teaRequest = Request(method: .Get,
                         uri: "/a/tea/please",
                         body: .init(from: "tea")!)

func teaService(req: Request) -> Response {
    Response(status: .teapot, headers: [], version: req.version, body: .init(from: "your tea")!)
}

func simpleService(status: Status = .ok, body: String) -> (Request) -> Response {
    { request in
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}


struct Server {
    let service: Service
    
    init(host: @escaping Service) {
        self.service = host
    }
    
    func process(request: Request) -> Response {
        service(request)
    }
}

let application = testService
//let application = teaService

let runtime = Server(host: application)
let response = runtime.process(request: teaRequest)
print(response.status, response.body)

// MARK: - Routes Implementation

protocol Segment {
    var stringValue: String { get }
    var path: Path { get }
}

typealias Path = [Segment]

struct Route {
    let path: Path
    let method: HTTPMethod
}

enum Parameter: String, Segment {
    case Int
    case String
    case UUID
    
    var stringValue: String { "{param, type.: \(self)}" }
    var path: Path { [self] }
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
    var stringValue: String { self }
    
    var path: Path { self.split(separator: "/").map { String($0) } }
}

let path = "/"
let pathSegments = path.split(separator: "/")

func route(_ method: HTTPMethod, _ segments: Segment...) -> Route {
    Route(path: segments, method: method)
}

// Route Samples
let allCats = route(.Get, "api/v1", "cats")
let aCat = route( .Get, "api", "v1", "cats", Parameter.UUID)
let adoptACat = route(.Post, "/api/v1/cats")

print(String(from: allCats))
print(String(from: aCat))
print(String(from: adoptACat))



precedencegroup Routing {
    associativity: left
}

typealias RoutedService = (Request) -> Response?

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

infix operator ~>: Routing

func ~> (route: Route, service: @escaping Service) -> RoutedService {
    router(route: route, service: service)
}

let allCatsRouter = allCats ~> simpleService(body: "All 🐈")
let aCatRouter = aCat ~> simpleService(body: "A 🐈")
let adoptACatRouter = adoptACat ~> simpleService(body: "Adopt a 🐈")

let empty: RoutedService = { request in nil }

func orRouter(left: @escaping RoutedService, right: @escaping RoutedService) -> RoutedService {
    { request in
        if let lhs = left(request) {
            return lhs
        } else {
            return right(request)
        }
    }
}

func routed(_ routes: RoutedService...) -> Service {
    let combined = routes.reduce(empty, orRouter)
    return { request in
        if let result = combined(request) {
            return result
        } else {
            return notFound(from: request)
        }
    }
}

let router = routed(allCatsRouter,
                    aCatRouter,
                    adoptACatRouter)

let catRequest = Request(method: .Get,
                         uri: "/api/v1/cats",
                         body: .empty)

func inspect(_ response: Response) {
    print("Reponse: \(response.status.description), Body: \(String(from: response.body))")
}

inspect(router(catRequest))
