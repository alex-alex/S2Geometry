//
//  S2CellIdTests.swift
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

class S2CellIdTests: XCTestCase {
	
	private func getCellId(_ latDegrees: Double, _ lngDegrees: Double) -> S2CellId {
		let id = S2CellId(latlng: S2LatLng.fromDegrees(lat: latDegrees, lng: lngDegrees))
//		logger.info(Long.toString(id.id(), 16));
		return id
	}
	
	func testBasic() {
//		logger.info("TestBasic")
		// Check default constructor.
		var id = S2CellId()
		XCTAssertEqual(id.id, 0)
		XCTAssert(!id.isValid)
		
		// Check basic accessor methods.
		id = S2CellId(face: 3, pos: 0x12345678, level: S2CellId.maxLevel - 4)
		XCTAssert(id.isValid)
		XCTAssertEqual(id.face, 3);
		XCTAssertEqual(id.pos, 0x12345700)
		XCTAssertEqual(id.level, S2CellId.maxLevel - 4);
		XCTAssert(!id.isLeaf)
		
		// Check face definitions
		XCTAssertEqual(getCellId(0, 0).face, 0)
		XCTAssertEqual(getCellId(0, 90).face, 1)
		XCTAssertEqual(getCellId(90, 0).face, 2)
		XCTAssertEqual(getCellId(0, 180).face, 3)
		XCTAssertEqual(getCellId(0, -90).face, 4)
		XCTAssertEqual(getCellId(-90, 0).face, 5)
		
		// Check parent/child relationships.
		XCTAssertEqual(id.childBegin(level: id.level + 2).pos, 0x12345610)
		XCTAssertEqual(id.childBegin().pos, 0x12345640)
		XCTAssertEqual(id.parent.pos, 0x12345400)
		XCTAssertEqual(id.parent(level: id.level - 2).pos, 0x12345000)
		
		// Check ordering of children relative to parents.
		XCTAssert(id.childBegin() < id)
		XCTAssert(id.childEnd() > id)
		XCTAssertEqual(id.childBegin().next().next().next().next(), id.childEnd())
		XCTAssertEqual(id.childBegin(level: S2CellId.maxLevel), id.rangeMin)
		XCTAssertEqual(id.childEnd(level: S2CellId.maxLevel), id.rangeMax.next())
		
		// Check wrapping from beginning of Hilbert curve to end and vice versa.
		XCTAssertEqual(S2CellId.begin(level: 0).prevWrap(), S2CellId.end(level: 0).prev())
		
		XCTAssertEqual(S2CellId.begin(level: S2CellId.maxLevel).prevWrap(), S2CellId(face: 5, pos: Int64(bitPattern: ~UInt64(0) >> UInt64(S2CellId.faceBits)), level: S2CellId.maxLevel))
		
		XCTAssertEqual(S2CellId.end(level: 4).prev().nextWrap(), S2CellId.begin(level: 4))
		XCTAssertEqual(S2CellId.end(level: S2CellId.maxLevel).prev().nextWrap(), S2CellId(face: 0, pos: 0, level: S2CellId.maxLevel))
		
		// Check that cells are represented by the position of their center along the Hilbert curve.
		XCTAssertEqual(Int64.addWithOverflow(id.rangeMin.id, id.rangeMax.id).0, Int64.multiplyWithOverflow(2, id.id).0)
	}
	
	func testInverses() {
//		logger.info("TestInverses");
		// Check the conversion of random leaf cells to S2LatLngs and back.
		for _ in 0 ..< 200000 {
			let id = S2CellId.random(level: S2CellId.maxLevel)
			XCTAssert(id.isLeaf && id.level == S2CellId.maxLevel)
			let center = id.latLng
			XCTAssertEqual(S2CellId(latlng: center).id, id.id)
		}
	}

	func testToToken() {
		XCTAssertEqual("000000000000010a", S2CellId(id: 266).token)
		XCTAssertEqual("80855c", S2CellId(id: -9185834709882503168).token)
	}

