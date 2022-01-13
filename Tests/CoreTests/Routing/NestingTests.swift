@testable import Core
import XCTest

final class NestingTests: XCTestCase {
    func testOneLevelNesting() async throws {
        let router = try routed("/api/v1", routed(route(.get, "cats") ~> simpleService(body: "all cats")))
        let request = simpleRequest(method: .get, uri: "/api/v1/cats")

        let response = try await router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "all cats")
    }

    func testTwoLevelNesting() async throws {
        let router = try routed("api", routed("v1", routed(route(.get, "cats") ~> simpleService(body: "all cats"))))
        let request = simpleRequest(method: .get, uri: "/api/v1/cats")

        let response = try await router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "all cats")
    }

    func testNestedOrRouting() async throws {
        let router = try routed("api",
                                routed("v1",
                                       routed(route(.get, "cats") ~> simpleService(body: "all cats")),
                                       routed(route(.post, "cats") ~> simpleService(body: "adopt cat"))))
        let allCatsRequest = simpleRequest(method: .get, uri: "/api/v1/cats")
        let adoptACatRequest = simpleRequest(method: .post, uri: "/api/v1/cats")

        let adoptACatResponse = try await router(adoptACatRequest)
        XCTAssertEqual(adoptACatResponse.status, .ok)
        XCTAssertEqual(String(data: adoptACatResponse.body.payload, encoding: .utf8), "adopt cat")

        let allCatsResponse = try await router(allCatsRequest)
        XCTAssertEqual(allCatsResponse.status, .ok)
        XCTAssertEqual(String(data: allCatsResponse.body.payload, encoding: .utf8), "all cats")
    }

    func testNestedRoutesWithParameters() async throws {
        let router = try routed("api",
                                routed("v1",
                                       routed(route(.get, "cats", Parameter("cat_id", type: .uuid)) ~> simpleService(body: "a cat with ID"))))

        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        let failedResponse = try await router(wrongRequest)
        XCTAssertEqual(failedResponse.status, .notFound)

        let goodRequest = simpleRequest(uri: "/api/v1/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        let successResponse = try await router(goodRequest)
        XCTAssertEqual(successResponse.status, .ok)
    }

    func testNestedRoutesWithNestedParameters() async throws {
        let router = try routed("api",
                            routed(Parameter("version", type: .uuid),
                                   routed(route(.get, "cats", Parameter("cat_id", type: .uuid)) ~> simpleService(body: "a cat with ID"))))

        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        let failedResponse = try await router(wrongRequest)
        XCTAssertEqual(failedResponse.status, .notFound)

        let goodRequest = simpleRequest(uri: "/api/114e0431-d939-485e-bf0c-ecfd566df419/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        let successResponse = try await router(goodRequest)
        XCTAssertEqual(successResponse.status, .ok)
    }
}
