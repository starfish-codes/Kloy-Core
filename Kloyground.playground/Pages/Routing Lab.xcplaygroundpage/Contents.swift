import Foundation
import Core

func simpleService(status: Status = .ok, body: String) -> (Request) -> Response {
    { request in
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}

func inspect(_ response: Response) {
    print("Reponse: \(response.status.description), Body: \(String(from: response.body))")
}

// MARK: - Routes Implementation

// Route Samples
let allCats  = route(.Get, "api/v1", "cats")
let aCat     = route(.Get, "api", "v1", "cats", Parameter("cat_id", type: .UUID))
let adoptCat = route(.Get, "/api/v1/cats")

// Router Samples
let allCatsRouter  = allCats  ~> simpleService(body: "All 🐈")
let catRouter      = aCat     ~> simpleService(body: "A 🐈")
let adoptCatRouter = adoptCat ~> simpleService(body: "Adopt a 🐈")


let router = routed(allCatsRouter,
                    catRouter,
                    adoptCatRouter)

print("All Cats Expected")
inspect(
    Server(from: router).process(request: Request(method: .Get,
                                                  uri: "/api/v1/cats",
                                                  body: .empty))
)
print()

// 1. matching parameters
print("A Cat Expected")
inspect(
    Server(from: router).process(request: Request(method: .Get,
                                                  uri: "/api/v1/cats/58b8d258-5e78-4108-9eee-c3cb6844331f",
                                                  body: .empty))
)
print()

// Left to todo:

// 2. nested routes
let router2 = routed("api/v1",
                     routed("cats",
                            routed(route(.Get, "")                                   ~> simpleService(body: "All 🐈"),
                                   route(.Get, Parameter("cat_id", type: .Int)) ~> simpleService(body: "A 🐈")
                            )
                     ),
                     routed(route(.Post, "cats")                                  ~> simpleService(body: "Adopt a 🐈"))
)

print("All Cats Expected")
inspect(
    Server(from: router2).process(request: Request(method: .Get,
                                                   uri: "/api/v1/cats",
                                                   body: .empty))
)
print()

print("A Cat Expected")
inspect(
    Server(from: router2).process(request: Request(method: .Get,
                                                   uri: "/api/v1/cats/58",
                                                   body: .empty))
)
print()

print("Adopt a Cat Expected")
inspect(
    Server(from: router2).process(request: Request(method: .Post,
                                                   uri: "/api/v1/cats",
                                                   body: .empty))
)


//MARK -- thinking about cleaning up routed

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
            var newRequest = request
            if newRequest.shiftRouteContext(by: segment) != nil {
                let combined = services.reduce({ _ in Response(status: .notFound, headers: [], version: request.version, body: .empty)}, <|>)
                return combined(newRequest)
            } else {
                return Response(status: .notFound, headers: [], version: request.version, body: .empty)
            }
        }
        else {
            return Response(status: .notFound, headers: [], version: request.version, body: .empty)
        }
    }
}
