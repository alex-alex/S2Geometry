//
//  S2Cell.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/1/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

/**
	An S2Cell is an S2Region object that represents a cell. Unlike S2CellIds, it
	supports efficient containment and intersection tests. However, it is also a
	more expensive representation.
*/
public struct S2Cell: S2Region, Equatable {
	
	private static let maxCellSize = 1 << S2CellId.maxLevel
	
	public let cellId: S2CellId
	public let face: UInt8
	public let level: UInt8
	public let orientation: UInt8
	public let uv: [[Double]]
	
	internal init(cellId: S2CellId = S2CellId(), face: UInt8 = 0, level: UInt8 = 0, orientation: UInt8 = 0, uv: [[Double]] = [[0, 0], [0, 0]]) {
		self.cellId = cellId
		self.face = face
		self.level = level
		self.orientation = orientation
		self.uv = uv
	}
	
	/// An S2Cell always corresponds to a particular S2CellId. The other constructors are just convenience methods.
	public init(id: S2CellId) {
		cellId = id
		
		var i = 0
		var j = 0
		var mOrientation: Int? = 0
		
		face = UInt8(id.toFaceIJOrientation(i: &i, j: &j, orientation: &mOrientation))
		orientation = UInt8(mOrientation!)
		level = UInt8(id.level)
		
		let cellSize = 1 << (S2CellId.maxLevel - Int(level))
		var _uv: [[Double]] = [[0, 0], [0, 0]]
		for (d, ij) in [i, j].enumerated() {
			// Compute the cell bounds in scaled (i,j) coordinates.
			let sijLo = (ij & -cellSize) * 2 - S2Cell.maxCellSize
			let sijHi = sijLo + cellSize * 2
			_uv[d][0] = S2Projections.stToUV(s: (1.0 / Double(S2Cell.maxCellSize)) * Double(sijLo))
			_uv[d][1] = S2Projections.stToUV(s: (1.0 / Double(S2Cell.maxCellSize)) * Double(sijHi))
		}
		uv = _uv
	}
	
	// This is a static method in order to provide named parameters.
	public init(face: Int, pos: UInt8, level: Int) {
		self.init(id: S2CellId(face: face, pos: Int64(pos), level: level))
	}
	
	// Convenience methods.
	public init(point: S2Point) {
		self.init(id: S2CellId(point: point))
	}
	
	public init(latlng: S2LatLng) {
		self.init(id: S2CellId(latlng: latlng))
	}
	
	public var isLeaf: Bool {
		return Int(level) == S2CellId.maxLevel
	}
	
	public func getVertex(_ k: Int) -> S2Point {
		return S2Point.normalize(point: getRawVertex(k))
	}
	
	/**
		Return the k-th vertex of the cell (k = 0,1,2,3). Vertices are returned in
		CCW order. The points returned by GetVertexRaw are not necessarily unit length.
	*/
	public func getRawVertex(_ k: Int) -> S2Point {
		// Vertices are returned in the order SW, SE, NE, NW.
		return S2Projections.faceUvToXyz(face: Int(face), u: uv[0][(k >> 1) ^ (k & 1)], v: uv[1][k >> 1])
	}
		
	public func getEdge(_ k: Int) -> S2Point {
		return S2Point.normalize(point: getRawEdge(k))
	}
	
	public func getRawEdge(_ k: Int) -> S2Point {
		switch (k) {
		case 0:
			return S2Projections.getVNorm(face: Int(face), v: uv[1][0])		// South
		case 1:
			return S2Projections.getUNorm(face: Int(face), u: uv[0][1])		// East
		case 2:
			return -S2Projections.getVNorm(face: Int(face), v: uv[1][1])	// North
		default:
			return -S2Projections.getUNorm(face: Int(face), u: uv[0][0])	// West
		}
	}
	
