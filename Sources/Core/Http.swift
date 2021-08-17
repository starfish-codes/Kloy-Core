import Foundation

struct Header {
    let name: String
    let value: String
}

enum Method {
    case Get, Post, Put, Delete, Options, Trace, Patch, Purge, Head
}

enum Version {
    case Http1dot1, Http2
}

enum ContentType: String, CaseIterable{
    case Json = "application/json"
    case FromUrlEncoded = "application/x-www-form-urlencoded"
    case Xml = "application/xml" 
    case Pdf = "application/pdf"
    case FormData = "multipart/form-data"
    case Mixed = "multipart/mixed"
    case OctedStream = "application/octet-stream"
    case Csv = "text/csv",
    case EventStream = "text/event-stream"
    case Plain = "text/plain",
    case Html = "text/html",
    case Xml = "text/xml"
    case Yaml = "text/yaml"
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
    let version: Version
    let body: Body
}

struct Response {
    let status: Status
    let headers: [Header]
    let version: Version
    let body: Body
}

struct Accept {
    let contentType: [ContentType]
}

typealias Service = (Request) -> Response
typealias Filter = (Service) -> Service
