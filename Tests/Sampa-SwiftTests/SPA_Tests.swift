import XCTest
@testable import SaMPA

final class SPA_Tests: XCTestCase {
    
    func makeTestParams(for date: Date) -> SPAParameters {
        return SPAParameters(
            date: date,
            timeZone: TimeZone(secondsFromGMT: 0)!,
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
        
        var dateComponents = DateComponents(timeZone: .none, year: 2013, month: 1, day: 1, hour: 0, minute: 30, second: 0, nanosecond: 0)
        let calendar = Calendar(identifier: .iso8601)
        var date = calendar.date(from: dateComponents)!
        var params = makeTestParams(for: calendar.date(from: dateComponents)!)
        
        var spa = SPA(params: params)
        var result = spa.calculate(.all)
        
        // alternative pathway to julian date
        let ts = (date.timeIntervalSince1970 / 86400.0 ) + 2440587.5+JulianDateParameters.delta_ut1/86400;
        
        XCTAssertEqual(date.julianDate, ts, accuracy: 1/10/86400, "conversion mismatch")
        
        XCTAssertNotNil(result)
        
        XCTAssertEqual(date.julianDate, 2456293.520833, accuracy: testAccuracy, "Inaccurate Julian Date Calculation")
        
        dateComponents = DateComponents(timeZone: .none, year: 2023, month: 7, day: 7, hour: 16, minute: 30, second: 6, nanosecond: 0)
        date = calendar.date(from: dateComponents)!

        params = makeTestParams(for: date)
        
        spa = SPA(params: params)
        result = spa.calculate()
        
        XCTAssertEqual(date.julianDate, 2460133.18757, accuracy: testAccuracy, "Inaccurate Julian Date Calculation")
    }
    
    /**
     * Check correct calculation of sunrise, transit and sunset values.
     *
     * This function uses the parameters and result values from Appendix A.5 at
     * [NREL-TP-560-34302](https://www.nrel.gov/docs/fy08osti/34302.pdf) (_Solar Position Algorithm for Solar Radiation Applications_).
     */
    func testSunriseSunTransitSunset() {
        var dateComponents = DateComponents(timeZone: .none, year: 2003, month: 10, day: 17, hour: 12, minute: 30, second: 30, nanosecond: 0)
        dateComponents.timeZone = TimeZone(secondsFromGMT: -7 * 3600)!
        let calendar = Calendar(identifier: .iso8601)
        let date = calendar.date(from: dateComponents)!
        var params = SPAParameters(
            date: date,
            timeZone: dateComponents.timeZone!,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786),
                altitude: 1830.14,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()))
        JulianDateParameters.delta_t = 67
        JulianDateParameters.delta_ut1 = 0
        params.pressure = 820
        params.temperature = 11
        params.atmosphericRefraction = 0.5667
        params.slope = 30
        params.azimuthRotation = -10
        
        let spa = SPA(params: params)
        let result = spa.calculate(SPAOptions.all)
        XCTAssertNotNil(result)
        
        XCTAssertEqual(JulianDateParameters.delta_t, 67)
        XCTAssertEqual(JulianDateParameters.delta_ut1, 0)
        
        XCTAssertEqual(spa.params.date.julianDate, 2452930.312847, accuracy: 0.025/86400, "jd")

        XCTAssertEqual(spa.earthHeliocentricLongitude, 24.0182616917, accuracy: 1e-7, "l")
        XCTAssertEqual(spa.earthHeliocentricLatitude, -0.0001011219, accuracy: 1e-7, "b")
        XCTAssertEqual(spa.earthRadiusVector, 0.9965422974, accuracy: 1e-7, "r")
        XCTAssertEqual(spa.geocentricLongitude, 204.0182616917, accuracy: 1e-7, "theta")
        XCTAssertEqual(spa.geocentricLatitude, 0.0001011219, accuracy: 1e-7, "beta")
        
