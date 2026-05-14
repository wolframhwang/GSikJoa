import ProjectDescription

let config = Config(
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("26.0"),
        swiftVersion: "5.10"
    )
)
