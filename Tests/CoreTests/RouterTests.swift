import XCTest
@testable import Core

func simpleRequest(method: HTTPMethod = .Get, uri: String) -> Request {
    Request(method: method, headers: [], uri: uri, version: .OneOne, body: .empty)
}

final class RouterTests: XCTestCase {
    
    func testCreateRoute() {
        let route = route(.Get, "api/v1/cats")
        let routeSegmentStrings = route.path.map { $0.stringValue }
        
        XCTAssertEqual(route.path.count, 3)
        XCTAssertEqual(routeSegmentStrings, ["api", "v1", "cats"])
    }
    
    // MARK: - Matching Tests
    
    func testMatch() {
        let allCatsRoute = route(.Get, "api/v1/cats")
        let request = simpleRequest(uri: "/api/v1/cats")
        
        XCTAssertTrue(match(allCatsRoute, with: request))
    }
    
    func testCaseInsenstiveMatch() {
        let allCatsRoute = route(.Get, "API/v1/caTs")
        let request = simpleRequest(uri: "/aPi/V1/CAts")
        
        XCTAssertTrue(match(allCatsRoute, with: request))
    }
    
    func testNoMatch() {
        let aCatsRoute  = route(.Get, "api/v1/cats", NamedParam("cat_id", type: .Int))
        let request = simpleRequest(uri: "/api/v1/cats")
        
        XCTAssertFalse(match(aCatsRoute, with: request))
    }
    
    func testMatchStringParameter() {
        let aCatsRoute  = route(.Get, "api", NamedParam("version", type: .String), "cats")
        let request = simpleRequest(uri: "/api/v1/cats")
        
        XCTAssertTrue(match(aCatsRoute, with: request))
    }
    
    func testMatchIntParameter() {
        let aCatsRoute  = route(.Get, "api", NamedParam("version", type: .Int), "cats")
        
        let wrongRequest = simpleRequest(uri: "/api/v1/cats")
        XCTAssertFalse(match(aCatsRoute, with: wrongRequest))
        
        let goodRequest = simpleRequest(uri: "/api/1/cats")
        XCTAssertTrue(match(aCatsRoute, with: goodRequest))
    }
    
    func testMatchUUIDParameter() {
        let aCatRoute  = route(.Get, "api/v1", "cats", NamedParam("cat_id", type: .UUID))
        
        let wrongRequest = simpleRequest(uri: "/api/v1/cats/test")
        XCTAssertFalse(match(aCatRoute, with: wrongRequest))
        
        let goodRequest = simpleRequest(uri: "/api/v1/cats/114e0431-d939-485e-bf0c-ecfd566df419")
        XCTAssertTrue(match(aCatRoute, with: goodRequest))
    }
}
