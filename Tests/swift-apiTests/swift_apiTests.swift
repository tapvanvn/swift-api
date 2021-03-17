import XCTest
@testable import swift_api

final class swift_apiTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_api().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
