import ProjectDescription

// MARK: - Constants

private let bundlePrefix = "com.gsikjoa"
private let deploymentTargets: DeploymentTargets = .iOS("17.0")
private let destinations: Destinations = [.iPhone]

// MARK: - Helpers

private func makeFramework(
    name: String,
    path: String,
    dependencies: [TargetDependency] = [],
    hasResources: Bool = false
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "\(bundlePrefix).\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        sources: ["\(path)/Sources/**"],
        resources: hasResources ? ["\(path)/Resources/**"] : nil,
        dependencies: dependencies
    )
}

private func makeUnitTests(
    name: String,
    path: String,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: "\(name)Tests",
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(bundlePrefix).\(name.lowercased())tests",
        deploymentTargets: deploymentTargets,
        sources: ["\(path)/Tests/**"],
        dependencies: [.target(name: name)] + dependencies
    )
}

// MARK: - Targets

let coreModules: [Target] = [
    makeFramework(name: "Domain", path: "Modules/Core/Domain"),
    makeFramework(
        name: "Data",
        path: "Modules/Core/Data",
        dependencies: [.target(name: "Domain")],
        hasResources: true
    ),
    makeFramework(
        name: "DesignSystem",
        path: "Modules/Core/DesignSystem",
        dependencies: [.target(name: "Domain")]
    ),
    makeFramework(name: "Utils", path: "Modules/Core/Utils"),
]

private let featureDeps: [TargetDependency] = [
    .target(name: "Domain"),
    .target(name: "DesignSystem"),
    .target(name: "Utils"),
]

let featureModules: [Target] = [
    makeFramework(name: "Onboarding", path: "Modules/Features/Onboarding", dependencies: featureDeps),
    makeFramework(name: "Home", path: "Modules/Features/Home", dependencies: featureDeps),
    makeFramework(name: "PackList", path: "Modules/Features/PackList", dependencies: featureDeps),
    makeFramework(name: "Quiz", path: "Modules/Features/Quiz", dependencies: featureDeps),
    makeFramework(name: "Result", path: "Modules/Features/Result", dependencies: featureDeps),
    makeFramework(name: "ConceptVault", path: "Modules/Features/ConceptVault", dependencies: featureDeps),
    makeFramework(name: "Settings", path: "Modules/Features/Settings", dependencies: featureDeps),
]

let appTarget: Target = .target(
    name: "GsikJoa",
    destinations: destinations,
    product: .app,
    bundleId: "\(bundlePrefix).app",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [
            "UIColorName": "LaunchBackground",
        ],
        "CFBundleDisplayName": "G식좋아",
        "CFBundleShortVersionString": "0.1.1",
        "CFBundleVersion": "3",
        "UIUserInterfaceStyle": "Light",
        "CFBundleDevelopmentRegion": "ko",
        "CFBundleAllowMixedLocalizations": false,
        "ITSAppUsesNonExemptEncryption": false,
    ]),
    sources: ["Modules/App/Sources/**"],
    resources: ["Modules/App/Resources/**"],
    dependencies: [
        .target(name: "Domain"),
        .target(name: "Data"),
        .target(name: "DesignSystem"),
        .target(name: "Utils"),
        .target(name: "Onboarding"),
        .target(name: "Home"),
        .target(name: "PackList"),
        .target(name: "Quiz"),
        .target(name: "Result"),
        .target(name: "ConceptVault"),
        .target(name: "Settings"),
    ]
)

let appTests: Target = .target(
    name: "GsikJoaTests",
    destinations: destinations,
    product: .unitTests,
    bundleId: "\(bundlePrefix).apptests",
    deploymentTargets: deploymentTargets,
    sources: ["Modules/App/Tests/**"],
    dependencies: [.target(name: "GsikJoa")]
)

let domainTests: Target = makeUnitTests(name: "Domain", path: "Modules/Core/Domain")

// MARK: - Project

let project = Project(
    name: "GsikJoa",
    organizationName: "GsikJoa",
    options: .options(
        defaultKnownRegions: ["ko"],
        developmentRegion: "ko"
    ),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "5.10",
            "SWIFT_STRICT_CONCURRENCY": "minimal",
            "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
            "DEVELOPMENT_TEAM": "AAWLC28736",
            "CODE_SIGN_STYLE": "Automatic",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [appTarget] + coreModules + featureModules + [appTests, domainTests],
    schemes: [
        .scheme(
            name: "GsikJoa",
            shared: true,
            buildAction: .buildAction(targets: ["GsikJoa"]),
            testAction: .targets(["GsikJoaTests", "DomainTests"]),
            runAction: .runAction(executable: "GsikJoa")
        ),
    ]
)
