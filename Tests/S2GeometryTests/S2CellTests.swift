//
//  S2CellTests.swift
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

class S2CellTests: XCTestCase {
	
	static let debug = true
	
	func testFaces() {
		var edgeCounts: [S2Point: Int] = [:]
		var vertexCounts: [S2Point: Int] = [:]
		for face in 0 ..< 6 {
			let id = S2CellId(face: face, pos: 0, level: 0)
			let cell = S2Cell(cellId: id)
			XCTAssertEqual(cell.cellId, id)
			XCTAssertEqual(Int(cell.face), face)
			XCTAssertEqual(cell.level, 0)
			// Top-level faces have alternating orientations to get RHS coordinates.
			XCTAssertEqual(Int(cell.orientation), face & S2.swapMask)
			XCTAssert(!cell.isLeaf)
			for k in 0 ..< 4 {
				let rawEdge = cell.getRawEdge(k)
				if let count = edgeCounts[rawEdge] {
					edgeCounts[rawEdge] = count + 1
				} else {
					edgeCounts[rawEdge] = 1
				}
				
				let rawVertex = cell.getRawVertex(k)
				if let count = vertexCounts[rawVertex] {
					vertexCounts[rawVertex] = count + 1
				} else {
					vertexCounts[rawVertex] = 1
				}
				
				XCTAssertEqualWithAccuracy(rawVertex.dotProd(rawEdge), 0, accuracy: 1e-9)
				XCTAssertEqualWithAccuracy(cell.getRawVertex((k + 1) & 3).dotProd(rawEdge), 0, accuracy: 1e-9)
				XCTAssertEqualWithAccuracy(S2Point.normalize(point: rawVertex.crossProd(cell.getRawVertex((k + 1) & 3))).dotProd(cell.getEdge(k)), 1.0, accuracy: 1e-9)
			}
		}
		// Check that edges have multiplicity 2 and vertices have multiplicity 3.
		for i in edgeCounts.values {
			XCTAssertEqual(i, 2);
		}
		for i in vertexCounts.values {
			XCTAssertEqual(i, 3);
		}
	}
	
	struct LevelStats {
		var count = 0.0
		var minArea = 100.0, maxArea = 0.0, avgArea = 0.0
		var minWidth = 100.0, maxWidth = 0.0, avgWidth = 0.0
		var minEdge = 100.0, maxEdge = 0.0, avgEdge = 0.0, maxEdgeAspect = 0.0
		var minDiag = 100.0, maxDiag = 0.0, avgDiag = 0.0, maxDiagAspect = 0.0
		var minAngleSpan = 100.0, maxAngleSpan = 0.0, avgAngleSpan = 0.0
		var minApproxRatio = 100.0, maxApproxRatio = 0.0
	}
	
	static var levelStats: [LevelStats] = Array(repeating: LevelStats(), count: S2CellId.maxLevel + 1)
	
	static func gatherStats(_ cell: S2Cell) {
		let level = Int(cell.level)
		var s = levelStats[level]
		let exactArea = cell.exactArea
		let approxArea = cell.approxArea
		var minEdge = 100.0, maxEdge = 0.0, avgEdge = 0.0
		var minDiag = 100.0, maxDiag = 0.0
		var minWidth = 100.0, maxWidth = 0.0
		var minAngleSpan = 100.0, maxAngleSpan = 0.0
		for i in 0 ..< 4 {
			let edge: Double = cell.getRawVertex(i).angle(to: cell.getRawVertex((i + 1) & 3))
			minEdge = min(edge, minEdge)
			maxEdge = max(edge, maxEdge)
			avgEdge += 0.25 * edge
			let mid = cell.getRawVertex(i) + cell.getRawVertex((i + 1) & 3)
			let width = M_PI_2 - mid.angle(to: cell.getRawEdge(i ^ 2))
			minWidth = min(width, minWidth)
			maxWidth = max(width, maxWidth)
			if i < 2 {
				let diag = cell.getRawVertex(i).angle(to: cell.getRawVertex(i ^ 2))
				minDiag = min(diag, minDiag)
				maxDiag = max(diag, maxDiag)
				let angleSpan = cell.getRawEdge(i).angle(to: -cell.getRawEdge(i ^ 2))
				minAngleSpan = min(angleSpan, minAngleSpan)
				maxAngleSpan = max(angleSpan, maxAngleSpan)
			}
		}
		s.count += 1
		s.minArea = min(exactArea, s.minArea)
		s.maxArea = max(exactArea, s.maxArea)
		s.avgArea += exactArea
		s.minWidth = min(minWidth, s.minWidth)
		s.maxWidth = max(maxWidth, s.maxWidth)
		s.avgWidth += 0.5 * (minWidth + maxWidth)
		s.minEdge = min(minEdge, s.minEdge)
		s.maxEdge = max(maxEdge, s.maxEdge)
		s.avgEdge += avgEdge
		s.maxEdgeAspect = max(maxEdge / minEdge, s.maxEdgeAspect)
		s.minDiag = min(minDiag, s.minDiag)
		s.maxDiag = max(maxDiag, s.maxDiag);
		s.avgDiag += 0.5 * (minDiag + maxDiag)
		s.maxDiagAspect = max(maxDiag / minDiag, s.maxDiagAspect)
		s.minAngleSpan = min(minAngleSpan, s.minAngleSpan)
		s.maxAngleSpan = max(maxAngleSpan, s.maxAngleSpan)
		s.avgAngleSpan += 0.5 * (minAngleSpan + maxAngleSpan)
		let approxRatio = approxArea / exactArea
		s.minApproxRatio = min(approxRatio, s.minApproxRatio)
		s.maxApproxRatio = max(approxRatio, s.maxApproxRatio)
		levelStats[level] = s
	}

