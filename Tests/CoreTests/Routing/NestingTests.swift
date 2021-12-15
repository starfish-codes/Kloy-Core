@testable import Core
import XCTest

@available(iOS 13.0.0, *)
@available(macOS 12.0.0, *)
final class NestingTests: XCTestCase {
    func testOneLevelNesting() async {
        let router = routed("/api/v1", routed(route(.get, "cats") ~> simpleService(body: "all cats")))
        let request = simpleRequest(method: .get, uri: "/api/v1/cats")

        let response = await router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "all cats")
    }

    func testTwoLevelNesting() async {
        let router = routed("api", routed("v1", routed(route(.get, "cats") ~> simpleService(body: "all cats"))))
        let request = simpleRequest(method: .get, uri: "/api/v1/cats")

        let response = await router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "all cats")
    }

    func testNestedOrRouting() async {
        let router = routed("api",
                            routed("v1",
                                   routed(route(.get, "cats") ~> simpleService(body: "all cats")),
                                   routed(route(.post, "cats") ~> simpleService(body: "adopt cat"))))
        let allCatsRequest = simpleRequest(method: .get, uri: "/api/v1/cats")
        let adoptACatRequest = simpleRequest(method: .post, uri: "/api/v1/cats")

        let adoptACatResponse = await router(adoptACatRequest)
        XCTAssertEqual(adoptACatResponse.status, .ok)
        XCTAssertEqual(String(data: adoptACatResponse.body.payload, encoding: .utf8), "adopt cat")

        let allCatsResponse = await router(allCatsRequest)
        XCTAssertEqual(allCatsResponse.status, .ok)
        XCTAssertEqual(String(data: allCatsResponse.body.payload, encoding: .utf8), "all cats")
    }

    func testNestedRoutesWithParameters() async {
        let router = routed("api",
                            routed("v1",
                                   routed(route(.get, "cats", Parameter("cat_id", type: .uuid)) ~> simpleService(body: "a cat with ID"))))

        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        let failedResponse = await router(wrongRequest)
        XCTAssertEqual(failedResponse.status, .notFound)

        let goodRequest = simpleRequest(uri: "/api/v1/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        let successResponse = await router(goodRequest)
        XCTAssertEqual(successResponse.status, .ok)
    }

    func testNestedRoutesWithNestedParameters() async {
        let router = routed("api",
                            routed(Parameter("version", type: .uuid),
                                   routed(route(.get, "cats", Parameter("cat_id", type: .uuid)) ~> simpleService(body: "a cat with ID"))))

        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        let failedResponse = await router(wrongRequest)
        XCTAssertEqual(failedResponse.status, .notFound)

        let goodRequest = simpleRequest(uri: "/api/114e0431-d939-485e-bf0c-ecfd566df419/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        let successResponse = await router(goodRequest)
        XCTAssertEqual(successResponse.status, .ok)
    }
}
