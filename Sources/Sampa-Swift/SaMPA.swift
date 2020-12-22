//
//  SaMPA.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

struct SaMPAResult {
    var sun: SPAResult
    var moon: MPAResult
    
    ///local observed, topocentric, angular distance between sun and moon centers [degrees]
    var ems: Double = .nan
    /// radius of sun disk [degrees]
    var rs: Double = .nan
    /// radius of moon disk [degrees]
    var rm: Double = .nan
    
    /// area of sun's unshaded lune (SUL) during eclipse [degrees squared]
    var a_sul: Double = .nan
    /// percent area of SUL during eclipse [percent]
    var a_sul_pct: Double = .nan
    
    /// estimated direct normal solar irradiance using SERI/NREL Bird Clear Sky Model [W/m^2]
    var dni: Double = .nan
    /// estimated direct normal solar irradiance from the sun's unshaded lune [W/m^2]
    var dni_sul: Double = .nan
    /// estimated global horizontal solar irradiance using SERI/NREL Bird Clear Sky Model [W/m^2]
    var ghi: Double = .nan
    /// estimated global horizontal solar irradiance from the sun's unshaded lune [W/m^2]
    var ghi_sul: Double = .nan
    /// estimated diffuse horizontal solar irradiance using SERI/NREL Bird Clear Sky Model [W/m^2]
    var dhi: Double = .nan
    /// estimated diffuse horizontal solar irradiance from the sun's unshaded lune [W/m^2]
    var dhi_sul: Double = .nan
}

class SaMPA {
    
    var spa: SPA?
    var mpa: MPA?
    
    func angular_distance_sun_moon(_ zen_sun: Double, _ azm_sun: Double, _ zen_moon: Double, _ azm_moon: Double) -> Double
    {
        let zs = Utils.deg2rad(zen_sun)
        let zm = Utils.deg2rad(zen_moon)

        return Utils.rad2deg(acos(cos(zs)*cos(zm) + sin(zs)*sin(zm)*cos(Utils.deg2rad(azm_sun - azm_moon))))
    }

    func sun_disk_radius(_ r: Double) -> Double
    {
        return 959.63/(3600.0 * r)
    }

    func moon_disk_radius(_ e: Double, _ pi: Double, _ cap_delta: Double) -> Double
    {
        return 358473400*(1 + sin(Utils.deg2rad(e))*sin(Utils.deg2rad(pi)))/(3600.0 * cap_delta)
    }

    func calculate(with spaParams: SPAParameters) -> SaMPAResult?
    {
        spa = SPA(params: spaParams)
        guard let spaResult = spa!.calculate(.all) else {
            return nil
        }
        mpa = MPA()
        let mpaResult = mpa!.calculate(using: spa!)
        
        var result = SaMPAResult(sun: spaResult, moon: mpaResult)
        
        result.ems = angular_distance_sun_moon(result.sun.zenith, result.sun.azimuth,
                                               result.moon.zenith, result.moon.azimuth)
        result.rs  = sun_disk_radius(spa!.r)
        result.rm  = moon_disk_radius(mpa!.e, mpa!.pi, mpa!.cap_delta)

        //sul_area(sampa->ems, sampa->rs, sampa->rm, &sampa->a_sul, &sampa->a_sul_pct);

        //if (sampa->function == SAMPA_ALL) estimate_irr(sampa);

        return result
    }
}
