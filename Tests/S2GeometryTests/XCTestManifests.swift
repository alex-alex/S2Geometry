//
//  XCTestManifests.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 8/3/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import XCTest

#if !os(macOS)
	public func allTests() -> [XCTestCaseEntry] {
		return [
		    testCase(R1IntervalTests.allTests),
		    testCase(S1AngleTests.allTests),
		    testCase(S1IntervalTests.allTests),
		    testCase(S2CapTests.allTests),
		    testCase(S2CellIdTests.allTests),
		    testCase(S2CellTests.allTests),
		    testCase(S2LatLngTests.allTests),
		    testCase(S2LoopTests.allTests),
		]
	}
#endif
