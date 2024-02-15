//
//  CompareWithEvaluationToolTests.swift
//  OpeningHoursParser
//
//  Created by Lieven Dekeyser on 13/02/2024.
//

import Foundation
import XCTest
import WebKit
import OpeningHoursParser


@available(iOS 15.0, *)
class CompareWithEvaluationToolTests: XCTestCase {
	var webView: WKWebView?
	
	enum WebViewError: Error {
		case notLoaded
		case unexpectedResponse
	}
	
	override func setUpWithError() throws {
		try super.setUpWithError()
		
		let navigationDelegate = WebViewDidFinishNavigationDelegate(expectation: self.expectation(description: "WKWebView did finish navigation"))
	
		let webView = WKWebView()
		webView.navigationDelegate = navigationDelegate
		let html = """
			<!DOCTYPE html>
			<html lang="en">
				<head>
					<title>Simple page using opening_hours.js</title>
					<meta charset="utf-8">
					<script src="https://openingh.openstreetmap.de/opening_hours.js/opening_hours+deps.min.js"></script>
					<script>
						function isValid(input_value) {
							try {
								let oh = new opening_hours(input_value, { lat: 51.05, lon: 3.73, address: {country_code: 'be'}}, { 'locale': navigator.language });
								return true;
							} catch (e) {
								return false;
							}
						}
					</script>
				</head>
				<body>
				</body>
			</html>
			"""
		
		webView.loadHTMLString(html, baseURL: nil)
		
		wait(for: [navigationDelegate.expectation], timeout: 10.0)
		
		if navigationDelegate.didFinish {
			self.webView = webView
		} else {
			self.webView = nil
			throw WebViewError.notLoaded
		}
	}
	
	private func isValidAccordingToEvaluationTool(_ openingHours: String) async throws -> Bool {
		let webView = try XCTUnwrap(self.webView)
		
		let response = try await webView.evaluateJavaScript("isValid('\(openingHours.escapedForJavascript)')")
		if let isValid = response as? Bool {
			return isValid
		} else {
			throw WebViewError.unexpectedResponse
		}
	}
	
	private func isValidAccordingToOpeningHoursParser(_ stringValue: String) throws -> Bool {
		let openingHours = OpeningHours(string: stringValue)
		return openingHours.ruleList.rules.count > 0
	}

	
	func test24_7() async throws {
		let isValid = try await isValidAccordingToEvaluationTool("24/7")
		XCTAssertTrue(isValid)
	}
	
	func testDifferencesWithEvaluationTool() async throws {
		let tempFolder = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: FileManager.default.temporaryDirectory, create: true)
		let validButUnparsable = tempFolder.appendingPathComponent("oh_valid_unparsable.txt", isDirectory: false)
		let invalidButParsable = tempFolder.appendingPathComponent("oh_invalid_parsable.txt", isDirectory: false)
		
		print("Writing results to \(tempFolder.path)")
		
		var differences = 0
		
		try await withLines(in: "opening_hours") { line in
			let components = line.split(separator: "\t", maxSplits: 1)
			guard components.count == 2 else {
				return
			}
			let stringValue = String(components[1])
			do {
				let isValid = try await self.isValidAccordingToEvaluationTool(stringValue)
				let isParsable = try self.isValidAccordingToOpeningHoursParser(stringValue)
				
				if isValid != isParsable {
					try "\(line)\n".append(to: isValid ? validButUnparsable : invalidButParsable)
					differences += 1
				}
			} catch {
				XCTFail("Exception for \(stringValue): \(error)")
			}
		}
		XCTAssertEqual(differences, 0)
	}
}


class WebViewDidFinishNavigationDelegate: NSObject, WKNavigationDelegate {
	let expectation: XCTestExpectation
	var didFinish: Bool = false
	
	init(expectation: XCTestExpectation) {
		self.expectation = expectation
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		didFinish = true
		expectation.fulfill()
	}
}

extension String {
	var escapedForJavascript: String {
		return self
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "'", with: "\\'")
			
	}
}

extension Data {
	func append(to fileURL: URL) throws {
		if FileManager.default.fileExists(atPath: fileURL.path) {
			let handle = try FileHandle(forWritingTo: fileURL)
			defer {
				try? handle.close()
			}
			try handle.seekToEnd()
			try handle.write(contentsOf: self)
		} else {
			try self.write(to: fileURL, options: .atomic)
		}
	}
}

extension String {
	enum EncodingError: Error {
		case utf8ConversionFailed
	}
	func append(to fileURL: URL) throws {
		guard let data = self.data(using: .utf8, allowLossyConversion: true) else {
			throw EncodingError.utf8ConversionFailed
		}
		
		try data.append(to: fileURL)
	}
}
