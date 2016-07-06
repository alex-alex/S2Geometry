# S2Geometry

[![Swift][swift-badge]][swift-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Usage

```swift
import S2Geometry

let latlng = S2LatLng(latDegrees: 50.637689, lngDegrees: 13.825341)
let cellId = S2CellId(latlng: latlng)
print("Cell ID:", cellId.id)
```

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/alex-alex/S2Geometry.git", majorVersion: 0, minor: 1),
    ]
)
```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[travis-badge]: https://travis-ci.org/alex-alex/S2Geometry.svg?branch=master
[travis-url]: https://travis-ci.org/alex-alex/S2Geometry
[codebeat-badge]: https://codebeat.co/badges/e810900c-b5ff-4480-b66a-06068bff979d
[codebeat-url]: https://codebeat.co/projects/github-com-alex-alex-s2geometry
