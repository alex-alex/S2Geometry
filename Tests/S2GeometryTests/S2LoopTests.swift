//
//  S2LoopTests.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 8/3/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

import XCTest
@testable import S2Geometry

class S2LoopTests: XCTestCase {
	
	// A stripe that slightly over-wraps the equator.
	private let candyCane = S2Loop("-20:150, -20:-70, 0:70, 10:-150, 10:70, -10:-70")
	
	// A small clockwise loop in the northern & eastern hemisperes.
	private let smallNeCw = S2Loop("35:20, 45:20, 40:25")
	
	// Loop around the north pole at 80 degrees.
	private let arctic80 = S2Loop("80:-150, 80:-30, 80:90")
	
	// Loop around the south pole at 80 degrees.
	private let antarctic80 = S2Loop("-80:120, -80:0, -80:-120")
	
	// The northern hemisphere, defined using two pairs of antipodal points.
	private var northHemi = S2Loop("0:-180, 0:-90, 0:0, 0:90")
	
	// The northern hemisphere, defined using three points 120 degrees apart.
	private let northHemi3 = S2Loop("0:-180, 0:-60, 0:60")
	
	// The western hemisphere, defined using two pairs of antipodal points.
	private var westHemi = S2Loop("0:-180, -90:0, 0:0, 90:0")
	
	// The "near" hemisphere, defined using two pairs of antipodal points.
	private let nearHemi = S2Loop("0:-90, -90:0, 0:90, 90:0")
	
	// A diamond-shaped loop around the point 0:180.
	private let loopA = S2Loop("0:178, -1:180, 0:-179, 1:-180")
	
	// Another diamond-shaped loop around the point 0:180.
	private let loopB = S2Loop("0:179, -1:180, 0:-178, 1:-180")
	
	// The intersection of A and B.
	private let aIntersectB = S2Loop("0:179, -1:180, 0:-179, 1:-180")
	
	// The union of A and B.
	private let aUnionB = S2Loop("0:178, -1:180, 0:-178, 1:-180")
	
	// A minus B (concave)
	private let aMinusB = S2Loop("0:178, -1:180, 0:179, 1:-180")
	
	// B minus A (concave)
	private let bMinusA = S2Loop("0:-179, -1:180, 0:-178, 1:-180")
	
	// A self-crossing loop with a duplicated vertex
	private let bowtie = S2Loop("0:0, 2:0, 1:1, 0:2, 2:2, 1:1")
	
	private var southHemi: S2Loop = S2Loop("0:-180, 0:-90, 0:0, 0:90").inverted
	
	private var eastHemi: S2Loop = S2Loop("0:-180, -90:0, 0:0, 90:0").inverted
	
	private var farHemi: S2Loop = S2Loop("0:-90, -90:0, 0:90, 90:0").inverted
	
	func testBounds() {
		XCTAssert(candyCane.rectBound.lng.isFull)
		XCTAssert(candyCane.rectBound.latLo.degrees < -20)
		XCTAssert(candyCane.rectBound.latHi.degrees > 10)
		XCTAssert(smallNeCw.rectBound.isFull)
		XCTAssertEqual(arctic80.rectBound, S2LatLngRect(lo: S2LatLng.fromDegrees(lat: 80, lng: -180), hi: S2LatLng.fromDegrees(lat: 90, lng: 180)))
		XCTAssertEqual(antarctic80.rectBound, S2LatLngRect(lo: S2LatLng.fromDegrees(lat: -90, lng: -180), hi: S2LatLng.fromDegrees(lat: -80, lng: 180)))
		
		var invertedArctic80 = arctic80
		invertedArctic80.invert()
		// The highest latitude of each edge is attained at its midpoint.
		let mid = (invertedArctic80.vertex(0) + invertedArctic80.vertex(1)) * 0.5
		XCTAssertEqualWithAccuracy(invertedArctic80.rectBound.latHi.radians, S2LatLng(point: mid).lat.radians, accuracy: 1e-9)
		
		XCTAssert(southHemi.rectBound.lng.isFull);
		XCTAssertEqual(southHemi.rectBound.lat, R1Interval(lo: -M_PI_2, hi: 0))
	}
	
