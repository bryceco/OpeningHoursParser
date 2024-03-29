import XCTest
@testable import OpeningHoursParser

final class OpeningHoursTests: XCTestCase {
	func test24_7() throws {
		let openingHours = OpeningHours(string: "24/7")
		XCTAssertEqual(openingHours.ruleList.rules.count, 1)
		
		let rule = try XCTUnwrap(openingHours.ruleList.rules.first)
		XCTAssert(rule.is24_7())
	}
	
	@available(iOS 15.0, *)
	func testDifferencesWhenSkippingMisplacedComma() async throws {
		try await withSampleData(in: "opening_hours") { stringValue in
			MonthsDaysHours.skipMisplacedComma = true
			let openingHoursSkippingMisplacedComma = OpeningHours(string: stringValue)
			MonthsDaysHours.skipMisplacedComma = false
			let openingHoursNotSkippingMisplacedComma = OpeningHours(string: stringValue)
			
			let rulesWhenSkipping = openingHoursSkippingMisplacedComma.ruleList.rules.count
			let rulesWhenNotSkipping = openingHoursNotSkippingMisplacedComma.ruleList.rules.count
			
			// For opening hours that were deemed valid before
			if rulesWhenNotSkipping > 0 {
				// skipping misplaced commas should not result in invalid opening hours
				XCTAssert(rulesWhenSkipping > 0, "Skipping comma made opening hours invalid: \(stringValue)")
				// skipping misplaced commas should not result in more rules than before
				XCTAssert(rulesWhenSkipping <= rulesWhenNotSkipping, "Skipping comma resulted in more rules (\(rulesWhenSkipping) vs \(rulesWhenNotSkipping)):  \(stringValue)")
			}
			
			if rulesWhenSkipping == rulesWhenNotSkipping {
				XCTAssertEqual(openingHoursSkippingMisplacedComma.description, openingHoursNotSkippingMisplacedComma.description, "Original: \(stringValue)")
			}
		}
	}
	
	func testMisplacedComma() throws {
		let stringValue = "Dec 15-Apr 20,Jun 20-Jul 31, 07:30-12:30,16:00-19:30"
		let openingHours = OpeningHours(string: stringValue)
		XCTAssertEqual(openingHours.ruleList.rules.count, 1)
	}
}

@available(iOS 15.0, *)
extension XCTestCase {
	func withSampleData(in testFileName: String, file: StaticString = #filePath, line: UInt = #line, check: @escaping (String) async -> Void) async throws {
		try await withLines(in: testFileName, file: file, line: line) { line in
			let components = line.split(separator: "\t", maxSplits: 1)
			guard components.count == 2 else {
				return
			}
			
			await check(String(components[1]))
		}
	}
	
	func withLines(in testFileName: String, file: StaticString = #filePath, line: UInt = #line, check: @escaping (String) async -> Void) async throws {
		let sampleDataURL = try XCTUnwrap(Bundle.module.url(forResource: testFileName, withExtension: "txt"), file: file, line: line)
		
		let handle = try FileHandle(forReadingFrom: sampleDataURL)
		for try await line in handle.bytes.lines {
			await check(line)
		}
		
		try handle.close()
	}
}

