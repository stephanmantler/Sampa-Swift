//
//  File.swift
//  
//
//  Created by stephan mantler on 20.12.2020.
//

import Foundation
import CoreLocation
import os

public struct SPAOptions : OptionSet {
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public let rawValue: Int
    
    public static let zenithAzimuth = SPAOptions(rawValue: 1)
    public static let incidence = SPAOptions(rawValue: 2)
    public static let riseTransitSet = SPAOptions(rawValue: 4)
    
    public static let all: SPAOptions = [.zenithAzimuth, incidence, riseTransitSet]
}

public struct SPAParameters {
    /// observer local time, including milliseconds and timezone
    public var date: Date
    public var timeZone: TimeZone

    /// Observer longitude/latitude/elevation
    /// longitude should be -180 to 180, lat -90-90,
    public var location: CLLocation

    /// average local pressure (millibars)
    public var pressure: Double = 1000

    /// annual average local temperature in °C
    public var temperature: Double = 10

    /// surface slope measured from the horizontal plane
    public var slope: Double = 0

    /// surface azimuth rotation (measured from south to projection of surface normal on horizonal plane, negative east)
    public var azimuthRotation: Double = 0

    /// atmospheric refraction at sunrise and sunset (0.5667 deg is typical)
    public var atmosphericRefraction: Double = 0.5667
    
    public init(date: Date, location: CLLocation, timeZone: TimeZone) {
        self.date = date
        self.location = location
        self.timeZone = timeZone
    }
}

public struct SPAResult {
    /// topocentric zenith angle [degrees]
    public var zenith: Double = .nan
    /// topocentric azimuth angle (westward from south) [for astronomers]
    public var azimuth_astro: Double = .nan
    /// topocentric azimuth angle (eastward from north) [for navigators and solar radiation]
    public var azimuth: Double = .nan
    /// surface incidence angle [degrees]
    public var incidence: Double = .nan

    /// local sun transit time (or solar noon) [fractional hour]
    public var suntransit: Date = .distantPast
    //local sunrise time (+/- 30 seconds) [fractional hour]
    public var sunrise: Date = .distantPast
    //local sunset time (+/- 30 seconds) [fractional hour]
    public var sunset: Date = .distantPast
}

public class SPA {
    public var params: SPAParameters
    
    // MARK: Earth periodic terms
    let L_TERMS =
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
    
    let B_TERMS =
    [
        [
            [280.0,3.199,84334.662], [102.0,5.422,5507.553], [80,3.88,5223.69], [44,3.7,2352.87], [32,4,1577.34]
        ],
        [
            [9,3.9,5507.55], [6,1.73,5223.69]
        ]
    ]

    let R_TERMS =
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
    
    public init(params: SPAParameters) {
        self.params = params
    }
    
    fileprivate func validateInputs(_ options: SPAOptions) -> Bool {
        // not checking Date or timezone.
        
        if ((params.pressure    < 0    ) || (params.pressure    > 5000)) { return false }
        if ((params.temperature <= -273) || (params.temperature > 6000)) { return false }
        if (fabs(params.atmosphericRefraction) > 5       ) { return false }

        if (options.contains(.incidence))
        {
            if (fabs(params.slope)         > 360) { return false }
            if (fabs(params.azimuthRotation)  > 360) { return false }
        }

        return true
    }

    /// earth heliocentric longitude , _l_ [degrees]
    var earthHeliocentricLongitude : Double = .signalingNaN
    /// earth heliocentric latitude, _b_ [degrees]
    var earthHeliocentricLatitude : Double = .signalingNaN
    /// earth radius vector, _r_ [Astronomical Units, AU]
    var earthRadiusVector : Double = .signalingNaN

    /// geocentric longitude [degrees]
    var geocentricLongitude : Double = .signalingNaN
    /// geocentric latitude [degrees]
    var geocentricLatitude : Double = .signalingNaN

    /// nutation longitude [degrees]
    var nutationLongitude : Double = .signalingNaN
    /// nutation obliquity [degrees]
    var nutationObliquity : Double = .signalingNaN
    /// ecliptic mean obliquity [arc seconds]
    var eclipticMeanObliquity : Double = .signalingNaN
    /// ecliptic true obliquity  [degrees]
    var eclipticTrueObliquity : Double = .signalingNaN

    /// aberration correction [degrees]
    var aberrationCorrection : Double = .signalingNaN
    /// apparent sun longitude [degrees]
    var apparentSunLongitude : Double = .signalingNaN
    /// Greenwich mean sidereal time [degrees]
    var greenwichMeanSiderealTime : Double = .signalingNaN
    /// Greenwich sidereal time [degrees]
    var greenwichSiderealTime : Double = .signalingNaN

    /// geocentric sun right ascension [degrees]
    var geocentricSunRightAscension : Double = .signalingNaN
    /// geocentric sun declination [degrees]
    var geocentricSunDeclination : Double = .signalingNaN

    /// observer hour angle [degrees]
    var observerHourAngle : Double = .signalingNaN
    /// sun equatorial horizontal parallax [degrees]
    var sunEquatorialHorizontalParallax : Double = .signalingNaN
    /// sun right ascension parallax [degrees]
    var sunRightAscensionParallax : Double = .signalingNaN
    /// topocentric sun declination [degrees]
    var topocentricSunDeclination : Double = .signalingNaN
    /// topocentric sun right ascension [degrees]
    var topocentricSunRightAscension : Double = .signalingNaN
    /// topocentric local hour angle [degrees]
    var topocentricLocalHourAngle : Double = .signalingNaN
    
