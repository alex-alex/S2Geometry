//
//  S2LatLngTests.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 8/3/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import XCTest
@testable import S2Geometry

class S2LatLngTests: XCTestCase {
	
	func testBasic() {
		let llRad = S2LatLng.fromRadians(lat: M_PI_4, lng: M_PI_2)
		XCTAssert(llRad.lat.radians == M_PI_4)
		XCTAssert(llRad.lng.radians == M_PI_2)
		XCTAssert(llRad.isValid)
		let llDeg = S2LatLng.fromDegrees(lat: 45, lng: 90)
		XCTAssertEqual(llDeg, llRad)
		XCTAssert(llDeg.isValid)
		XCTAssert(!S2LatLng.fromDegrees(lat: -91, lng: 0).isValid)
		XCTAssert(!S2LatLng.fromDegrees(lat: 0, lng: 181).isValid)
		
		var bad = S2LatLng.fromDegrees(lat: 120, lng: 200)
		XCTAssert(!bad.isValid)
		var better = bad.normalized
		XCTAssert(better.isValid)
		XCTAssertEqual(better.lat, S1Angle(degrees: 90))
		XCTAssertEqualWithAccuracy(better.lng.radians, S1Angle(degrees: -160).radians, accuracy: 1e-9)
		
		bad = S2LatLng.fromDegrees(lat: -100, lng: -360)
		XCTAssert(!bad.isValid)
		better = bad.normalized
		XCTAssert(better.isValid)
		XCTAssertEqual(better.lat, S1Angle(degrees: -90))
		XCTAssertEqualWithAccuracy(better.lng.radians, 0, accuracy: 1e-9)
		
		XCTAssert((S2LatLng.fromDegrees(lat: 10, lng: 20) + S2LatLng.fromDegrees(lat: 20, lng: 30)).approxEquals(to: S2LatLng.fromDegrees(lat: 30, lng: 50)))
		XCTAssert((S2LatLng.fromDegrees(lat: 10, lng: 20) - S2LatLng.fromDegrees(lat: 20, lng: 30)).approxEquals(to: S2LatLng.fromDegrees(lat: -10, lng: -10)))
		XCTAssert((S2LatLng.fromDegrees(lat: 10, lng: 20) * 0.5).approxEquals(to: S2LatLng.fromDegrees(lat: 5, lng: 10)))
	}
	
	func testConversion() {
		// Test special cases: poles, "date line"
		XCTAssertEqualWithAccuracy(S2LatLng(point: S2LatLng.fromDegrees(lat: 90.0, lng: 65.0).point).lat.degrees, 90.0, accuracy: 1e-9)
		XCTAssertEqual(S2LatLng(point: S2LatLng.fromRadians(lat: -M_PI_2, lng: 1).point).lat.radians, -M_PI_2)
		XCTAssertEqualWithAccuracy(abs(S2LatLng(point: S2LatLng.fromDegrees(lat: 12.2, lng: 180.0).point).lng.degrees), 180.0, accuracy: 1e-9)
		XCTAssertEqual(abs(S2LatLng(point: S2LatLng.fromRadians(lat: 0.1, lng: -M_PI).point).lng.radians), M_PI)
		
		// Test a bunch of random points.
		for _ in 0 ..< 100000 {
			let p = S2Point.random
			XCTAssert(S2.approxEquals(p, S2LatLng(point: p).point))
		}
		
		// Test generation from E5
		let test = S2LatLng.fromE5(lat: 123456, lng: 98765)
		XCTAssertEqualWithAccuracy(test.lat.degrees, 1.23456, accuracy: 1e-9)
		XCTAssertEqualWithAccuracy(test.lng.degrees, 0.98765, accuracy: 1e-9)
	}

	func testDistance() {
		XCTAssertEqual(S2LatLng.fromDegrees(lat: 90, lng: 0).getDistance(to: S2LatLng.fromDegrees(lat: 90, lng: 0)).radians, 0.0)
		XCTAssertEqualWithAccuracy(S2LatLng.fromDegrees(lat: -37, lng: 25).getDistance(to: S2LatLng.fromDegrees(lat: -66, lng: -155)).degrees, 77, accuracy: 1e-13)
		XCTAssertEqualWithAccuracy(S2LatLng.fromDegrees(lat: 0, lng: 165).getDistance(to: S2LatLng.fromDegrees(lat: 0, lng: -80)).degrees, 115, accuracy: 1e-13)
		XCTAssertEqualWithAccuracy(S2LatLng.fromDegrees(lat: 47, lng: -127).getDistance(to: S2LatLng.fromDegrees(lat: -47, lng: 53)).degrees, 180, accuracy: 2e-6)
	}
	
}

extension S2LatLngTests {
	static var allTests: [(String, (S2LatLngTests) -> () throws -> Void)] {
		return [
			("testBasic", testBasic),
			("testConversion", testConversion),
			("testDistance", testDistance),
		]
	}
}