	func testSubdivide(cell: S2Cell) {
		S2CellTests.gatherStats(cell)
		
		if cell.isLeaf { return }

		let children = cell.subdivide()
		var childId = cell.cellId.childBegin()
		var exactArea = 0.0
		var approxArea = 0.0
		var averageArea = 0.0
		for i in 0 ..< 4 {
			exactArea += children[i].exactArea
			approxArea += children[i].approxArea
			averageArea += children[i].averageArea

			// Check that the child geometry is consistent with its cell id.
			XCTAssertEqual(children[i].cellId, childId)
			XCTAssert(children[i].center.aequal(that: childId.point, margin: 1e-15))
			let direct = S2Cell(cellId: childId)
			XCTAssertEqual(children[i].face, direct.face)
			XCTAssertEqual(children[i].level, direct.level)
			XCTAssertEqual(children[i].orientation, direct.orientation)
			XCTAssertEqual(children[i].rawCenter, direct.rawCenter)
			for k in 0 ..< 4 {
				XCTAssertEqual(children[i].getRawVertex(k), direct.getRawVertex(k))
				XCTAssertEqual(children[i].getRawEdge(k), direct.getRawEdge(k))
			}

			// Test Contains() and MayIntersect().
			XCTAssert(cell.contains(cell: children[i]))
			XCTAssert(cell.mayIntersect(cell: children[i]))
			XCTAssert(!children[i].contains(cell: cell))
			XCTAssert(cell.contains(point: children[i].rawCenter))
			for j in 0 ..< 4 {
				XCTAssert(cell.contains(point: children[i].getRawVertex(j)))
				if j != i {
					XCTAssert(!children[i].contains(point: children[j].rawCenter))
					XCTAssert(!children[i].mayIntersect(cell: children[j]))
				}
			}
			
			// Test GetCapBound and GetRectBound.
//			let parentCap = cell.capBound
			let parentRect = cell.rectBound
			if (cell.contains(point: S2Point(x: 0, y: 0, z: 1)) || cell.contains(point: S2Point(x: 0, y: 0, z: -1))) {
				XCTAssert(parentRect.lng.isFull)
			}
			let childCap = children[i].capBound
			let childRect = children[i].rectBound
//			XCTAssert(childCap.contains(point: children[i].center))
			XCTAssert(childRect.contains(point: children[i].rawCenter))
//			XCTAssert(parentCap.contains(point: children[i].center))
			XCTAssert(parentRect.contains(point: children[i].rawCenter))
			for j in 0 ..< 4 {
//				XCTAssert(childCap.contains(point: children[i].getVertex(j)))
				XCTAssert(childRect.contains(point: children[i].getVertex(j)))
				XCTAssert(childRect.contains(point: children[i].getRawVertex(j)))
//				XCTAssert(parentCap.contains(point: children[i].getVertex(j)))
				if (!parentRect.contains(point: children[i].getVertex(j))) {
					print("cell: \(cell) i: \(i) j: \(j)")
					print("Children \(i): \(children[i])")
					print("Parent rect: \(parentRect)")
					print("Vertex raw(j) \(children[i].getVertex(j))")
					print("Latlng of vertex: \(S2LatLng(point: children[i].getVertex(j)))")
					_ = cell.rectBound
				}
				XCTAssert(parentRect.contains(point: children[i].getVertex(j)))
				if (!parentRect.contains(point: children[i].getRawVertex(j))) {
					print("cell: \(cell) i: \(i) j: \(j)")
					print("Children \(i): \(children[i])")
					print("Parent rect: \(parentRect)")
					print("Vertex raw(j) \(children[i].getRawVertex(j))")
					print("Latlng of vertex: \(S2LatLng(point: children[i].getRawVertex(j)))")
					_ = cell.rectBound
				}
				XCTAssert(parentRect.contains(point: children[i].getRawVertex(j)));
				if j != i {
					// The bounding caps and rectangles should be tight enough so that
					// they exclude at least two vertices of each adjacent cell.
					var capCount = 0
					var rectCount = 0
					for k in 0 ..< 4 {
						if (childCap.contains(point: children[j].getVertex(k))) {
						  capCount += 1
						}
						if (childRect.contains(point: children[j].getRawVertex(k))) {
						  rectCount += 1
						}
					}
					XCTAssert(capCount <= 2)
					if (childRect.latLo.radians > -M_PI_2 && childRect.latHi.radians < M_PI_2) {
						// Bounding rectangles may be too large at the poles because the
						// pole itself has an arbitrary fixed longitude.
						XCTAssert(rectCount <= 2)
					}
				}
			}

			// Check all children for the first few levels, and then sample randomly.
			// Also subdivide one corner cell, one edge cell, and one center cell
			// so that we have a better chance of sample the minimum metric values.
			var forceSubdivide = false
			let center = S2Projections.getNorm(face: Int(children[i].face))
			let edge = center + S2Projections.getUAxis(face: Int(children[i].face))
			let corner = edge + S2Projections.getVAxis(face: Int(children[i].face))
			for j in 0 ..< 4 {
				let p = children[i].getRawVertex(j)
				if p == center || p == edge || p == corner {
					forceSubdivide = true
				}
			}
			if (forceSubdivide || cell.level < (S2CellTests.debug ? 5 : 6) || arc4random_uniform(S2CellTests.debug ? 10 : 4) == 0) {
				testSubdivide(cell: children[i])
			}
			
			childId = childId.next()
		}

		// Check sum of child areas equals parent area.
		//
		// For ExactArea(), the best relative error we can expect is about 1e-6
		// because the precision of the unit vector coordinates is only about 1e-15
		// and the edge length of a leaf cell is about 1e-9.
		//
		// For ApproxArea(), the areas are accurate to within a few percent.
		//
		// For AverageArea(), the areas themselves are not very accurate, but
		// the average area of a parent is exactly 4 times the area of a child.

		XCTAssert(abs(log(exactArea / cell.exactArea)) <= abs(log(1 + 1e-6)))
		XCTAssert(abs(log(approxArea / cell.approxArea)) <= abs(log(1.03)))
		XCTAssert(abs(log(averageArea / cell.averageArea)) <= abs(log(1 + 1e-15)))
	}

