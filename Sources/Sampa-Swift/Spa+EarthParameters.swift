//
//  File.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

extension SPA {
    func earth_values(_ term_sum: [Double], _ jme: Double) -> Double
    {
        var sum: Double = 0

        for i in 0..<term_sum.count {
            sum += term_sum[i]*pow(jme, Double(i))
        }

        sum /= 1.0e8

        return sum;
    }
    
    func earth_periodic_term_summation(_ terms:[[Double]], _ jme: Double) -> Double
    {
        var sum: Double = 0

        for i in 0..<terms.count {
            sum += terms[i][0]*cos(terms[i][1]+terms[i][2]*jme)
        }

        return sum
    }


    func earth_heliocentric_longitude(_ jme: Double) -> Double
    {
        var sum: [Double] = Array.init(repeating: 0, count: L_TERMS.count)

        for i in 0..<L_TERMS.count {
            sum[i] = earth_periodic_term_summation(L_TERMS[i], jme)
        }

        return limit_degrees(rad2deg(earth_values(sum, jme)))

    }

    func earth_heliocentric_latitude(_ jme: Double) -> Double
    {
        var sum: [Double] = Array.init(repeating: 0, count: B_TERMS.count)

        for i in 0..<B_TERMS.count {
            sum[i] = earth_periodic_term_summation(B_TERMS[i], jme)
        }

        return rad2deg(earth_values(sum, jme))

    }
    
    func earth_radius_vector(_ jme: Double) -> Double
    {
        var sum: [Double] = Array.init(repeating: 0, count: R_TERMS.count)

        for i in 0..<R_TERMS.count {
            sum[i] = earth_periodic_term_summation(R_TERMS[i], jme)
        }

        return earth_values(sum, jme)
    }

    func geocentric_longitude(_ l: Double) -> Double
    {
        var theta = l + 180.0

        if (theta >= 360.0) { theta -= 360.0 }

        return theta
    }

    func geocentric_latitude(_ b: Double) -> Double
    {
        return -b
    }

    func mean_elongation_moon_sun(_ jce: Double) -> Double
    {
        return third_order_polynomial(1.0/189474.0, -0.0019142, 445267.11148, 297.85036, jce);
    }

    func mean_anomaly_sun(_ jce: Double) -> Double
    {
        return third_order_polynomial(-1.0/300000.0, -0.0001603, 35999.05034, 357.52772, jce);
    }

    func mean_anomaly_moon(_ jce: Double) -> Double
    {
        return third_order_polynomial(1.0/56250.0, 0.0086972, 477198.867398, 134.96298, jce);
    }

    func argument_latitude_moon(_ jce: Double) -> Double
    {
        return third_order_polynomial(1.0/327270.0, -0.0036825, 483202.017538, 93.27191, jce);
    }

    func ascending_longitude_moon(_ jce: Double) -> Double
    {
        return third_order_polynomial(1.0/450000.0, 0.0020708, -1934.136261, 125.04452, jce);
    }
    
    func nutation_longitude_and_obliquity(_ jce: Double, _ x: [Double])
    {
        var xy_term_sum: Double
        var sum_psi: Double = 0
        var sum_epsilon: Double = 0

        for i in 0..<Y_TERMS.count {
            xy_term_sum  = deg2rad(xy_term_summation(i, x));
            sum_psi     += (PE_TERMS[i][TERM_PSI_A] + jce*PE_TERMS[i][TERM_PSI_B])*sin(xy_term_sum);
            sum_epsilon += (PE_TERMS[i][TERM_EPS_C] + jce*PE_TERMS[i][TERM_EPS_D])*cos(xy_term_sum);
        }

        del_psi     = sum_psi     / 36000000.0;
        del_epsilon = sum_epsilon / 36000000.0;
    }

    func ecliptic_mean_obliquity(_ jme: Double) -> Double
    {
        let u = jme/10.0;

        return 84381.448 + u*(-4680.93 + u*(-1.55 + u*(1999.25 + u*(-51.38 + u*(-249.67 +
                           u*(  -39.05 + u*( 7.12 + u*(  27.87 + u*(  5.79 + u*2.45)))))))));
    }

    func ecliptic_true_obliquity(_ delta_epsilon: Double, _ epsilon0: Double) -> Double
    {
        return delta_epsilon + epsilon0/3600.0;
    }

    func aberration_correction(_ r: Double) -> Double
    {
        return -20.4898 / (3600.0*r);
    }

    func apparent_sun_longitude(_ theta: Double, _ delta_psi: Double, _ delta_tau: Double) -> Double
    {
        return theta + delta_psi + delta_tau;
    }

    func greenwich_mean_sidereal_time (_ jd: Double, _ jc: Double) -> Double
    {
        return limit_degrees(280.46061837 + 360.98564736629 * (jd - 2451545.0) +
                                           jc*jc*(0.000387933 - jc/38710000.0));
    }

    func greenwich_sidereal_time (_ nu0: Double, _ delta_psi: Double, _ epsilon: Double) -> Double
    {
        return nu0 + delta_psi*cos(deg2rad(epsilon));
    }
    
    func geocentric_right_ascension(_ lamda: Double, _ epsilon: Double, _ beta: Double) -> Double
    {
        let lamda_rad   = deg2rad(lamda);
        let epsilon_rad = deg2rad(epsilon);

        return limit_degrees(rad2deg(atan2(sin(lamda_rad)*cos(epsilon_rad) -
                                           tan(deg2rad(beta))*sin(epsilon_rad), cos(lamda_rad))));
    }

    func geocentric_declination(_ beta: Double, _ epsilon: Double, _ lamda: Double) -> Double
    {
        let beta_rad    = deg2rad(beta);
        let epsilon_rad = deg2rad(epsilon);

        return rad2deg(asin(sin(beta_rad)*cos(epsilon_rad) +
                            cos(beta_rad)*sin(epsilon_rad)*sin(deg2rad(lamda))));
    }

    func observer_hour_angle(_ nu: Double, _ longitude: Double, _ alpha_deg: Double) -> Double
    {
        return limit_degrees(nu + longitude - alpha_deg);
    }

    func sun_equatorial_horizontal_parallax(_ r: Double) -> Double
    {
        return 8.794 / (3600.0 * r);
    }

}
