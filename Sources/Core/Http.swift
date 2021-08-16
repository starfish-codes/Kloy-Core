import Foundation

struct Header {
    let name: String
    let value: String
}

enum Method {
    case Get, Post, Put, Delete, Options, Trace, Patch, Purge, Head
}

struct Status {
    let code: Int
    let description: String
}

struct Body {
    let payload: Data
    
    static let empty = Body(payload: Data())
}

struct Request {
    let method: Method
    let headers: [Header]
    let uri: String
    let version: String
    let body: Body
}

struct Response {
    let status: Status
    let headers: [Header]
    let version: String
    let body: Body
}

typealias Service = (Request) -> Response
typealias Filter = (Service) -> Service
