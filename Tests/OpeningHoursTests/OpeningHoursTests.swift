import XCTest
@testable import OpeningHours

final class OpeningHoursTests: XCTestCase {
	
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

	
	func testValidOpeningHours() throws {
		try withSampleData(in: "opening_hours_valid") { stringValue in
			let openingHours = OpeningHours(string: stringValue)
			XCTAssertFalse(openingHours.hasError, "Unexpected error in \(stringValue) at position \(openingHours.errorPosition)")
		}
	}
	
	func testInvalidOpeningHours() throws {
		try withSampleData(in: "opening_hours_invalid") { stringValue in
			let openingHours = OpeningHours(string: stringValue)
			XCTAssertTrue(openingHours.hasError, "Expected error in \(stringValue)")
		}
	}
}
