#if os(Linux)

import XCTest
@testable import S2GeometryTestSuite

XCTMain([
  testCase(S2GeometryTests.allTests),
])
#endif
