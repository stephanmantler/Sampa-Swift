import XCTest
@testable import Sampa_Swift

final class Sampa_SwiftTests: XCTestCase {
    
    func makeTestParams(for date: DateComponents) -> SPAParameters {
        return SPAParameters(
            date: date,
            timezone: .current,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 64.1466,longitude: -21.9426) /* Reykjavík, Iceland */,
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()))
    }
    
    /// Test julian date calculation.
    func testJulianDate() {
        // we will allow a 0.25 second difference for julian date calculations.
        let testAccuracy = 0.25/86400
        
        var date = DateComponents(timeZone: .none, year: 2013, month: 1, day: 1, hour: 0, minute: 30, second: 0, nanosecond: 0)
        var params = makeTestParams(for: date)
        
        var spa = SPA(params: params)
        var result = spa.calculate()
        
        XCTAssertEqual(spa.jd, 2456293.520833, accuracy: testAccuracy, "Inaccurate Julian Date Calculation")
        
        date = DateComponents(timeZone: .none, year: 2023, month: 7, day: 7, hour: 16, minute: 30, second: 6, nanosecond: 0)
        params = makeTestParams(for: date)
        
        spa = SPA(params: params)
        result = spa.calculate()
        
        XCTAssertEqual(spa.jd, 2460133.18757, accuracy: testAccuracy, "Inaccurate Julian Date Calculation")
    }
    
    func testComplete() {
        let date = DateComponents(timeZone: .none, year: 2009, month: 7, day: 22, hour: 1, minute: 33, second: 0, nanosecond: 0)
        var params = SPAParameters(
            date: date,
            timezone: .current,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 24.61167, longitude: 143.36167),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()))
        params.delta_t = 66.4
        params.delta_ut1 = 0
        params.pressure = 1000
        params.temperature = 11
        params.atmosphericRefraction = 0.5667
        
        let spa = SPA(params: params)
        let result = spa.calculate()
        
        XCTAssertEqual(result!.azimuth, 104.387917, accuracy: 1e-6)
        XCTAssertEqual(result!.zenith, 14.512686, accuracy: 1e-6)
        XCTAssertEqual(spa.l, 299.4024, accuracy: 1e-4)
        XCTAssertEqual(spa.b, -1.308E-5, accuracy: 1e-7)
        XCTAssertEqual(spa.r, 1.016024, accuracy: 1e-6)
        XCTAssertEqual(spa.del_psi, 4.441121e-3, accuracy: 1e-7)
        XCTAssertEqual(spa.del_epsilon, 1.203311e-3, accuracy: 1e-7)
    }

    static var allTests = [
        ("testJulianDate", testJulianDate),
    ]
}
