//
//  Utilities.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/30/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

import Foundation
import XCTest
@testable import S2Geometry

extension Int {
	static func random(max: Int = Int(UInt32.max)) -> Int {
		#if os(Linux)
			return Int(random() % (max + 1))
		#else
			return Int(arc4random_uniform(UInt32(max)))
		#endif
	}
}

extension Double {
	static func random() -> Double {
		return Double(Int.random()) / Double(UInt32.max)
	}
}

extension S2Point {
	/// Return a random unit-length vector.
	static var random: S2Point {
		return S2Point(x: .random(), y: .random(), z: .random())
	}
	
	/// Return a right-handed coordinate frame (three orthonormal vectors). Returns an array of three points: x,y,z
	static var randomFrame: [S2Point] {
		let p0 = S2Point.random
		let p1 = S2Point.normalize(point: p0.crossProd(.random))
		let p2 = S2Point.normalize(point: p0.crossProd(p1))
		return [p0, p1, p2]
	}
	
	init(latDegrees: Double, lngDegrees: Double) {
		self = S2LatLng.fromDegrees(lat: latDegrees, lng: lngDegrees).point
	}
}

extension S2CellId {
	/**
		Return a random cell id at the given level or at a randomly chosen level.
		The distribution is uniform over the space of cell ids, but only
		approximately uniform over the surface of the sphere.
	*/
	static func random(level: Int) -> S2CellId {
		let face = Int.random(max: S2CellId.numFaces)
		let pos = Int64(Int.random()) & ((1 << (2 * Int64(S2CellId.maxLevel))) - 1)
		return S2CellId(face: face, pos: pos, level: level)
	}
	
	static var random: S2CellId {
		return random(level: Int.random(max: S2CellId.maxLevel + 1))
	}
}

func parseVertices(_ str: String) -> [S2Point] {
	var vertices: [S2Point] = []
	
//	str.components(separatedBy: CharacterSet(charactersIn: ",").union(.whitespaces))
	let tokens = str.characters.split(omittingEmptySubsequences: true, whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
	
	for token in tokens {
		guard let colon = token.characters.index(of: ":"),
			let lat = Double(token.substring(to: colon)),
			let lng = Double(token.substring(from: token.index(after: colon)))
		else { fatalError() }
		vertices.append(S2LatLng.fromDegrees(lat: lat, lng: lng).point)
	}
	return vertices
}

extension S2Point {
	init(_ str: String) {
		let vertices = parseVertices(str)
		self = vertices[0]
	}
}

extension S2Loop {
	init(_ str: String) {
		let vertices = parseVertices(str)
		self.init(vertices: vertices)
	}
}
