import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Sampa_SwiftTests.allTests),
    ]
}
#endif
