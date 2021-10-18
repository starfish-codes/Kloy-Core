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
                                   route(.Get, Parameter("cat_id", type: .Int))      ~> simpleService(body: "A 🐈"),
                                   route(.Put, Parameter("cat_id", type: .Int))      ~> simpleService(body: "🍼 a 🐈")
                            )
                     ),
                     routed(route(.Post, "cats")                                     ~> simpleService(body: "Adopt a 🐈"))
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

print("Feed A Cat Expected")
inspect(
    Server(from: router2).process(request: Request(method: .Put,
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
print()


let router3 = routed("api/v2/cats",
                     routed(
                        route(.Get, "") ~> simpleService(body: "All V2 Cats")
                     ),
                     routed(Parameter("cat_id", type: .Int),routed(
                        route(.Get, "") ~> simpleService(body: "A V2 Cat"),
                        route(.Put, "") ~> simpleService(body: "Feed a V2 cat")
                     ))
)

print("All V2 Cats Expected")
inspect(
    Server(from: router3).process(request: Request(method: .Get,
                                                   uri: "/api/v2/cats",
                                                   body: .empty))
)
print()

print("A V2 Cat Expected")
inspect(
    Server(from: router3).process(request: Request(method: .Get,
                                                   uri: "/api/v2/cats/58",
                                                   body: .empty))
)
print()

print("Feed a V2 Cat Expected")
inspect(
    Server(from: router3).process(request: Request(method: .Put,
                                                   uri: "/api/v2/cats/42",
                                                   body: .empty))
)
print()

//MARK -- query params

//url = "api/v1/cats?colour=black"

func simpleServiceWithQueryParams(status: Status = .ok, body: String, query: String) -> (Request) -> Response {
    { request in
        //Handle query params
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}