	/**
		Return the inward-facing normal of the great circle passing through the
		edge from vertex k to vertex k+1 (mod 4). The normals returned by
		GetEdgeRaw are not necessarily unit length.
	
		If this is not a leaf cell, set children[0..3] to the four children of
		this cell (in traversal order) and return true. Otherwise returns false.
		This method is equivalent to the following:
	
		for (pos=0, id=child_begin(); id != child_end(); id = id.next(), ++pos)
		children[i] = S2Cell(id);
	
		except that it is more than two times faster.
	*/
	public func subdivide() throws -> [S2Cell] {
		// This function is equivalent to just iterating over the child cell ids
		// and calling the S2Cell constructor, but it is about 2.5 times faster.
		
		guard !cellId.isLeaf else { return [] }
		
		// Compute the cell midpoint in uv-space.
		let uvMid = centerUV
		
		// Create four children with the appropriate bounds.
		var children: [S2Cell] = [S2Cell(), S2Cell(), S2Cell(), S2Cell()]
		var id = cellId.childBegin()
		for pos in 0 ..< 4 {
			
			var _uv: [[Double]] = [[0, 0], [0, 0]]
			let ij = try S2.posToIJ(orientation: Int(orientation), position: pos)
			
			for d in 0 ..< 2 {
				// The dimension 0 index (i/u) is in bit 1 of ij.
				let m = 1 - ((ij >> (1 - d)) & 1)
				_uv[d][m] = uvMid.get(index: d)
				_uv[d][1 - m] = uv[d][1 - m]
			}
			let child = try S2Cell(cellId: id, face: face, level: level + 1, orientation: orientation ^ UInt8(S2.posToOrientation(position: pos)), uv: _uv)
			children.append(child)
			
			id = id.next()
		}
		return children
	}
	
	/**
		Return the direction vector corresponding to the center in (s,t)-space of
		the given cell. This is the point at which the cell is divided into four
		subcells; it is not necessarily the centroid of the cell in (u,v)-space or
		(x,y,z)-space. The point returned by GetCenterRaw is not necessarily unit length.
	*/
	public var center: S2Point {
		return S2Point.normalize(point: rawCenter)
	}
	
	public var rawCenter: S2Point {
		return cellId.rawPoint
	}
	
	/**
		Return the center of the cell in (u,v) coordinates (see `S2Projections`).
		Note that the center of the cell is defined as the point
		at which it is recursively subdivided into four children; in general, it is
		not at the midpoint of the (u,v) rectangle covered by the cell
	*/
	public var centerUV: R2Vector {
		var i = 0
		var j = 0
		var orientation: Int? = nil
		_ = cellId.toFaceIJOrientation(i: &i, j: &j, orientation: &orientation)
		let cellSize = 1 << (S2CellId.maxLevel - Int(level))
		
		// TODO(dbeaumont): Figure out a better naming of the variables here (and elsewhere).
		let si = (i & -cellSize) * 2 + cellSize - S2Cell.maxCellSize
		let x = S2Projections.stToUV(s: (1.0 / Double(S2Cell.maxCellSize)) * Double(si))
		
		let sj = (j & -cellSize) * 2 + cellSize - S2Cell.maxCellSize
		let y = S2Projections.stToUV(s: (1.0 / Double(S2Cell.maxCellSize)) * Double(sj))
		
		return R2Vector(x: x, y: y)
	}
	
	public func contains(point p: S2Point) -> Bool {
		// We can't just call XYZtoFaceUV, because for points that lie on the
		// boundary between two faces (i.e. u or v is +1/-1) we need to return
		// true for both adjacent cells.
		guard let uvPoint = S2Projections.faceXyzToUv(face: Int(face), point: p) else { return false }
		return uvPoint.x >= uv[0][0] && uvPoint.x <= uv[0][1] && uvPoint.y >= uv[1][0] && uvPoint.y <= uv[1][1]
	}
	
	////////////////////////////////////////////////////////////////////////
	// MARK: S2Region
	////////////////////////////////////////////////////////////////////////
	
	public var capBound: S2Cap {
		return S2Cap()
	}
	
	// We grow the bounds slightly to make sure that the bounding rectangle
	// also contains the normalized versions of the vertices. Note that the
	// maximum result magnitude is Pi, with a floating-point exponent of 1.
	// Therefore adding or subtracting 2**-51 will always change the result.
	private static let maxError = 1.0 / Double(1 << 51)
	
	// The 4 cells around the equator extend to +/-45 degrees latitude at the
	// midpoints of their top and bottom edges. The two cells covering the
	// poles extend down to +/-35.26 degrees at their vertices.
	// adding kMaxError (as opposed to the C version) because of asin and atan2
	// roundoff errors
	private static let poleMinLat = asin(sqrt(1.0 / 3.0)) - maxError // 35.26 degrees
	
