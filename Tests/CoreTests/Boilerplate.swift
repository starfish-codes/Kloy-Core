import Core

func simpleRequest(method: HTTPMethod = .Get, uri: String) -> Request {
    Request(method: method, headers: [], uri: uri, version: .OneOne, body: .empty)
}

func simpleReponse(status: Status = .ok, text: String) -> Response {
    Response(status: status, headers: [], version: .OneOne, body: .init(from: text)!)
}
