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
