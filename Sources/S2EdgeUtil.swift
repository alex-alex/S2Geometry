//
//  S2EdgeUtil.swift
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
* A wedge relation's test method accepts two edge chains A=(a0,a1,a2) and
* B=(b0,b1,b2) where a1==b1, and returns either -1, 0, or 1 to indicate the
* relationship between the region to the left of A and the region to the left
* of B. Wedge relations are used to determine the local relationship between
* two polygons that share a common vertex.
*
*  All wedge relations require that a0 != a2 and b0 != b2. Other degenerate
* cases (such as a0 == b2) are handled as expected. The parameter "ab1"
* denotes the common vertex a1 == b1.
*/
public protocol WedgeRelation {
	func test(a0: S2Point, ab1: S2Point, a2: S2Point, b0: S2Point, b2: S2Point) -> Int
}

/**
	This class contains various utility functions related to edges. It collects
	together common code that is needed to implement polygonal geometry such as
	polylines, loops, and general polygons.
*/
public struct S2EdgeUtil {
	
	/**
		IEEE floating-point operations have a maximum error of 0.5 ULPS (units in
		the last place). For double-precision numbers, this works out to 2**-53
		(about 1.11e-16) times the magnitude of the result. It is possible to
		analyze the calculation done by getIntersection() and work out the
		worst-case rounding error. I have done a rough version of this, and my
		estimate is that the worst case distance from the intersection point X to
		the great circle through (a0, a1) is about 12 ULPS, or about 1.3e-15. This
		needs to be increased by a factor of (1/0.866) to account for the
		edgeSpliceFraction() in S2PolygonBuilder. Note that the maximum error
		measured by the unittest in 1,000,000 trials is less than 3e-16.
	*/
	public static let defaultIntersectionTolerance = S1Angle(radians: 1.5e-15)
	
	/// This class allows a vertex chain v0, v1, v2, ... to be efficiently tested for intersection with a given fixed edge AB.
	public struct EdgeCrosser {
		
		private let a: S2Point
		private let b: S2Point
		private let aCrossB: S2Point
		
		// The fields below are updated for each vertex in the chain.
		
		// Previous vertex in the vertex chain.
		private var c: S2Point = S2Point()
		// The orientation of the triangle ACB.
		private var acb: Int = 0
		
		/**
		* AB is the given fixed edge, and C is the first vertex of the vertex
		* chain. All parameters must point to fixed storage that persists for the
		* lifetime of the EdgeCrosser object.
		*/
		public init(a: S2Point, b: S2Point, c: S2Point) {
			self.a = a
			self.b = b
			self.aCrossB = a.crossProd(b)
			restartAt(c: c)
		}
		
		/// Call this function when your chain 'jumps' to a new place.
		public mutating func restartAt(c: S2Point) {
			self.c = c
			acb = -S2.robustCCW(a: a, b: b, c: c, aCrossB: aCrossB)
		}
		
	}
	
	/**
		This class computes a bounding rectangle that contains all edges defined by
		a vertex chain v0, v1, v2, ... All vertices must be unit length. Note that
		the bounding rectangle of an edge can be larger than the bounding rectangle
		of its endpoints, e.g. consider an edge that passes through the north pole.
	*/
	public struct RectBounder {
		// The previous vertex in the chain.
		private var a: S2Point = S2Point()
		
		// The corresponding latitude-longitude.
		private var aLatLng: S2LatLng = S2LatLng()
		
		// The current bounding rectangle.
		/// The bounding rectangle of the edge chain that connects the vertices defined so far.
		public private(set) var bound: S2LatLngRect = .empty
		
		public init() {
			
		}
		
