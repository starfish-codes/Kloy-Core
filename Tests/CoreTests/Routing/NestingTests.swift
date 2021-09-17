import XCTest
@testable import Core

final class NestingTests: XCTestCase {
    func testOneLevelNesting() {
        let router = routed("/api/v1", routed(route(.Get, "cats") ~> simpleService(body: "all cats")))
        let request = simpleRequest(method: .Get, uri: "/api/v1/cats")
        
        let response = router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "all cats")
    }
    
    func testTwoLevelNesting() {
        let router = routed("api", routed("v1", routed(route(.Get, "cats") ~> simpleService(body: "all cats"))))
        let request = simpleRequest(method: .Get, uri: "/api/v1/cats")
        
        let response = router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "all cats")
    }
    
    func testNestedOrRouting() {
        let router = routed("api",
                            routed("v1",
                                   routed(route(.Get, "cats") ~> simpleService(body: "all cats")),
                                   routed(route(.Post, "cats") ~> simpleService(body: "adopt cat"))
                            ))
        let allCatsRequest = simpleRequest(method: .Get, uri: "/api/v1/cats")
        let adoptACatRequest = simpleRequest(method: .Post, uri: "/api/v1/cats")
        
        let adoptACatResponse = router(adoptACatRequest)
        XCTAssertEqual(adoptACatResponse.status, .ok)
        XCTAssertEqual(String(data: adoptACatResponse.body.payload, encoding: .utf8), "adopt cat")
        
        let allCatsResponse = router(allCatsRequest)
        XCTAssertEqual(allCatsResponse.status, .ok)
        XCTAssertEqual(String(data: allCatsResponse.body.payload, encoding: .utf8), "all cats")
    }
    
    func testNestedRoutesWithParameters() {
        let router = routed("api",
                            routed("v1",
                                   routed(route(.Get, "cats", Parameter("cat_id", type: .UUID)) ~> simpleService(body: "a cat with ID"))))
        
        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        let failedResponse = router(wrongRequest)
        XCTAssertEqual(failedResponse.status, .notFound)
        
        let goodRequest = simpleRequest(uri: "/api/v1/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        let successResponse = router(goodRequest)
        XCTAssertEqual(successResponse.status, .ok)
    }
    
    func testNestedRoutesWithNestedParameters() {
      
        let router = routed("api",
                            routed(Parameter("version", type: .UUID),
                                   routed(route(.Get, "cats", Parameter("cat_id", type: .UUID)) ~> simpleService(body: "a cat with ID"))))

        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        let failedResponse = router(wrongRequest)
        XCTAssertEqual(failedResponse.status, .notFound)

        let goodRequest = simpleRequest(uri: "/api/114e0431-d939-485e-bf0c-ecfd566df419/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        let successResponse = router(goodRequest)
        XCTAssertEqual(successResponse.status, .ok)
    }
}
