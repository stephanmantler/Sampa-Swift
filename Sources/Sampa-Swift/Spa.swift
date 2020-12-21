//
//  File.swift
//  
//
//  Created by stephan mantler on 20.12.2020.
//

import Foundation
import CoreLocation
import os

struct SPAOptions : OptionSet {
    let rawValue: Int
    
    static let zenithAzimuth = SPAOptions(rawValue: 1)
    static let incidence = SPAOptions(rawValue: 2)
    static let riseTransitSet = SPAOptions(rawValue: 4)
    
    static let all = [.zenithAzimuth, incidence, riseTransitSet]
}

struct SPAParameters {
    /// observer local time, including milliseconds
    var date: DateComponents

    /// DUT1 from https://datacenter.iers.org/data/latestVersion/6_BULLETIN_A_V2013_016.txt
    var delta_ut1: Double = -0.2
    /// same source as DUT1. delta_t = 32.184 + (TAI-UTC) - DUT1
    var delta_t: Double = 32.184 + 37 + 0.2

    /// Observer time zone (negative west of Greenwich)
    /// valid range: -18   to   18 hours
    var timezone: TimeZone

    /// Observer longitude/latitude/elevation
    /// longitude should be -180 to 180, lat -90-90,
    var location: CLLocation

    /// average local pressure (millibars)
    var pressure: Double = 1000

    /// annual average local temperature in °C
    var temperature: Double = 10

    /// surface slope measured from the horizontal plane
    var slope: Double = 0

    /// surface azimuth rotation (measured from south to projection of surface normal on horizonal plane, negative east)
    var azimuthRotation: Double = 0

    /// atmospheric refraction at sunrise and sunset (0.5667 deg is typical)
    var atmosphericRefraction: Double = 0.5667
}

struct SPAResult {
    /// topocentric zenith angle [degrees]
    var zenith: Double = .nan;
    /// topocentric azimuth angle (westward from south) [for astronomers]
    var azimuth_astro: Double = .nan;
    /// topocentric azimuth angle (eastward from north) [for navigators and solar radiation]
    var azimuth: Double = .nan;
    /// surface incidence angle [degrees]
    var incidence: Double = .nan;

    /// local sun transit time (or solar noon) [fractional hour]
    var suntransit: Double = .nan;
    //local sunrise time (+/- 30 seconds) [fractional hour]
    var sunrise: Double = .nan;
    //local sunset time (+/- 30 seconds) [fractional hour]
    var sunset: Double = .nan;
}

class SPA {
    let params: SPAParameters
    
    // MARK: General parameters
    let SUN_RADIUS = 0.26667
    
