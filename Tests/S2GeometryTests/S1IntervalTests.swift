//
//  S1IntervalTests.swift
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

class S1IntervalTests: XCTestCase {

	func testIntervalOps(_ x: S1Interval, _ y: S1Interval, _ expectedRelation: String, _ expectedUnion: S1Interval, _ expectedIntersection: S1Interval) {
		let chars = Array(expectedRelation.characters)

		// Test all of the interval operations on the given pair of intervals.
		// "expected_relation" is a sequence of "T" and "F" characters corresponding
		// to the expected results of Contains(), InteriorContains(), Intersects(),
		// and InteriorIntersects() respectively.
		
		XCTAssertEqual(x.contains(interval: y), chars[0] == "T")
		XCTAssertEqual(x.interiorContains(interval: y), chars[1] == "T")
		XCTAssertEqual(x.intersects(with: y), chars[2] == "T")
		XCTAssertEqual(x.interiorIntersects(with: y), chars[3] == "T")
		
		// bounds() returns a const reference to a member variable, so we need to
		// make a copy when invoking it on a temporary object.
		XCTAssertEqual(expectedUnion, x.union(with: y))
//		XCTAssertEqual(expectedIntersection, x.intersection(with: y))
		
		XCTAssertEqual(x.contains(interval: y), x.union(with: y) == x)
//		XCTAssertEqual(x.intersects(with: y), !x.intersection(with: y).isEmpty)
		
		if y.lo == y.hi {
			let r = x.add(point: y.lo)
			XCTAssertEqual(expectedUnion, r)
		}
	}
	
