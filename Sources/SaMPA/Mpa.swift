//
//  File.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

public struct MPAResult {
    /// topocentric zenith angle [degrees]
    public var zenith: Double = .nan
    /// topocentric azimuth angle (westward from south) [for astronomers]
    public var azimuth_astro: Double = .nan
    /// topocentric azimuth angle (eastward from north) [for navigators and solar radiation]
    public var azimuth: Double = .nan
}

public class MPA {
    let TERM_D = 0
    let TERM_M = 1
    let TERM_MPR = 2
    let TERM_F = 3
    let TERM_LB = 4
    let TERM_R = 5
    
    //-----------------Intermediate MPA OUTPUT VALUES--------------------
    
    /// moon mean longitude [degrees]
    var l_prime: Double = .nan;
    /// moon mean elongation [degrees]
    var d: Double = .nan
    /// sun mean anomaly [degrees]
    var m: Double = .nan
    /// moon mean anomaly [degrees]
    var m_prime: Double = .nan
    /// moon argument of latitude [degrees]
    var f: Double = .nan
    /// term l
    var l: Double = .nan
    /// term r
    var r: Double = .nan
    /// term b
    var b: Double = .nan
    /// moon longitude [degrees]
    var lamda_prime: Double = .nan
    /// moon latitude [degrees]
    var beta: Double = .nan
    /// distance from earth to moon [kilometers]
    var cap_delta: Double = .nan
    /// moon equatorial horizontal parallax [degrees]
    var pi: Double = .nan
    /// apparent moon longitude [degrees]
    var lamda: Double = .nan
    
    /// geocentric moon right ascension [degrees]
    var alpha: Double = .nan
    /// geocentric moon declination [degrees]
    var delta: Double = .nan
    
    /// observer hour angle [degrees]
    var h: Double = .nan
    /// moon right ascension parallax [degrees]
    var del_alpha: Double = .nan
    /// topocentric moon declination [degrees]
    var delta_prime: Double = .nan
    /// topocentric moon right ascension [degrees]
    var alpha_prime: Double = .nan
    /// topocentric local hour angle [degrees]
    var h_prime: Double = .nan
    
    /// topocentric elevation angle (uncorrected) [degrees]
    var e0: Double = .nan
    /// atmospheric refraction correction [degrees]
    var del_e: Double = .nan
    /// topocentric elevation angle (corrected) [degrees]
    var e: Double = .nan
    