    // MARK: Earth periodic terms
    let L_TERMS /* [L_COUNT][L_MAX_SUBCOUNT][TERM_COUNT]*/ =
    [
        [
            [175347046.0,0,0], [3341656.0,4.6692568,6283.07585], [34894.0,4.6261,12566.1517], [3497.0,2.7441,5753.3849], [3418.0,2.8289,3.5231], [3136.0,3.6277,77713.7715], [2676.0,4.4181,7860.4194], [2343.0,6.1352,3930.2097], [1324.0,0.7425,11506.7698], [1273.0,2.0371,529.691], [1199.0,1.1096,1577.3435], [990,5.233,5884.927], [902,2.045,26.298], [857,3.508,398.149], [780,1.179,5223.694], [753,2.533,5507.553], [505,4.583,18849.228], [492,4.205,775.523], [357,2.92,0.067], [317,5.849,11790.629], [284,1.899,796.298], [271,0.315,10977.079], [243,0.345,5486.778], [206,4.806,2544.314], [205,1.869,5573.143], [202,2.458,6069.777], [156,0.833,213.299], [132,3.411,2942.463], [126,1.083,20.775], [115,0.645,0.98], [103,0.636,4694.003], [102,0.976,15720.839], [102,4.267,7.114], [99,6.21,2146.17], [98,0.68,155.42], [86,5.98,161000.69], [85,1.3,6275.96], [85,3.67,71430.7], [80,1.81,17260.15], [79,3.04,12036.46], [75,1.76,5088.63], [74,3.5,3154.69], [74,4.68,801.82], [70,0.83,9437.76], [62,3.98,8827.39], [61,1.82,7084.9], [57,2.78,6286.6], [56,4.39,14143.5], [56,3.47,6279.55], [52,0.19,12139.55], [52,1.33,1748.02], [51,0.28,5856.48], [49,0.49,1194.45], [41,5.37,8429.24], [41,2.4,19651.05], [39,6.17,10447.39], [37,6.04,10213.29], [37,2.57,1059.38], [36,1.71,2352.87], [36,1.78,6812.77], [33,0.59,17789.85], [30,0.44,83996.85], [30,2.74,1349.87], [25,3.16,4690.48]
        ], [
            [628331966747.0,0,0], [206059.0,2.678235,6283.07585], [4303.0,2.6351,12566.1517], [425.0,1.59,3.523], [119.0,5.796,26.298], [109.0,2.966,1577.344], [93,2.59,18849.23], [72,1.14,529.69], [68,1.87,398.15], [67,4.41,5507.55], [59,2.89,5223.69], [56,2.17,155.42], [45,0.4,796.3], [36,0.47,775.52], [29,2.65,7.11], [21,5.34,0.98], [19,1.85,5486.78], [19,4.97,213.3], [17,2.99,6275.96], [16,0.03,2544.31], [16,1.43,2146.17], [15,1.21,10977.08], [12,2.83,1748.02], [12,3.26,5088.63], [12,5.27,1194.45], [12,2.08,4694], [11,0.77,553.57], [10,1.3,6286.6], [10,4.24,1349.87], [9,2.7,242.73], [9,5.64,951.72], [8,5.3,2352.87], [6,2.65,9437.76], [6,4.67,4690.48]
        ], [
            [52919.0,0,0], [8720.0,1.0721,6283.0758], [309.0,0.867,12566.152], [27,0.05,3.52], [16,5.19,26.3], [16,3.68,155.42], [10,0.76,18849.23], [9,2.06,77713.77], [7,0.83,775.52], [5,4.66,1577.34], [4,1.03,7.11], [4,3.44,5573.14], [3,5.14,796.3], [3,6.05,5507.55], [3,1.19,242.73], [3,6.12,529.69], [3,0.31,398.15], [3,2.28,553.57], [2,4.38,5223.69], [2,3.75,0.98]
        ], [
            [289.0,5.844,6283.076], [35,0,0], [17,5.49,12566.15], [3,5.2,155.42], [1,4.72,3.52], [1,5.3,18849.23], [1,5.97,242.73]
        ], [
            [114.0,3.142,0], [8,4.13,6283.08],  [1,3.84,12566.15]
        ], [
            [1,3.14,0]
        ]
    ]
    
    let B_TERMS /* [B_COUNT][B_MAX_SUBCOUNT][TERM_COUNT] */ =
    [
        [
            [280.0,3.199,84334.662], [102.0,5.422,5507.553], [80,3.88,5223.69], [44,3.7,2352.87], [32,4,1577.34]
        ],
        [
            [9,3.9,5507.55], [6,1.73,5223.69]
        ]
    ];

    let R_TERMS /* [R_COUNT][R_MAX_SUBCOUNT][TERM_COUNT] */ =
    [
        [
            [100013989.0,0,0], [1670700.0,3.0984635,6283.07585], [13956.0,3.05525,12566.1517], [3084.0,5.1985,77713.7715], [1628.0,1.1739,5753.3849], [1576.0,2.8469,7860.4194], [925.0,5.453,11506.77], [542.0,4.564,3930.21], [472.0,3.661,5884.927], [346.0,0.964,5507.553], [329.0,5.9,5223.694], [307.0,0.299,5573.143], [243.0,4.273,11790.629], [212.0,5.847,1577.344], [186.0,5.022,10977.079], [175.0,3.012,18849.228], [110.0,5.055,5486.778], [98,0.89,6069.78], [86,5.69,15720.84], [86,1.27,161000.69], [65,0.27,17260.15], [63,0.92,529.69], [57,2.01,83996.85], [56,5.24,71430.7], [49,3.25,2544.31], [47,2.58,775.52], [45,5.54,9437.76], [43,6.01,6275.96], [39,5.36,4694], [38,2.39,8827.39], [37,0.83,19651.05], [37,4.9,12139.55], [36,1.67,12036.46], [35,1.84,2942.46], [33,0.24,7084.9], [32,0.18,5088.63], [32,1.78,398.15], [28,1.21,6286.6], [28,1.9,6279.55], [26,4.59,10447.39]
        ], [
            [103019.0,1.10749,6283.07585], [1721.0,1.0644,12566.1517], [702.0,3.142,0], [32,1.02,18849.23], [31,2.84,5507.55], [25,1.32,5223.69], [18,1.42,1577.34], [10,5.91,10977.08], [9,1.42,6275.96], [9,0.27,5486.78]
        ], [
            [4359.0,5.7846,6283.0758], [124.0,5.579,12566.152], [12,3.14,0], [9,3.63,77713.77], [6,1.87,5573.14], [3,5.47,18849.23]
        ], [
            [145.0,4.273,6283.076], [7,3.92,12566.15]
        ], [
            [4,2.56,6283.08]
        ]
    ]
    
