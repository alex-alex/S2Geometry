//
//  S2Loop.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/1/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

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
public struct S2Loop: S2Region {

	/// Max angle that intersections can be off by and yet still be considered colinear.
	public static let maxIntersectionError = 1e-15
	
	public let vertices: [S2Point]
	
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
//		initOrigin()
//		initBound()
//		initFirstLogicalVertex()
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
//		initFirstLogicalVertex()
	}
	
	/// Return true if this loop represents a hole in its containing polygon.
	public var isHole: Bool {
		return (depth & 1) != 0
	}
	
	/// The sign of a loop is -1 if the loop represents a hole in its containing polygon, and +1 otherwise.
	public var sign: Int {
		return isHole ? -1 : 1
	}
	
//	public var numVertices: Int {
//		return vertices.count
//	}
	
	/**
		For convenience, we make two entire copies of the vertex list available:
		vertex(n..2*n-1) is mapped to vertex(0..n-1), where n == numVertices().
	*/
	public func vertex(_ i: Int) -> S2Point {
		return vertices[i >= vertices.count ? i - vertices.count : i]
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
	
//	private mutating func initOrigin() {
//		// The bounding box does not need to be correct before calling this
//		// function, but it must at least contain vertex(1) since we need to
//		// do a Contains() test on this point below.
//		precondition(bound.contains(point: vertex(1)))
//		
//		// To ensure that every point is contained in exactly one face of a
//		// subdivision of the sphere, all containment tests are done by counting the
//		// edge crossings starting at a fixed point on the sphere (S2::Origin()).
//		// We need to know whether this point is inside or outside of the loop.
//		// We do this by first guessing that it is outside, and then seeing whether
//		// we get the correct containment result for vertex 1. If the result is
//		// incorrect, the origin must be inside the loop.
//		//
//		// A loop with consecutive vertices A,B,C contains vertex B if and only if
//		// the fixed vector R = S2::Ortho(B) is on the left side of the wedge ABC.
//		// The test below is written so that B is inside if C=R but not if A=R.
//		
//		originInside = false // Initialize before calling Contains().
//		let v1Inside = S2.orderedCCW(S2.ortho(vertex(1)), vertex(0), vertex(2), vertex(1))
//		if (v1Inside != contains(vertex(1))) {
//			originInside = true;
//		}
//	}
	
}
