// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Sentry",
    platforms: [.iOS(.v9), .macOS(.v10_10), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(name: "Sentry", targets: ["Sentry"]),
        .library(name: "Sentry-Dynamic", type: .dynamic, targets: ["Sentry"])
    ],
    targets: [
        .target(
            name: "Sentry",
            path: "Sources",
            sources: [
                "Sentry/",
                "BuzzSentryCrash/"
            ],
            publicHeadersPath: "Sentry/Public/",
            cxxSettings: [
                .define("GCC_ENABLE_CPP_EXCEPTIONS", to: "YES"),
                .headerSearchPath("Sentry/include"),
                .headerSearchPath("Sentry/Public"),
                .headerSearchPath("BuzzSentryCrash/Installations"),
                .headerSearchPath("BuzzSentryCrash/Recording"),
                .headerSearchPath("BuzzSentryCrash/Recording/Monitors"),
                .headerSearchPath("BuzzSentryCrash/Recording/Tools"),
                .headerSearchPath("BuzzSentryCrash/Reporting/Filters"),
                .headerSearchPath("BuzzSentryCrash/Reporting/Filters/Tools"),
                .headerSearchPath("BuzzSentryCrash/Reporting/Tools")
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++")
            ]
        )
    ],
    cxxLanguageStandard: .cxx14
)
