import Foundation

public struct Header {
    let name: String
    let value: String
}

public enum HTTPMethod: String {
    case Get, Post, Put, Delete, Options, Trace, Patch, Purge, Head
}

public enum HTTPVersion {
    case OneOne, Two
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

public struct Status: Equatable {
    public let code: Int
    public let description: String
}

public extension String {
    init(from: Body) {
        if let payload = String(data: from.payload, encoding: .utf8) {
            self.init(payload.count > 0 ? payload : "[empty body]")
        } else {
            self.init("[Encoding error]")
        }
    }
}

public struct Body {
    public let payload: Data
    
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
    public let method: HTTPMethod
    public let headers: [Header]
    public let uri: String
    public let version: HTTPVersion
    public let body: Body
    
    public init(method: HTTPMethod,
                headers: [Header] = [],
                uri: String,
                version: HTTPVersion = .OneOne,
                body: Body) {
        self.method = method
        self.headers = headers
        self.uri = uri
        self.version = version
        self.body = body
    }
    
    var namedParameters: [String:String] = [:]
    mutating func setNamedParameter(name: String, value: String) {
        namedParameters[name] = value
    }
    
    public func getParameter(_ name: String) -> String? {
        namedParameters[name]
    }
    
    public func getParameter<T>(_ name: String, as type: T.Type = T.self) -> T?
    where T: LosslessStringConvertible {
        self.getParameter(name).flatMap(T.init)
    }
}

public struct Response {
    public let status: Status
    public let headers: [Header]
    public let version: HTTPVersion
    public let body: Body
    
    public init(status: Status, headers: [Header], version: HTTPVersion, body: Body) {
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
