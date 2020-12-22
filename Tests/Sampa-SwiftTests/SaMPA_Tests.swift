//
//  File.swift
//  
//
//  Created by stephan mantler on 22.12.2020.
//

import Foundation

import XCTest
@testable import Sampa_Swift

final class SaMPA_Tests: XCTestCase {
    
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
    
    func testSunMoon() {
        
        let date = DateComponents(timeZone: .none, year: 2003, month: 10, day: 17, hour: 12, minute: 30, second: 30, nanosecond: 0)
        var params = SPAParameters(
            date: date,
            timezone: TimeZone(secondsFromGMT: -7 * 3600)!,
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
}
