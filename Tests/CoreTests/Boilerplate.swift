import Core

func simpleRequest(method: HTTPMethod = .Get, uri: String) -> Request {
    Request(method: method, headers: [], uri: uri, version: .OneOne, body: .empty)
}

func simpleReponse(status: Status = .ok, text: String) -> Response {
    Response(status: status, headers: [], version: .OneOne, body: .init(from: text)!)
}

func simpleService(status: Status = .ok, body: String) -> (Request) -> Response {
    { request in
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}