    ///////////////////////////////////////////////////////
    ///  Moon's Periodic Terms for Longitude and Distance
    ///////////////////////////////////////////////////////
    let ML_TERMS: [[Double]] =
        [[0,0,1,0,6288774,-20905355], [2,0,-1,0,1274027,-3699111], [2,0,0,0,658314,-2955968], [0,0,2,0,213618,-569925], [0,1,0,0,-185116,48888], [0,0,0,2,-114332,-3149], [2,0,-2,0,58793,246158], [2,-1,-1,0,57066,-152138], [2,0,1,0,53322,-170733], [2,-1,0,0,45758,-204586], [0,1,-1,0,-40923,-129620], [1,0,0,0,-34720,108743], [0,1,1,0,-30383,104755], [2,0,0,-2,15327,10321], [0,0,1,2,-12528,0], [0,0,1,-2,10980,79661], [4,0,-1,0,10675,-34782], [0,0,3,0,10034,-23210], [4,0,-2,0,8548,-21636], [2,1,-1,0,-7888,24208], [2,1,0,0,-6766,30824], [1,0,-1,0,-5163,-8379], [1,1,0,0,4987,-16675], [2,-1,1,0,4036,-12831], [2,0,2,0,3994,-10445], [4,0,0,0,3861,-11650], [2,0,-3,0,3665,14403], [0,1,-2,0,-2689,-7003], [2,0,-1,2,-2602,0], [2,-1,-2,0,2390,10056], [1,0,1,0,-2348,6322], [2,-2,0,0,2236,-9884], [0,1,2,0,-2120,5751], [0,2,0,0,-2069,0], [2,-2,-1,0,2048,-4950], [2,0,1,-2,-1773,4130], [2,0,0,2,-1595,0], [4,-1,-1,0,1215,-3958], [0,0,2,2,-1110,0], [3,0,-1,0,-892,3258], [2,1,1,0,-810,2616], [4,-1,-2,0,759,-1897], [0,2,-1,0,-713,-2117], [2,2,-1,0,-700,2354], [2,1,-2,0,691,0], [2,-1,0,-2,596,0], [4,0,1,0,549,-1423], [0,0,4,0,537,-1117], [4,-1,0,0,520,-1571], [1,0,-2,0,-487,-1739], [2,1,0,-2,-399,0], [0,0,2,-2,-381,-4421], [1,1,1,0,351,0], [3,0,-2,0,-340,0], [4,0,-3,0,330,0], [2,-1,2,0,327,0], [0,2,1,0,-323,1165], [1,1,-1,0,299,0], [2,0,3,0,294,0], [2,0,-1,-2,0,8752]]
    ///////////////////////////////////////////////////////
    ///  Moon's Periodic Terms for Latitude
    ///////////////////////////////////////////////////////
    let MB_TERMS: [[Double]] =
        [[0,0,0,1,5128122,0], [0,0,1,1,280602,0], [0,0,1,-1,277693,0], [2,0,0,-1,173237,0], [2,0,-1,1,55413,0], [2,0,-1,-1,46271,0], [2,0,0,1,32573,0], [0,0,2,1,17198,0], [2,0,1,-1,9266,0], [0,0,2,-1,8822,0], [2,-1,0,-1,8216,0], [2,0,-2,-1,4324,0], [2,0,1,1,4200,0], [2,1,0,-1,-3359,0], [2,-1,-1,1,2463,0], [2,-1,0,1,2211,0], [2,-1,-1,-1,2065,0], [0,1,-1,-1,-1870,0], [4,0,-1,-1,1828,0], [0,1,0,1,-1794,0], [0,0,0,3,-1749,0], [0,1,-1,1,-1565,0], [1,0,0,1,-1491,0], [0,1,1,1,-1475,0], [0,1,1,-1,-1410,0], [0,1,0,-1,-1344,0], [1,0,0,-1,-1335,0], [0,0,3,1,1107,0], [4,0,0,-1,1021,0], [4,0,-1,1,833,0], [0,0,1,-3,777,0], [4,0,-2,1,671,0], [2,0,0,-3,607,0], [2,0,2,-1,596,0], [2,-1,1,-1,491,0], [2,0,-2,1,-451,0], [0,0,3,-1,439,0], [2,0,2,1,422,0], [2,0,-3,-1,421,0], [2,1,-1,1,-366,0], [2,1,0,1,-351,0], [4,0,0,1,331,0], [2,-1,1,1,315,0], [2,-2,0,-1,302,0], [0,0,1,3,-283,0], [2,1,1,-1,-229,0], [1,1,0,-1,223,0], [1,1,0,1,223,0], [0,1,-2,-1,-220,0], [2,1,-1,-1,-220,0], [1,0,1,1,-185,0], [2,-1,-2,-1,181,0], [0,1,2,1,-177,0], [4,0,-2,-1,176,0], [4,-1,-1,-1,166,0], [1,0,1,-1,-164,0], [4,0,1,-1,132,0], [1,0,-1,-1,-119,0], [4,-1,0,-1,115,0], [2,-2,0,1,107,0]]
    ///////////////////////////////////////////////////////////////////////////////////////////////
    
    func moon_mean_longitude(_ jce: Double) -> Double
    {
        return Utils.limit_degrees(Utils.fourth_order_polynomial(
                             -1.0/65194000, 1.0/538841, -0.0015786, 481267.88123421, 218.3164477, jce))
    }

    func moon_mean_elongation(_ jce: Double) -> Double
    {
        return Utils.limit_degrees(Utils.fourth_order_polynomial(
                             -1.0/113065000, 1.0/545868, -0.0018819, 445267.1114034, 297.8501921, jce))
    }

    func sun_mean_anomaly(_ jce: Double) -> Double
    {
        return Utils.limit_degrees(Utils.third_order_polynomial(
                             1.0/24490000, -0.0001536, 35999.0502909, 357.5291092, jce))
    }

    func moon_mean_anomaly(_ jce: Double) -> Double
    {
        return Utils.limit_degrees(Utils.fourth_order_polynomial(
                             -1.0/14712000, 1.0/69699, 0.0087414, 477198.8675055, 134.9633964, jce))
    }

    func moon_latitude_argument(_ jce: Double) ->Double
    {
        return Utils.limit_degrees(Utils.fourth_order_polynomial(
                             1.0/863310000, -1.0/3526000, -0.0036539, 483202.0175233, 93.2720950, jce));
    }

    func moon_periodic_term_summation(_ d: Double, _ m: Double, _ m_prime: Double,
                                      _ f: Double, _ jce: Double,
                                      _ terms: [[Double]]) -> (Double, Double)
    {
        var e_mult: Double
        var trig_arg: Double
        let e  = 1.0 - jce*(0.002516 + jce*0.0000074)
        
        var sin_sum: Double = 0
        var cos_sum: Double = 0

        for i in 0..<terms.count {
            e_mult   = pow(e, fabs(terms[i][TERM_M]));
            trig_arg = Utils.deg2rad(terms[i][TERM_D]*d + terms[i][TERM_M] * m +
                               terms[i][TERM_F]*f + terms[i][TERM_MPR] * m_prime);
            sin_sum = sin_sum + e_mult * terms[i][TERM_LB] * sin(trig_arg);
            cos_sum = cos_sum + e_mult * terms[i][TERM_R]  * cos(trig_arg);
        }
        return (sin_sum, cos_sum)
    }

