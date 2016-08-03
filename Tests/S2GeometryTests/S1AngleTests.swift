//
//  S1AngleTests.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/30/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

import XCTest
@testable import S2Geometry

class S1AngleTests: XCTestCase {
	
	func testBasic() {
		// Check that the conversion between Pi radians and 180 degrees is exact.
		XCTAssertEqual(S1Angle(radians: M_PI).radians, M_PI)
		XCTAssertEqual(S1Angle(radians: M_PI).degrees, 180.0)
		XCTAssertEqual(S1Angle(degrees: 180).radians, M_PI)
		XCTAssertEqual(S1Angle(degrees: 180).degrees, 180.0)
		
		XCTAssertEqual(S1Angle(radians: M_PI / 2).degrees, 90.0)
		
		// Check negative angles.
		XCTAssertEqual(S1Angle(radians: -M_PI / 2).degrees, -90.0)
		XCTAssertEqual(S1Angle(degrees: -45).radians, -M_PI / 4)
		
		// Check that E5/E6/E7 representations work as expected.
		XCTAssertEqual(S1Angle(e5: 2000000), S1Angle(degrees: 20))
		XCTAssertEqual(S1Angle(e6: -60000000), S1Angle(degrees: -60))
		XCTAssertEqual(S1Angle(e7: 750000000), S1Angle(degrees: 75))
		XCTAssertEqual(S1Angle(degrees: 12.34567).e5, 1234567)
		XCTAssertEqual(S1Angle(degrees: 12.345678).e6, 12345678)
		XCTAssertEqual(S1Angle(degrees: -12.3456789).e7, -123456789)
	}
	
}

extension S1AngleTests {
	static var allTests: [(String, (S1AngleTests) -> () throws -> Void)] {
		return [
			("testBasic", testBasic),
		]
	}
}
