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
let aCat     = route(.Get, "api", "v1", "cats", Parameter.UUID)
let adoptCat = route(.Get, "/api/v1/cats")

// Router Samples
let allCatsRouter  = allCats  ~> simpleService(body: "All 🐈")
let catRouter      = aCat     ~> simpleService(body: "A 🐈")
let adoptCatRouter = adoptCat ~> simpleService(body: "Adopt a 🐈")


let router = routed(allCatsRouter,
                    catRouter,
                    adoptCatRouter)

inspect(
    Server(from: router).process(request: Request(method: .Get,
                                                  uri: "/api/v1/cats",
                                                  body: .empty))
)

// Left to todo:

// 1. matching parameters
inspect(
    Server(from: router).process(request: Request(method: .Get,
                                                  uri: "/api/v1/cats/58b8d258-5e78-4108-9eee-c3cb6844331f ",
                                                  body: .empty))
)

// 2. nested routes
func routed(_ segment: Segment, _ services: Service...) -> Service {
    { request in
        Response(status: .internalServerError, headers: [], version: request.version, body: .init(from: "Not implemented")!)
    }
}

let router2 = routed("api/v1",
                     routed("cats",
                            routed(route(.Get, "")             ~> simpleService(body: "All 🐈"),
                                   route(.Get, Parameter.UUID) ~> simpleService(body: "A 🐈"),
                                   route(.Post, "")            ~> simpleService(body: "Adopt a 🐈")
                            )
                     )
)

inspect(
    Server(from: router2).process(request: Request(method: .Get,
                                                   uri: "/api/v1/cats",
                                                   body: .empty))
)
