@testable import Core
import XCTest

@available(macOS 12.0.0, *)
final class RouterTests: XCTestCase {
    func testCreateRoute() {
        let route = route(.get, "api/v1/cats")
        let routeSegmentStrings = route.path.map(\.stringValue)

        XCTAssertEqual(route.path.count, 3)
        XCTAssertEqual(routeSegmentStrings, ["api", "v1", "cats"])
    }

    // MARK: - Matching Tests

    func testMatch() {
        let allCatsRoute = route(.get, "api/v1/cats")
        let request = simpleRequest(uri: "/api/v1/cats")

        XCTAssertNotNil(matchRequest(allCatsRoute, with: request))
    }

    func testCaseInsenstiveMatch() {
        let allCatsRoute = route(.get, "API/v1/caTs")
        let request = simpleRequest(uri: "/aPi/V1/CAts")

        XCTAssertNotNil(matchRequest(allCatsRoute, with: request))
    }

    func testNoMatch() {
        let aCatsRoute = route(.get, "api/v1/cats", Parameter("cat_id", type: .int))
        let request = simpleRequest(uri: "/api/v1/cats")

        XCTAssertNil(matchRequest(aCatsRoute, with: request))
    }

    func testMatchStringParameter() {
        let aCatsRoute = route(.get, "api", Parameter("version", type: .string), "cats")
        let request = simpleRequest(uri: "/api/v1/cats")

        XCTAssertNotNil(matchRequest(aCatsRoute, with: request))
    }

    func testMatchIntParameter() {
        let aCatsRoute = route(.get, "api", Parameter("version", type: .int), "cats")

        let wrongRequest = simpleRequest(uri: "/api/v1/cats")
        XCTAssertNil(matchRequest(aCatsRoute, with: wrongRequest))

        let goodRequest = simpleRequest(uri: "/api/1/cats")
        XCTAssertNotNil(matchRequest(aCatsRoute, with: goodRequest))
    }

    func testMatchUUIDParameter() {
        let aCatRoute = route(.get, "api/v1", "cats", Parameter("cat_id", type: .uuid))

        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        XCTAssertNil(matchRequest(aCatRoute, with: wrongRequest))

        let goodRequest = simpleRequest(uri: "/api/v1/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        XCTAssertNotNil(matchRequest(aCatRoute, with: goodRequest))
    }

    func testNamedParameterPassedDownStream() throws {
        let sampleUUID = UUID()
        let aCatRoute = route(.get, "api/v1", "cats", Parameter("cat_id", type: .uuid))
        let upStreamRequest = simpleRequest(uri: "/api/v1/cats/\(sampleUUID.uuidString)")

        let after = matchRequest(aCatRoute, with: upStreamRequest)
        XCTAssertNil(upStreamRequest.getParameter("cat_id"))

        let downStreamRequest = try XCTUnwrap(after)
        let uuidParamter: UUID = try XCTUnwrap(downStreamRequest.getParameter("cat_id"))

        XCTAssertEqual(uuidParamter, sampleUUID)
    }

    func testNonMatchDueToMethod() {
        let allCatsRoute = route(.get, "api/v1/cats")
        let request = simpleRequest(method: .put, uri: "api/v1/cats")

        XCTAssertNil(matchRequest(allCatsRoute, with: request))
    }

    func testNonMatchDueToPath() {
        let allCatsRoute = route(.get, "api/v1/cats")
        let request = simpleRequest(method: .get, uri: "api/v1/katzen")

        XCTAssertNil(matchRequest(allCatsRoute, with: request))
    }

    func testRoutedServiceWithValidRequest() async throws {
        let validRequest = simpleRequest(method: .get, uri: "api/v1/cats")
        let expectedResponse = simpleReponse(status: .teapot, text: "empty")

        let routedService = route(.get, "api/v1/cats") ~> { _ in expectedResponse }
        let responseCandidate = await routedService(validRequest)
        let response = try XCTUnwrap(responseCandidate)
        XCTAssertEqual(expectedResponse.status, response.status)
    }

    func testRoutedServiceWithInvalidRequest() async throws {
        let invalidRequest = simpleRequest(method: .post, uri: "api/v1/cats")
        let expectedResponse = simpleReponse(text: "empty")

        let routedService = route(.get, "api/v1/cats") ~> { _ in expectedResponse }
        let response = await routedService(invalidRequest)

        XCTAssertNil(response)
    }

    func testOrCombinedRoutedService() async throws {
        let invalidRequest = simpleRequest(uri: "boom")

        let leftRequest = simpleRequest(uri: "left")
        let leftResponse = simpleReponse(text: "left")

        let rightRequest = simpleRequest(uri: "right")
        let rightResponse = simpleReponse(text: "right")

        let routedService = (route(.get, "left") ~> { _ in leftResponse }) <|> (route(.get, "right") ~> { _ in rightResponse })
        let leftCandidate = await routedService(leftRequest)
        let rightCandidate = await routedService(rightRequest)

        let testLeft = try XCTUnwrap(leftCandidate)
        XCTAssertEqual("left", String(data: testLeft.body.payload, encoding: .utf8))

        let testRight = try XCTUnwrap(rightCandidate)
        XCTAssertEqual("right", String(data: testRight.body.payload, encoding: .utf8))

        let invalid = await routedService(invalidRequest)
        XCTAssertNil(invalid)
    }

    func testRouter() async throws {
        let invalidRequest = simpleRequest(uri: "boom")

        let leftRequest = simpleRequest(uri: "left")
        let leftResponse = simpleReponse(text: "left")

        let rightRequest = simpleRequest(uri: "right")
        let rightResponse = simpleReponse(text: "right")

        let routedService = routed(route(.get, "left") ~> { _ in leftResponse },
                                   route(.get, "right") ~> { _ in rightResponse })

        let leftCandidate = await routedService(leftRequest)
        let rightCandidate = await routedService(rightRequest)

        let testLeft = try XCTUnwrap(leftCandidate)
        XCTAssertEqual("left", String(data: testLeft.body.payload, encoding: .utf8))

        let testRight = try XCTUnwrap(rightCandidate)
        XCTAssertEqual("right", String(data: testRight.body.payload, encoding: .utf8))

        let invalid = await routedService(invalidRequest)

        let notFound = try XCTUnwrap(invalid)
        XCTAssertEqual(notFound.status, .notFound)
    }

    func testParameterRouterEdgeCase() async throws {
        let service = routed("api/v2/cats",
                             routed(
                                 route(.get, "") ~> simpleService(body: "All V2 Cats")
                             ),
                             routed(Parameter("cat_id", type: .int), routed(
                                 route(.get, "") ~> simpleService(body: "A V2 Cat"),
                                 route(.put, "") ~> simpleService(body: "Feed a V2 cat")
                             )))

        let request = Request(method: .put, uri: "/api/v2/cats", body: .empty)
        let responseCandidate = await service(request)

        let response = try XCTUnwrap(responseCandidate)
        XCTAssertEqual(response.status, .notFound)
    }
}
