import XCTest
@testable import Core

final class QueryParserTests: XCTestCase {
    func testOneQueryParamUUID(){
        let url = "api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f"
        let parserId = zip(urlParser, parseQueryUUID("id")).map(
            {_, id in
                return id
            })
        let id = parserId.parse(url)
        
        XCTAssertEqual(id.match!, UUID("58b8d258-5e78-4108-9eee-c3cb6844331f"))
    }
    
    func testTwoQueryParams(){
        let url = "api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black"
        let parserId = zip(urlParser, parseQueryUUID("id"))
            .map({_, id in
                return id
            })
        let parsedId = parserId.parse(url)
        let rest = String(parsedId.rest)
        let parsedColor = parseQueryString("color").parse(rest)
        
        XCTAssertEqual(parsedId.match!, UUID("58b8d258-5e78-4108-9eee-c3cb6844331f"))
        XCTAssertEqual(parsedColor.match!, "black")
    }
    
    func testThreeQueryParams(){
        let url = "api/v1/cats?id=58b8d258-5e78-4108-9eee-c3cb6844331f&color=black&gender=female"
        let parserId = zip(urlParser, parseQueryUUID("id"))
            .map({_, id in
                return id
            })
        let parsedId = parserId.parse(url)
        let rest = String(parsedId.rest)
        let parsedColor = parseQueryString("color").parse(rest)
        let parsedGender = parseQueryString("gender").parse(String(parsedColor.rest))
        
        XCTAssertEqual(parsedId.match!, UUID("58b8d258-5e78-4108-9eee-c3cb6844331f"))
        XCTAssertEqual(parsedColor.match!, "black")
        XCTAssertEqual(parsedGender.match!, "female")
    }
}