    func moon_longitude_and_latitude(_ jce: Double, _ l_prime: Double, _ f: Double, _ m_prime: Double, _ l: Double, _ b: Double) -> (Double, Double)
    //                                                                          double *lamda_prime, double *beta)
    {
        let a1 = 119.75 +    131.849*jce
        let a2 =  53.09 + 479264.290*jce
        let a3 = 313.45 + 481266.484*jce
        let delta_l =  3958*sin(Utils.deg2rad(a1))      + 318*sin(Utils.deg2rad(a2))   + 1962*sin(Utils.deg2rad(l_prime-f))
        let delta_b = -2235*sin(Utils.deg2rad(l_prime)) + 175*sin(Utils.deg2rad(a1-f)) +  127*sin(Utils.deg2rad(l_prime-m_prime))
            + 382*sin(Utils.deg2rad(a3))      + 175*sin(Utils.deg2rad(a1+f)) -  115*sin(Utils.deg2rad(l_prime+m_prime));

        let lamda_prime = Utils.limit_degrees(l_prime + (l + delta_l)/1000000)
        let beta        = Utils.limit_degrees(          (b + delta_b)/1000000)
        
        return (lamda_prime, beta)
    }
    
    func moon_earth_distance(_ r: Double) -> Double
    {
        return 385000.56 + r/1000
    }

    func moon_equatorial_horiz_parallax(_ delta: Double) -> Double
    {
        return Utils.rad2deg(asin(6378.14/delta))
    }

    func apparent_moon_longitude(_ lamda_prime: Double, _ del_psi: Double) -> Double
    {
        return lamda_prime + del_psi
    }

    public func calculate(using spa: SPA) -> MPAResult
    {
        l_prime = moon_mean_longitude(spa.params.date.julianEphemerisCentury)
        d       = moon_mean_elongation(spa.params.date.julianEphemerisCentury)
        m       = sun_mean_anomaly(spa.params.date.julianEphemerisCentury)
        m_prime = moon_mean_anomaly(spa.params.date.julianEphemerisCentury)
        f       = moon_latitude_argument(spa.params.date.julianEphemerisCentury)
        
        let lr = moon_periodic_term_summation(d, m, m_prime, f, spa.params.date.julianEphemerisCentury, ML_TERMS)
        l = lr.0
        r = lr.1
        
        let b0 = moon_periodic_term_summation(d, m, m_prime, f, spa.params.date.julianEphemerisCentury, MB_TERMS)
        b = b0.0

        let lb =  moon_longitude_and_latitude(spa.params.date.julianEphemerisCentury, l_prime, f, m_prime, l, b)
        lamda_prime = lb.0
        beta = lb.1

        cap_delta = moon_earth_distance(r)
        pi = moon_equatorial_horiz_parallax(cap_delta)


        lamda = apparent_moon_longitude(lamda_prime, spa.nutationLongitude)
        alpha = Utils.geocentric_right_ascension(lamda, spa.eclipticTrueObliquity, beta)
        delta = Utils.geocentric_declination(beta, spa.eclipticTrueObliquity, lamda)

        h  = Utils.observer_hour_angle(spa.greenwichSiderealTime, spa.params.location.coordinate.longitude, alpha)

        
        let ap = Utils.right_ascension_parallax_and_topocentric_dec(
            spa.params.location.coordinate.latitude,
            spa.params.location.altitude, pi, h, delta)
        delta_prime = ap.0
        del_alpha = ap.1

        alpha_prime = Utils.topocentric_right_ascension(alpha, del_alpha)
        h_prime     = Utils.topocentric_local_hour_angle(h, del_alpha)

        e0      = Utils.topocentric_elevation_angle(spa.params.location.coordinate.latitude, delta_prime, h_prime)
        
        del_e   = Utils.atmospheric_refraction_correction(spa.params.pressure, spa.params.temperature,
                                                    spa.params.atmosphericRefraction, e0)
        e       = Utils.topocentric_elevation_angle_corrected(e0, del_e)

        
        var result = MPAResult()
        
        result.zenith        = Utils.topocentric_zenith_angle(e)
        result.azimuth_astro = Utils.topocentric_azimuth_angle_astro(h_prime, spa.params.location.coordinate.latitude, delta_prime);
        result.azimuth       = Utils.topocentric_azimuth_angle(result.azimuth_astro)
        
        return result
    }

}
