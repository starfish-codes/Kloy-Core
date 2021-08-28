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

let catRequest = Request(method: .Get,
                         uri: "/api/v1/cats",
                         body: .empty)

let response = Server(from: router).process(request: catRequest)
inspect(response)
