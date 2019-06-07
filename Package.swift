// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "Analytics",
            type: .dynamic,
            targets: ["Analytics"])
    ],
    targets: [
        .target(
            name: "Analytics",
            path: "Analytics",
			cSettings: [.headerSearchPath("Analytics/Classes"), .headerSearchPath("Analytics/Vendor"), .headerSearchPath("Analytics/Classes/Crypto"), .headerSearchPath("Analytics/Classes/Middlewares"), .headerSearchPath("Analytics/Classes/Integrations"), .headerSearchPath("Analytics/Classes/Internal")])
    ],
	cLanguageStandard: .gnu99
)
