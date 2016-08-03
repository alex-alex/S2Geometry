#if os(Linux)

import XCTest
@testable import S2GeometryTestSuite

XCTMain([
  testCase(R1IntervalTests.allTests),
  testCase(S1AngleTests.allTests),
  testCase(S1IntervalTests.allTests),
  testCase(S2CapTests.allTests),
  testCase(S2CellIdTests.allTests),
  testCase(S2CellTests.allTests),
  testCase(S2LatLngTests.allTests),
  testCase(S2LoopTests.allTests),
])
#endif