    ////////////////////////////////////////////////////////////////
    ///  Periodic Terms for the nutation in longitude and obliquity
    ////////////////////////////////////////////////////////////////

    let Y_TERMS =
    [
        [0,0,0,0,1], [-2,0,0,2,2], [0,0,0,2,2], [0,0,0,0,2], [0,1,0,0,0], [0,0,1,0,0], [-2,1,0,2,2], [0,0,0,2,1], [0,0,1,2,2], [-2,-1,0,2,2], [-2,0,1,0,0], [-2,0,0,2,1], [0,0,-1,2,2], [2,0,0,0,0], [0,0,1,0,1], [2,0,-1,2,2], [0,0,-1,0,1], [0,0,1,2,1], [-2,0,2,0,0], [0,0,-2,2,1], [2,0,0,2,2], [0,0,2,2,2], [0,0,2,0,0], [-2,0,1,2,2], [0,0,0,2,0], [-2,0,0,2,0], [0,0,-1,2,1], [0,2,0,0,0], [2,0,-1,0,1], [-2,2,0,2,2], [0,1,0,0,1], [-2,0,1,0,1], [0,-1,0,0,1], [0,0,2,-2,0], [2,0,-1,2,1], [2,0,1,2,2], [0,1,0,2,2], [-2,1,1,0,0], [0,-1,0,2,2], [2,0,0,2,1], [2,0,1,0,0], [-2,0,2,2,2], [-2,0,1,2,1], [2,0,-2,0,1], [2,0,0,0,1], [0,-1,1,0,0], [-2,-1,0,2,1], [-2,0,0,0,1], [0,0,2,2,1], [-2,0,2,0,1], [-2,1,0,2,1], [0,0,1,-2,0], [-1,0,1,0,0], [-2,1,0,0,0], [1,0,0,0,0], [0,0,1,2,0], [0,0,-2,2,2], [-1,-1,1,0,0], [0,1,1,0,0], [0,-1,1,2,2], [2,-1,-1,2,2], [0,0,3,2,2], [2,-1,0,2,2]
    ]
    
    let TERM_PSI_A = 0
    let TERM_PSI_B = 1
    let TERM_EPS_C = 2
    let TERM_EPS_D = 3

    let PE_TERMS /* [Y_COUNT][TERM_PE_COUNT] */ =
    [
        [-171996,-174.2,92025,8.9], [-13187,-1.6,5736,-3.1], [-2274,-0.2,977,-0.5], [2062,0.2,-895,0.5], [1426,-3.4,54,-0.1], [712,0.1,-7,0], [-517,1.2,224,-0.6], [-386,-0.4,200,0], [-301,0,129,-0.1], [217,-0.5,-95,0.3], [-158,0,0,0], [129,0.1,-70,0], [123,0,-53,0], [63,0,0,0], [63,0.1,-33,0], [-59,0,26,0], [-58,-0.1,32,0], [-51,0,27,0], [48,0,0,0], [46,0,-24,0], [-38,0,16,0], [-31,0,13,0], [29,0,0,0], [29,0,-12,0], [26,0,0,0], [-22,0,0,0], [21,0,-10,0], [17,-0.1,0,0], [16,0,-8,0], [-16,0.1,7,0], [-15,0,9,0], [-13,0,7,0], [-12,0,6,0], [11,0,0,0], [-10,0,5,0], [-8,0,3,0], [7,0,-3,0], [-7,0,0,0], [-7,0,3,0], [-7,0,3,0], [6,0,0,0], [6,0,-3,0], [6,0,-3,0], [-6,0,3,0], [-6,0,3,0], [5,0,0,0], [-5,0,3,0], [-5,0,3,0], [-5,0,3,0], [4,0,0,0], [4,0,0,0], [4,0,0,0], [-4,0,0,0], [-4,0,0,0], [-4,0,0,0], [3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0]
    ]
    
