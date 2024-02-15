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

