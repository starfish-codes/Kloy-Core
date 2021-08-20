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



func logFilter(_ service: @escaping Service) -> Service {
    //do some cool logging stuff
    print("I loged something")
    return service
}


func unauthorizedService(req: Request) -> Response {
    Response(status: .unauthorized, headers: [], version: req.version, body: .empty)
}

func checkAuth(_ service: @escaping Service) -> Service {
    //Do some fancy auth checking
    print("I checked the auth header and dit some other fancy stuff")
    //Something is wrong
    let wentWrong = true
    if wentWrong {
        return unauthorizedService
    }
    // auth checking was valid
    // return service
}

//Could also do something like this or even combine the two
//let authFilter: Filter = checkAuth;

//using forward -- I like this one better
// first authFilter an logingFilter are combined into 1 function and the the teaServices is 'piped' into that function
let serviceWithfilters = teaService |> checkAuth >>> logFilter
let otherRuntime = Server(host: serviceWithfilters)
let otherResponse = otherRuntime.process(request: teaRequest)
print(otherResponse.status, otherResponse.body)

//using backward

let anotherServiceWithfilters = logFilter <<< checkAuth <| teaService
let yetAnotherRuntime = Server(host: anotherServiceWithfilters)
let yetAnotherResponse = yetAnotherRuntime.process(request: teaRequest)
print(yetAnotherResponse.status, yetAnotherResponse.body)
