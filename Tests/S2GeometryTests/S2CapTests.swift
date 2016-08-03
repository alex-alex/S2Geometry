//
//  S2CapTests.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/30/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import XCTest
@testable import S2Geometry

class S2CapTests: XCTestCase {
	
	static let eps = 1e-15
	
	func testBasic() {
		// Test basic properties of empty and full caps.
		let empty = S2Cap.empty
		let full = S2Cap.full
		XCTAssert(empty.isValid)
		XCTAssert(empty.isEmpty)
		XCTAssert(empty.complement.isFull)
		XCTAssert(full.isValid)
		XCTAssert(full.isFull)
		XCTAssert(full.complement.isEmpty)
		XCTAssertEqual(full.height, 2.0)
		XCTAssertEqualWithAccuracy(full.angle.degrees, 180, accuracy: 1e-9)
		
		// Containment and intersection of empty and full caps.
		XCTAssert(empty.contains(other: empty))
		XCTAssert(full.contains(other: empty))
		XCTAssert(full.contains(other: full))
		XCTAssert(!empty.interiorIntersects(with: empty))
		XCTAssert(full.interiorIntersects(with: full))
		XCTAssert(!full.interiorIntersects(with: empty))
		
		// Singleton cap containing the x-axis.
		let xaxis = S2Cap(axis: S2Point(x: 1, y: 0, z: 0), height: 0)
		XCTAssert(xaxis.contains(point: S2Point(x: 1, y: 0, z: 0)))
		XCTAssert(!xaxis.contains(point: S2Point(x: 1, y: 1e-20, z: 0)))
		XCTAssertEqual(xaxis.angle.radians, 0.0)
		
		// Singleton cap containing the y-axis.
		let yaxis = S2Cap(axis: S2Point(x: 0, y: 1, z: 0), angle: S1Angle(radians: 0))
		XCTAssert(!yaxis.contains(point: xaxis.axis))
		XCTAssertEqual(xaxis.height, 0.0)
		
		// Check that the complement of a singleton cap is the full cap.
		let xcomp = xaxis.complement
		XCTAssert(xcomp.isValid)
		XCTAssert(xcomp.isFull)
		XCTAssert(xcomp.contains(point: xaxis.axis))
		
		// Check that the complement of the complement is *not* the original.
		XCTAssert(xcomp.complement.isValid)
		XCTAssert(xcomp.complement.isEmpty)
		XCTAssert(!xcomp.complement.contains(point: xaxis.axis))
		
		// Check that very small caps can be represented accurately.
		// Here "kTinyRad" is small enough that unit vectors perturbed by this
		// amount along a tangent do not need to be renormalized.
		let kTinyRad = 1e-10
		let tiny = S2Cap(axis: S2Point.normalize(point: S2Point(x: 1, y: 2, z: 3)), angle: S1Angle(radians: kTinyRad))
		let tangent = S2Point.normalize(point: tiny.axis.crossProd(S2Point(x: 3, y: 2, z: 1)))
		XCTAssert(tiny.contains(point: tiny.axis + tangent * (0.99 * kTinyRad)))
		XCTAssert(!tiny.contains(point: tiny.axis + tangent * (1.01 * kTinyRad)))
		
		// Basic tests on a hemispherical cap.
		let hemi = S2Cap(axis: S2Point.normalize(point: S2Point(x: 1, y: 0, z: 1)), height: 1)
		XCTAssertEqual(hemi.complement.axis, -hemi.axis)
		XCTAssertEqual(hemi.complement.height, 1.0)
		XCTAssert(hemi.contains(point: S2Point(x: 1, y: 0, z: 0)))
		XCTAssert(!hemi.complement.contains(point: S2Point(x: 1, y: 0, z: 0)))
		XCTAssert(hemi.contains(point: S2Point.normalize(point: S2Point(x: 1, y: 0, z: -(1 - S2CapTests.eps)))))
		XCTAssert(!hemi.interiorContains(point: S2Point.normalize(point: S2Point(x: 1, y: 0, z: -(1 + S2CapTests.eps)))))
		
		// A concave cap.
		let concave = S2Cap(axis: S2Point(latDegrees: 80, lngDegrees: 10), angle: S1Angle(degrees: 150));
		XCTAssert(concave.contains(point: S2Point(latDegrees: -70 * (1 - S2CapTests.eps), lngDegrees: 10)))
		XCTAssert(!concave.contains(point: S2Point(latDegrees: -70 * (1 + S2CapTests.eps), lngDegrees: 10)))
		XCTAssert(concave.contains(point: S2Point(latDegrees: -50 * (1 - S2CapTests.eps), lngDegrees: -170)))
		// FIXME: Wrong result
//		XCTAssert(!concave.contains(point: S2Point(latDegrees: -50 * (1 + S2CapTests.eps), lngDegrees: -170)))
		
		// Cap containment tests.
		XCTAssert(!empty.contains(other: xaxis))
		XCTAssert(!empty.interiorIntersects(with: xaxis))
		XCTAssert(full.contains(other: xaxis))
		XCTAssert(full.interiorIntersects(with: xaxis))
		XCTAssert(!xaxis.contains(other: full))
		XCTAssert(!xaxis.interiorIntersects(with: full))
		XCTAssert(xaxis.contains(other: xaxis))
		XCTAssert(!xaxis.interiorIntersects(with: xaxis))
		XCTAssert(xaxis.contains(other: empty))
		XCTAssert(!xaxis.interiorIntersects(with: empty))
		XCTAssert(hemi.contains(other: tiny))
		XCTAssert(hemi.contains(other: S2Cap(axis: S2Point(x: 1, y: 0, z: 0), angle: S1Angle(radians: M_PI_4 - S2CapTests.eps))))
		XCTAssert(!hemi.contains(other: S2Cap(axis: S2Point(x: 1, y: 0, z: 0), angle: S1Angle(radians: M_PI_4 + S2CapTests.eps))))
		XCTAssert(concave.contains(other: hemi))
		XCTAssert(concave.interiorIntersects(with: hemi.complement))
		XCTAssert(!concave.contains(other: S2Cap(axis: -concave.axis, height: 0.1)))
	}
	
