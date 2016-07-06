//
//  S2Point.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/1/16.
//  Copyright © 2016 Alex Studnicka. All rights reserved.
//

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

/**
	An S2Point represents a point on the unit sphere as a 3D vector. Usually
	points are normalized to be unit length, but some methods do not require this.
*/
public struct S2Point: Comparable, Hashable {

	public let x: Double
	public let y: Double
	public let z: Double
	
	public init(x: Double = 0, y: Double = 0, z: Double = 0) {
		self.x = x
		self.y = y
		self.z = z
	}
	
	public var norm2: Double {
		return x * x + y * y + z * z
	}
	
	public var norm: Double {
		return sqrt(norm2)
	}
	
	/// Return a vector orthogonal to this one
//	public S2Point ortho() {
//	int k = largestAbsComponent();
//	S2Point temp;
//	if (k == 1) {
//	temp = new S2Point(1, 0, 0);
//	} else if (k == 2) {
//	temp = new S2Point(0, 1, 0);
//	} else {
//	temp = new S2Point(0, 0, 1);
//	}
//	return S2Point.normalize(crossProd(this, temp));
//	}
	
	/// Return the index of the largest component fabs
	public var largestAbsComponent: Int {
		let temp = S2Point.fabs(point: self)
		if temp.x > temp.y {
			if temp.x > temp.z {
				return 0
			} else {
				return 2
			}
		} else {
			if temp.y > temp.z {
				return 1
			} else {
				return 2
			}
		}
	}
	
	public static func fabs(point p: S2Point) -> S2Point {
		return S2Point(x: abs(p.x), y: abs(p.y), z: abs(p.z))
	}
	
	public static func normalize(point p: S2Point) -> S2Point {
		var norm = p.norm
		if norm != 0 {
			norm = 1.0 / norm
		}
		return p * norm
	}
	
	public func get(axis: Int) -> Double {
		return (axis == 0) ? x : (axis == 1) ? y : z
	}
	
	/** Return the angle between two vectors in radians */
	public func angle(x: S2Point) -> Double {
		return atan2((self × x).norm, self ⋅ x)
	}
	
	/** Compare two vectors, return true if all their components are within a difference of margin. */
	public func aequal(that: S2Point, margin: Double) -> Bool {
		return (abs(x - that.x) < margin) && (abs(y - that.y) < margin) && (abs(z - that.z) < margin)
	}
	
	// MARK: Hashable
	
	public var hashValue: Int {
		var value: UInt64 = 17
		value += 37 * value + abs(x)._bitPattern
		value += 37 * value + abs(y)._bitPattern
		value += 37 * value + abs(z)._bitPattern
		return Int(value ^ (value >> 32))
	}
	
}

public func ==(lhs: S2Point, rhs: S2Point) -> Bool {
	return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

public func <(lhs: S2Point, rhs: S2Point) -> Bool {
	if lhs.x < rhs.x {
		return true
	}
	if rhs.x < lhs.x {
		return false
	}
	if lhs.y < rhs.y {
		return true
	}
	if rhs.y < lhs.y {
		return false
	}
	if lhs.z < rhs.z {
		return true
	}
	return false
}

public func abs(x: S2Point) -> S2Point {
	return S2Point(x: abs(x.x), y: abs(x.y), z: abs(x.z))
}

public prefix func -(x: S2Point) -> S2Point {
	return S2Point(x: -x.x, y: -x.y, z: -x.z)
}

public func +(lhs: S2Point, rhs: S2Point) -> S2Point {
	return S2Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
}

public func -(lhs: S2Point, rhs: S2Point) -> S2Point {
	return S2Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
}

public func *(lhs: S2Point, rhs: Double) -> S2Point {
	return S2Point(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
}

infix operator ⋅ { associativity left precedence 140 }
public func ⋅(lhs: S2Point, rhs: S2Point) -> Double {
	return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
}

infix operator × { associativity left precedence 140 }
public func ×(lhs: S2Point, rhs: S2Point) -> S2Point {
	return S2Point(x: lhs.y * rhs.z - lhs.z * rhs.y, y: lhs.z * rhs.x - lhs.x * rhs.z, z: lhs.x * rhs.y - lhs.y * rhs.x)
}
