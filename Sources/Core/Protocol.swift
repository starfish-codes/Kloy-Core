public extension Status {
    // MARK: - Informational Response (1xx)

    // MARK: - Success (2xx)

    static let ok = Status(code: 200, description: "OK")
    static let created = Status(code: 201, description: "Created")
    static let accepted = Status(code: 202, description: "Accepted")
    static let nonAuthorativeInformation = Status(code: 203, description: "Non-Authoritative Information")
    static let noContent = Status(code: 204, description: "No Content")
    static let resetContent = Status(code: 205, description: "Reset Content")
    static let partialContent = Status(code: 206, description: "Partial Content")
    static let multiStatus = Status(code: 207, description: "Multi-Status")
    static let alreadyReported = Status(code: 208, description: "Already Reported")
    static let instanceManipulationUsed = Status(code: 226, description: "IM Used")

    // MARK: - Redirection (3xx)

    // MARK: - Client Errors (4xx)

    static let badRequest = Status(code: 400, description: "Bad Request")
    static let unauthorized = Status(code: 401, description: "Unauthorized")
    static let forbidden = Status(code: 403, description: "Forbidden")
    static let notFound = Status(code: 404, description: "Not Found")
    static let methodNotAllowed = Status(code: 405, description: "Method Not Allowed")
    // ...
    static let teapot = Status(code: 418, description: "I'm a teapot")

    // MARK: - Server Errors (5xx)

    static let internalServerError = Status(code: 500, description: "Internal Server Error")
}