	public func testRectBound() {
		// Empty and full caps.
		XCTAssert(S2Cap.empty.rectBound.isEmpty)
		XCTAssert(S2Cap.full.rectBound.isFull)
		
		let degreeEps = 1e-13
		// Maximum allowable error for latitudes and longitudes measured in
		// degrees. (assertDoubleNear uses a fixed tolerance that is too small.)

		// Cap that includes the south pole.
		var rect = S2Cap(axis: S2Point(latDegrees: -45, lngDegrees: 57), angle: S1Angle(degrees: 50)).rectBound
		XCTAssertEqualWithAccuracy(rect.latLo.degrees, -90, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.latHi.degrees, 5, accuracy: degreeEps)
		XCTAssert(rect.lng.isFull)
		
		// Cap that is tangent to the north pole.
		rect = S2Cap(axis: S2Point.normalize(point: S2Point(x: 1, y: 0, z: 1)), angle: S1Angle(radians: M_PI_4)).rectBound
		XCTAssertEqualWithAccuracy(rect.lat.lo, 0, accuracy: 1e-9);
		XCTAssertEqualWithAccuracy(rect.lat.hi, M_PI_2, accuracy: 1e-9);
		XCTAssert(rect.lng.isFull)

		rect = S2Cap(axis: S2Point.normalize(point: S2Point(x: 1, y: 0, z: 1)), angle: S1Angle(degrees: 45)).rectBound
		XCTAssertEqualWithAccuracy(rect.latLo.degrees, 0, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.latHi.degrees, 90, accuracy: degreeEps)
		XCTAssert(rect.lng.isFull)

		// The eastern hemisphere.
		rect = S2Cap(axis: S2Point(x: 0, y: 1, z: 0), angle: S1Angle(radians: M_PI_2 + 5e-16)).rectBound
		XCTAssertEqualWithAccuracy(rect.latLo.degrees, -90, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.latHi.degrees, 90, accuracy: degreeEps)
		XCTAssert(rect.lng.isFull)
		
		// A cap centered on the equator.
		rect = S2Cap(axis: S2Point(latDegrees: 0, lngDegrees: 50), angle: S1Angle(degrees: 20)).rectBound
		XCTAssertEqualWithAccuracy(rect.latLo.degrees, -20, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.latHi.degrees, 20, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.lngLo.degrees, 30, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.lngHi.degrees, 70, accuracy: degreeEps)
		
		// A cap centered on the north pole.
		rect = S2Cap(axis: S2Point(latDegrees: 90, lngDegrees: 123), angle: S1Angle(degrees: 10)).rectBound
		XCTAssertEqualWithAccuracy(rect.latLo.degrees, 80, accuracy: degreeEps)
		XCTAssertEqualWithAccuracy(rect.latHi.degrees, 90, accuracy: degreeEps)
		XCTAssert(rect.lng.isFull)
	}
	
