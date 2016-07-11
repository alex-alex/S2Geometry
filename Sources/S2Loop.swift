//
//  S2Loop.swift
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
	An S2Loop represents a simple spherical polygon. It consists of a single
	chain of vertices where the first vertex is implicitly connected to the last.
	All loops are defined to have a CCW orientation, i.e. the interior of the
	polygon is on the left side of the edges. This implies that a clockwise loop
	enclosing a small area is interpreted to be a CCW loop enclosing a very large area.

	Loops are not allowed to have any duplicate vertices (whether adjacent or
	not), and non-adjacent edges are not allowed to intersect. Loops must have at
	least 3 vertices. Although these restrictions are not enforced in optimized
	code, you may get unexpected results if they are violated.

	Point containment is defined such that if the sphere is subdivided into
	faces (loops), every point is contained by exactly one face. This implies
	that loops do not necessarily contain all (or any) of their vertices An
	S2LatLngRect represents a latitude-longitude rectangle. It is capable of
	representing the empty and full rectangles as well as single points.
*/
public struct S2Loop: S2Region, Comparable {

	/// Max angle that intersections can be off by and yet still be considered colinear.
	public static let maxIntersectionError = 1e-15
	
	public private(set) var vertices: [S2Point]
	
	/**
		Edge index used for performance-critical operations. For example,
		contains() can determine whether a point is inside a loop in nearly
		constant time, whereas without an edge index it is forced to compare the
		query point against every edge in the loop.
	*/
	private var index: S2EdgeIndex? = nil
	
	/// Maps each S2Point to its order in the loop, from 1 to numVertices.
	private var vertexToIndex: [S2Point: Int] = [:]
	
	/// The index (into "vertices") of the vertex that comes first in the total ordering of all vertices in this loop.
	private var firstLogicalVertex: Int = 0
	
	private var bound: S2LatLngRect = .full
	private var originInside: Bool = false
	
	/**
		The depth of a loop is defined as its nesting level within its containing
		polygon. "Outer shell" loops have depth 0, holes within those loops have
		depth 1, shells within those holes have depth 2, etc. This field is only
		used by the S2Polygon implementation.
	*/
	public var depth: Int = 0
	
	/**
		Initialize a loop connecting the given vertices. The last vertex is
		implicitly connected to the first. All points should be unit length. Loops
		must have at least 3 vertices.
	*/
	public init(vertices: [S2Point]) {
		self.vertices = vertices
		
		// if (debugMode) {
		//  assert (isValid(vertices, DEFAULT_MAX_ADJACENT));
		// }
		
		// initOrigin() must be called before InitBound() because the latter
		// function expects Contains() to work properly.
		initOrigin()
//		initBound()
		initFirstLogicalVertex()
	}
	
	/// Initialize a loop corresponding to the given cell.
	public init(cell: S2Cell) {
		self.init(cell: cell, bound: cell.rectBound)
	}
	
	/// Like the constructor above, but assumes that the cell's bounding rectangle has been precomputed.
	public init(cell: S2Cell, bound: S2LatLngRect) {
		self.bound = bound
		self.vertices = [cell.getVertex(0), cell.getVertex(1), cell.getVertex(2), cell.getVertex(3)]
//		initOrigin()
		initFirstLogicalVertex()
	}
	
	/// Return true if this loop represents a hole in its containing polygon.
	public var isHole: Bool {
		return (depth & 1) != 0
	}
	
	/// The sign of a loop is -1 if the loop represents a hole in its containing polygon, and +1 otherwise.
	public var sign: Int {
		return isHole ? -1 : 1
	}
	
	public var numVertices: Int {
		return vertices.count
	}
	
	/**
		For convenience, we make two entire copies of the vertex list available:
		vertex(n..2*n-1) is mapped to vertex(0..n-1), where n == numVertices().
	*/
	public func vertex(_ i: Int) -> S2Point {
		return vertices[i >= vertices.count ? i - vertices.count : i]
	}
	
	/**
	* Calculates firstLogicalVertex, the vertex in this loop that comes first in
	* a total ordering of all vertices (by way of S2Point's compareTo function).
	*/
	private mutating func initFirstLogicalVertex() {
		var first = 0;
		for i in 1 ..< numVertices {
			if vertex(i) < vertex(first) {
				first = i;
			}
		}
		firstLogicalVertex = first;
	}
	
	/// Return true if the loop area is at most 2*Pi.
	public var isNormalized: Bool {
		// We allow a bit of error so that exact hemispheres are considered normalized.
		return true
//		return area <= 2 * M_PI + 1e-14
	}

	/// Invert the loop if necessary so that the area enclosed by the loop is at most 2*Pi.
	public mutating func normalize() {
		if !isNormalized {
			invert()
		}
	}
	
