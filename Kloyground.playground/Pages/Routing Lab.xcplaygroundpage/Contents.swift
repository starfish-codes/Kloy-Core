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



//MARK -- query params

//url = "api/v1/cats?colour=black"

//In its core computing query params is just parsing of a string to a First class type
//For example: api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f
//The id should be parsed to a uuid.
//This also means that the route will only hit this path if the query param is of a valid type
//Also the route is still valid if the query params are reversed
//Example:
//  api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&colour=black
//  api/v1/cats?colour=black&id=58b8d258-5e78-4108-9eee-c3cb6844331f
//These ☝️ are the same 

struct QueryParser<T> {
    let parse: (_ url: inout String, _ queryName:String) -> T?
}


extension String {
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

let url = "api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&colour=black"

let slice = url.slice(from: "id=", to:"&")


let uuidParser = QueryParser<UUID> { url, queryName in
    
    
    return UUID()
}