	/*public func testAreaCentroid() {
		XCTAssertEqualWithAccuracy(northHemi.area, 2 * M_PI, accuracy: 1e-9)
		XCTAssertEqualWithAccuracy(eastHemi.area, 2 * M_PI, accuracy: 1e-9)
		
		// Construct spherical caps of random height, and approximate their boundary
		// with closely spaces vertices. Then check that the area and centroid are
		// correct.
		
		for _ in 0 ..< 1 {
			// Choose a coordinate frame for the spherical cap.
			let x = S2Point.random
			let y = S2Point.normalize(point: x.crossProd(.random))
			let z = S2Point.normalize(point: x.crossProd(y))
			
			// Given two points at latitude phi and whose longitudes differ by dtheta,
			// the geodesic between the two points has a maximum latitude of
			// atan(tan(phi) / cos(dtheta/2)). This can be derived by positioning
			// the two points at (-dtheta/2, phi) and (dtheta/2, phi).
			//
			// We want to position the vertices close enough together so that their
			// maximum distance from the boundary of the spherical cap is kMaxDist.
			// Thus we want fabs(atan(tan(phi) / cos(dtheta/2)) - phi) <= kMaxDist.
			let kMaxDist = 1e-6
			let height = 2.0 * .random
			let phi = asin(1 - height)
			var maxDtheta = 2 * acos(tan(abs(phi)) / tan(abs(phi) + kMaxDist))
			maxDtheta = min(.pi, maxDtheta) // At least 3 vertices.
			
			var vertices: [S2Point] = []
			
			var theta = 0.0
			while theta < 2 * .pi {
				let cosThetaCosPhi = cos(theta) * cos(phi)
				let xCosThetaCosPhi = x * cosThetaCosPhi
				let sinThetaCosPhi = sin(theta) * cos(phi)
				let ySinThetaCosPhi = y * sinThetaCosPhi
				let zSinPhi = z * sin(phi)
				
				let sum = xCosThetaCosPhi + ySinThetaCosPhi + zSinPhi
				
				vertices.append(sum)

				theta += .random * maxDtheta
			}
			
			let loop = S2Loop(vertices: vertices)
			let areaCentroid = loop.areaAndCentroid
			
			let area = loop.area
			let centroid = loop.centroid
			let expectedArea = 2 * .pi * height
			XCTAssertEqual(areaCentroid.area, area)
			XCTAssertEqual(areaCentroid.centroid, centroid)
			
			XCTAssertLessThanOrEqual(abs(area - expectedArea), 2 * .pi * kMaxDist)
			
			// high probability
			XCTAssert(abs(area - expectedArea) >= 0.01 * kMaxDist)
			
			let expectedCentroid = z * (expectedArea * (1 - 0.5 * height))
			
			XCTAssertLessThanOrEqual((centroid - expectedCentroid).norm, 2 * kMaxDist)
		}
	}*/

	private func rotate(_ loop: S2Loop) -> S2Loop {
		var vertices: [S2Point] = []
		for i in 1 ... loop.numVertices {
			vertices.append(loop.vertex(i))
		}
		return S2Loop(vertices: vertices)
	}

	public func testContains() {
		XCTAssert(candyCane.contains(point: S2LatLng.fromDegrees(lat: 5, lng: 71).point))
		for _ in 0 ..< 4 {
			XCTAssert(northHemi.contains(point: S2Point(x: 0, y: 0, z: 1)))
			XCTAssert(!northHemi.contains(point: S2Point(x: 0, y: 0, z: -1)))
			XCTAssert(!southHemi.contains(point: S2Point(x: 0, y: 0, z: 1)))
			XCTAssert(southHemi.contains(point: S2Point(x: 0, y: 0, z: -1)))
			XCTAssert(!westHemi.contains(point: S2Point(x: 0, y: 1, z: 0)))
			XCTAssert(westHemi.contains(point: S2Point(x: 0, y: -1, z: 0)))
			XCTAssert(eastHemi.contains(point: S2Point(x: 0, y: 1, z: 0)))
			XCTAssert(!eastHemi.contains(point: S2Point(x: 0, y: -1, z: 0)))
			northHemi = rotate(northHemi)
			southHemi = rotate(southHemi)
			eastHemi = rotate(eastHemi)
			westHemi = rotate(westHemi)
		}
		
		// This code checks each cell vertex is contained by exactly one of
		// the adjacent cells.
		for level in 0 ..< 3 {
			var loops: [S2Loop] = []
			var loopVertices: [S2Point] = []
			var points: Set<S2Point> = []
			
			let end = S2CellId.end(level: level)
			var id = S2CellId.begin(level: level)
			while id != end {
				let cell = S2Cell(cellId: id)
				points.insert(cell.center)
				for k in 0 ..< 4 {
					loopVertices.append(cell.getVertex(k))
					points.insert(cell.getVertex(k))
				}
				loops.append(S2Loop(vertices: loopVertices))
				loopVertices.removeAll()
				id = id.next()
			}
			for point in points {
				var count = 0
				for loop in loops where loop.contains(point: point) {
					count += 1
				}
				XCTAssertEqual(count, 1)
			}
		}
	}
	
	private func advance( _ id: S2CellId, _ n: Int) -> S2CellId {
		var id = id, n = n - 1
		while id.isValid && n >= 0 {
			id = id.next()
			n -= 1
		}
		return id
	}
	
