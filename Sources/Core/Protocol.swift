extension Status {
    // MARK: - Informational Response (1xx)
    
    // MARK: - Success (2xx)
    public static let ok = Status(code: 200, description: "OK")
    public static let created = Status(code: 201, description: "Created")
    public static let accepted = Status(code: 202, description: "Accepted")
    public static let nonAuthorativeInformation = Status(code: 203, description: "Non-Authoritative Information")
    public static let noContent = Status(code: 204, description: "No Content")
    public static let resetContent = Status(code: 205, description: "Reset Content")
    public static let partialContent = Status(code: 206, description: "Partial Content")
    public static let multiStatus = Status(code: 207, description: "Multi-Status")
    public static let alreadyReported = Status(code: 208, description: "Already Reported")
    public static let instanceManipulationUsed = Status(code: 226, description: "IM Used")
    
    // MARK: - Redirection (3xx)
    
    // MARK: - Client Errors (4xx)
    public static let badRequest = Status(code: 400, description: "Bad Request")
    public static let unauthorized = Status(code: 401, description: "Unauthorized")
    public static let forbidden = Status(code: 403, description: "Forbidden")
    public static let notFound = Status(code: 404, description: "Not Found")
    public static let methodNotAllowed = Status(code: 405, description: "Method Not Allowed")
    // ...
    public static let teapot = Status(code: 418, description: "I'm a teapot")
    
    // MARK: - Server Errors (5xx)
}