	func testTokens() {
//		logger.info("TestTokens");
		
		// Test random cell ids at all levels.
		for _ in 0 ..< 10000 {
			let id = S2CellId.random
			if !id.isValid {
				continue;
			}
			let token = id.token
			XCTAssert(token.characters.count <= 16)
			XCTAssertEqual(try S2CellId(token: token), id)
		}
		// Check that invalid cell ids can be encoded.
		let token = S2CellId.none.token
		XCTAssertEqual(try S2CellId(token: token), S2CellId.none)
	}

	private static let maxExpandLevel = 3

	private func expandCell(_ parent: S2CellId, _ cells: inout [S2CellId], _ parentMap: inout [S2CellId: S2CellId]) {
		cells.append(parent)
		if (parent.level == S2CellIdTests.maxExpandLevel) {
			return
		}
		
		var i = 0, j = 0, orientation: Int? = 0
		let face = parent.toFaceIJOrientation(i: &i, j: &j, orientation: &orientation)
		XCTAssertEqual(face, parent.face)

		var pos = 0

		var child = parent.childBegin()
		while child != parent.childEnd() {
			// Do some basic checks on the children
			XCTAssertEqual(child.level, parent.level + 1)
			XCTAssert(!child.isLeaf)
			var childOrientation: Int? = 0
			XCTAssertEqual(child.toFaceIJOrientation(i: &i, j: &j, orientation: &childOrientation), face)
			XCTAssertEqual(childOrientation, (orientation ?? 0) ^ S2.posToOrientation(position: pos))
			
			parentMap[child] = parent
			expandCell(child, &cells, &parentMap)
			pos += 1
			child = child.next()
		}
	}

	func testContainment() {
//		logger.info("TestContainment");
		var parentMap: [S2CellId: S2CellId] = [:]
		var cells: [S2CellId] = []
		// TODO: 6 faces
		for face in 0 ..< 1 {
			expandCell(S2CellId(face: face, pos: 0, level: 0), &cells, &parentMap)
		}
		for i in 0 ..< cells.count {
			for j in 0 ..< cells.count {
				var contained = true

				var id = cells[j]
				while id != cells[i] {
					if !parentMap.keys.contains(id) {
						contained = false
						break
					}
					guard let _id = parentMap[id] else { XCTAssert(false); break }
					id = _id
				}
				XCTAssertEqual(cells[i].contains(other: cells[j]), contained)
				XCTAssertEqual(cells[j] >= cells[i].rangeMin && cells[j] <= cells[i].rangeMax, contained)
				XCTAssertEqual(cells[i].intersects(with: cells[j]), cells[i].contains(other: cells[j]) || cells[j].contains(other: cells[i]))
			}
		}
	}

	private static let maxWalkLevel = 8

	func testContinuity() {
//		logger.info("TestContinuity");
		// Make sure that sequentially increasing cell ids form a continuous
		// path over the surface of the sphere, i.e. there are no
		// discontinuous jumps from one region to another.

		let maxDist = S2Projections.maxEdge.getValue(level: S2CellIdTests.maxWalkLevel)
		let end = S2CellId.end(level: S2CellIdTests.maxWalkLevel)
		var id = S2CellId.begin(level: S2CellIdTests.maxWalkLevel)
		while id != end {
			XCTAssert(id.rawPoint.angle(to: id.nextWrap().rawPoint) <= maxDist)
			
			// Check that the ToPointRaw() returns the center of each cell in (s,t) coordinates.
			let p = id.rawPoint
			let face = S2Projections.xyzToFace(point: p)
			let uv = S2Projections.validFaceXyzToUv(face: face, point: p)
			XCTAssertEqualWithAccuracy(remainder(S2Projections.uvToST(u: uv.x), 1.0 / Double(1 << S2CellIdTests.maxWalkLevel)), 0, accuracy: 1e-9)
			XCTAssertEqualWithAccuracy(remainder(S2Projections.uvToST(u: uv.y), 1.0 / Double(1 << S2CellIdTests.maxWalkLevel)), 0, accuracy: 1e-9)
			id = id.next()
		}
	}
	
