import XCTest
@testable import OpeningHoursParser

final class OpeningHoursTests: XCTestCase {
	func test24_7() throws {
		let openingHours = OpeningHours(string: "24/7")
		XCTAssertEqual(openingHours.ruleList.rules.count, 1)
		
		let rule = try XCTUnwrap(openingHours.ruleList.rules.first)
		XCTAssert(rule.is24_7())
	}
	
	private func withSampleData(in testFileName: String, file: StaticString = #filePath, line: UInt = #line, check: (String) -> Void) throws {
		let sampleDataURL = try XCTUnwrap(Bundle.module.url(forResource: testFileName, withExtension: "txt"), file: file, line: line)
		
		let sampleData = try String(contentsOf: sampleDataURL, encoding: .utf8)
		
		let lines = sampleData.components(separatedBy: .newlines)
		
		for lineIndex in lines.indices {
			let line = lines[lineIndex]
			
			let components = line.split(separator: "\t", maxSplits: 1)
			
			
			guard components.count == 2 else {
				continue
			}
			
			let stringValue = String(components[1])
			
			check(stringValue)
		}
	}
	
	/*
	func testValidityOfTestData() throws {
		try withSampleData(in: "opening_hours") { stringValue in
			let openingHours = OpeningHours(string: stringValue)
			XCTAssertFalse(openingHours.ruleList.rules.isEmpty, "Unexpected error in '\(stringValue)' at position \(openingHours.errorPosition)")
		}
	}
	func testDifferencesWhenSkippingMisplacedComma() throws {
		try withSampleData(in: "opening_hours") { stringValue in
			MonthsDaysHours.skipMisplacedComma = false
			let oh1 = OpeningHours(string: stringValue)
			MonthsDaysHours.skipMisplacedComma = true
			let oh2 = OpeningHours(string: stringValue)
			XCTAssertEqual(oh1.ruleList.rules.count, oh2.ruleList.rules.count, "Difference for: \(stringValue)")
		}
	}
	*/
	
	func testMisplacedComma() throws {
		let stringValue = "Dec 15-Apr 20,Jun 20-Jul 31, 07:30-12:30,16:00-19:30"
		let openingHours = OpeningHours(string: stringValue)
		XCTAssertEqual(openingHours.ruleList.rules.count, 1)
	}
}