    init(params: SPAParameters) {
        self.params = params
    }
    
    fileprivate func validateInputs(_ options: SPAOptions) -> Bool {
        // not checking Date or timezone.
        
        if ((params.pressure    < 0    ) || (params.pressure    > 5000)) { return false }
        if ((params.temperature <= -273) || (params.temperature > 6000)) { return false }
        if ((params.delta_ut1   <= -1  ) || (params.delta_ut1   >= 1  )) { return false }

        if (fabs(params.delta_t)       > 8000    ) { return false }
        if (fabs(params.atmosphericRefraction) > 5       ) { return false }

        if (options.contains(.incidence))
        {
            if (fabs(params.slope)         > 360) { return false }
            if (fabs(params.azimuthRotation)  > 360) { return false }
        }

        return true
    }
    /// Julian day
    var jd : Double = .signalingNaN
    /// Julian century
    var jc : Double = .signalingNaN

    /// Julian ephemeris day
    var jde : Double = .signalingNaN
    /// Julian ephemeris century
    var jce : Double = .signalingNaN
    /// Julian ephemeris millennium
    var jme : Double = .signalingNaN

    /// earth heliocentric longitude [degrees]
    var l : Double = .signalingNaN
    /// earth heliocentric latitude [degrees]
    var b : Double = .signalingNaN
    /// earth radius vector [Astronomical Units, AU]
    var r : Double = .signalingNaN

    /// geocentric longitude [degrees]
    var theta : Double = .signalingNaN
    /// geocentric latitude [degrees]
    var beta : Double = .signalingNaN

    /*
    var x0 : Double = .signalingNaN         //mean elongation (moon-sun) [degrees]
    var x1 : Double = .signalingNaN         //mean anomaly (sun) [degrees]
    var x2 : Double = .signalingNaN         //mean anomaly (moon) [degrees]
    var x3 : Double = .signalingNaN         //argument latitude (moon) [degrees]
    var x4 : Double = .signalingNaN         //ascending longitude (moon) [degrees]
*/
    /// nutation longitude [degrees]
    var del_psi : Double = .signalingNaN
    /// nutation obliquity [degrees]
    var del_epsilon : Double = .signalingNaN
    /// ecliptic mean obliquity [arc seconds]
    var epsilon0 : Double = .signalingNaN
    /// ecliptic true obliquity  [degrees]
    var epsilon : Double = .signalingNaN

    /// aberration correction [degrees]
    var del_tau : Double = .signalingNaN
    /// apparent sun longitude [degrees]
    var lamda : Double = .signalingNaN
    /// Greenwich mean sidereal time [degrees]
    var nu0 : Double = .signalingNaN
    /// Greenwich sidereal time [degrees]
    var nu : Double = .signalingNaN

    /// geocentric sun right ascension [degrees]
    var alpha : Double = .signalingNaN
    /// geocentric sun declination [degrees]
    var delta : Double = .signalingNaN

    /// observer hour angle [degrees]
    var h : Double = .signalingNaN
    /// sun equatorial horizontal parallax [degrees]
    var xi : Double = .signalingNaN
    /// sun right ascension parallax [degrees]
    var del_alpha : Double = .signalingNaN
    /// topocentric sun declination [degrees]
    var delta_prime : Double = .signalingNaN
    /// topocentric sun right ascension [degrees]
    var alpha_prime : Double = .signalingNaN
    /// topocentric local hour angle [degrees]
    var h_prime : Double = .signalingNaN
    
    /// topocentric elevation angle (uncorrected) [degrees]
    var e0 : Double = .signalingNaN
    /// atmospheric refraction correction [degrees]
    var del_e : Double = .signalingNaN
    /// topocentric elevation angle (corrected) [degrees]
    var e : Double = .signalingNaN
    
