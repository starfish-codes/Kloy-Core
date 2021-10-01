import Foundation
import Core
import Darwin

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

//url = "api/v1/cats?color=black"

//In its core computing query params is just parsing of a string to a First class type
//For example: api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f
//The id should be parsed to a uuid.
//This also means that the route will only hit this path if the query param is of a valid type
//Also the route is still valid if the query params are reversed
//Example:
//  api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black
//  api/v1/cats?color=black&id=58b8d258-5e78-4108-9eee-c3cb6844331f

//These ☝️ are all the same
//  api/v1/cats
// ☝️ this one is not matching

//Content-type can be a classifier as well


//First idea --> net so good

//extension Substring {
//    func slice(from: String, to: String?) -> String? {
//        return (range(of: from)?.upperBound).flatMap { substringFrom in
//            switch to{
//            case .some(let value):
//                (range(of: value, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
//                    String(self[substringFrom..<substringTo])
//            }
//            case .none:
//                String(self[substringFrom...])
//            }
//        }
//    }
//    func slice(from: String) -> String? {
//       slice(from: from, to: nil)
//    }
//}

//split on ? -> second part exist -> split &
//let url = "api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black"

//let queryParams = url.split(separator: "?")[1]?.split(separator: "&").reduce([:], { $0 })
//func splitQueryParams(url:String) -> [String : String]{
//    var dict: [String:String] = [:]
//    let queryParams = url.split(separator: "?")
//    guard queryParams.count != 2 else {return dict}
//
//    queryParams.split(separator: "&")
//        .reduce(dict, { agr, next in
//            let queryParam = next.split(separator: "=")
//            if queryParams.count == 2 {
//                agr[String(queryParams[0])] = String(queryParams[1])
//            }
//        })
//
//}
//
//let slice = url[...]
//    .slice(from: "color=")

struct Parser<A> {
    let parse: (_ str: inout Substring) ->  A?
    
    func parse(_ str:String) -> (match: A?, rest:Substring){
        var str = str[...]
        let match = self.parse(&str)
        return (match, str)
    }

    func map<B>(_ f: @escaping (A)-> B) -> Parser<B> {
        return Parser<B> { str in
          self.parse(&str).map(f)
        }
    }
}

struct QueryParser<A> {
    let parse: (_ queries: inout Substring, _ queryName:String) ->  A?
    
    func parse(_ url:String,_ queryName:String) -> (match: A?, rest:Substring){
        var url = url[...]
        let match = self.parse(&url, queryName)
        return (match, url)
    }
            
                    
}



func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
  return Parser<(A, B)> { str in
    let original = str
    guard let matchA = a.parse(&str) else { return nil }
    guard let matchB = b.parse(&str) else {
      str = original
      return nil
    }
    return (matchA, matchB)
  }
}


func convertQueryParamsIntoArray(in str:Substring) -> Array<Substring>? {
    let queries = str.split(separator: "&")
    if queries.count == 0 {return nil}
    return queries
}

func literal(_ literal: String ) -> Parser<Void> {
    return Parser<Void> { str in
        guard str.hasPrefix(literal) else { return nil }
        str.removeFirst(literal.count)
        return ()
    }
}


//This is a parser that parse the url until the query params, it strips away the url and leaves the query params
let urlParser = Parser<String> { url in
    var prefix = url.prefix(while: {$0 != "?"})
    prefix.append(contentsOf: "?") //The ? also belongs to the prefix
    //Maybe some validation if it is indeed a url -> starts with http 👈 not so sure about this
    if !prefix.starts(with: "http") {return nil}
    url.removeFirst(prefix.count)
    return String(prefix) //This could be optimised
}

//We have a url ->
let testUrl = "https://cats.starfish.team/api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black"


//This will get the UUID interpretation of the query its value
func queryUUID(_ queryName: String) -> Parser<UUID> {
    return Parser<UUID>{ str in
        guard let array = convertQueryParamsIntoArray(in: str) else {return nil}
        guard var found = array.first(where: {$0.starts(with: queryName)}) else {return nil}
        guard (literal("\(queryName)=").parse(&found) != nil) else {return nil}
        
        guard let match =  UUID(String(found)) else {return nil}
        //Mutate the str so that found is removed from it
        str = array.filter({!$0.starts(with: "\(queryName)=\(found)")}).reduce("", {$0 + "&" + $1})
        return match
    }
}

//This will get the String interpretation of the query its value
func queryString(_ queryName: String) -> Parser<String> {
    return Parser<String>{ str in
        guard let array = convertQueryParamsIntoArray(in: str) else {return nil}
        guard var found = array.first(where: {$0.starts(with: queryName)}) else {return nil}

        guard (literal("\(queryName)=").parse(&found) != nil) else {return nil}
        
        //Mutate the str so that found is removed from it
        str = array.filter({!$0.starts(with: "\(queryName)=\(found)")}).reduce("", {$0 + "&" + $1})
        return String(found)
    }
}

let parserId = zip(urlParser, queryUUID("id")).map({ _, id in
    return id
})

let id = parserId.parse(testUrl)

//This will fail because color is not a uuid -> string is preserved
let parserColorFail = zip(urlParser, queryUUID("color")).map({ _, id in
    return id
})

let colorFail = parserColorFail.parse(testUrl)

//This will succeed
let parserColor = zip(urlParser, queryString("color")).map({ _, color in
    return color
})

let color = parserColor.parse(testUrl)
var rest = color.rest
let uuid = queryUUID("id").parse(&rest)

