///   /hello <-> GET HelloService
///
///   route("api", route("v1", route("hello", route(.Get, helloService))))
///
///   route("hello", route(.Get, helloService))
///
///

/// "/test".bind(.Get.to(handler))

precedencegroup Routing {
    associativity: left
}

struct PathMethod {}

infix operator <+>: Routing

func <+> (path: String, method: Method) -> PathMethod {
    PathMethod()
}


struct RoutedService {}

infix operator ~>: Routing

func ~> (pathMethod: PathMethod, service: Service) -> RoutedService {
    return RoutedService()
}

func testService(req: Request) -> Response {
    notFound(from: req)
}
let testRouter = "/test" <+> .Get ~> testService
let anotherTestRouter = "/test" <+> .Get ~> testService


func notFound(from req: Request) -> Response {
    Response(status: .notFound, headers: [], version: req.version, body: .empty)
}

func route(_ segment: String, _ services:  Service...) -> Service {
  { request in
    let components = request.uri.split(separator: "/")
    guard components.count > 0 else {
        return notFound(from: request)
    }
    
    if components[0] == segment {
        // find a match in the services list
        // pass on the tail segments of the path
        return services[0](request)
    } else {
        return notFound(from: request)
    }
  }
}

func route(_ method: Method, _ service: @escaping Service) -> Service {
  { request in
    if request.method == method {
        return service(request)
    } else {
        return notFound(from: request)
    }
  }
}


routers(
    [
        testRouter,
        anotherTestRouter
    ]
)

//I am not sure about the return type could also be void and this func a method in Server 
func routers(_ routers:RoutedService...) -> RoutedService{
    //Somehow combine and store them 
}
