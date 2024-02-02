import XCTest
@testable import OpeningHours

final class OpeningHoursTests: XCTestCase {
	
	func testValidOpeningHours() throws {
		let sampleDataURL = try XCTUnwrap(Bundle.module.url(forResource: "opening_hours_valid", withExtension: "txt"))
		
		let sampleData = try String(contentsOf: sampleDataURL, encoding: .utf8)
		
		let lines = sampleData.components(separatedBy: .newlines)
		
		for lineIndex in lines.indices {
			let line = lines[lineIndex]
			
			let components = line.split(separator: "\t", maxSplits: 1)
			
			
			guard components.count == 2 else {
				continue
			}
			
			let stringValue = String(components[1])
			
			let openingHours = OpeningHours(string: stringValue)
			XCTAssertFalse(openingHours.hasError, "Unexpected error in \(stringValue) at position \(openingHours.errorPosition)")
		}
	}
	
	func testInvalidOpeningHours() throws {
		let sampleDataURL = try XCTUnwrap(Bundle.module.url(forResource: "opening_hours_invalid", withExtension: "txt"))
		
		let sampleData = try String(contentsOf: sampleDataURL, encoding: .utf8)
		
		let lines = sampleData.components(separatedBy: .newlines)
		
		for lineIndex in lines.indices {
			let line = lines[lineIndex]
			
			let components = line.split(separator: "\t", maxSplits: 1)
			
			
			guard components.count == 2 else {
				continue
			}
			
			let stringValue = String(components[1])
			
			let openingHours = OpeningHours(string: stringValue)
			XCTAssertTrue(openingHours.hasError, "Expected error in \(stringValue)")
		}
	}
}
