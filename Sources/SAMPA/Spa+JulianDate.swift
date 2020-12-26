//
//  File.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

class JulianDateParameters {
    static let shared = JulianDateParameters()
    
    var _delta_ut1 = -0.2
    var _delta_t = 32.184 + 37 + 0.2
    
    /// DUT1 from https://datacenter.iers.org/data/latestVersion/6_BULLETIN_A_V2013_016.txt
    static var delta_ut1: Double  {
        get { return shared._delta_ut1 }
        set(value) { shared._delta_ut1 = value }
    }
    
    /// same source as DUT1. delta_t = 32.184 + (TAI-UTC) - DUT1
    static var delta_t: Double  {
        get { return shared._delta_t }
        set(value) { shared._delta_t = value }
    }
}

extension Date {
    var julianDate : Double {
        get {
            return ( ( self.timeIntervalSince1970 + JulianDateParameters.delta_ut1 ) / 86400.0 ) + 2440587.5
        }
    }
    /*
    func calculateJulianDay() -> Double
    {
        var day_decimal: Double
        var julian_day: Double
        var a: Double
        
        //let calendar = Calendar(identifier: .iso8601)
        let dc = params.date// calendar.dateComponents(in: params.timezone, from: params.time)

        day_decimal = Double(dc.day!) + (Double(dc.hour!) - Double(dc.timeZone?.secondsFromGMT() ?? 0)/3600 + (Double(dc.minute!) + (Double(dc.second!) + params.delta_ut1)/60.0)/60.0)/24.0

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
    } */
    
    var julianCentury : Double {
        get
        {
            return (julianDate - 2451545.0)/36525.0
        }
    }

    var julianEphemerisDay: Double {
        get
        {
            return self.julianDate + JulianDateParameters.delta_t/86400.0
        }
    }

    var julianEphemerisCentury: Double {
        get
        {
            return (self.julianEphemerisDay - 2451545.0)/36525.0
        }
    }

    var julianEphemerisMillennium: Double {
        get
        {
            return (self.julianEphemerisCentury/10.0)
        }
    }

}
