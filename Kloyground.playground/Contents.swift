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



//Idea for implementing the filters 

precedencegroup ForwarApplication {
    associativity: left
}

precedencegroup BackwarApplication {
    associativity: right
    higherThan: ForwardApplication
}

precedencegroup ForwardComposition {
  associativity: left
  higherThan: ForwardApplication
}

precedencegroup BackwarComposition {
  associativity: right
  higherThan: BackwarApplication
}

infix operator |>: ForwarApplication

func |> <A,B>(a:A, f:(A)->B)->B{
    return f(a);
}

infix operator <|:BackwarApplication

func <| <A,B>(f:(A) -> B, a: A){
    return f(a);
}

infix operator >>>: ForwardComposition

//The andThen from the paper
func >>> <A,B,C>(f: @escaping (A) -> B, g: @escaping (B) -> c) -> ((A) -> C){
    return { a in
        g(f(a))
    }
}

infix operator <<<: BackwardComposition

func >>> <A,B,C>(f: @escaping (A) -> B, g: @escaping (B) -> c) -> ((A) -> C){
    return { a in
        f(g(a))
    }
}

func logingFilter(_ servcie:Service) -> Service{
    //do some cole loging stuff
    print("I loged something")
    return service
}

func unauthorizedService(req: Request) -> Response {
    Response(status: .unauthorized, headers: [], version: req.version, body: .empty)
}

func checkAuth(_ service:Service) -> Service{
    //Do some fancy auth checking 
    print("I checked the auth header and dit some other fancy stuff")
    //Something is wrong 
    let wentWrong = true
    if wentWrong{
        return unauthorizedService
    }
    //auth checking was valid 
    return servcie
}
//Could also do something like this or even combine the two 
let authFilter: Filter = checkAuth; 

//using forward -- I like this one better
// first authFilter an logingFilter are combined into 1 function and the the teaServices is 'piped' into that function 
let serviceWithfilters = teaService |> authFilter >>> logingFilter
let runtime = Server(host: serviceWithfilters)
let response = runtime.process(request: teaRequest)
print(response.status, response.body)


//using backward 
let anotherServiceWithfilters = logingFilter <<< authFilter <| teaService 
let runtime = Server(host: anotherServiceWithfilters)
let response = runtime.process(request: teaRequest)
print(response.status, response.body)