	private func assertRelation(_ a: S2Loop, _ b: S2Loop, _ containsOrCrosses: Int, _ intersects: Bool, _ nestable: Bool) {
		XCTAssertEqual(a.contains(other: b), containsOrCrosses == 1)
		XCTAssertEqual(a.intersects(with: b), intersects)
		if nestable {
			XCTAssertEqual(a.containsNested(other: b), a.contains(other: b))
		}
		if containsOrCrosses >= -1 {
			XCTAssertEqual(a.containsOrCrosses(other: b), containsOrCrosses)
		}
	}
	
	/*public func testLoopRelations() {
		assertRelation(northHemi, northHemi, 1, true, false);
		assertRelation(northHemi, southHemi, 0, false, false);
		assertRelation(northHemi, eastHemi, -1, true, false);
		assertRelation(northHemi, arctic80, 1, true, true);
		assertRelation(northHemi, antarctic80, 0, false, true);
		assertRelation(northHemi, candyCane, -1, true, false);

		// We can't compare northHemi3 vs. northHemi or southHemi.
		assertRelation(northHemi3, northHemi3, 1, true, false);
		assertRelation(northHemi3, eastHemi, -1, true, false);
		assertRelation(northHemi3, arctic80, 1, true, true);
		assertRelation(northHemi3, antarctic80, 0, false, true);
		assertRelation(northHemi3, candyCane, -1, true, false);

		assertRelation(southHemi, northHemi, 0, false, false);
		assertRelation(southHemi, southHemi, 1, true, false);
		assertRelation(southHemi, farHemi, -1, true, false);
		assertRelation(southHemi, arctic80, 0, false, true);
		assertRelation(southHemi, antarctic80, 1, true, true);
		assertRelation(southHemi, candyCane, -1, true, false);

		assertRelation(candyCane, northHemi, -1, true, false);
		assertRelation(candyCane, southHemi, -1, true, false);
		assertRelation(candyCane, arctic80, 0, false, true);
		assertRelation(candyCane, antarctic80, 0, false, true);
		assertRelation(candyCane, candyCane, 1, true, false);

		assertRelation(nearHemi, westHemi, -1, true, false);

		assertRelation(smallNeCw, southHemi, 1, true, false);
		assertRelation(smallNeCw, westHemi, 1, true, false);
		assertRelation(smallNeCw, northHemi, -2, true, false);
		assertRelation(smallNeCw, eastHemi, -2, true, false);

		assertRelation(loopA, loopA, 1, true, false);
		assertRelation(loopA, loopB, -1, true, false);
		assertRelation(loopA, aIntersectB, 1, true, false);
		assertRelation(loopA, aUnionB, 0, true, false);
		assertRelation(loopA, aMinusB, 1, true, false);
		assertRelation(loopA, bMinusA, 0, false, false);

		assertRelation(loopB, loopA, -1, true, false);
		assertRelation(loopB, loopB, 1, true, false);
		assertRelation(loopB, aIntersectB, 1, true, false);
		assertRelation(loopB, aUnionB, 0, true, false);
		assertRelation(loopB, aMinusB, 0, false, false);
		assertRelation(loopB, bMinusA, 1, true, false);

		assertRelation(aIntersectB, loopA, 0, true, false);
		assertRelation(aIntersectB, loopB, 0, true, false);
		assertRelation(aIntersectB, aIntersectB, 1, true, false);
		assertRelation(aIntersectB, aUnionB, 0, true, true);
		assertRelation(aIntersectB, aMinusB, 0, false, false);
		assertRelation(aIntersectB, bMinusA, 0, false, false);

		assertRelation(aUnionB, loopA, 1, true, false);
		assertRelation(aUnionB, loopB, 1, true, false);
		assertRelation(aUnionB, aIntersectB, 1, true, true);
		assertRelation(aUnionB, aUnionB, 1, true, false);
		assertRelation(aUnionB, aMinusB, 1, true, false);
		assertRelation(aUnionB, bMinusA, 1, true, false);

		assertRelation(aMinusB, loopA, 0, true, false);
		assertRelation(aMinusB, loopB, 0, false, false);
		assertRelation(aMinusB, aIntersectB, 0, false, false);
		assertRelation(aMinusB, aUnionB, 0, true, false);
		assertRelation(aMinusB, aMinusB, 1, true, false);
		assertRelation(aMinusB, bMinusA, 0, false, true);

		assertRelation(bMinusA, loopA, 0, false, false);
		assertRelation(bMinusA, loopB, 0, true, false);
		assertRelation(bMinusA, aIntersectB, 0, false, false);
		assertRelation(bMinusA, aUnionB, 0, true, false);
		assertRelation(bMinusA, aMinusB, 0, false, true);
		assertRelation(bMinusA, bMinusA, 1, true, false);
	}*/

}

extension S2LoopTests {
	static var allTests: [(String, (S2LoopTests) -> () throws -> Void)] {
		return [
			("testBounds", testBounds),
			("testContains", testContains),
//			("testLoopRelations", testLoopRelations),
		]
	}
}
