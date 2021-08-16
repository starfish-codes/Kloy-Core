///   /hello <-> GET HelloService
///
///   route("api", route("v1", route("hello", route(.Get, helloService))))
///
///   route("hello", route(.Get, helloService))
///
///

let notFound = Response(status: .notFound, headers: [], version: .Http1dot1, body: .empty)

func route(_ segment: String, _ services:  Service...) -> Service {
  { request in
    let components = request.uri.split(separator: "/")
    guard components.count > 0 else {
        return notFound
    }
    
    if components[0] == segment {
        // find a match in the services list
        // pass on the tail segments of the path
        return services[0](request)
    } else {
        return notFound
    }
  }
}

func route(_ method: Method, _ service: @escaping Service) -> Service {
  { request in
    if request.method == method {
        return service(request)
    } else {
        return notFound
    }
  }
}
