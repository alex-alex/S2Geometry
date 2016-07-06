//
//  S2.swift
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

internal extension Double {
	var _bitPattern: UInt64 {
		return unsafeBitCast(self, to: UInt64.self)
	}
}

public struct S2 {
	
	enum Error: ErrorProtocol {
		case IllegalArgumentException
	}
	
	// Together these flags define a cell orientation. If SWAP_MASK
	// is true, then canonical traversal order is flipped around the
	// diagonal (i.e. i and j are swapped with each other). If
	// INVERT_MASK is true, then the traversal order is rotated by 180
	// degrees (i.e. the bits of i and j are inverted, or equivalently,
	// the axis directions are reversed).
	public static let swapMask = 0x01
	public static let invertMask = 0x02
	
	// Number of bits in the mantissa of a double.
	private static let exponentShift = 52
	// Mask to extract the exponent from a double.
	private static let exponentMask: Int64 = 0x7ff0000000000000
	
	/**
		If v is non-zero, return an integer `exp` such that
		`(0.5 <= |v|*2^(-exp) < 1)`. If v is zero, return 0.
	
		Note that this arguably a bad definition of exponent because it makes `exp(9) == 4`.
		In decimal this would be like saying that the exponent of 1234 is 4, when in scientific 'exponent' notation 1234 is `1.234 x 10^3`.
	
		TODO(dbeaumont): Replace this with "DoubleUtils.getExponent(v) - 1" ?
	*/
	static func exp(v: Double) -> Int {
		guard v != 0 else { return 0 }
		let bits = unsafeBitCast(v, to: Int64.self)
		return Int((exponentMask & bits) >> Int64(exponentShift)) - 1022
	}
	
	/// Mapping Hilbert traversal order to orientation adjustment mask.
	internal static let posToOrientation = [swapMask, 0, 0, invertMask + swapMask]
	
	/**
		Returns an XOR bit mask indicating how the orientation of a child subcell
		is related to the orientation of its parent cell. The returned value can
		be XOR'd with the parent cell's orientation to give the orientation of
		the child cell.
	
		- Parameter position: The position of the subcell in the Hilbert traversal, in the range [0,3].
		
		- Throws: `IllegalArgumentException` if position is out of bounds.
		
		- Returns: A bit mask containing some combination of {@link #SWAP_MASK} and {@link #INVERT_MASK}.
	*/
	public static func posToOrientation(position: Int) throws -> Int {
		guard 0 <= position && position < 4 else { throw Error.IllegalArgumentException }
		return posToOrientation[position]
	}
	
	/// Mapping from cell orientation + Hilbert traversal to IJ-index.
	private static let posToIJ: [[Int]] = [
//		 0  1  2  3
		[0, 1, 3, 2],	// canonical order: (0,0), (0,1), (1,1), (1,0)
		[0, 2, 3, 1],	// axes swapped: (0,0), (1,0), (1,1), (0,1)
		[3, 2, 0, 1],	// bits inverted: (1,1), (1,0), (0,0), (0,1)
		[3, 1, 0, 2]	// swapped & inverted: (1,1), (0,1), (0,0), (1,0)
	]
	
	/**
		Return the IJ-index of the subcell at the given position in the Hilbert
		curve traversal with the given orientation. This is the inverse of `ijToPos`
	
		- Parameter orientation: The subcell orientation, in the range [0,3].
		- Parameter position: The position of the subcell in the Hilbert traversal, in the range [0,3].
		
		- Throws: `IllegalArgumentException` if either parameter is out of bounds.
		
		- Returns: The IJ-index where `0->(0,0), 1->(0,1), 2->(1,0), 3->(1,1)`.
	*/
	public static func posToIJ(orientation: Int, position: Int) throws -> Int {
		guard 0 <= orientation && orientation < 4 else { throw Error.IllegalArgumentException }
		guard 0 <= position && position < 4 else { throw Error.IllegalArgumentException }
		return posToIJ[orientation][position]
	}
	
	/// Mapping from Hilbert traversal order + cell orientation to IJ-index.
	private static let ijToPos: [[Int]] = [
//		 (0,0) (0,1) (1,0) (1,1)
		[0, 1, 3, 2],	// canonical order
		[0, 3, 1, 2],	// axes swapped
		[2, 3, 1, 0],	// bits inverted
		[2, 1, 3, 0],	// swapped & inverted
	]
	
