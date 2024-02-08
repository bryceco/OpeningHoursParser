import XCTest
import OpeningHoursParser

final class OpeningHoursTests: XCTestCase {
	func test24_7() throws {
		let openingHours = OpeningHours(string: "24/7")
		XCTAssertEqual(openingHours.ruleList.rules.count, 1)
		
		let rule = try XCTUnwrap(openingHours.ruleList.rules.first)
		XCTAssert(rule.is24_7())
	}
}
