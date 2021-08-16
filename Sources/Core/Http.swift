struct Request {}
struct Response {}

typealias Service = (Request) -> Response
typealias Filter = (Service) -> Service
