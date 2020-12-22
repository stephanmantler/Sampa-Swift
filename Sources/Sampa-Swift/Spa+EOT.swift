//
//  File.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

let JD_COUNT = 3
let JD_MINUS = 0
let JD_ZERO = 1
let JD_PLUS = 2
let SUN_COUNT = 3
let SUN_TRANSIT = 0
let SUN_RISE = 1
let SUN_SET = 2

extension SPA {
    func sun_mean_longitude(_ jme: Double) -> Double
    {
        return Utils.limit_degrees(280.4664567 + jme*(360007.6982779 + jme*(0.03032028 +
                        jme*(1/49931.0   + jme*(-1/15300.0     + jme*(-1/2000000.0))))))
    }

    func limit_minutes(_ minutes: Double) -> Double
    {
        var limited=minutes

        if      (limited < -20.0) { limited = limited + 1440.0 }
        else if (limited >  20.0) { limited = limited - 1440.0 }

        return limited
    }


    func eot(_ m: Double, _ alpha: Double, _ del_psi: Double, _ epsilon: Double) -> Double
    {
        return limit_minutes(4.0*(m - 0.0057183 - alpha + del_psi*cos(Utils.deg2rad(epsilon))))
    }

    func approx_sun_transit_time(_ alpha_zero: Double, _ longitude: Double, _ nu: Double) -> Double
    {
        return (alpha_zero - longitude - nu) / 360.0
    }


    func limit_degrees180pm(_ degrees: Double) -> Double
    {
        let deg = degrees / 360.0
        var limited = 360.0*(deg-floor(deg))
        if      (limited < -180.0) { limited = limited + 360.0 }
        else if (limited >  180.0) { limited = limited - 360.0 }

        return limited
    }

    func limit_degrees180(_ degrees: Double) -> Double
    {
        let deg = degrees / 180.0
        var limited = 180.0*(deg-floor(deg))
        if (limited < 0) { limited = limited + 180.0 }

        return limited
    }

    func sun_hour_angle_at_rise_set(_ latitude: Double, _ delta_zero: Double, _ h0_prime: Double) -> Double
    {
        var h0: Double             = -99999
        let latitude_rad: Double   = Utils.deg2rad(latitude)
        let delta_zero_rad: Double = Utils.deg2rad(delta_zero)
        let argument: Double       = (sin(Utils.deg2rad(h0_prime)) - sin(latitude_rad)*sin(delta_zero_rad)) /
                                                         (cos(latitude_rad)*cos(delta_zero_rad))

        if (fabs(argument) <= 1) {
            h0 = limit_degrees180(Utils.rad2deg(acos(argument)))
        }

        return h0
    }

    func rts_alpha_delta_prime(_ ad: [Double], _ n: Double) -> Double
    {
        var a = ad[JD_ZERO] - ad[JD_MINUS]
        var b = ad[JD_PLUS] - ad[JD_ZERO]

        if (fabs(a) >= 2.0) { a = limit_zero2one(a) }
        if (fabs(b) >= 2.0) { b = limit_zero2one(b) }

        return ad[JD_ZERO] + n * (a + b + (b-a)*n)/2.0
    }

    func rts_sun_altitude(_ latitude: Double, _ delta_prime: Double, _ h_prime: Double) -> Double
    {
        let latitude_rad    = Utils.deg2rad(latitude)
        let delta_prime_rad = Utils.deg2rad(delta_prime)

        return Utils.rad2deg(asin(sin(latitude_rad)*sin(delta_prime_rad) +
                                    cos(latitude_rad)*cos(delta_prime_rad)*cos(Utils.deg2rad(h_prime))))
    }
    
    func limit_zero2one(_ value: Double) -> Double
    {
        var limited = value - floor(value)
        if (limited < 0) { limited = limited + 1.0 }

        return limited
    }


    func dayfrac_to_local_hr(_ dayfrac: Double, _ timezone: Double) -> Double
    {
        return 24.0*limit_zero2one(dayfrac + timezone/24.0)
    }
    
    func approx_sun_rise_and_set(_ m_rts: [Double], _ h0: Double) -> [Double]
    {
        let h0_dfrac = h0/360.0
        var r: [Double] = Array(repeating: 0, count: 3)
        
        r[SUN_RISE]    = limit_zero2one(m_rts[SUN_TRANSIT] - h0_dfrac)
        r[SUN_SET]     = limit_zero2one(m_rts[SUN_TRANSIT] + h0_dfrac)
        r[SUN_TRANSIT] = limit_zero2one(m_rts[SUN_TRANSIT])
        
        return r
    }
    
