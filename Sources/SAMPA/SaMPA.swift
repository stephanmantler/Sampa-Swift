//
//  SAMPA.swift
//  
//
//  Created by stephan mantler on 21.12.2020.
//

import Foundation

public struct SAMPAResult {
    public var sun: SPAResult
    public var moon: MPAResult
    
    ///local observed, topocentric, angular distance between sun and moon centers [degrees]
    public var ems: Double = .nan
    /// radius of sun disk [degrees]
    public var rs: Double = .nan
    /// radius of moon disk [degrees]
    public var rm: Double = .nan
    
    /// area of sun's unshaded lune (SUL) during eclipse [degrees squared]
    public var a_sul: Double = .nan
    /// percent area of SUL during eclipse [percent]
    public var a_sul_pct: Double = .nan
    
    /// estimated direct normal solar irradiance using SERI/NREL Bird Clear Sky Model [W/m^2]
    public var dni: Double = .nan
    /// estimated direct normal solar irradiance from the sun's unshaded lune [W/m^2]
    public var dni_sul: Double = .nan
    /// estimated global horizontal solar irradiance using SERI/NREL Bird Clear Sky Model [W/m^2]
    public var ghi: Double = .nan
    /// estimated global horizontal solar irradiance from the sun's unshaded lune [W/m^2]
    public var ghi_sul: Double = .nan
    /// estimated diffuse horizontal solar irradiance using SERI/NREL Bird Clear Sky Model [W/m^2]
    public var dhi: Double = .nan
    /// estimated diffuse horizontal solar irradiance from the sun's unshaded lune [W/m^2]
    public var dhi_sul: Double = .nan
}

public class SAMPA {
    
    var spa: SPA?
    var mpa: MPA?
    public var result: SAMPAResult?
    
    public init() {
        self.spa = nil
        self.mpa = nil
        self.result = nil
    }
    
    public init(with params: SPAParameters) {
        self.spa = nil
        self.mpa = nil
        self.result = self.calculate(with: params)
    }
    
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

    public func calculate(with spaParams: SPAParameters) -> SAMPAResult?
    {
        self.result = nil
        spa = SPA(params: spaParams)
        guard let spaResult = spa!.calculate(.all) else {
            return nil
        }
        mpa = MPA()
        let mpaResult = mpa!.calculate(using: spa!)
        
        var result = SAMPAResult(sun: spaResult, moon: mpaResult)
        
        result.ems = angular_distance_sun_moon(result.sun.zenith, result.sun.azimuth,
                                               result.moon.zenith, result.moon.azimuth)
        result.rs  = sun_disk_radius(spa!.earthRadiusVector)
        result.rm  = moon_disk_radius(mpa!.e, mpa!.pi, mpa!.cap_delta)

        //sul_area(sampa->ems, sampa->rs, sampa->rm, &sampa->a_sul, &sampa->a_sul_pct);

        //if (sampa->function == SAMPA_ALL) estimate_irr(sampa);
        self.result = result
        return result
    }
}
