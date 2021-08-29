import XCTest
@testable import Core

final class SegmentMatchTests: XCTestCase {
    func testSegmentMatchInitialization() {
        let emptyMatch = SegmentMatch()
        XCTAssertNil(emptyMatch.parameterValue)
    }
    
    func testSegmentMatchWithData() throws {
        let stdMatch = SegmentMatch(name: "Name", value: "Value")
        
        let parameterValue = try XCTUnwrap(stdMatch.parameterValue)
        XCTAssertEqual(parameterValue.name, "Name")
        XCTAssertEqual(parameterValue.value, "Value")
    }
    
    func testSegmentMatchWithPartialData() throws {
        let partialDataMatchRight = SegmentMatch(name: nil, value: "Value")
        let partialDataMatchLeft = SegmentMatch(name: "Name", value: nil)
        
        XCTAssertNil(partialDataMatchRight.parameterValue)
        XCTAssertNil(partialDataMatchLeft.parameterValue)
    }
}

final class ParameterizedSegmentTests: XCTestCase {
    func testStringValue() {
        let segment = NamedParameter("param", type: .UUID)
        
        XCTAssertEqual(segment.stringValue, "{param: UUID}")
    }
    
    func testPath() {
        let namedParameter = NamedParameter("param", type: .UUID)
        
        XCTAssertEqual(namedParameter.path.count, 1)
        XCTAssertEqual(namedParameter.path[0] as? NamedParameter, namedParameter)
    }
    
    func testIntMatch() throws {
        let namedParameter = NamedParameter("param", type: .Int)
        
        let match10 = try XCTUnwrap(namedParameter.match("10"))
        XCTAssertEqual(match10.parameterValue?.value, "10")
        
        let matchXX = namedParameter.match("XX")
        XCTAssertNil(matchXX)
        
        let matchExceedMax = namedParameter.match(String(Int.max) + "1")
        XCTAssertNil(matchExceedMax)
        
        let matchExceedMin = namedParameter.match(String(Int.min) + "1")
        XCTAssertNil(matchExceedMin)
    }
    
    func testStringMatch() throws {
        let namedParameter = NamedParameter("param", type: .String)
        
        let matchHello = try XCTUnwrap(namedParameter.match("Hello"))
        XCTAssertEqual(matchHello.parameterValue?.value, "Hello")
    }
    
    func testUUIDMatch() throws {
        let namedParameter = NamedParameter("param", type: .UUID)
        let validUUID = UUID().uuidString
        
        let matchUUID = try XCTUnwrap(namedParameter.match(validUUID))
        XCTAssertEqual(matchUUID.parameterValue?.value, validUUID)
    }
}

final class StringSegmentTests: XCTestCase {
    func testStringValue() {
        let pathString = "Test"
        
        XCTAssertEqual(pathString.stringValue, "Test")
    }
    
    func testSingleStringPath() {
        let simplePathString = "test"
        
        XCTAssertEqual(simplePathString.path.count, 1)
        XCTAssertEqual(simplePathString.path[0] as? String, "test")
        
        let simplePathStringWithLeadingSlash = "/test"
        XCTAssertEqual(simplePathStringWithLeadingSlash.path.count, 1)
        XCTAssertEqual(simplePathStringWithLeadingSlash.path[0] as? String, "test")
    }
    
    func testNestedSegmentPath() {
        let structuredPathString = "/api/v1/test"
        
        XCTAssertEqual(structuredPathString.path.count, 3)
        XCTAssertEqual(structuredPathString.path[0] as? String, "api")
        XCTAssertEqual(structuredPathString.path[1] as? String, "v1")
        XCTAssertEqual(structuredPathString.path[2] as? String, "test")
    }
    
    func testStringMatch() throws {
        let pathString = "test"
        
        let segment = try XCTUnwrap(pathString.match("test"))
        XCTAssertNil(segment.parameterValue)
    }
    
    func testCaseInsensitiveStringMatch() throws {
        let pathString = "tEsT"
        
        let segment = try XCTUnwrap(pathString.match("TeSt"))
        XCTAssertNil(segment.parameterValue)
    }
    
    func testStringNotMatch() {
        let pathString = "test"
        
        XCTAssertNil(pathString.match("tset"))
    }
}