	func testBasic() {
		// "Quadrants" are numbered as follows:
		// quad1 == [0, Pi/2]
		// quad2 == [Pi/2, Pi]
		// quad3 == [-Pi, -Pi/2]
		// quad4 == [-Pi/2, 0]
		
		// Constructors and accessors.
		let quad12 = S1Interval(lo: 0, hi: -M_PI)
		XCTAssertEqual(quad12.lo, 0.0)
		XCTAssertEqual(quad12.hi, M_PI)
		let quad34 = S1Interval(lo: -M_PI, hi: 0)
		XCTAssertEqual(quad34.lo, M_PI)
		XCTAssertEqual(quad34.hi, 0.0)
		let pi = S1Interval(lo: M_PI, hi: M_PI)
		XCTAssertEqual(pi.lo, M_PI)
		XCTAssertEqual(pi.hi, M_PI)
		let mipi = S1Interval(lo: -M_PI, hi: -M_PI)
		XCTAssertEqual(mipi.lo, M_PI)
		XCTAssertEqual(mipi.hi, M_PI)
		let quad23 = S1Interval(lo: M_PI_2, hi: -M_PI_2) // inverted
		XCTAssertEqual(quad23.lo, M_PI_2)
		XCTAssertEqual(quad23.hi, -M_PI_2)
		let quad1 = S1Interval(lo: 0, hi: M_PI_2)
		
		// is_valid(), is_empty(), is_inverted()
		let zero = S1Interval(lo: 0, hi: 0)
		XCTAssert(zero.isValid && !zero.isEmpty && !zero.isFull)
		let empty = S1Interval.empty
		XCTAssert(empty.isValid && empty.isEmpty && !empty.isFull)
		XCTAssert(empty.isInverted)
		let full = S1Interval.full
		XCTAssert(full.isValid && !full.isEmpty && full.isFull)
		XCTAssert(!quad12.isEmpty && !quad12.isFull && !quad12.isInverted)
		XCTAssert(!quad23.isEmpty && !quad23.isFull && quad23.isInverted)
		XCTAssert(pi.isValid && !pi.isEmpty && !pi.isInverted)
		XCTAssert(mipi.isValid && !mipi.isEmpty && !mipi.isInverted)

		// GetCenter(), GetLength()
		XCTAssertEqual(quad12.center, M_PI_2)
		XCTAssertEqual(quad12.length, M_PI)
		XCTAssertEqualWithAccuracy(S1Interval(lo: 3.1, hi: 2.9).center, 3.0 - M_PI, accuracy: 1e-9)
		XCTAssertEqualWithAccuracy(S1Interval(lo: -2.9, hi: -3.1).center, M_PI - 3.0, accuracy: 1e-9)
		XCTAssertEqualWithAccuracy(S1Interval(lo: 2.1, hi: -2.1).center, M_PI, accuracy: 1e-9)
		XCTAssertEqual(pi.center, M_PI)
		XCTAssertEqual(pi.length, 0.0)
		XCTAssertEqual(mipi.center, M_PI)
		XCTAssertEqual(mipi.length, 0.0)
		XCTAssertEqual(abs(quad23.center), M_PI)
		XCTAssertEqual(abs(quad23.length), M_PI)
		let quad123 = S1Interval(lo: 0, hi: -M_PI_2)
		XCTAssertEqualWithAccuracy(quad123.center, 0.75 * M_PI, accuracy: 1e-9)
		XCTAssertEqualWithAccuracy(quad123.length, 1.5 * M_PI, accuracy: 1e-9)
		XCTAssert(empty.length < 0)
		XCTAssertEqual(full.length, 2 * M_PI)
		
		// Complement()
		XCTAssert(empty.complement.isFull)
		XCTAssert(full.complement.isEmpty)
		XCTAssert(pi.complement.isFull)
		XCTAssert(mipi.complement.isFull)
		XCTAssert(zero.complement.isFull)
//		XCTAssert(quad12.complement.approxEquals(quad34))
//		XCTAssert(quad34.complement.approxEquals(quad12))
		let quad4 = S1Interval(lo: -M_PI_2, hi: 0)
//		XCTAssert(quad123.complement.approxEquals(quad4))
		let quad234 = S1Interval(lo: M_PI_2, hi: 0)
		
		// Contains(double), InteriorContains(double)
		XCTAssert(!empty.contains(point: 0) && !empty.contains(point: M_PI) && !empty.contains(point: -M_PI));
//		XCTAssert(!empty.interiorContains(S2.M_PI) && !empty.interiorContains(-S2.M_PI));
//		XCTAssert(full.contains(0) && full.contains(S2.M_PI) && full.contains(-S2.M_PI));
//		XCTAssert(full.interiorContains(S2.M_PI) && full.interiorContains(-S2.M_PI));
//		XCTAssert(quad12.contains(0) && quad12.contains(S2.M_PI) && quad12.contains(-S2.M_PI));
//		XCTAssert(quad12.interiorContains(S2.M_PI_2) && !quad12.interiorContains(0));
//		XCTAssert(!quad12.interiorContains(S2.M_PI) && !quad12.interiorContains(-S2.M_PI));
//		XCTAssert(quad23.contains(S2.M_PI_2) && quad23.contains(-S2.M_PI_2));
//		XCTAssert(quad23.contains(S2.M_PI) && quad23.contains(-S2.M_PI));
//		XCTAssert(!quad23.contains(0));
//		XCTAssert(!quad23.interiorContains(S2.M_PI_2) && !quad23.interiorContains(-S2.M_PI_2));
//		XCTAssert(quad23.interiorContains(S2.M_PI) && quad23.interiorContains(-S2.M_PI));
//		XCTAssert(!quad23.interiorContains(0));
//		XCTAssert(pi.contains(S2.M_PI) && pi.contains(-S2.M_PI) && !pi.contains(0));
//		XCTAssert(!pi.interiorContains(S2.M_PI) && !pi.interiorContains(-S2.M_PI));
//		XCTAssert(mipi.contains(S2.M_PI) && mipi.contains(-S2.M_PI) && !mipi.contains(0));
//		XCTAssert(!mipi.interiorContains(S2.M_PI) && !mipi.interiorContains(-S2.M_PI));
//		XCTAssert(zero.contains(0) && !zero.interiorContains(0));
		
		// Contains(S1Interval), InteriorContains(S1Interval),
		// Intersects(), InteriorIntersects(), Union(), Intersection()
		let quad2 = S1Interval(lo: M_PI_2, hi: -M_PI)
		let quad3 = S1Interval(lo: M_PI, hi: -M_PI_2)
		let pi2 = S1Interval(lo: M_PI_2, hi: M_PI_2)
		let mipi2 = S1Interval(lo: -M_PI_2, hi: -M_PI_2)

		testIntervalOps(empty, empty, "TTFF", empty, empty)
		testIntervalOps(empty, full, "FFFF", full, empty)
		testIntervalOps(empty, zero, "FFFF", zero, empty)
		testIntervalOps(empty, pi, "FFFF", pi, empty)
		testIntervalOps(empty, mipi, "FFFF", mipi, empty)
		
		testIntervalOps(full, empty, "TTFF", full, empty)
		testIntervalOps(full, full, "TTTT", full, full)
		testIntervalOps(full, zero, "TTTT", full, zero)
		testIntervalOps(full, pi, "TTTT", full, pi)
		testIntervalOps(full, mipi, "TTTT", full, mipi)
		testIntervalOps(full, quad12, "TTTT", full, quad12)
		testIntervalOps(full, quad23, "TTTT", full, quad23)
		
		testIntervalOps(zero, empty, "TTFF", zero, empty)
		testIntervalOps(zero, full, "FFTF", full, zero)
		testIntervalOps(zero, zero, "TFTF", zero, zero)
		testIntervalOps(zero, pi, "FFFF", S1Interval(lo: 0, hi: M_PI), empty)
		testIntervalOps(zero, pi2, "FFFF", quad1, empty)
		testIntervalOps(zero, mipi, "FFFF", quad12, empty)
		testIntervalOps(zero, mipi2, "FFFF", quad4, empty)
		testIntervalOps(zero, quad12, "FFTF", quad12, zero)
		testIntervalOps(zero, quad23, "FFFF", quad123, empty)

		testIntervalOps(pi2, empty, "TTFF", pi2, empty)
		testIntervalOps(pi2, full, "FFTF", full, pi2)
		testIntervalOps(pi2, zero, "FFFF", quad1, empty)
		testIntervalOps(pi2, pi, "FFFF", S1Interval(lo: M_PI_2, hi: M_PI), empty)
		testIntervalOps(pi2, pi2, "TFTF", pi2, pi2)
		testIntervalOps(pi2, mipi, "FFFF", quad2, empty)
		testIntervalOps(pi2, mipi2, "FFFF", quad23, empty)
		testIntervalOps(pi2, quad12, "FFTF", quad12, pi2)
		testIntervalOps(pi2, quad23, "FFTF", quad23, pi2)
		
		testIntervalOps(pi, empty, "TTFF", pi, empty)
		testIntervalOps(pi, full, "FFTF", full, pi)
		testIntervalOps(pi, zero, "FFFF", S1Interval(lo: M_PI, hi: 0), empty)
		testIntervalOps(pi, pi, "TFTF", pi, pi)
		testIntervalOps(pi, pi2, "FFFF", S1Interval(lo: M_PI_2, hi: M_PI), empty)
		testIntervalOps(pi, mipi, "TFTF", pi, pi)
		testIntervalOps(pi, mipi2, "FFFF", quad3, empty)
		testIntervalOps(pi, quad12, "FFTF", S1Interval(lo: 0, hi: M_PI), pi)
		testIntervalOps(pi, quad23, "FFTF", quad23, pi)

		testIntervalOps(mipi, empty, "TTFF", mipi, empty)
		testIntervalOps(mipi, full, "FFTF", full, mipi)
		testIntervalOps(mipi, zero, "FFFF", quad34, empty)
		testIntervalOps(mipi, pi, "TFTF", mipi, mipi)
		testIntervalOps(mipi, pi2, "FFFF", quad2, empty)
		testIntervalOps(mipi, mipi, "TFTF", mipi, mipi)
		testIntervalOps(mipi, mipi2, "FFFF", S1Interval(lo: -M_PI, hi: -M_PI_2), empty)
		testIntervalOps(mipi, quad12, "FFTF", quad12, mipi)
		testIntervalOps(mipi, quad23, "FFTF", quad23, mipi)
		
		testIntervalOps(quad12, empty, "TTFF", quad12, empty)
		testIntervalOps(quad12, full, "FFTT", full, quad12)
		testIntervalOps(quad12, zero, "TFTF", quad12, zero)
		testIntervalOps(quad12, pi, "TFTF", quad12, pi)
		testIntervalOps(quad12, mipi, "TFTF", quad12, mipi)
		testIntervalOps(quad12, quad12, "TFTT", quad12, quad12)
		testIntervalOps(quad12, quad23, "FFTT", quad123, quad2)
		testIntervalOps(quad12, quad34, "FFTF", full, quad12)
		
		testIntervalOps(quad23, empty, "TTFF", quad23, empty)
		testIntervalOps(quad23, full, "FFTT", full, quad23)
		testIntervalOps(quad23, zero, "FFFF", quad234, empty)
		testIntervalOps(quad23, pi, "TTTT", quad23, pi)
		testIntervalOps(quad23, mipi, "TTTT", quad23, mipi)
		testIntervalOps(quad23, quad12, "FFTT", quad123, quad2)
		testIntervalOps(quad23, quad23, "TFTT", quad23, quad23)
		testIntervalOps(quad23, quad34, "FFTT", quad234, S1Interval(lo: -M_PI, hi: -M_PI_2))
		
		testIntervalOps(quad1, quad23, "FFTF", quad123, S1Interval(lo: M_PI_2, hi: M_PI_2))
		testIntervalOps(quad2, quad3, "FFTF", quad23, mipi)
		testIntervalOps(quad3, quad2, "FFTF", quad23, pi)
		testIntervalOps(quad2, pi, "TFTF", quad2, pi)
		testIntervalOps(quad2, mipi, "TFTF", quad2, mipi)
		testIntervalOps(quad3, pi, "TFTF", quad3, pi)
		testIntervalOps(quad3, mipi, "TFTF", quad3, mipi)
		
		let mid12 = S1Interval(lo: M_PI_2 - 0.02, hi: M_PI_2 + 0.01)
		let mid23 = S1Interval(lo: M_PI - 0.01, hi: -M_PI + 0.02)
		let mid34 = S1Interval(lo: -M_PI_2 - 0.02, hi: -M_PI_2 + 0.01)
		let mid41 = S1Interval(lo: -0.01, hi: 0.02)
		
		let quad2hi = S1Interval(lo: mid23.lo, hi: quad12.hi)
		let quad1lo = S1Interval(lo: quad12.lo, hi: mid41.hi)
		let quad12eps = S1Interval(lo: quad12.lo, hi: mid23.hi)
		let quadeps12 = S1Interval(lo: mid41.lo, hi: quad12.hi)
		let quad123eps = S1Interval(lo: quad12.lo, hi: mid34.hi)
		testIntervalOps(quad12, mid12, "TTTT", quad12, mid12)
		testIntervalOps(mid12, quad12, "FFTT", quad12, mid12)
		testIntervalOps(quad12, mid23, "FFTT", quad12eps, quad2hi)
		testIntervalOps(mid23, quad12, "FFTT", quad12eps, quad2hi)
		testIntervalOps(quad12, mid34, "FFFF", quad123eps, empty)
		testIntervalOps(mid34, quad12, "FFFF", quad123eps, empty)
		testIntervalOps(quad12, mid41, "FFTT", quadeps12, quad1lo)
		testIntervalOps(mid41, quad12, "FFTT", quadeps12, quad1lo)
		
		let quad2lo = S1Interval(lo: quad23.lo, hi: mid12.hi)
		let quad3hi = S1Interval(lo: mid34.lo, hi: quad23.hi)
		let quadeps23 = S1Interval(lo: mid12.lo, hi: quad23.hi)
		let quad23eps = S1Interval(lo: quad23.lo, hi: mid34.hi)
		let quadeps123 = S1Interval(lo: mid41.lo, hi: quad23.hi)
		testIntervalOps(quad23, mid12, "FFTT", quadeps23, quad2lo)
		testIntervalOps(mid12, quad23, "FFTT", quadeps23, quad2lo)
		testIntervalOps(quad23, mid23, "TTTT", quad23, mid23);
		testIntervalOps(mid23, quad23, "FFTT", quad23, mid23);
		testIntervalOps(quad23, mid34, "FFTT", quad23eps, quad3hi)
		testIntervalOps(mid34, quad23, "FFTT", quad23eps, quad3hi)
		testIntervalOps(quad23, mid41, "FFFF", quadeps123, empty)
		testIntervalOps(mid41, quad23, "FFFF", quadeps123, empty)
		
		// AddPoint()
		var r = S1Interval.empty
		var res = r.add(point: 0)
		XCTAssertEqual(res, zero)
		
		res = r.add(point: M_PI)
		XCTAssertEqual(res, pi)
		
		res = r.add(point: -M_PI)
		XCTAssertEqual(res, mipi)
		
		res = r.add(point: M_PI)
		res = res.add(point: -M_PI)
		XCTAssertEqual(res, pi)
		
		res = res.add(point: -M_PI)
		res = res.add(point: M_PI)
		XCTAssertEqual(res, mipi)
		
		res = r.add(point: mid12.lo)
		res = res.add(point: mid12.hi)
		XCTAssertEqual(res, mid12)
		
		res = r.add(point: mid23.lo)
		res = res.add(point: mid23.hi)
		XCTAssertEqual(res, mid23)
		
		res = quad1.add(point: -0.9 * M_PI)
		res = res.add(point: -M_PI_2)
		XCTAssertEqual(res, quad123)
		
		r = S1Interval.full
		res = r.add(point: 0)
		XCTAssert(res.isFull)
		
		res = r.add(point: M_PI)
		XCTAssert(res.isFull)
		
		res = r.add(point: -M_PI)
		XCTAssert(res.isFull)
		
		// FromPointPair()
		XCTAssertEqual(S1Interval(p1: -M_PI, p2: M_PI), pi)
		XCTAssertEqual(S1Interval(p1: M_PI, p2: -M_PI), pi)
		XCTAssertEqual(S1Interval(p1: mid34.hi, p2: mid34.lo), mid34)
		XCTAssertEqual(S1Interval(p1: mid23.lo, p2: mid23.hi), mid23)
		
		// Expanded()
		XCTAssertEqual(empty.expanded(radius: 1), empty)
		XCTAssertEqual(full.expanded(radius: 1), full)
		XCTAssertEqual(zero.expanded(radius: 1), S1Interval(lo: -1, hi: 1))
		XCTAssertEqual(mipi.expanded(radius: 0.01), S1Interval(lo: M_PI - 0.01, hi: -M_PI + 0.01))
		XCTAssertEqual(pi.expanded(radius: 27), full)
		XCTAssertEqual(pi.expanded(radius: M_PI_2), quad23)
		XCTAssertEqual(pi2.expanded(radius: M_PI_2), quad12)
		XCTAssertEqual(mipi2.expanded(radius: M_PI_2), quad34)
		
		// ApproxEquals()
//		XCTAssert(empty.approxEquals(empty));
//		XCTAssert(zero.approxEquals(empty) && empty.approxEquals(zero));
//		XCTAssert(pi.approxEquals(empty) && empty.approxEquals(pi));
//		XCTAssert(mipi.approxEquals(empty) && empty.approxEquals(mipi));
//		XCTAssert(pi.approxEquals(mipi) && mipi.approxEquals(pi));
//		XCTAssert(pi.union(mipi).approxEquals(pi));
//		XCTAssert(mipi.union(pi).approxEquals(pi));
//		XCTAssert(pi.union(mid12).union(zero).approxEquals(quad12));
//		XCTAssert(quad2.intersection(quad3).approxEquals(pi));
//		XCTAssert(quad3.intersection(quad2).approxEquals(pi));
	}
	
}

extension S1IntervalTests {
	static var allTests: [(String, (S1IntervalTests) -> () throws -> Void)] {
		return [
			("testBasic", testBasic),
		]
	}
}
