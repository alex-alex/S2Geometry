//
//  R2Vector.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 6/30/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

/**
	R2Vector represents a vector in the two-dimensional space. It defines the
	basic geometrical operations for 2D vectors, e.g. cross product, addition, norm, comparison etc.
*/
public struct R2Vector: Comparable {
	
	public let x: Double
	public let y: Double
	
	public init(x: Double = 0, y: Double = 0) {
		self.x = x
		self.y = y
	}
	
	public func get(index: Int) -> Double {
		return index == 0 ? x : y
	}
	
	public var norm2: Double {
		return (x * x) + (y * y)
	}
	
}

public func ==(lhs: R2Vector, rhs: R2Vector) -> Bool {
	return lhs.x == rhs.x && lhs.y == rhs.y
}

public func <(lhs: R2Vector, rhs: R2Vector) -> Bool {
	if lhs.x < rhs.x {
		return true
	}
	if rhs.x < lhs.x {
		return false
	}
	if lhs.y < rhs.y {
		return true
	}
	return false
}

public func +(lhs: R2Vector, rhs: R2Vector) -> R2Vector {
	return R2Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func -(lhs: R2Vector, rhs: R2Vector) -> R2Vector {
	return R2Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func *(lhs: R2Vector, m: Double) -> R2Vector {
	return R2Vector(x: lhs.x * m, y: lhs.y * m)
}

infix operator ⋅ { associativity left precedence 140 }
public func ⋅(lhs: R2Vector, rhs: R2Vector) -> Double {
	return lhs.x * rhs.x + lhs.y * rhs.y
}

infix operator × { associativity left precedence 140 }
public func ×(lhs: R2Vector, rhs: R2Vector) -> Double {
	return lhs.x * rhs.y - lhs.y * rhs.x
}
