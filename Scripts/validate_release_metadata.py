#!/usr/bin/env python3
"""Check package, Pod, example and documentation metadata before a release."""
import argparse
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", help="Require the release tag to match the Pod source tag exactly.")
    args = parser.parse_args()
    spec = read("TFYSwiftCalendarkit.podspec")
    version_match = re.search(r"spec\.version\s*=\s*'([0-9]+\.[0-9]+\.[0-9]+)'", spec)
    minimum_match = re.search(r"spec\.ios\.deployment_target\s*=\s*'([0-9]+)\.0'", spec)
    if not version_match or not minimum_match:
        parser.exit(1, "Invalid Pod version or minimum deployment target.\n")
    version = version_match.group(1)
    minimum = minimum_match.group(1)
    errors = []

    def require(condition, message):
        if not condition:
            errors.append(message)

    require(f".iOS(.v{minimum})" in read("Package.swift"), "SPM minimum differs from CocoaPods.")
    require(f"@available(iOS {minimum}.0, *)" in read("Sources/TFYSwiftCalendarkit/TFYSwiftCalendarView.swift"),
            "SwiftUI availability differs from CocoaPods.")
    targets = re.findall(r"IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);",
                         read("Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj/project.pbxproj"))
    require(bool(targets) and all(target == f"{minimum}.0" for target in targets),
            "Example deployment targets differ from CocoaPods.")
    info = plistlib.loads((ROOT / "Examples/TFYSwiftCalendarExample/Info.plist").read_bytes())
    require(info.get("CFBundleShortVersionString") == version, "Example version differs from CocoaPods.")
    require(re.search(rf"^## {re.escape(version)}\s*$", read("CHANGELOG.md"), re.MULTILINE),
            "Changelog is missing the release version.")
    readme = read("README.md")
    require(f'from: "{version}"' in readme and f"'~> {version}'" in readme,
            "README installation examples differ from CocoaPods.")
    require(f"iOS {minimum}+" in readme, "README minimum differs from CocoaPods.")
    # The repository currently uses XCTest method tests; keep published counts in sync.
    test_count = sum(len(re.findall(r"^\s+func test\w+\(", path.read_text(encoding="utf-8"), re.MULTILINE))
                     for path in (ROOT / "Tests").rglob("*.swift"))
    require(f"当前包含 {test_count} 个回归测试" in readme, "README test count differs from XCTest methods.")
    require(f"Minimum deployment target: iOS {minimum}" in read("CONTRIBUTING.md"),
            "Contributor requirements differ from CocoaPods.")
    require(f"iOS {minimum} or later" in read("Examples/TFYSwiftCalendarExample/README.md"),
            "Example README minimum differs from CocoaPods.")
    release_notes = ROOT / f"Documentation/RELEASE_{version}.md"
    require(release_notes.is_file(), "Release notes are missing.")
    if release_notes.is_file():
        require(f"回归测试共 {test_count} 项" in release_notes.read_text(encoding="utf-8"),
                "Release notes test count differs from XCTest methods.")
    require(":tag => spec.version.to_s" in spec, "Pod source must use the exact release version as its tag.")
    if args.tag:
        require(args.tag == version, f"Release tag must be {version}, received {args.tag}.")
    if errors:
        parser.exit(1, "\n".join(f"ERROR: {message}" for message in errors) + "\n")
    print(f"Release metadata consistent: {version}, iOS {minimum}+, SPM/CocoaPods/example/docs, {test_count} XCTest methods.")


if __name__ == "__main__":
    main()
