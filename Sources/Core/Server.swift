public struct Server {
    let service: Service

    let filters: [Filter]

    public init(from: @escaping Service, filters: [Filter] = []) {
        service = from
        var fil = filters
        fil += [errorFilter]
        self.filters = fil
    }

    public func process(request: Request) async -> Response {
        try! await request |> (service  |> filters.reduce({$0}, >>>))
    }

}



public struct Abort: Error{
    public init(_ status: Status, reason: String, headers: [Header] = []) {
        self.status = status
        self.headers = headers
        self.reason = reason
    }
    
    let status: Status
    let headers: [Header]
    let reason: String
    
}


