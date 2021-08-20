import Foundation
import Core

// Routing

func notFound(from req: Request) -> Response {
    Response(status: .notFound, headers: [], version: req.version, body: .empty)
}

precedencegroup Routing {
    associativity: left
}

struct PathMethod {}

infix operator <+>: Routing

func <+> (path: String, method: Core.Method) -> PathMethod {
    PathMethod()
}


struct RoutedService {}

infix operator ~>: Routing

func ~> (pathMethod: PathMethod, service: Service) -> RoutedService {
    return RoutedService()
}

//func testService(req: Request) -> Response {
//    notFound(from: req)
//}
//let testRouter = "/test" <+> .Get ~> testService




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


