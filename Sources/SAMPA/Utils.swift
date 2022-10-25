//
//  File.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

class Utils {
    // MARK: General parameters
    static let SUN_RADIUS = 0.26667
    
    static func rad2deg(_ radians: Double) -> Double
    {
        return (180.0 / Double.pi)*radians
    }
    
    static func deg2rad(_ degrees: Double) -> Double
    {
        return (Double.pi / 180.0)*degrees
    }

    static func limit_degrees(_ degrees: Double) -> Double
    {
        var limited: Double
        let dgs = degrees / 360

        limited = 360.0*(dgs-floor(dgs))
        if (limited < 0) { limited += 360.0 }

        return limited
    }
        
    static func third_order_polynomial(_ a: Double, _ b: Double, _ c: Double, _ d: Double, _ x: Double) -> Double
    {
        return ((a*x + b)*x + c)*x + d
    }

    static func fourth_order_polynomial(_ a: Double, _ b: Double, _ c: Double, _ d: Double, _ e: Double, _ x: Double) -> Double
    {
        return (((a*x + b)*x + c)*x + d)*x + e
    }

    static func geocentric_right_ascension(_ lamda: Double, _ epsilon: Double, _ beta: Double) -> Double
    {
        let lamda_rad   = deg2rad(lamda)
        let epsilon_rad = deg2rad(epsilon)

        return limit_degrees(rad2deg(atan2(sin(lamda_rad)*cos(epsilon_rad) -
                                                        tan(deg2rad(beta))*sin(epsilon_rad), cos(lamda_rad))))
    }

    static func geocentric_declination(_ beta: Double, _ epsilon: Double, _ lamda: Double) -> Double
    {
        let beta_rad    = deg2rad(beta)
        let epsilon_rad = deg2rad(epsilon)

        return rad2deg(asin(sin(beta_rad)*cos(epsilon_rad) +
                                    cos(beta_rad)*sin(epsilon_rad)*sin(deg2rad(lamda))))
    }
    
    static func observer_hour_angle(_ nu: Double, _ longitude: Double, _ alpha_deg: Double) -> Double
    {
        return limit_degrees(nu + longitude - alpha_deg)
    }
    
    static func right_ascension_parallax_and_topocentric_dec(
        _ latitude: Double, _ elevation: Double, _ xi: Double, _ h: Double, _ delta: Double) -> (Double, Double)
    {
        var delta_alpha_rad: Double = 0
        let lat_rad   = Utils.deg2rad(latitude)
        let xi_rad    = Utils.deg2rad(xi)
        let h_rad     = Utils.deg2rad(h)
        let delta_rad = Utils.deg2rad(delta)
        let u = atan(0.99664719 * tan(lat_rad))
        let y = 0.99664719 * sin(u) + elevation * sin(lat_rad)/6378140.0
        let x =              cos(u) + elevation * cos(lat_rad)/6378140.0

        delta_alpha_rad =      atan2(                -x * sin(xi_rad) * sin(h_rad),
                                      cos(delta_rad) - x * sin(xi_rad) * cos(h_rad))

        let delta_prime = Utils.rad2deg(atan2((sin(delta_rad) - y * sin(xi_rad)) * cos(delta_alpha_rad),
                                      cos(delta_rad) - x * sin(xi_rad) * cos(h_rad)))

        let del_alpha = Utils.rad2deg(delta_alpha_rad)
        
        return ( delta_prime, del_alpha )
    }
    
    static func topocentric_right_ascension(_ alpha_deg: Double, _ delta_alpha: Double) -> Double
    {
        return alpha_deg + delta_alpha
    }

    static func topocentric_local_hour_angle(_ h: Double, _ delta_alpha: Double) -> Double
    {
        return h - delta_alpha
    }

    static func topocentric_elevation_angle(_ latitude: Double, _ delta_prime: Double, _ h_prime: Double) -> Double
    {
        let lat_rad         = Utils.deg2rad(latitude)
        let delta_prime_rad = Utils.deg2rad(delta_prime)

        return Utils.rad2deg(asin(sin(lat_rad)*sin(delta_prime_rad) +
                                    cos(lat_rad)*cos(delta_prime_rad) * cos(Utils.deg2rad(h_prime))))
    }
    
    static func atmospheric_refraction_correction(_ pressure: Double, _ temperature: Double,
                                           _ atmos_refract: Double, _ e0: Double) -> Double
    {
        var del_e: Double = 0

        if (e0 >= -1*(SUN_RADIUS + atmos_refract)) {
            del_e = (pressure / 1010.0) * (283.0 / (273.0 + temperature)) *
                1.02 / (60.0 * tan(Utils.deg2rad(e0 + 10.3/(e0 + 5.11))))
        }

        return del_e
    }

    static func topocentric_elevation_angle_corrected(_ e0: Double, _ delta_e: Double) -> Double
    {
        return e0 + delta_e
    }

    static func topocentric_zenith_angle(_ e: Double) -> Double
    {
        return 90.0 - e
    }

    static func topocentric_azimuth_angle_astro(_ h_prime: Double, _ latitude: Double, _ delta_prime: Double) -> Double
    {
        let h_prime_rad = deg2rad(h_prime)
        let lat_rad     = deg2rad(latitude)

        return limit_degrees(rad2deg(atan2(sin(h_prime_rad),
                                                       cos(h_prime_rad)*sin(lat_rad) - tan(deg2rad(delta_prime))*cos(lat_rad))))
    }

    static func topocentric_azimuth_angle(_ azimuth_astro: Double) -> Double
    {
        return limit_degrees(azimuth_astro + 180.0)
    }
}
