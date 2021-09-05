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
        let request = simpleRequest(method: .Post, uri: "/api/v1/cats")
        
        let response = router(request)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(data: response.body.payload, encoding: .utf8), "adopt cat")
    }
}