	/**
		Returns the order in which a specified subcell is visited by the Hilbert
		curve. This is the inverse of `posToIJ`
	
		- Parameter orientation: The subcell orientation, in the range [0,3].
		- Parameter ijIndex: The subcell index where `0->(0,0), 1->(0,1), 2->(1,0), 3->(1,1)`.
	
		- Throws: `IllegalArgumentException` if either parameter is out of bounds.
		
		- Returns: The position of the subcell in the Hilbert traversal, in the range [0,3].
	*/
	public static func toPos(orientation: Int, ijIndex: Int) throws -> Int {
		guard 0 <= orientation && orientation < 4 else { throw Error.IllegalArgumentException }
		guard 0 <= ijIndex && ijIndex < 4 else { throw Error.IllegalArgumentException }
		return ijToPos[orientation][ijIndex]
	}
	
	/// Defines an area or a length cell metric.
	public struct Metric {
		
		/// The "deriv" value of a metric is a derivative, and must be multiplied by a length or area in (s,t)-space to get a useful value.
		public let deriv: Double
		public let dim: Int
		
		/// Defines a cell metric of the given dimension (1 == length, 2 == area).
		public init(dim: Int, deriv: Double) {
			self.deriv = deriv
			self.dim = dim
		}
		
		/// Return the value of a metric for cells at the given level.
		public func getValue(level: Int) -> Double {
			return scalb(deriv, Double(dim) * (1 - Double(level)))
		}
		
		/**
			Return the level at which the metric has approximately the given value.
			For example, S2::kAvgEdge.GetClosestLevel(0.1) returns the level at which
			the average cell edge length is approximately 0.1. The return value is
			always a valid level.
		*/
		public func getClosestLevel(value: Double) -> Int {
			return getMinLevel(value: M_SQRT2 * value)
		}
		
		/**
			Return the minimum level such that the metric is at most the given value,
			or S2CellId::kMaxLevel if there is no such level. For example,
			S2::kMaxDiag.GetMinLevel(0.1) returns the minimum level such that all
			cell diagonal lengths are 0.1 or smaller. The return value is always a
			valid level.
		*/
		public func getMinLevel(value: Double) -> Int {
			guard value > 0 else { return S2CellId.maxLevel }
			
			// This code is equivalent to computing a floating-point "level" value and rounding up.
			let exponent = exp(value / (Double(1 << dim) * deriv))
			let level = max(0, min(S2CellId.maxLevel, -((Int(exponent._bitPattern) - 1) >> (dim - 1))))
			// assert (level == S2CellId.MAX_LEVEL || getValue(level) <= value);
			// assert (level == 0 || getValue(level - 1) > value);
			return level
		}
		
		/**
			Return the maximum level such that the metric is at least the given
			value, or zero if there is no such level. For example,
			S2.kMinWidth.GetMaxLevel(0.1) returns the maximum level such that all
			cells have a minimum width of 0.1 or larger. The return value is always a
			valid level.
		*/
		public func getMaxLevel(value: Double) -> Int {
			guard value > 0 else { return S2CellId.maxLevel }
			
			// This code is equivalent to computing a floating-point "level" value and rounding down.
			let exponent = exp(Double(1 << dim) * deriv / value)
			let level = max(0, min(S2CellId.maxLevel, (Int(exponent._bitPattern - 1) >> (dim - 1))))
			// assert (level == 0 || getValue(level) >= value);
			// assert (level == S2CellId.MAX_LEVEL || getValue(level + 1) < value);
			return level
		}
		
	}
	
	/**
		Return a unique "origin" on the sphere for operations that need a fixed
		reference point. It should *not* be a point that is commonly used in edge
		tests in order to avoid triggering code to handle degenerate cases. (This
		rules out the north and south poles.)
	*/
	public static let origin = S2Point(x: 0, y: 1, z: 0)
	
	/// Return true if the given point is approximately unit length (this is mainly useful for assertions).
	public static func isUnitLength(point p: S2Point) -> Bool {
		return abs(p.norm2 - 1) <= 1e-15
	}
	
	// Don't instantiate
	private init() { }
	
}
