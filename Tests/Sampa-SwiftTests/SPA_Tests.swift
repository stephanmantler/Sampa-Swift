import XCTest
@testable import SaMPA

final class SPA_Tests: XCTestCase {
    
    func makeTestParams(for date: DateComponents) -> SPAParameters {
        return SPAParameters(
            date: date,
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
        var result = spa.calculate(.all)
        
        XCTAssertNotNil(result)
        
        XCTAssertEqual(spa.julianDate, 2456293.520833, accuracy: testAccuracy, "Inaccurate Julian Date Calculation")
        
        date = DateComponents(timeZone: .none, year: 2023, month: 7, day: 7, hour: 16, minute: 30, second: 6, nanosecond: 0)
        params = makeTestParams(for: date)
        
        spa = SPA(params: params)
        result = spa.calculate()
        
        XCTAssertEqual(spa.julianDate, 2460133.18757, accuracy: testAccuracy, "Inaccurate Julian Date Calculation")
    }
    
    /**
     * Check correct calculation of sunrise, transit and sunset values.
     *
     * This function uses the parameters and result values from Appendix A.5 at
     * [NREL-TP-560-34302](https://www.nrel.gov/docs/fy08osti/34302.pdf) (_Solar Position Algorithm for Solar Radiation Applications_).
     */
    func testSunriseSunTransitSunset() {
        var date = DateComponents(timeZone: .none, year: 2003, month: 10, day: 17, hour: 12, minute: 30, second: 30, nanosecond: 0)
        date.timeZone = TimeZone(secondsFromGMT: -7 * 3600)
        var params = SPAParameters(
            date: date,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786),
                altitude: 1830.14,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()))
        params.delta_t = 67
        params.delta_ut1 = 0
        params.pressure = 820
        params.temperature = 11
        params.atmosphericRefraction = 0.5667
        params.slope = 30
        params.azimuthRotation = -10
        
        let spa = SPA(params: params)
        let result = spa.calculate(SPAOptions.all)
        XCTAssertNotNil(result)

        XCTAssertEqual(result!.sunrise, 6.212067, accuracy: 1e-6)
        XCTAssertEqual(result!.suntransit, 11.768045, accuracy: 1e-6)
        XCTAssertEqual(result!.sunset, 17.338667, accuracy: 1e-6)
    }
    
    /**
     * Check correct calculation of baseline SPA parameters.
     *
     * This function uses the parameters and result values of the NREL C implementation test/sample code.
     */

    func testBaselineSPA() {
        var date = DateComponents(timeZone: .none, year: 2009, month: 7, day: 22, hour: 1, minute: 33, second: 0, nanosecond: 0)
        date.timeZone = .current
        var params = SPAParameters(
            date: date,
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
        let result = spa.calculate(SPAOptions.all)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.azimuth, 104.387917, accuracy: 1e-6)
        XCTAssertEqual(result!.zenith, 14.512686, accuracy: 1e-6)
        XCTAssertEqual(spa.earthHeliocentricLongitude, 299.4024, accuracy: 1e-4)
        XCTAssertEqual(spa.earthHeliocentricLatitude, -1.308E-5, accuracy: 1e-7)
        XCTAssertEqual(spa.earthRadiusVector, 1.016024, accuracy: 1e-6)
        XCTAssertEqual(spa.nutationLongitude, 4.441121e-3, accuracy: 1e-7)
        XCTAssertEqual(spa.nutationObliquity, 1.203311e-3, accuracy: 1e-7)
    }

    static var allTests = [
        ("testJulianDate", testJulianDate),
        ("testBaselineSPA", testBaselineSPA),
        ("testSunriseSunTransitSunset", testSunriseSunTransitSunset)
    ]
}