        XCTAssertEqual(spa.nutationLongitude, -0.00399840, accuracy: 1e-7, "del_psi")
        XCTAssertEqual(spa.nutationObliquity, 0.00166657, accuracy: 1e-7, "del_epsilon")
        XCTAssertEqual(spa.eclipticTrueObliquity, 23.440465, accuracy: 1e-6, "epsilon")
        XCTAssertEqual(spa.apparentSunLongitude, 204.008551928, accuracy: 1e-7, "lamda")

        XCTAssertEqual(spa.sunEquatorialHorizontalParallax, 0.00245125, accuracy: 1e-7, "xi")
        XCTAssertEqual(spa.geocentricSunRightAscension, 202.22741, accuracy: 1e-5, "alpha")
        XCTAssertEqual(spa.topocentricSunDeclination, -9.316179, accuracy: 1e-6, "delta_prime")
        
        XCTAssertEqual(spa.greenwichSiderealTime, 318.5119098, accuracy: 1e-7, "nu")
        XCTAssertEqual(spa.greenwichMeanSiderealTime, 318.51557827, accuracy: 1e-7, "nu0")
        XCTAssertEqual(spa.topocentricSunRightAscension, 202.22704, accuracy:1e-5, "alpha_prime")
        XCTAssertEqual(spa.sunRightAscensionParallax, -0.00036853, accuracy:1e-7, "del_alpha")
        XCTAssertEqual(spa.observerHourAngle, 11.10590201, accuracy: 1e-7, "h")
        XCTAssertEqual(spa.topocentricLocalHourAngle, 11.10627055, accuracy:1e-5, "h_prime")

        XCTAssertEqual(spa.topocentricElevationAngle, 39.87204590, accuracy: 1e-7, "e0")
        XCTAssertEqual(spa.topocentricElevationAngleCorrected, 39.88837798, accuracy: 1e-6, "e")
        XCTAssertEqual(spa.atmosphericRefractionCorrection, 0.01633207, accuracy: 1e-7, "del_e")
        XCTAssertEqual(spa.equationOfTime, 14.641503, accuracy: 1e-5, "eot")
        XCTAssertEqual(result!.zenith, 50.11162202, accuracy: 1e-6, "topocentric zenith")
        XCTAssertEqual(result!.azimuth, 194.34024051, accuracy: 1e-6, "topocentric azimuth")

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
        var dateComponents = DateComponents(timeZone: .none, year: 2009, month: 7, day: 22, hour: 1, minute: 33, second: 0, nanosecond: 0)
        dateComponents.timeZone = .current
        let calendar = Calendar(identifier: .iso8601)
        let date = calendar.date(from: dateComponents)!
        var params = SPAParameters(
            date: date,
            timeZone: dateComponents.timeZone!,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 24.61167, longitude: 143.36167),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()))
        JulianDateParameters.delta_t = 66.4
        JulianDateParameters.delta_ut1 = 0
        params.pressure = 1000
        params.temperature = 11
        params.atmosphericRefraction = 0.5667
        
        let spa = SPA(params: params)
        let result = spa.calculate(SPAOptions.all)
        XCTAssertNotNil(result)
        XCTAssertEqual(spa.earthHeliocentricLongitude, 299.4024, accuracy: 1e-4)
        XCTAssertEqual(spa.earthHeliocentricLatitude, -1.308E-5, accuracy: 1e-7)
        XCTAssertEqual(spa.earthRadiusVector, 1.016024, accuracy: 1e-6)
        XCTAssertEqual(spa.nutationLongitude, 4.441121e-3, accuracy: 1e-7)
        XCTAssertEqual(spa.nutationObliquity, 1.203311e-3, accuracy: 1e-7)
        XCTAssertEqual(result!.azimuth, 104.387917, accuracy: 1e-6)
        XCTAssertEqual(result!.zenith, 14.512686, accuracy: 1e-6)
    }

    static var allTests = [
        ("testJulianDate", testJulianDate),
        ("testBaselineSPA", testBaselineSPA),
        ("testSunriseSunTransitSunset", testSunriseSunTransitSunset)
    ]
}
