public struct Server {
    let service: Service
    
    public init(from: @escaping Service) {
        service = from
    }
    
    public func process(request: Request) -> Response {
        service(request)
    }
}
