import Foundation

public struct Header {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

public enum HTTPMethod: String {
    case get, post, put, delete, options, trace, patch, purge, head
}

public enum HTTPVersion {
    case oneOne, two
}

enum ContentType: String, CaseIterable {
    case json = "application/json"
    case fromUrlEncoded = "application/x-www-form-urlencoded"
    case xml = "application/xml"
    case pdf = "application/pdf"
    case formData = "multipart/form-data"
    case mixed = "multipart/mixed"
    case octedStream = "application/octet-stream"
    case csv = "text/csv"
    case eventStream = "text/event-stream"
    case plain = "text/plain"
    case html = "text/html"
    case textXml = "text/xml" // ???
    case yaml = "text/yaml"
}

public struct Status: Equatable {
    public let code: Int
    public let description: String

    public init(code: Int, description: String) {
        self.code = code
        self.description = description
    }
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
    public let path: Path
    public let version: HTTPVersion
    public let body: Body

    public init(method: HTTPMethod,
                headers: [Header] = [],
                uri: String,
                version: HTTPVersion = .oneOne,
                body: Body)
    {
        self.method = method
        self.headers = headers
        self.uri = uri
        path = uri.split(separator: "/").map(String.init)
        self.version = version
        self.body = body
    }

    var parameters: [String: String] = [:]
    mutating func setParameter(name: String, value: String) {
        parameters[name] = value
    }

    public func getParameter(_ name: String) -> String? {
        parameters[name]
    }

    public func getParameter<T>(_ name: String, as _: T.Type = T.self) -> T?
        where T: LosslessStringConvertible
    {
        getParameter(name).flatMap(T.init)
    }

    var routeContextIndex: Int = 0
    public var routeContextPath: Path {
        Array(path[routeContextIndex...])
    }

    public mutating func shiftRouteContext(by segment: Segment) -> Path? {
        let segmentPath = segment.path
        guard segmentPath.count <= routeContextPath.count else { return nil }

        let rootPath = routeContextPath[..<segmentPath.count]
        if rootPath.elementsEqual(segmentPath, by: { $0.stringValue == $1.stringValue }) {
            routeContextIndex += rootPath.endIndex
            return routeContextPath
        } else {
            return nil
        }
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

    public init(contentType: [ContentType]) {
        self.contentType = contentType
    }
}

public typealias Service = (Request) async -> Response
public typealias Filter = (Service) async -> Service