    /// equation of time [minutes]
    var eot : Double = .signalingNaN
    /// sunrise hour angle [degrees]
    var srha : Double = .signalingNaN
    /// sunset hour angle [degrees]
    var ssha : Double = .signalingNaN
    /// sun transit altitude [degrees]
    var sta : Double = .signalingNaN
    
    func rad2deg(_ radians: Double) -> Double
    {
        return (180.0 / Double.pi)*radians
    }
    
    func deg2rad(_ degrees: Double) -> Double
    {
        return (Double.pi / 180.0)*degrees
    }

    func limit_degrees(_ degrees: Double) -> Double
    {
        var limited: Double
        let dgs = degrees / 360

        limited = 360.0*(dgs-floor(dgs))
        if (limited < 0) { limited += 360.0 }

        return limited
    }
        
    func third_order_polynomial(_ a: Double, _ b: Double, _ c: Double, _ d: Double, _ x: Double) -> Double
    {
        return ((a*x + b)*x + c)*x + d;
    }
    
    func xy_term_summation(_ i: Int, _ x: [Double]) -> Double
    {
        var sum: Double = 0

        for j in 0..<x.count {
            sum = sum + x[j] * Double(Y_TERMS[i][j])
        }
        return sum
    }

    func calculate_geocentric_sun_right_ascension_and_declination()
    {
        var x: [Double] = Array(repeating: Double.nan, count: 5)

        jc = julianCentury(jd)
        jde = julianEphemerisDay(jd, params.delta_t)
        jce = julianEphemerisCentury(jde)
        jme = julianEphemerisMillennium(jce)

        l = earth_heliocentric_longitude(jme)
        b = earth_heliocentric_latitude(jme)
        r = earth_radius_vector(jme)

        theta = geocentric_longitude(l)
        beta  = geocentric_latitude(b)

        x[0] = mean_elongation_moon_sun(jce);
        x[1] = mean_anomaly_sun(jce);
        x[2] = mean_anomaly_moon(jce);
        x[3] = argument_latitude_moon(jce);
        x[4] = ascending_longitude_moon(jce);
        nutation_longitude_and_obliquity(jce, x)

        epsilon0 = ecliptic_mean_obliquity(jme)
        epsilon  = ecliptic_true_obliquity(del_epsilon, epsilon0)

        del_tau   = aberration_correction(r);
        lamda     = apparent_sun_longitude(theta, del_psi, del_tau)
        nu0       = greenwich_mean_sidereal_time (jd, jc)
        nu        = greenwich_sidereal_time (nu0, del_psi, epsilon)

        alpha = geocentric_right_ascension(lamda, epsilon, beta)
        delta = geocentric_declination(beta, epsilon, lamda)
    }
    
    func calculate(_ options: SPAOptions = .zenithAzimuth) -> SPAResult? {
        
        if(!validateInputs(options)) {
            return nil
        }
        //var result = SPAResult()

        jd = calculateJulianDay()
        calculate_geocentric_sun_right_ascension_and_declination()
        
        h  = observer_hour_angle(nu, params.location.coordinate.longitude, alpha)
        xi = sun_equatorial_horizontal_parallax(r)

        calculate_right_ascension_parallax_and_topocentric_dec()

        alpha_prime = topocentric_right_ascension(alpha, del_alpha);
        h_prime     = topocentric_local_hour_angle(h, del_alpha);

        e0      = topocentric_elevation_angle(params.location.coordinate.latitude, delta_prime, h_prime);

        del_e   = atmospheric_refraction_correction(params.pressure, params.temperature,
                                                    params.atmosphericRefraction, e0);
        e       = topocentric_elevation_angle_corrected(e0, del_e);
        
        var result = SPAResult()

        result.zenith        = topocentric_zenith_angle(e);
        result.azimuth_astro = topocentric_azimuth_angle_astro(h_prime, params.location.coordinate.latitude, delta_prime);
        result.azimuth       = topocentric_azimuth_angle(result.azimuth_astro);
        
        return result
/*


            if ((params.function == SPA_ZA_INC) || (params.function == SPA_ALL))
                params.incidence  = surface_incidence_angle(params.zenith, params.azimuth_astro,
                                                          params.azm_rotation, params.slope);

            if ((params.function == SPA_ZA_RTS) || (params.function == SPA_ALL))
                calculate_eot_and_sun_rise_transit_set(spa);
        }

        return result;
    }
 */
        return nil /* for now */
    }
}