	/// Reverse the order of the loop vertices, effectively complementing the region represented by the loop.
	public mutating func invert() {
		let last = numVertices - 1
		
		for i in (0 ... (last - 1) / 2).reversed() {
//		for (int i = (last - 1) / 2; i >= 0; --i) {
			let t = vertices[i]
			vertices[i] = vertices[last - i];
			vertices[last - i] = t;
		}
//		vertexToIndex = null
//		index = null;
//		originInside ^= true;
		if bound.lat.lo > -M_PI_2 && bound.lat.hi < M_PI_2 {
			// The complement of this loop contains both poles.
			bound = .full
		} else {
			initBound()
		}
		initFirstLogicalVertex()
	}
	
	private mutating func initOrigin() {
		// The bounding box does not need to be correct before calling this
		// function, but it must at least contain vertex(1) since we need to
		// do a Contains() test on this point below.
		precondition(bound.contains(point: vertex(1)))
		
		// To ensure that every point is contained in exactly one face of a
		// subdivision of the sphere, all containment tests are done by counting the
		// edge crossings starting at a fixed point on the sphere (S2::Origin()).
		// We need to know whether this point is inside or outside of the loop.
		// We do this by first guessing that it is outside, and then seeing whether
		// we get the correct containment result for vertex 1. If the result is
		// incorrect, the origin must be inside the loop.
		//
		// A loop with consecutive vertices A,B,C contains vertex B if and only if
		// the fixed vector R = S2::Ortho(B) is on the left side of the wedge ABC.
		// The test below is written so that B is inside if C=R but not if A=R.
		
//		originInside = false // Initialize before calling Contains().
//		let v1Inside = S2.orderedCCW(a: vertex(1).ortho, b: vertex(0), c: vertex(2), o: vertex(1))
//		if v1Inside != contains(point: vertex(1)) {
//			originInside = true
//		}
	}
	
	private mutating func initBound() {
		// The bounding rectangle of a loop is not necessarily the same as the
		// bounding rectangle of its vertices. First, the loop may wrap entirely
		// around the sphere (e.g. a loop that defines two revolutions of a
		// candy-cane stripe). Second, the loop may include one or both poles.
		// Note that a small clockwise loop near the equator contains both poles.
		
//		let bounder = S2EdgeUtil.RectBounder()
//		for i in 0 ... numVertices {
//			bounder.addPoint(vertex(i))
//		}
//		let b = bounder.bound
//		// Note that we need to initialize bound with a temporary value since
//		// contains() does a bounding rectangle check before doing anything else.
//		bound = .full
//		if contains(point: S2Point(x: 0, y: 0, z: 1)) {
//			b = S2LatLngRect(lat: R1Interval(lo: b.lat.lo, hi: M_PI_2), lng: .full)
//		}
//		// If a loop contains the south pole, then either it wraps entirely
//		// around the sphere (full longitude range), or it also contains the
//		// north pole in which case b.lng().isFull() due to the test above.
//		
//		if b.lng.isFull && contains(point: S2Point(x: 0, y: 0, z: -1)) {
//			b = S2LatLngRect(lat: R1Interval(lo: -M_PI_2, hi: b.lat.hi), lng: b.lng)
//		}
//		bound = b
	}
	
	////////////////////////////////////////////////////////////////////////
	// MARK: S2Region
	////////////////////////////////////////////////////////////////////////
	
	public var capBound: S2Cap {
		return bound.capBound
	}
	
	public var rectBound: S2LatLngRect {
		return bound
	}
	
	public func contains(cell: S2Cell) -> Bool {
		return false
	}
	
	public func mayIntersect(cell: S2Cell) -> Bool {
		return false
	}
	
}

public func ==(lhs: S2Loop, rhs: S2Loop) -> Bool {
	return lhs.vertices == rhs.vertices
}

public func <(lhs: S2Loop, rhs: S2Loop) -> Bool {
	if lhs.numVertices != rhs.numVertices {
		return lhs.numVertices < rhs.numVertices
	}
	// Compare the two loops' vertices, starting with each loop's
	// firstLogicalVertex. This allows us to always catch cases where logically
	// identical loops have different vertex orderings (e.g. ABCD and BCDA).
	let maxVertices = lhs.numVertices
	var iThis = lhs.firstLogicalVertex
	var iOther = rhs.firstLogicalVertex
	for _ in 0 ..< maxVertices {
		if lhs.vertex(iThis) != rhs.vertex(iOther) {
			return lhs.vertex(iThis) < rhs.vertex(iOther)
		}
		iThis += 1
		iOther += 1
	}
	return false
}