    /// topocentric elevation angle (uncorrected) [degrees]
    var topocentricElevationAngle : Double = .signalingNaN
    /// atmospheric refraction correction [degrees]
    var atmosphericRefractionCorrection : Double = .signalingNaN
    /// topocentric elevation angle (corrected) [degrees]
    var topocentricElevationAngleCorrected : Double = .signalingNaN
    
    /// equation of time [minutes]
    var equationOfTime : Double = .signalingNaN
    /// sunrise hour angle [degrees]
    var sunriseHourAngle : Double = .signalingNaN
    /// sunset hour angle [degrees]
    var sunsetHourAngle : Double = .signalingNaN
    /// sun transit altitude [degrees]
    var sunTransitAltitude : Double = .signalingNaN
    
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

        earthHeliocentricLongitude = earth_heliocentric_longitude(params.date.julianEphemerisMillennium)
        earthHeliocentricLatitude = earth_heliocentric_latitude(params.date.julianEphemerisMillennium)
        earthRadiusVector = earth_radius_vector(params.date.julianEphemerisMillennium)

        geocentricLongitude = geocentric_longitude(earthHeliocentricLongitude)
        geocentricLatitude  = geocentric_latitude(earthHeliocentricLatitude)

        x[0] = mean_elongation_moon_sun(params.date.julianEphemerisCentury)
        x[1] = mean_anomaly_sun(params.date.julianEphemerisCentury)
        x[2] = mean_anomaly_moon(params.date.julianEphemerisCentury)
        x[3] = argument_latitude_moon(params.date.julianEphemerisCentury)
        x[4] = ascending_longitude_moon(params.date.julianEphemerisCentury)
        calculateNutationLongitudeAndObliquity(params.date.julianEphemerisCentury, x)

        eclipticMeanObliquity = ecliptic_mean_obliquity(params.date.julianEphemerisMillennium)
        eclipticTrueObliquity  = ecliptic_true_obliquity(nutationObliquity, eclipticMeanObliquity)

        aberrationCorrection   = aberration_correction(earthRadiusVector)
        apparentSunLongitude     = apparent_sun_longitude(geocentricLongitude, nutationLongitude, aberrationCorrection)
        greenwichMeanSiderealTime       = greenwich_mean_sidereal_time (params.date.julianDate, params.date.julianCentury)
        greenwichSiderealTime        = greenwich_sidereal_time (greenwichMeanSiderealTime, nutationLongitude, eclipticTrueObliquity)

        geocentricSunRightAscension = Utils.geocentric_right_ascension(apparentSunLongitude, eclipticTrueObliquity, geocentricLatitude)
        geocentricSunDeclination = Utils.geocentric_declination(geocentricLatitude, eclipticTrueObliquity, apparentSunLongitude)
    }
    
    func combineFractionalDate(_ hours: Double) -> Date {
        // make midnight first
        var remainder = params.date.timeIntervalSince1970.remainder(dividingBy: 86400)
        if ( remainder < 0 ) { remainder = remainder + 86400 }
        let baseDate = params.date.addingTimeInterval( -remainder )
            //.addingTimeInterval(-TimeInterval(params.timeZone.secondsFromGMT()))
        
        let offset = hours * 3600
        let result = baseDate.addingTimeInterval(offset)
        return result
    }
    
    public func calculate(_ options: SPAOptions = .all) -> SPAResult? {
        
        if(!validateInputs(options)) {
            return nil
        }

        calculate_geocentric_sun_right_ascension_and_declination()
        
        observerHourAngle  = Utils.observer_hour_angle(greenwichSiderealTime, params.location.coordinate.longitude, geocentricSunRightAscension)
        sunEquatorialHorizontalParallax = sun_equatorial_horizontal_parallax(earthRadiusVector)

        let dp = Utils.right_ascension_parallax_and_topocentric_dec(params.location.coordinate.latitude, params.location.altitude, sunEquatorialHorizontalParallax, observerHourAngle, geocentricSunDeclination)
        topocentricSunDeclination = dp.0
        sunRightAscensionParallax = dp.1

        topocentricSunRightAscension = Utils.topocentric_right_ascension(geocentricSunRightAscension, sunRightAscensionParallax)
        topocentricLocalHourAngle     = Utils.topocentric_local_hour_angle(observerHourAngle, sunRightAscensionParallax)

        topocentricElevationAngle = Utils.topocentric_elevation_angle(
            params.location.coordinate.latitude,
            topocentricSunDeclination,
            topocentricLocalHourAngle)

        atmosphericRefractionCorrection = Utils.atmospheric_refraction_correction(
            params.pressure,
            params.temperature,
            params.atmosphericRefraction,
            topocentricElevationAngle)
        
        topocentricElevationAngleCorrected = Utils.topocentric_elevation_angle_corrected(topocentricElevationAngle, atmosphericRefractionCorrection)
        
        var result = SPAResult()

        result.zenith        = Utils.topocentric_zenith_angle(topocentricElevationAngleCorrected)
        result.azimuth_astro = Utils.topocentric_azimuth_angle_astro(topocentricLocalHourAngle, params.location.coordinate.latitude, topocentricSunDeclination)
        result.azimuth       = Utils.topocentric_azimuth_angle(result.azimuth_astro)
        
        if options.contains(.incidence) {
            result.incidence = surface_incidence_angle(
                result.zenith,
                result.azimuth_astro,
                params.azimuthRotation,
                params.slope)
        }
        
        if options.contains(.riseTransitSet) {
            let rts = calculate_eot_and_sun_rise_transit_set()
            result.sunrise = combineFractionalDate(rts.0)
            result.suntransit = combineFractionalDate(rts.1)
            result.sunset = combineFractionalDate(rts.2)
        }
        
        return result
    }
}
