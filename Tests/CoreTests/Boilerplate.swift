import Core

func simpleRequest(method: HTTPMethod = .get, uri: String) -> Request {
    Request(method: method, headers: [], uri: uri, version: .oneOne, body: .empty)
}

func simpleResponse(status: Status = .ok, text: String) -> Response {
    Response(status: status, headers: [], version: .oneOne, body: .init(from: text)!)
}

func simpleService(status: Status = .ok, body: String) -> (Request) -> Response {
    { request in
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}
