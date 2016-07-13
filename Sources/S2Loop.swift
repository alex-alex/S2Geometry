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
	private var vertexToIndex: [S2Point: Int]? = nil
	
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
		vertexToIndex = nil
		index = nil
		originInside = !originInside
		
		if bound.lat.lo > -M_PI_2 && bound.lat.hi < M_PI_2 {
			// The complement of this loop contains both poles.
			bound = .full
		} else {
			initBound()
		}
		initFirstLogicalVertex()
	}
	
	/// The point 'p' does not need to be normalized.
	public func contains(point p: S2Point) -> Bool {
		if !bound.contains(point: p) {
			return false
		}
		
		var inside = originInside
		let origin = S2.origin
//		let crosser = S2EdgeUtil.EdgeCrosser(origin, p, vertices[numVertices - 1])
		
		// The s2edgeindex library is not optimized yet for long edges,
		// so the tradeoff to using it comes with larger loops.
		if numVertices < 2000 {
//			for (int i = 0; i < numVertices; i++) {
//				inside ^= crosser.edgeOrVertexCrossing(vertices[i]);
//			}
		} else {
//			DataEdgeIterator it = getEdgeIterator(numVertices);
//			int previousIndex = -2;
//			for (it.getCandidates(origin, p); it.hasNext(); it.next()) {
//				int ai = it.index();
//				if (previousIndex != ai - 1) {
//					crosser.restartAt(vertices[ai]);
//				}
//				previousIndex = ai;
//				inside ^= crosser.edgeOrVertexCrossing(vertex(ai + 1));
//			}
		}
		
		return inside;
	}
	
	/**
		Returns the shortest distance from a point P to this loop, given as the
		angle formed between P, the origin and the nearest point on the loop to P.
		This angle in radians is equivalent to the arclength along the unit sphere.
	*/
	public func getDistance(to p: S2Point) -> S1Angle {
		let normalized = S2Point.normalize(point: p)
		
		// The furthest point from p on the sphere is its antipode, which is an
		// angle of PI radians. This is an upper bound on the angle.
		var minDistance = S1Angle(radians: M_PI)
		for i in 0 ..< numVertices {
			minDistance = min(minDistance, S2EdgeUtil.getDistance(x: normalized, a: vertex(i), b: vertex(i + 1)))
		}
		return minDistance
	}
	
	/// Return true if this loop is valid.
	public var isValid: Bool {
		if numVertices < 3 {
//			log.info("Degenerate loop");
			return false
		}
		
		// All vertices must be unit length.
		for i in 0 ..< numVertices {
			if !S2.isUnitLength(point: vertex(i)) {
//				log.info("Vertex " + i + " is not unit length");
				return false
			}
		}
		
		// Loops are not allowed to have any duplicate vertices.
		var vmap: Set<S2Point> = []
		for i in 0 ..< numVertices {
			if !vmap.insert(vertex(i)).inserted {
//				log.info("Duplicate vertices: " + previousVertexIndex + " and " + i);
				return false
			}
		}
		
		// Non-adjacent edges are not allowed to intersect.
//		var crosses = false
//		DataEdgeIterator it = getEdgeIterator(numVertices);
//		for (int a1 = 0; a1 < numVertices; a1++) {
//			int a2 = (a1 + 1) % numVertices;
//			EdgeCrosser crosser = new EdgeCrosser(vertex(a1), vertex(a2), vertex(0));
//			int previousIndex = -2;
//			for (it.getCandidates(vertex(a1), vertex(a2)); it.hasNext(); it.next()) {
//				int b1 = it.index();
//				int b2 = (b1 + 1) % numVertices;
//				// If either 'a' index equals either 'b' index, then these two edges
//				// share a vertex. If a1==b1 then it must be the case that a2==b2, e.g.
//				// the two edges are the same. In that case, we skip the test, since we
//				// don't want to test an edge against itself. If a1==b2 or b1==a2 then
//				// we have one edge ending at the start of the other, or in other words,
//				// the edges share a vertex -- and in S2 space, where edges are always
//				// great circle segments on a sphere, edges can only intersect at most
//				// once, so we don't need to do further checks in that case either.
//				if (a1 != b2 && a2 != b1 && a1 != b1) {
//					// WORKAROUND(shakusa, ericv): S2.robustCCW() currently
//					// requires arbitrary-precision arithmetic to be truly robust. That
//					// means it can give the wrong answers in cases where we are trying
//					// to determine edge intersections. The workaround is to ignore
//					// intersections between edge pairs where all four points are
//					// nearly colinear.
//					double abc = S2.angle(vertex(a1), vertex(a2), vertex(b1));
//					boolean abcNearlyLinear = S2.approxEquals(abc, 0D, MAX_INTERSECTION_ERROR) ||
//					S2.approxEquals(abc, S2.M_PI, MAX_INTERSECTION_ERROR);
//					double abd = S2.angle(vertex(a1), vertex(a2), vertex(b2));
//					boolean abdNearlyLinear = S2.approxEquals(abd, 0D, MAX_INTERSECTION_ERROR) ||
//					S2.approxEquals(abd, S2.M_PI, MAX_INTERSECTION_ERROR);
//					if (abcNearlyLinear && abdNearlyLinear) {
//						continue;
//					}
//					
//					if (previousIndex != b1) {
//						crosser.restartAt(vertex(b1));
//					}
//					
//					// Beware, this may return the loop is valid if there is a
//					// "vertex crossing".
//					// TODO(user): Fix that.
//					crosses = crosser.robustCrossing(vertex(b2)) > 0;
//					previousIndex = b2;
//					if (crosses ) {
//						log.info("Edges " + a1 + " and " + b1 + " cross");
//						log.info(String.format("Edge locations in degrees: " + "%s-%s and %s-%s",
//						new S2LatLng(vertex(a1)).toStringDegrees(),
//						new S2LatLng(vertex(a2)).toStringDegrees(),
//						new S2LatLng(vertex(b1)).toStringDegrees(),
//						new S2LatLng(vertex(b2)).toStringDegrees()));
//						return false
//					}
//				}
//			}
//		}

		return true
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
		
		originInside = false // Initialize before calling Contains().
		let v1Inside = S2.orderedCCW(a: vertex(1).ortho, b: vertex(0), c: vertex(2), o: vertex(1))
		if v1Inside != contains(point: vertex(1)) {
			originInside = true
		}
	}
	
	private mutating func initBound() {
		// The bounding rectangle of a loop is not necessarily the same as the
		// bounding rectangle of its vertices. First, the loop may wrap entirely
		// around the sphere (e.g. a loop that defines two revolutions of a
		// candy-cane stripe). Second, the loop may include one or both poles.
		// Note that a small clockwise loop near the equator contains both poles.
		
		var bounder = S2EdgeUtil.RectBounder()
		for i in 0 ... numVertices {
			bounder.add(point: vertex(i))
		}
		var b = bounder.bound
		// Note that we need to initialize bound with a temporary value since
		// contains() does a bounding rectangle check before doing anything else.
		bound = .full
		if contains(point: S2Point(x: 0, y: 0, z: 1)) {
			b = S2LatLngRect(lat: R1Interval(lo: b.lat.lo, hi: M_PI_2), lng: .full)
		}
		// If a loop contains the south pole, then either it wraps entirely
		// around the sphere (full longitude range), or it also contains the
		// north pole in which case b.lng().isFull() due to the test above.
		
		if b.lng.isFull && contains(point: S2Point(x: 0, y: 0, z: -1)) {
			b = S2LatLngRect(lat: R1Interval(lo: -M_PI_2, hi: b.lat.hi), lng: b.lng)
		}
		bound = b
	}
	
	/**
		Return the index of a vertex at point "p", or -1 if not found. The return
		value is in the range 1..num_vertices_ if found.
	*/
	private mutating func findVertex(point p: S2Point) -> Int {
		if vertexToIndex == nil {
			vertexToIndex = [:]
			for i in 1 ..< numVertices {
				vertexToIndex?[vertex(i)] = i
			}
		}
		return vertexToIndex?[p] ?? -1
	}
	
	/**
		This method encapsulates the common code for loop containment and
		intersection tests. It is used in three slightly different variations to
		implement contains(), intersects(), and containsOrCrosses().
	
		In a nutshell, this method checks all the edges of this loop (A) for
		intersection with all the edges of B. It returns -1 immediately if any edge
		intersections are found. Otherwise, if there are any shared vertices, it
		returns the minimum value of the given WedgeRelation for all such vertices
		(returning immediately if any wedge returns -1). Returns +1 if there are no
		intersections and no shared vertices.
	*/
	private func checkEdgeCrossings(b: S2Loop, relation: WedgeRelation) -> Int {
//		DataEdgeIterator it = getEdgeIterator(b.numVertices);
//		int result = 1;
//		// since 'this' usually has many more vertices than 'b', use the index on
//		// 'this' and loop over 'b'
//		for (int j = 0; j < b.numVertices(); ++j) {
//		S2EdgeUtil.EdgeCrosser crosser =
//		new S2EdgeUtil.EdgeCrosser(b.vertex(j), b.vertex(j + 1), vertex(0));
//		int previousIndex = -2;
//		for (it.getCandidates(b.vertex(j), b.vertex(j + 1)); it.hasNext(); it.next()) {
//		int i = it.index();
//		if (previousIndex != i - 1) {
//		crosser.restartAt(vertex(i));
//		}
//		previousIndex = i;
//		int crossing = crosser.robustCrossing(vertex(i + 1));
//		if (crossing < 0) {
//		continue;
//		}
//		if (crossing > 0) {
//		return -1; // There is a proper edge crossing.
//		}
//		if (vertex(i + 1).equals(b.vertex(j + 1))) {
//		result = Math.min(result, relation.test(
//		vertex(i), vertex(i + 1), vertex(i + 2), b.vertex(j), b.vertex(j + 2)));
//		if (result < 0) {
//		return result;
//		}
//		}
//		}
//		}
//		return result;
		return 0
	}
	
	////////////////////////////////////////////////////////////////////////
	// MARK: S2Region
	////////////////////////////////////////////////////////////////////////
	
	/// Return a bounding spherical cap.
	public var capBound: S2Cap {
		return bound.capBound
	}
	
	/// Return a bounding latitude-longitude rectangle.
	public var rectBound: S2LatLngRect {
		return bound
	}
	
	/**
		If this method returns true, the region completely contains the given cell.
		Otherwise, either the region does not contain the cell or the containment
		relationship could not be determined.
	*/
	public func contains(cell: S2Cell) -> Bool {
		// It is faster to construct a bounding rectangle for an S2Cell than for
		// a general polygon. A future optimization could also take advantage of
		// the fact than an S2Cell is convex.
		
		let cellBound = cell.rectBound
		if !bound.contains(other: cellBound) {
			return false
		}
		let cellLoop = S2Loop(cell: cell, bound: cellBound)
		return contains(cellLoop)
	}
	
	/**
		If this method returns false, the region does not intersect the given cell.
		Otherwise, either region intersects the cell, or the intersection
		relationship could not be determined.
	*/
	public func mayIntersect(cell: S2Cell) -> Bool {
		// It is faster to construct a bounding rectangle for an S2Cell than for
		// a general polygon. A future optimization could also take advantage of
		// the fact than an S2Cell is convex.
		
		let cellBound = cell.rectBound
		if !bound.intersects(with: cellBound) {
			return false
		}
		let cellLoop = S2Loop(cell: cell, bound: cellBound)
		return cellLoop.intersects(with: self)
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