	func testCoverage() {
//		logger.info("TestCoverage");
		// Make sure that random points on the sphere can be represented to the
		// expected level of accuracy, which in the worst case is sqrt(2/3) times
		// the maximum arc length between the points on the sphere associated with
		// adjacent values of "i" or "j". (It is sqrt(2/3) rather than 1/2 because
		// the cells at the corners of each face are stretched -- they have 60 and
		// 120 degree angles.)
		
		let maxDist = 0.5 * S2Projections.maxDiag.getValue(level: S2CellId.maxLevel)
		for _ in 0 ..< 1_000_000 {
			// randomPoint();
			let p = S2Point(x: .random(), y: .random(), z: .random())
			let q = S2CellId(point: p).rawPoint
			
			XCTAssert(p.angle(to: q) <= maxDist)
		}
	}
	
	func testAllNeighbors(_ id: S2CellId, _ level: Int) {
		XCTAssert(level >= id.level && level < S2CellId.maxLevel)
		
		// We compute GetAllNeighbors, and then add in all the children of "id"
		// at the given level. We then compare this against the result of finding
		// all the vertex neighbors of all the vertices of children of "id" at the
		// given level. These should give the same result.
		var all: [S2CellId] = id.getAllNeighbors(level: level)
		var expected:  [S2CellId] = []
		let end = id.childEnd(level: level + 1)
		var c = id.childBegin(level: level + 1)
		while c != end {
			all.append(c.parent)
			expected += c.getVertexNeighbors(level: level)
			c = c.next()
		}
		// Sort the results and eliminate duplicates.
		all.sort()
		expected.sort()
		XCTAssertEqual(Set(all), Set(expected))
	}
	
	func testNeighbors() {
//		logger.info("TestNeighbors");

		// Check the edge neighbors of face 1.
		let outFaces = [5, 3, 2, 0]
		let faceNbrs = S2CellId(face: 1, pos: 0, level: 0).getEdgeNeighbors()
		for i in 0 ..< 4 {
			XCTAssert(faceNbrs[i].isFace)
			XCTAssertEqual(faceNbrs[i].face, outFaces[i])
		}
		
		// Check the vertex neighbors of the center of face 2 at level 5.
		var nbrs = S2CellId(point: S2Point(x: 0, y: 0, z: 1)).getVertexNeighbors(level: 5)
		nbrs.sort()
		for i in 0 ..< 4 {
			XCTAssertEqual(nbrs[i], S2CellId(face: 2, i: (1 << 29) - (i < 2 ? 1 : 0), j: (1 << 29) - ((i == 0 || i == 3) ? 1 : 0)).parent(level: 5))
		}
		nbrs.removeAll()

		// Check the vertex neighbors of the corner of faces 0, 4, and 5.
		let id = S2CellId(face: 0, pos: 0, level: S2CellId.maxLevel)
		nbrs = id.getVertexNeighbors(level: 0)
		nbrs.sort()
		XCTAssertEqual(nbrs.count, 3)
		XCTAssertEqual(nbrs[0], S2CellId(face: 0, pos: 0, level: 0))
		XCTAssertEqual(nbrs[1], S2CellId(face: 4, pos: 0, level: 0))
		XCTAssertEqual(nbrs[2], S2CellId(face: 5, pos: 0, level: 0))
		
		// Check that GetAllNeighbors produces results that are consistent
		// with GetVertexNeighbors for a bunch of random cells.
		for _ in 0 ..< 1000 {
			var id1 = S2CellId.random
			if id1.isLeaf {
				id1 = id1.parent
			}

			// TestAllNeighbors computes approximately 2**(2*(diff+1)) cell id1s,
			// so it's not reasonable to use large values of "diff".
			let maxDiff = min(6, S2CellId.maxLevel - id1.level - 1)
			let level = id1.level + Int.random(max: maxDiff)
			testAllNeighbors(id1, level)
		}
	}

}

extension S2CellIdTests {
	static var allTests: [(String, (S2CellIdTests) -> () throws -> Void)] {
		return [
			("testBasic", testBasic),
			("testInverses", testInverses),
			("testToToken", testToToken),
			("testTokens", testTokens),
			("testContainment", testContainment),
			("testContinuity", testContinuity),
			("testCoverage", testCoverage),
			("testNeighbors", testNeighbors),
		]
	}
}
