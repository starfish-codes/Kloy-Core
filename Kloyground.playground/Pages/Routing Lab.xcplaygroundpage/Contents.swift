import Core
import Foundation

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
let allCats = route(.get, "api/v1", "cats")
let aCat = route(.get, "api", "v1", "cats", Parameter("cat_id", type: .uuid))
let adoptCat = route(.get, "/api/v1/cats")

// Router Samples
let allCatsRouter = allCats ~> simpleService(body: "All 🐈")
let catRouter = aCat ~> simpleService(body: "A 🐈")
let adoptCatRouter = adoptCat ~> simpleService(body: "Adopt a 🐈")

let router = routed(allCatsRouter,
                    catRouter,
                    adoptCatRouter)

print("All Cats Expected")
inspect(
    Server(from: router).process(request: Request(method: .get,
                                                  uri: "/api/v1/cats",
                                                  body: .empty))
)
print()

// 1. matching parameters
print("A Cat Expected")
inspect(
    Server(from: router).process(request: Request(method: .get,
                                                  uri: "/api/v1/cats/58b8d258-5e78-4108-9eee-c3cb6844331f",
                                                  body: .empty))
)
print()

// Left to todo:

// 2. nested routes
let router2 = routed("api/v1",
                     routed("cats",
                            routed(route(.get, "") ~> simpleService(body: "All 🐈"),
                                   route(.get, Parameter("cat_id", type: .int)) ~> simpleService(body: "A 🐈"),
                                   route(.put, Parameter("cat_id", type: .int)) ~> simpleService(body: "🍼 a 🐈"))),
                     routed(route(.post, "cats") ~> simpleService(body: "Adopt a 🐈")))

print("All Cats Expected")
inspect(
    Server(from: router2).process(request: Request(method: .get,
                                                   uri: "/api/v1/cats",
                                                   body: .empty))
)
print()

print("A Cat Expected")
inspect(
    Server(from: router2).process(request: Request(method: .get,
                                                   uri: "/api/v1/cats/58",
                                                   body: .empty))
)
print()

print("Feed A Cat Expected")
inspect(
    Server(from: router2).process(request: Request(method: .put,
                                                   uri: "/api/v1/cats/58",
                                                   body: .empty))
)
print()

print("Adopt a Cat Expected")
inspect(
    Server(from: router2).process(request: Request(method: .post,
                                                   uri: "/api/v1/cats",
                                                   body: .empty))
)
print()

let router3 = routed("api/v2/cats",
                     routed(
                         route(.get, "") ~> simpleService(body: "All V2 Cats")
                     ),
                     routed(Parameter("cat_id", type: .int), routed(
                         route(.get, "") ~> simpleService(body: "A V2 Cat"),
                         route(.put, "") ~> simpleService(body: "Feed a V2 cat")
                     )))

print("All V2 Cats Expected")
inspect(
    Server(from: router3).process(request: Request(method: .get,
                                                   uri: "/api/v2/cats",
                                                   body: .empty))
)
print()

print("A V2 Cat Expected")
inspect(
    Server(from: router3).process(request: Request(method: .get,
                                                   uri: "/api/v2/cats/58",
                                                   body: .empty))
)
print()

print("Feed a V2 Cat Expected")
inspect(
    Server(from: router3).process(request: Request(method: .put,
                                                   uri: "/api/v2/cats/42",
                                                   body: .empty))
)
print()

// MARK: - - query params

// url = "api/v1/cats?colour=black"

func simpleServiceWithQueryParams(status: Status = .ok, body: String, query _: String) -> (Request) -> Response {
    { request in
        // Handle query params
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}

// MARK: - - query params

// url = "api/v1/cats?color=black"

// In its core computing query params is just parsing of a string to a First class type
// For example: api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f
// The id should be parsed to a uuid.
// This also means that the route will only hit this path if the query param is of a valid type
// Also the route is still valid if the query params are reversed
// Example:
//  api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black
//  api/v1/cats?color=black&id=58b8d258-5e78-4108-9eee-c3cb6844331f

// These ☝️ are all the same
//  api/v1/cats
// ☝️ this one is not matching

// Content-type can be a classifier as well

// We have a url ->
let testUrl = "https://cats.starfish.team/api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black"

let parserId = zip(urlParser, parseQueryUUID("id")).map { _, id in
    id
}

let id = parserId.parse(testUrl)

// This will fail because color is not a uuid -> string is preserved
let parserColorFail = zip(urlParser, parseQueryUUID("color")).map { _, id in
    id
}

let colorFail = parserColorFail.parse(testUrl)

// This will succeed
let parserColor = zip(urlParser, parseQueryString("color")).map { _, color in
    color
}

let color = parserColor.parse(testUrl)
var rest = color.rest
let uuid = parseQueryUUID("id")
uuid.parse(String(rest))

let testUrl2 = "https://cats.starfish.team/api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black&gender=female"

let color2 = parserColor.parse(testUrl2)
var rest2 = color2.rest
let uuid2 = parseQueryUUID("id").parse(String(rest2))

print(rest2)

let url = "api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black&gender=female"
let parserId2 = zip(urlParser, parseQueryUUID("id")).map { _, id in
    id
}

let parsedId = parserId2.parse(url)
let rest3 = String(parsedId.rest)
let parsedColor = parseQueryString("color").parse(rest3)
let parsedGender = parseQueryString("gender").parse(String(parsedColor.rest))