	public var rectBound: S2LatLngRect {
		if level > 0 {
			// Except for cells at level 0, the latitude and longitude extremes are
			// attained at the vertices. Furthermore, the latitude range is
			// determined by one pair of diagonally opposite vertices and the
			// longitude range is determined by the other pair.
			//
			// We first determine which corner (i,j) of the cell has the largest
			// absolute latitude. To maximize latitude, we want to find the point in
			// the cell that has the largest absolute z-coordinate and the smallest
			// absolute x- and y-coordinates. To do this we look at each coordinate
			// (u and v), and determine whether we want to minimize or maximize that
			// coordinate based on the axis direction and the cell's (u,v) quadrant.
			let u = uv[0][0] + uv[0][1]
			let v = uv[1][0] + uv[1][1]
			let i = S2Projections.getUAxis(face: Int(face)).z == 0 ? (u < 0 ? 1 : 0) : (u > 0 ? 1 : 0)
			let j = S2Projections.getVAxis(face: Int(face)).z == 0 ? (v < 0 ? 1 : 0) : (v > 0 ? 1 : 0)
			
			var lat = R1Interval.fromPointPair(p1: getLatitude(i: i, j: j), p2: getLatitude(i: 1 - i, j: 1 - j))
			lat = lat.expanded(radius: S2Cell.maxError).intersection(with: S2LatLngRect.fullLat)
			if (lat.lo == -M_PI_2 || lat.hi == M_PI_2) {
				return S2LatLngRect(lat: lat, lng: S1Interval.full)
			}
			let lng = S1Interval.fromPointPair(p1: getLongitude(i: i, j: 1 - j), p2: getLongitude(i: 1 - i, j: j))
			return S2LatLngRect(lat: lat, lng: lng.expanded(radius: S2Cell.maxError))
		}
		
		// The face centers are the +X, +Y, +Z, -X, -Y, -Z axes in that order.
		// assert (S2Projections.getNorm(face).get(face % 3) == ((face < 3) ? 1 : -1))
		switch face {
		case 0:
			return S2LatLngRect(lat: R1Interval(lo: -M_PI_4, hi: M_PI_4), lng: S1Interval(lo: -M_PI_4, hi: M_PI_4))
		case 1:
			return S2LatLngRect(lat: R1Interval(lo: -M_PI_4, hi: M_PI_4), lng: S1Interval(lo: M_PI_4, hi: 3 * M_PI_4))
		case 2:
			return S2LatLngRect(lat: R1Interval(lo: S2Cell.poleMinLat, hi: M_PI_2), lng: S1Interval(lo: -M_PI, hi: M_PI))
		case 3:
			return S2LatLngRect(lat: R1Interval(lo: -M_PI_4, hi: M_PI_4), lng: S1Interval(lo: 3 * M_PI_4, hi: -3 * M_PI_4))
		case 4:
			return S2LatLngRect(lat: R1Interval(lo: -M_PI_4, hi: M_PI_4), lng: S1Interval(lo: -3 * M_PI_4, hi: -M_PI_4))
		default:
			return S2LatLngRect(lat: R1Interval(lo: -M_PI_2, hi: -S2Cell.poleMinLat), lng: S1Interval(lo: -M_PI, hi: M_PI))
		}
	}
	
	public func contains(cell: S2Cell) -> Bool {
		return false
	}
	
	public func mayIntersect(cell: S2Cell) -> Bool {
		return false
	}
	
	// Return the latitude or longitude of the cell vertex given by (i,j),
	// where "i" and "j" are either 0 or 1.
	
	private func getLatitude(i: Int, j: Int) -> Double {
		let p = S2Projections.faceUvToXyz(face: Int(face), u: uv[0][i], v: uv[1][j])
		return atan2(p.z, sqrt(p.x * p.x + p.y * p.y))
	}
	
	private func getLongitude(i: Int, j: Int) -> Double {
		let p = S2Projections.faceUvToXyz(face: Int(face), u: uv[0][i], v: uv[1][j])
		return atan2(p.y, p.x)
	}
	
}

public func ==(lhs: S2Cell, rhs: S2Cell) -> Bool {
	return lhs.face == rhs.face && lhs.level == rhs.level && lhs.orientation == rhs.orientation && lhs.cellId == rhs.cellId
}
