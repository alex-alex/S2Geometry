//
//  S2Cap.swift
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
	This class represents a spherical cap, i.e. a portion of a sphere cut off by
	a plane. The cap is defined by its axis and height. This representation has
	good numerical accuracy for very small caps (unlike the (axis,
	min-distance-from-origin) representation), and is also efficient for
	containment tests (unlike the (axis, angle) representation).

	Here are some useful relationships between the cap height (h), the cap
	opening angle (theta), the maximum chord length from the cap's center (d),
	and the radius of cap's base (a). All formulas assume a unit radius.

	h = 1 - cos(theta) = 2 sin^2(theta/2) d^2 = 2 h = a^2 + h^2
*/
public struct S2Cap: S2Region {
	
	/**
		Multiply a positive number by this constant to ensure that the result of a
		floating point operation is at least as large as the true
		infinite-precision result.
	*/
	private static let roundUp = 2 / Double(1 << 52)
	
	public let axis: S2Point
	public let height: Double
	
	/**
		Create a cap given its axis and the cap height, i.e. the maximum projected
		distance along the cap axis from the cap center. 'axis' should be a
		unit-length vector.
	*/
	public init(axis: S2Point = S2Point(), height: Double = 0) {
		self.axis = axis
		self.height = height
	}
	
	/**
		Create a cap given its axis and the cap opening angle, i.e. maximum angle
		between the axis and a point on the cap. 'axis' should be a unit-length
		vector, and 'angle' should be between 0 and 180 degrees.
	*/
	public init(axis: S2Point, angle: S1Angle) {
		// The height of the cap can be computed as 1-cos(angle), but this isn't
		// very accurate for angles close to zero (where cos(angle) is almost 1).
		// Computing it as 2*(sin(angle/2)**2) gives much better precision.
		
		// assert (S2.isUnitLength(axis));
		let d = sin(0.5 * angle.radians)
		self.init(axis: axis, height: 2 * d * d)
	}
	
	/**
		Create a cap given its axis and its area in steradians. 'axis' should be a
		unit-length vector, and 'area' should be between 0 and 4 * M_PI.
	*/
	public init(axis: S2Point, area: Double) {
		// assert (S2.isUnitLength(axis));
		self.init(axis: axis, height: area / (2 * M_PI))
	}
	
	/// Return an empty cap, i.e. a cap that contains no points.
	public static let empty = S2Cap(axis: S2Point(x: 1, y: 0, z: 0), height: -1)
	
	/// Return a full cap, i.e. a cap that contains all points.
	public static let full = S2Cap(axis: S2Point(x: 1, y: 0, z: 0), height: 2)
	
	public var area: Double {
		return 2 * M_PI * max(0, height)
	}
	
	/// Return the cap opening angle in radians, or a negative number for empty caps.
	public var angle: S1Angle {
		// This could also be computed as acos(1 - height_), but the following
		// formula is much more accurate when the cap height is small. It
		// follows from the relationship h = 1 - cos(theta) = 2 sin^2(theta/2).
		if isEmpty {
			return S1Angle(radians: -1)
		}
		return S1Angle(radians: 2 * asin(sqrt(0.5 * height)))
	}
	
	/// We allow negative heights (to represent empty caps) but not heights greater than 2.
	public var isValid: Bool {
		return S2.isUnitLength(point: axis) && height <= 2
	}
	
	/// Return true if the cap is empty, i.e. it contains no points.
	public var isEmpty: Bool {
		return height < 0
	}
	
	/// Return true if the cap is full, i.e. it contains all points.
	public var isFull: Bool {
		return height >= 2
	}
	
	////////////////////////////////////////////////////////////////////////
	// MARK: S2Region
	////////////////////////////////////////////////////////////////////////
	
	public var capBound: S2Cap {
		return self
	}
	
	public var rectBound: S2LatLngRect {
		return S2LatLngRect(lat: .empty, lng: .empty)
	}
	
	public func contains(cell: S2Cell) -> Bool {
		return false
	}
	
	public func mayIntersect(cell: S2Cell) -> Bool {
		return false
	}
	
}
