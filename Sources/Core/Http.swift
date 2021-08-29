import Foundation

public struct Header {
    let name: String
    let value: String
}

public enum Method {
    case Get, Post, Put, Delete, Options, Trace, Patch, Purge, Head
}

public enum Version {
    case Http1dot1, Http2
}

enum ContentType: String, CaseIterable {
    case Json = "application/json"
    case FromUrlEncoded = "application/x-www-form-urlencoded"
    case Xml = "application/xml" 
    case Pdf = "application/pdf"
    case FormData = "multipart/form-data"
    case Mixed = "multipart/mixed"
    case OctedStream = "application/octet-stream"
    case Csv = "text/csv"
    case EventStream = "text/event-stream"
    case Plain = "text/plain"
    case Html = "text/html"
    case TextXml = "text/xml" // ???
    case Yaml = "text/yaml"
}

public struct Status {
    let code: Int
    let description: String
}

public struct Body {
    let payload: Data
    
    public init(payload: Data) {
        self.payload = payload
    }
    
    public init?(from input: String, encoding: String.Encoding = .utf8) {
        guard let data = input.data(using: encoding) else {
            return nil
        }
        payload = data
    }
    
    public static let empty = Body(payload: Data())
}

public struct Request {
    public let method: Method
    public let headers: [Header]
    public let uri: String
    public let version: Version
    public let body: Body
    
    public init(method: Method,
                headers: [Header] = [],
                uri: String,
                version: Version = .Http1dot1,
                body: Body) {
        self.method = method
        self.headers = headers
        self.uri = uri
        self.version = version
        self.body = body
    }
}

public struct Response {
    public let status: Status
    public let headers: [Header]
    public let version: Version
    public let body: Body
    
    public init(status: Status, headers: [Header], version: Version, body: Body) {
        self.status = status
        self.headers = headers
        self.version = version
        self.body = body
    }
}

struct Accept {
    let contentType: [ContentType]
}

public typealias Service = (Request) -> Response
public typealias Filter = (Service) -> Service
