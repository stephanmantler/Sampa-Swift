//
//  File.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

extension SPA {
    func calculateJulianDay() -> Double
    {
        var day_decimal: Double
        var julian_day: Double
        var a: Double
        
        //let calendar = Calendar(identifier: .iso8601)
        let dc = params.date// calendar.dateComponents(in: params.timezone, from: params.time)

        day_decimal = Double(dc.day!) + (Double(dc.hour!) - Double(params.timezone.secondsFromGMT())/3600 + (Double(dc.minute!) + (Double(dc.second!) + params.delta_ut1)/60.0)/60.0)/24.0

        var month = Double(dc.month!)
        var year = Double(dc.year!)
        if (month < 3) {
            month += 12
            year -= 1
        }

        julian_day = (365.25*(year+4716.0)).rounded(.down) + (30.6001*(month+1)).rounded(.down) + day_decimal - 1524.5

        if (julian_day > 2299160.0) {
            a = (year/100).rounded(.down)
            julian_day += (2 - a + (a/4).rounded(.down))
        }

        return julian_day;
    }
    
    func julianCentury(_ jd: Double) -> Double
    {
        return (jd-2451545.0)/36525.0
    }

    func julianEphemerisDay(_ jd: Double, _ delta_t: Double) -> Double
    {
        return jd+delta_t/86400.0
    }

    func julianEphemerisCentury(_ jde: Double) -> Double
    {
        return (jde - 2451545.0)/36525.0
    }

    func julianEphemerisMillennium(_ jce: Double) -> Double
    {
        return (jce/10.0)
    }

}
