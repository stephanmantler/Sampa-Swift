import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SPA_Tests.allTests),
        testCase(SAMPA_Tests.allTests),
    ]
}
#endif
