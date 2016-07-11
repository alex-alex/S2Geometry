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