		/**
			This method is called to add each vertex to the chain. 'b' must point to
			fixed storage that persists for the lifetime of the RectBounder.
		*/
		public mutating func add(point b: S2Point) {
			// assert (S2.isUnitLength(b));
			
			let bLatLng = S2LatLng(point: b)
			
			if bound.isEmpty {
				bound = bound.add(point: bLatLng)
			} else {
				// We can't just call bound.addPoint(bLatLng) here, since we need to
				// ensure that all the longitudes between "a" and "b" are included.
				bound = bound.union(with: S2LatLngRect(lo: aLatLng, hi: bLatLng))
				
				// Check whether the min/max latitude occurs in the edge interior.
				// We find the normal to the plane containing AB, and then a vector
				// "dir" in this plane that also passes through the equator. We use
				// RobustCrossProd to ensure that the edge normal is accurate even
				// when the two points are very close together.
				let aCrossB = S2.robustCrossProd(a: a, b: b)
				let dir = aCrossB.crossProd(S2Point(x: 0, y: 0, z: 1))
				let da = dir.dotProd(a)
				let db = dir.dotProd(b)
				
				if da * db < 0 {
					// Minimum/maximum latitude occurs in the edge interior. This affects
					// the latitude bounds but not the longitude bounds.
					let absLat = acos(abs(aCrossB.get(axis: 2) / aCrossB.norm))
					var lat = bound.lat
					if da < 0 {
						// It's possible that absLat < lat.lo() due to numerical errors.
						lat = R1Interval(lo: lat.lo, hi: max(absLat, bound.lat.hi))
					} else {
						lat = R1Interval(lo: min(-absLat, bound.lat.lo), hi: lat.hi)
					}
					bound = S2LatLngRect(lat: lat, lng: bound.lng)
				}
			}
			a = b
			aLatLng = bLatLng
		}
	}
	
	/**
		Given a point X and an edge AB, return the distance ratio AX / (AX + BX).
		If X happens to be on the line segment AB, this is the fraction "t" such
		that X == Interpolate(A, B, t). Requires that A and B are distinct.
	*/
	public static func getDistanceFraction(x: S2Point, a0: S2Point, a1: S2Point) -> Double {
		precondition(a0 != a1)
		let d0 = x.angle(to: a0)
		let d1 = x.angle(to: a1)
		return d0 / (d0 + d1)
	}
	
	/**
		Return the minimum distance from X to any point on the edge AB. The result
		is very accurate for small distances but may have some numerical error if
		the distance is large (approximately Pi/2 or greater). The case A == B is
		handled correctly. Note: x, a and b must be of unit length. Throws
		IllegalArgumentException if this is not the case.
	*/
	public static func getDistance(x: S2Point, a: S2Point, b: S2Point) -> S1Angle {
		return getDistance(x: x, a: a, b: b, aCrossB: S2.robustCrossProd(a: a, b: b))
	}
	
	/**
		A slightly more efficient version of getDistance() where the cross product
		of the two endpoints has been precomputed. The cross product does not need
		to be normalized, but should be computed using S2.robustCrossProd() for the
		most accurate results.
	*/
	public static func getDistance(x: S2Point, a: S2Point, b: S2Point, aCrossB: S2Point) -> S1Angle {
		precondition(S2.isUnitLength(point: x))
		precondition(S2.isUnitLength(point: a))
		precondition(S2.isUnitLength(point: b))
		
		// There are three cases. If X is located in the spherical wedge defined by
		// A, B, and the axis A x B, then the closest point is on the segment AB.
		// Otherwise the closest point is either A or B; the dividing line between
		// these two cases is the great circle passing through (A x B) and the
		// midpoint of AB.
		
		if S2.simpleCCW(a: aCrossB, b: a, c: x) && S2.simpleCCW(a: x, b: b, c: aCrossB) {
			// The closest point to X lies on the segment AB. We compute the distance
			// to the corresponding great circle. The result is accurate for small
			// distances but not necessarily for large distances (approaching Pi/2).
			
			let sinDist = abs(x.dotProd(aCrossB)) / aCrossB.norm
			return S1Angle(radians: asin(min(1.0, sinDist)))
		}
		
		// Otherwise, the closest point is either A or B. The cheapest method is
		// just to compute the minimum of the two linear (as opposed to spherical)
		// distances and convert the result to an angle. Again, this method is
		// accurate for small but not large distances (approaching Pi).
		
		let linearDist2 = min((x - a).norm2, (x - b).norm2)
		return S1Angle(radians: 2 * asin(min(1.0, 0.5 * sqrt(linearDist2))))
	}
	
}