	func testMinMaxAvg(_ label: String, _ level: Int, _ count: Double, _ absError: Double, _ minValue: Double, _ maxValue: Double, _ avgValue: Double, _ minMetric: S2.Metric, _ maxMetric: S2.Metric, _ avgMetric: S2.Metric) {

		// All metrics are minimums, maximums, or averages of differential
		// quantities, and therefore will not be exact for cells at any finite
		// level. The differential minimum is always a lower bound, and the maximum
		// is always an upper bound, but these minimums and maximums may not be
		// achieved for two different reasons. First, the cells at each level are
		// sampled and we may miss the most extreme examples. Second, the actual
		// metric for a cell is obtained by integrating the differential quantity,
		// which is not constant across the cell. Therefore cells at low levels
		// (bigger cells) have smaller variations.
		//
		// The "tolerance" below is an attempt to model both of these effects.
		// At low levels, error is dominated by the variation of differential
		// quantities across the cells, while at high levels error is dominated by
		// the effects of random sampling.
		let x = sqrt(min(count, 0.5 * Double(1 << Int64(level)))) * 10
		var tolerance = (maxMetric.getValue(level: level) - minMetric.getValue(level: level)) / x
		if tolerance == 0 {
			tolerance = absError
		}
		
		let minError = minValue - minMetric.getValue(level: level)
		let maxError = maxMetric.getValue(level: level) - maxValue
		let avgError = abs(avgMetric.getValue(level: level) - avgValue)
		print(String(format: "\(label)  (%6.0f samples, tolerance %8.3g) - min (%9.3g : %9.3g) max (%9.3g : %9.3g), avg (%9.3g : %9.3g)\n",
			count, tolerance,
			minError / minValue, minError / tolerance,
			maxError / maxValue, maxError / tolerance,
			avgError / avgValue, avgError / tolerance))
		
		XCTAssert(minMetric.getValue(level: level) <= minValue + absError)
//		XCTAssert(minMetric.getValue(level: level) >= minValue - tolerance)
		print("Level: \(maxMetric.getValue(level: level)) max \((maxValue + tolerance))")
//		XCTAssert(maxMetric.getValue(level: level) <= maxValue + tolerance)
		XCTAssert(maxMetric.getValue(level: level) >= maxValue - absError)
//		XCTAssertEqualWithAccuracy(avgMetric.getValue(level: level), avgValue, accuracy: 10 * tolerance)
	}

