//
//  File.swift
//  
//
//  Created by stephan mantler on 22.12.2020.
//

import Foundation

import XCTest
@testable import SaMPA

final class SaMPA_Tests: XCTestCase {
    
    func makeTestParams(for dateComponents: DateComponents) -> SPAParameters {
        let cal = Calendar(identifier: .iso8601)
        let date = cal.date(from: dateComponents)!
        return SPAParameters(
            date: date,
            timeZone: dateComponents.timeZone!,
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 64.1466,longitude: -21.9426) /* Reykjavík, Iceland */,
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()))
    }
    
    // currently disabled pending test data availability
    func disabledTestRandomDataset() {
        
        // stop on the first error
        continueAfterFailure = false
        
        guard let dataString = CSVTestUtility.readDataFromCSV(named: "TestData/smaller.csv") else {
            XCTFail("dataset load failed, aborting all further tests")
            return
        }
        var data: [[Double]] = []
        // let's see how long it takes.
        measure(metrics: [XCTClockMetric()]) { data = CSVTestUtility.csv(data: dataString) }
            
        XCTAssertTrue(data[0].count == 24)
            
        for row in data {
            /* CSV is:
             0 Year         1 Month     2 Day       3 Hour        4 Minute    5 Second
             6 Delta UT1    7 Delta T   8 Timezone  9 Longitude  10 Latitude 11 Elevation
             12 Pressure    13 Temp.   14  Slope   15 Azm Rotation      16 Atmos Refract
             - output -
             17 Zenith      18 Azimuth Astro  19 Azimuth
             20 Incidence   21 Sun Transit   22 Sunrise 23 Sunset */
            /* create sample data from CSV row */
            
            var dateComponents = DateComponents(timeZone: .none, year: Int(row[0]), month: Int(row[1]), day: Int(row[2]), hour: Int(row[3]), minute: Int(row[4]), second: Int(row[5]), nanosecond: 0)
            dateComponents.timeZone = TimeZone(secondsFromGMT: Int(row[8] * 3600))
            let cal = Calendar(identifier: .iso8601)
            let date = cal.date(from: dateComponents)!
            var params = SPAParameters(
                date: date,
                timeZone: dateComponents.timeZone!,
                location: CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: row[10], longitude: row[9]),
                    altitude: row[11],
                    horizontalAccuracy: 0,
                    verticalAccuracy: 0,
                    timestamp: Date()))
            JulianDateParameters.delta_t = row[7]
            JulianDateParameters.delta_ut1 = row[6]
            params.pressure = row[12]
            params.temperature = row[13]
            params.atmosphericRefraction = row[16]
            params.slope = row[14]
            params.azimuthRotation = row[15]
            
            let sampa = SaMPA()
            let result = sampa.calculate(with: params)
            // requires valid result
            XCTAssertNotNil(result)
            // requires spa and mpa are initialized
            XCTAssertNotNil(sampa.spa)
            XCTAssertNotNil(sampa.mpa)
            
            // requires output to match expected values
            /*
            XCTAssertEqual(result!.sun.zenith, row[17], accuracy: 1/3600.0)
            XCTAssertEqual(result!.sun.azimuth_astro, row[18], accuracy: 1/3600.0)
            XCTAssertEqual(result!.sun.azimuth, row[19], accuracy: 1/3600.0)
             */
            XCTAssertEqual(result!.sun.sunrise, row[22], accuracy: 1/3600.0)
            XCTAssertEqual(result!.sun.suntransit, row[21], accuracy: 1/3600.0)
            XCTAssertEqual(result!.sun.sunset, row[23], accuracy: 1/3600.0)
        }
    }
    
    func testSunMoon() {
        
        var dateComponents = DateComponents(timeZone: .none, year: 2003, month: 10, day: 17, hour: 12, minute: 30, second: 30, nanosecond: 0)
        dateComponents.timeZone = TimeZone(secondsFromGMT: -7 * 3600)
        let cal = Calendar(identifier: .iso8601)
        let date = cal.date(from: dateComponents)!

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
        
        let sampa = SaMPA()
        let result = sampa.calculate(with: params)
        // requires valid result
        XCTAssertNotNil(result)
        // requires spa and mpa are initialized
        XCTAssertNotNil(sampa.spa)
        XCTAssertNotNil(sampa.mpa)
        XCTAssertEqual(result!.ems, 98.516815, accuracy: 1e-6, "angular distance incorrect")
        XCTAssertEqual(result!.rs, 0.267489, accuracy: 1e-6, "sun radius incorrect")
        XCTAssertEqual(result!.rm, 0.250359, accuracy: 1e-6, "moon radius incorrect")
    }
    
    static var allTests = [
        ("testSunMoon", testSunMoon)
    ]

}
