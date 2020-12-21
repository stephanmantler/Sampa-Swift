import XCTest
@testable import Sampa_Swift

final class Sampa_SwiftTests: XCTestCase {
    
    func makeTestParams(for date: DateComponents) -> SPAParameters {
        return SPAParameters(
            date: date,
            timezone: .current,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 10,longitude: 10),
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
    
    /// Test calculation of heliocentric parameters
    func testHeliocentricParameters() {
        let date = DateComponents(timeZone: .none, year: 2010, month: 3, day: 21, hour: 6, minute: 0, second: 0, nanosecond: 0)
        let params = makeTestParams(for: date)
        
        let spa = SPA(params: params)
        let result = spa.calculate()

        // not sure yet which values to test this against
        //XCTAssertEqual(spa.l, 0)
    }

    static var allTests = [
        ("testJulianDate", testJulianDate),
    ]
}
