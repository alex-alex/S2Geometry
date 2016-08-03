//
//  R1IntervalTests.swift
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

class R1IntervalTests: XCTestCase {
	
	/**
		Test all of the interval operations on the given pair of intervals.
		"expected_relation" is a sequence of "T" and "F" characters corresponding
		to the expected results of contains(), interiorContains(), Intersects(),
		and InteriorIntersects() respectively.
	*/
	func testIntervalOps(_ x: R1Interval, _ y: R1Interval, _ expectedRelation: String) {
		let chars = Array(expectedRelation.characters)
		
		XCTAssertEqual(x.contains(interval: y), chars[0] == "T")
		XCTAssertEqual(x.interiorContains(interval: y), chars[1] == "T")
		XCTAssertEqual(x.intersects(with: y), chars[2] == "T")
		XCTAssertEqual(x.interiorIntersects(with: y), chars[3] == "T")
		
		XCTAssertEqual(x.contains(interval: y), x.union(with: y) == x)
		XCTAssertEqual(x.intersects(with: y), !x.intersection(with: y).isEmpty)
	}
	
	func testBasic() {
		// Constructors and accessors.
		let unit = R1Interval(lo: 0, hi: 1)
		let negunit = R1Interval(lo: -1, hi: 0)
		XCTAssertEqual(unit.lo, 0.0)
		XCTAssertEqual(unit.hi, 1.0)
		XCTAssertEqual(negunit.lo, -1.0)
		XCTAssertEqual(negunit.hi, 0.0)
		
		// is_empty()
		let half = R1Interval(lo: 0.5, hi: 0.5)
		XCTAssert(!unit.isEmpty)
		XCTAssert(!half.isEmpty)
		let empty = R1Interval.empty
		XCTAssert(empty.isEmpty)
		
		// GetCenter(), GetLength()
		XCTAssertEqual(unit.center, 0.5)
		XCTAssertEqual(half.center, 0.5)
		XCTAssertEqual(negunit.length, 1.0)
		XCTAssertEqual(half.length, 0.0)
		XCTAssert(empty.length < 0)
		
		// contains(double), interiorContains(double)
		XCTAssert(unit.contains(point: 0.5))
		XCTAssert(unit.interiorContains(point: 0.5))
		XCTAssert(unit.contains(point: 0))
		XCTAssert(!unit.interiorContains(point: 0))
		XCTAssert(unit.contains(point: 1))
		XCTAssert(!unit.interiorContains(point: 1))
		
		// contains(R1Interval), interiorContains(R1Interval)
		// Intersects(R1Interval), InteriorIntersects(R1Interval)
		testIntervalOps(empty, empty, "TTFF")
		testIntervalOps(empty, unit, "FFFF")
		testIntervalOps(unit, half, "TTTT")
		testIntervalOps(unit, unit, "TFTT")
		testIntervalOps(unit, empty, "TTFF")
		testIntervalOps(unit, negunit, "FFTF")
		testIntervalOps(unit, R1Interval(lo: 0, hi: 0.5), "TFTT")
		testIntervalOps(half, R1Interval(lo: 0, hi: 0.5), "FFTF")
		
		// addPoint()
		var r: R1Interval = empty.add(point: 5)
		XCTAssert(r.lo == 5.0 && r.hi == 5.0)
		r = r.add(point: -1)
		XCTAssert(r.lo == -1.0 && r.hi == 5.0)
		r = r.add(point: 0)
		XCTAssert(r.lo == -1.0 && r.hi == 5.0)
		
		// fromPointPair()
		XCTAssertEqual(R1Interval(p1: 4, p2: 4), R1Interval(p1: 4, p2: 4))
		XCTAssertEqual(R1Interval(p1: -1, p2: -2), R1Interval(p1: -2, p2: -1))
		XCTAssertEqual(R1Interval(p1: -5, p2: 3), R1Interval(p1: -5, p2: 3))
		
		// expanded()
		XCTAssertEqual(empty.expanded(radius: 0.45), empty)
		XCTAssertEqual(unit.expanded(radius: 0.5), R1Interval(lo: -0.5, hi: 1.5))
		
		// union(), intersection()
		XCTAssert(R1Interval(lo: 99, hi: 100).union(with: empty) == R1Interval(lo: 99, hi: 100))
		XCTAssert(empty.union(with: R1Interval(lo: 99, hi: 100)) == R1Interval(lo: 99, hi: 100))
		XCTAssert(R1Interval(lo: 5, hi: 3).union(with: R1Interval(lo: 0, hi: -2)).isEmpty)
		XCTAssert(R1Interval(lo: 0, hi: -2).union(with: R1Interval(lo: 5, hi: 3)).isEmpty)
		XCTAssert(unit.union(with: unit) == unit)
		XCTAssert(unit.union(with: negunit) == R1Interval(lo: -1, hi: 1))
		XCTAssert(negunit.union(with: unit) == R1Interval(lo: -1, hi: 1))
		XCTAssert(half.union(with: unit) == unit)
		XCTAssert(unit.intersection(with: half) == half)
		XCTAssert(unit.intersection(with: negunit) == R1Interval(lo: 0, hi: 0))
		XCTAssert(negunit.intersection(with: half).isEmpty)
		XCTAssert(unit.intersection(with: empty).isEmpty)
		XCTAssert(empty.intersection(with: unit).isEmpty)
	}
	
}

extension R1IntervalTests {
	static var allTests: [(String, (R1IntervalTests) -> () throws -> Void)] {
		return [
			("testBasic", testBasic),
		]
	}
}