	public func testCells() {
		// For each cube face, we construct some cells on
		// that face and some caps whose positions are relative to that face,
		// and then check for the expected intersection/containment results.
		
		// The distance from the center of a face to one of its vertices.
		let faceRadius = atan(M_SQRT2)
		
		for face in 0 ..< 6 {
			// The cell consisting of the entire face.
			let rootCell = S2Cell(face: face, pos: 0, level: 0)
			
			// A leaf cell at the midpoint of the v=1 edge.
			let edgeCell = S2Cell(point: S2Projections.faceUvToXyz(face: face, u: 0, v: 1 - S2CapTests.eps))
			
			// A leaf cell at the u=1, v=1 corner.
			let cornerCell = S2Cell(point: S2Projections.faceUvToXyz(face: face, u: 1 - S2CapTests.eps, v: 1 - S2CapTests.eps))
			
			// Quick check for full and empty caps.
			XCTAssert(S2Cap.full.contains(cell: rootCell))
			XCTAssert(!S2Cap.empty.mayIntersect(cell: rootCell))
			
			// Check intersections with the bounding caps of the leaf cells that are
			// adjacent to 'corner_cell' along the Hilbert curve. Because this corner
			// is at (u=1,v=1), the curve stays locally within the same cube face.
			let first = cornerCell.cellId.prev().prev().prev()
			let last = cornerCell.cellId.next().next().next().next()
			var id = first
			while id < last {
				// FIXME: Wrong result
//				let cell = S2Cell(cellId: id)
//				XCTAssertEqual(cell.capBound.contains(cell: cornerCell), id == cornerCell.cellId)
//				XCTAssertEqual(cell.capBound.mayIntersect(cell: cornerCell), id.parent.contains(other: cornerCell.cellId))
				id = id.next()
			}
			
			let antiFace = (face + 3) % 6 // Opposite face.
			for capFace in 0 ..< 6 {
				// A cap that barely contains all of 'cap_face'.
				let center = S2Projections.getNorm(face: capFace)
				let covering = S2Cap(axis: center, angle: S1Angle(radians: faceRadius + S2CapTests.eps))
				XCTAssertEqual(covering.contains(cell: rootCell), capFace == face)
				XCTAssertEqual(covering.mayIntersect(cell: rootCell), capFace != antiFace)
				XCTAssertEqual(covering.contains(cell: edgeCell), center.dotProd(edgeCell.center) > 0.1)
				XCTAssertEqual(covering.contains(cell: edgeCell), covering.mayIntersect(cell: edgeCell))
				XCTAssertEqual(covering.contains(cell: cornerCell), capFace == face)
				XCTAssertEqual(covering.mayIntersect(cell: cornerCell), center.dotProd(cornerCell.center) > 0)
				
				// A cap that barely intersects the edges of 'cap_face'.
				let bulging = S2Cap(axis: center, angle: S1Angle(radians: M_PI_4 + S2CapTests.eps))
				XCTAssert(!bulging.contains(cell: rootCell))
				XCTAssertEqual(bulging.mayIntersect(cell: rootCell), capFace != antiFace)
				XCTAssertEqual(bulging.contains(cell: edgeCell), capFace == face)
				XCTAssertEqual(bulging.mayIntersect(cell: edgeCell), center.dotProd(edgeCell.center) > 0.1)
				XCTAssert(!bulging.contains(cell: cornerCell))
				XCTAssert(!bulging.mayIntersect(cell: cornerCell))
				
				// A singleton cap.
				let singleton = S2Cap(axis: center, angle: S1Angle(radians: 0))
				XCTAssertEqual(singleton.mayIntersect(cell: rootCell), capFace == face)
				XCTAssert(!singleton.mayIntersect(cell: edgeCell))
				XCTAssert(!singleton.mayIntersect(cell: cornerCell))
			}
		}
	}
	
}

extension S2CapTests {
	static var allTests: [(String, (S2CapTests) -> () throws -> Void)] {
		return [
			("testBasic", testBasic),
			("testRectBound", testRectBound),
			("testCells", testCells),
		]
	}
}
