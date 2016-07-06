//
//  S2LatLngRect.swift
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
	An S2LatLngRect represents a latitude-longitude rectangle. It is capable of
	representing the empty and full rectangles as well as single points.
*/
public struct S2LatLngRect: S2Region {
	
	public let lat: R1Interval
	public let lng: S1Interval
	
	public var lo: S2LatLng {
		return S2LatLng(lat: S1Angle(radians: lat.lo), lng: S1Angle(radians: lng.lo))
	}
	
	public var hi: S2LatLng {
		return S2LatLng(lat: S1Angle(radians: lat.hi), lng: S1Angle(radians: lng.hi))
	}
	
	/**
		Construct a rectangle from minimum and maximum latitudes and longitudes. If
		lo.lng > hi.lng, the rectangle spans the 180 degree longitude line.
	*/
	public init(lo: S2LatLng, hi: S2LatLng) {
		lat = R1Interval(lo: lo.lat.radians, hi: hi.lat.radians)
		lng = S1Interval(lo: lo.lng.radians, hi: hi.lng.radians)
		// assert (isValid());
	}
	
	/// Construct a rectangle from latitude and longitude intervals.
	public init(lat: R1Interval, lng: S1Interval) {
		self.lat = lat
		self.lng = lng
		// assert (isValid());
	}
	
	/// The canonical empty rectangle
	public static var empty: S2LatLngRect {
		return S2LatLngRect(lat: .empty, lng: .empty)
	}
	
	/// The canonical full rectangle.
	public static var full: S2LatLngRect {
		return S2LatLngRect(lat: fullLat, lng: fullLng)
	}
	
	/// The full allowable range of latitudes.
	public static var fullLat: R1Interval {
		return R1Interval(lo: -M_PI_2, hi: M_PI_2)
	}
	
	/// The full allowable range of longitudes.
	public static var fullLng: S1Interval {
		return .full
	}
	
	/// Return the smallest rectangle containing the union of this rectangle and the given rectangle.
	public func union(with other: S2LatLngRect) -> S2LatLngRect {
		return S2LatLngRect(lat: lat.union(with: other.lat), lng: lng.union(with: other.lng))
	}
	
	////////////////////////////////////////////////////////////////////////
	// MARK: S2Region
	////////////////////////////////////////////////////////////////////////
	
	public var capBound: S2Cap {
		return S2Cap()
	}
	
	public var rectBound: S2LatLngRect {
		return self
	}
	
	public func contains(cell: S2Cell) -> Bool {
		return false
	}
	
	/**
		This test is cheap but is NOT exact. Use Intersects() if you want a more
		accurate and more expensive test. Note that when this method is used by an
		S2RegionCoverer, the accuracy isn't all that important since if a cell may
		intersect the region then it is subdivided, and the accuracy of this method
		goes up as the cells get smaller.
	*/
	public func mayIntersect(cell: S2Cell) -> Bool {
		return false
	}
	
}