    func sun_rise_and_set(
        _ m_rts: [Double],
        _ h_rts: [Double],
        _ delta_prime: [Double],
        _ latitude: Double,
        _ h_prime: [Double],
        _ h0_prime: Double,
        _ sun: Int) -> Double
    {
        return m_rts[sun] + (h_rts[sun] - h0_prime) /
            (360.0*cos(Utils.deg2rad(delta_prime[sun]))*cos(Utils.deg2rad(latitude))*sin(Utils.deg2rad(h_prime[sun])))
    }

    func calculate_eot_and_sun_rise_transit_set() -> (Double, Double, Double)
    {
        let sun_rts = SPA(params: self.params)
        var nu: Double
        var m: Double
        var h0: Double
        var n: Double
        var alpha: [Double] = Array(repeating: 0, count: JD_COUNT)
        var delta: [Double] = Array(repeating: 0, count: JD_COUNT)
        var m_rts: [Double] = Array(repeating:0, count: SUN_COUNT)
        var nu_rts: [Double] = Array(repeating: 0, count: JD_COUNT)
        var h_rts: [Double] = Array(repeating: 0, count: JD_COUNT)
        var alpha_prime: [Double] = Array(repeating: 0, count: JD_COUNT)
        var delta_prime: [Double] = Array(repeating: 0, count: JD_COUNT)
        var h_prime: [Double] = Array(repeating: 0, count: JD_COUNT)
        
        let h0_prime = -1*(Utils.SUN_RADIUS + params.atmosphericRefraction)

        m        = sun_mean_longitude(julianEphemerisMillennium)
        equationOfTime = eot(m, self.geocentricSunRightAscension, nutationLongitude, eclipticTrueObliquity)

        sun_rts.params.date.hour = 0
        sun_rts.params.date.minute = 0
        sun_rts.params.date.second = 0
        sun_rts.params.delta_ut1 = 0
        sun_rts.params.date.timeZone = TimeZone(secondsFromGMT: 0)!

        sun_rts.julianDate = sun_rts.calculateJulianDay()
        sun_rts.calculate_geocentric_sun_right_ascension_and_declination()

        nu = sun_rts.greenwichSiderealTime

        sun_rts.params.delta_t = 0
        sun_rts.julianDate = sun_rts.julianDate - 1
        
        for i in 0..<JD_COUNT {
            sun_rts.calculate_geocentric_sun_right_ascension_and_declination()
            alpha[i] = sun_rts.geocentricSunRightAscension
            delta[i] = sun_rts.geocentricSunDeclination
            sun_rts.julianDate = sun_rts.julianDate + 1
        }

        m_rts[SUN_TRANSIT] = approx_sun_transit_time(
            alpha[JD_ZERO], params.location.coordinate.longitude, nu)
        h0 = sun_hour_angle_at_rise_set(
            params.location.coordinate.latitude, delta[JD_ZERO], h0_prime)

        if (h0 >= 0) {

            m_rts = approx_sun_rise_and_set(m_rts, h0)

            for i in 0..<SUN_COUNT {

                nu_rts[i]      = nu + 360.985647*m_rts[i]

                n              = m_rts[i] + params.delta_t/86400.0
                alpha_prime[i] = rts_alpha_delta_prime(alpha, n)
                delta_prime[i] = rts_alpha_delta_prime(delta, n)

                h_prime[i]     = limit_degrees180pm(
                    nu_rts[i] + params.location.coordinate.longitude - alpha_prime[i])

                h_rts[i]       = rts_sun_altitude(
                    params.location.coordinate.latitude, delta_prime[i], h_prime[i])
            }

            sunriseHourAngle = h_prime[SUN_RISE]
            sunsetHourAngle = h_prime[SUN_SET]
            sunTransitAltitude  = h_rts[SUN_TRANSIT]

            let suntransit = dayfrac_to_local_hr(
                m_rts[SUN_TRANSIT] - h_prime[SUN_TRANSIT] / 360.0,
                Double(params.date.timeZone?.secondsFromGMT() ?? 0)/3600.0)

            let sunrise = dayfrac_to_local_hr(
                sun_rise_and_set(
                    m_rts, h_rts, delta_prime,
                    params.location.coordinate.latitude,
                    h_prime, h0_prime, SUN_RISE),
                Double(params.date.timeZone?.secondsFromGMT() ?? 0)/3600.0)

            let sunset  = dayfrac_to_local_hr(
                sun_rise_and_set(
                    m_rts, h_rts, delta_prime,
                    params.location.coordinate.latitude,
                    h_prime, h0_prime, SUN_SET),
                Double(params.date.timeZone?.secondsFromGMT() ?? 0)/3600.0)

            return (sunrise, suntransit, sunset)
        }
        return (.nan, .nan, .nan)
    }
}