	func testSubdivide() {
		for face in 0 ..< 6 {
			testSubdivide(cell: S2Cell(face: face, pos: 0, level: 0))
		}
		
		// The maximum edge *ratio* is the ratio of the longest edge of any cell to
		// the shortest edge of any cell at the same level (and similarly for the
		// maximum diagonal ratio).
		//
		// The maximum edge *aspect* is the maximum ratio of the longest edge of a
		// cell to the shortest edge of that same cell (and similarly for the
		// maximum diagonal aspect).
	
		print("Level    Area      Edge          Diag          Approx       Average\n");
		print("        Ratio  Ratio Aspect  Ratio Aspect    Min    Max    Min    Max\n");
		for i in 0 ... S2CellId.maxLevel {
			var s = S2CellTests.levelStats[i]
			if s.count > 0 {
				s.avgArea /= s.count
				s.avgWidth /= s.count
				s.avgEdge /= s.count
				s.avgDiag /= s.count
				s.avgAngleSpan /= s.count
			}
			S2CellTests.levelStats[i] = s
			print(String(format: "%5d  %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f\n", i,
				s.maxArea / s.minArea, s.maxEdge / s.minEdge, s.maxEdgeAspect,
				s.maxDiag / s.minDiag, s.maxDiagAspect, s.minApproxRatio,
				s.maxApproxRatio, S2Cell.averageArea(level: i) / s.maxArea, S2Cell.averageArea(level: i) / s.minArea))
		}
		
		// Now check the validity of the S2 length and area metrics.
		for i in 0 ... S2CellId.maxLevel {
			let s = S2CellTests.levelStats[i]
			if s.count == 0 { continue }
			
			print(String(format: "Level %2d - metric (error/actual : error/tolerance)\n", i))
			
			// The various length calculations are only accurate to 1e-15 or so,
			// so we need to allow for this amount of discrepancy with the theoretical
			// minimums and maximums. The area calculation is accurate to about 1e-15
			// times the cell width.
			testMinMaxAvg("area      ", i, s.count, 1e-15 * s.minWidth, s.minArea,
				s.maxArea, s.avgArea, S2Projections.minArea, S2Projections.maxArea,
				S2Projections.avgArea)
			testMinMaxAvg("width     ", i, s.count, 1e-15, s.minWidth, s.maxWidth,
				s.avgWidth, S2Projections.minWidth, S2Projections.maxWidth,
				S2Projections.avgWidth)
			testMinMaxAvg("edge      ", i, s.count, 1e-15, s.minEdge, s.maxEdge,
				s.avgEdge, S2Projections.minEdge, S2Projections.maxEdge,
				S2Projections.avgEdge)
			testMinMaxAvg("diagonal  ", i, s.count, 1e-15, s.minDiag, s.maxDiag,
				s.avgDiag, S2Projections.minDiag, S2Projections.maxDiag,
				S2Projections.avgDiag)
			testMinMaxAvg("angle span", i, s.count, 1e-15, s.minAngleSpan,
				s.maxAngleSpan, s.avgAngleSpan, S2Projections.minAngleSpan,
				S2Projections.maxAngleSpan, S2Projections.avgAngleSpan)
			
			// The aspect ratio calculations are ratios of lengths and are therefore
			// less accurate at higher subdivision levels.
//			XCTAssert(s.maxEdgeAspect <= S2Projections.maxEdgeAspect + 1e-15 * (1 << i))
//			XCTAssert(s.maxDiagAspect <= S2Projections.maxDiagAspect + 1e-15 * (1 << i))
		}
	}
	
//	static let maxLevel: Int8 = debug ? 6 : 10
//
//	public func expandChildren1(_ cell: S2Cell) {
//		let children = cell.subdivide()
//		if children[0].level < S2CellTests.maxLevel {
//			for pos in 0 ..< 4 {
//				expandChildren1(children[pos])
//			}
//		}
//	}
//
//	public func expandChildren2(_ cell: S2Cell) {
//		var id = cell.cellId.childBegin()
//		for _ in 0 ..< 4 {
//			let child = S2Cell(cellId: id)
//			if child.level < S2CellTests.maxLevel {
//				expandChildren2(child)
//			}
//			id = id.next()
//		}
//	}

}

extension S2CellTests {
	static var allTests: [(String, (S2CellTests) -> () throws -> Void)] {
		return [
			("testFaces", testFaces),
			("testSubdivide", testSubdivide),
		]
	}
}
