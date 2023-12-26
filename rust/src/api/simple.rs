use sgp4;
use nalgebra::{Matrix3, Vector3};
use chrono::{DateTime, Timelike, Datelike, Utc, NaiveDate, NaiveTime, NaiveDateTime, Duration};
use parse_tle::tle;
use clap::{Parser, Args};
use std::f64::consts::PI;

pub const RADIUS_EQUATOR: f64 = 6.378137e6; // m
pub const SURFACE_ECC: f64 = 0.08182;
pub const ROT_RATE: f64 = 7.2921150e-5;
pub const AXIAL_TILT: f64 = -23.439;
pub const J2000_DAY: f64 = 2451545.0;
pub const J2000_EARTH_MEAN_ANOMALY: f64 = 1.98627277778;
pub const EARTH_MEAN_ANOMALY_PER_JDAY: f64 = 0.00547555711;

/// Convert East North Up vector to Azimuth, Elevation, and Radial Distance
#[flutter_rust_bridge::frb(sync)] 
pub fn enu_to_azelrad(
    p_enu: Vector3<f64>,
) -> Vector3<f64> {
    let dis: f64 = p_enu.norm();
    let az: f64 = (p_enu[0]).atan2(p_enu[1]);
    let el: f64 = (p_enu[2] / dis).asin();
    return  Vector3::<f64>::new(az, el, dis);
}

/// Calculate inertial to corotational frame rotation matrix
/// 
/// Inputs
/// ------
/// date_time: `DateTime<Utc>`
///     Date and Time 
/// 
/// rot_rate_rad_day: `f64`
///     Rotation rate of body in radians per day
#[flutter_rust_bridge::frb(sync)] 
pub fn calc_inertial_rotational_rotam(
    date_time: DateTime<Utc>,
    rad_per_day: f64
) -> Matrix3<f64> { 
    let theta: f64 = rad_per_day * datetime_to_j2000days(date_time);
    let rotam: Matrix3<f64> = Matrix3::<f64>::new(
        theta.cos(), -theta.sin(), 0.,
        theta.sin(), theta.cos(), 0.,
        0., 0., 1.);

    return rotam
}

#[flutter_rust_bridge::frb(sync)] 
fn datetime_to_j2000days(date_time: DateTime<Utc>) -> f64 {
    let year: u32 = date_time.year() as u32;
    let month: u32 = date_time.month();
    let day: u32 = date_time.day();

    let hours: u32 = date_time.hour();
    let minutes: u32 = date_time.minute();
    let seconds: u32 = date_time.second();

    let j2000_days: f64 = ymdhms_to_j2000days(
        year, 
        month, 
        day, 
        hours, 
        minutes, 
        seconds,
    );
    return j2000_days;
}

#[flutter_rust_bridge::frb(sync)] 
pub fn ymdhms_to_j2000days(
    year: u32, 
    month: u32, 
    day: u32, 
    hours: u32, 
    minutes: u32, 
    seconds: u32
) -> f64 {
    let julian_day: f64 = date_to_julian_day_num(year, month, day) as f64;
    let sidereal_time: f64 = (hours + (minutes + seconds / 60) / 60) as f64 / 24.;
    let j2000_days: f64 = julian_day + sidereal_time - J2000_DAY;
    return j2000_days;
}

/// Convert gregorian date to julian day
/// 
/// Inputs
/// ------
/// year: `i32`
///     Common Era year
/// 
/// month: `i32`
///     Month number of year
/// 
/// day: `i32`
///     Day of month
#[flutter_rust_bridge::frb(sync)] 
pub fn date_to_julian_day_num(
    year: u32,
    month: u32,
    day: u32
) -> i32 {
    // Be careful with Sign 
    let i_y: i32 = year as i32;
    let i_m: i32 = month as i32;
    let i_d: i32 = day as i32;
    
    // FIXME-TD: fix magic numbers
    let del_month: i32 = (i_m - 14) / 12; // Adjusts for jul & aug
    let julian_day_num: i32 = (1461 * (i_y + 4800 + del_month))/4 
        + (367 * (i_m - 2 - 12 * (del_month)))/12 
        - (3 * ((i_y + 4900 + del_month) / 100))/4 
        + i_d - 32075;

    return julian_day_num
}

/// Geodetic to rectangular coordinates
/// E.g. Latitude, Longitude, Altitude to ECEF
/// 
/// Inputs
/// ------
/// lla: `Vector3<f64>`
///     geodetic coords
/// 
/// Outputs
/// -------
/// xyz: `Vector3<f64>`
///     Cartesian coords
#[flutter_rust_bridge::frb(sync)] 
pub fn planetodetic_to_cartesian_rotational(
    lla: Vector3<f64>,
    equatorial_radius: f64,
    eccentricity: f64
) -> Vector3<f64> {
    let radius: f64 = calc_prime_vertical(
        lla[0], 
        equatorial_radius,
        eccentricity);
    let x: f64 = (radius + lla[2]) * lla[0].cos() * lla[1].cos();
    let y: f64 = (radius + lla[2]) * lla[0].cos() * lla[1].sin();
    let z: f64 = ((1.0 - eccentricity.powi(2)) * radius + lla[2]) * lla[0].sin();
    let xyz: Vector3<f64> = Vector3::new(x, y, z); 
    return xyz
}

/// Calculate prime vertical radius to surface at latitude
/// 
/// Inputs
/// ------
/// lat_deg: `f64`
///     Lattitude in degrees
#[flutter_rust_bridge::frb(sync)] 
pub fn calc_prime_vertical(
    lat_deg: f64, 
    equatorial_radius: f64,
    eccentricity: f64
) -> f64 {
    let lat_radians: f64 = PI * lat_deg / 180.0;
    let radius: f64 = 
        equatorial_radius / (1.0 - (eccentricity * lat_radians.sin()).powi(2)).sqrt();
    return radius
}


#[flutter_rust_bridge::frb(sync)] 
pub fn is_eclipsed_by_earth(
    p_eci: Vector3<f64>,
    date_time: DateTime<Utc>,
) -> bool {  
    let j2000_days: f64 = datetime_to_j2000days(date_time);

    let sun_eci: Vector3<f64> = calc_sun_norm_eci_vec(j2000_days);
    let beta: f64 = sun_eci.dot(&p_eci).asin();

    // TODO-TD: increase precision in radius calculation
    let beta_eclipse: f64 = PI - (RADIUS_EQUATOR / p_eci.norm()).asin();
    return beta > beta_eclipse;
}

#[flutter_rust_bridge::frb(sync)] 
pub fn calc_sun_norm_eci_vec(
    j2000_days: f64
) -> Vector3<f64> {
    let mean_lon_deg: f64 = 280.460 + 0.98560028 * j2000_days;
    let mean_lon: f64 = mean_lon_deg * PI / 180.0;
    let mean_anom: f64 = calc_julian_day_mean_anom(j2000_days);

    let ecliptic_lon: f64 = mean_lon + calc_ecliptic_lon(mean_anom);

    let obliquity: f64 = -(AXIAL_TILT + 0.0000004 * j2000_days);

    let eci_x_norm: f64 = ecliptic_lon.cos();
    let eci_y_norm: f64 = ecliptic_lon.sin() * obliquity.cos();
    let eci_z_norm: f64 = ecliptic_lon.sin() * obliquity.sin();

    return Vector3::new(eci_x_norm, eci_y_norm, eci_z_norm);
}

pub fn calc_julian_day_mean_anom(j2000_days: f64) -> f64 {
    let rad_per_jday: f64 = EARTH_MEAN_ANOMALY_PER_JDAY;
    return J2000_EARTH_MEAN_ANOMALY + rad_per_jday * j2000_days;
}

/// Map between fixed frame observation to enu
/// 
/// Inputs
/// ------
/// pos_lla: `Vector3<f64>`
///     Lattitude, Longitude, Altitude
/// 
/// ecef_2: `Vector3<f64>`
///     ECEF object
/// 
/// Outputs
/// -------
/// enu: `Vector3<f64>`
///     East, North, Up
#[flutter_rust_bridge::frb(sync)] 
pub fn fixed_frame_to_enu(
    observer_lla: Vector3<f64>, 
    p_tgt_fixed: Vector3<f64>,
    equatorial_radius: f64,
    eccentricity: f64
) -> Vector3<f64> {
    let observer_ecef: Vector3<f64> = planetodetic_to_cartesian_rotational(
        observer_lla,
        equatorial_radius,
        eccentricity);
    let vec_ecef: Vector3<f64> = p_tgt_fixed - observer_ecef;
    let ecef_enu: Matrix3<f64> = Matrix3::new(
        -observer_lla[1].sin(), observer_lla[1].cos(), 0.0,
        -observer_lla[1].cos()*observer_lla[0].sin(), -observer_lla[1].sin()*observer_lla[0].sin(), observer_lla[0].cos(),
        observer_lla[1].cos()*observer_lla[0].cos(), observer_lla[1].sin()*observer_lla[0].cos(), observer_lla[0].sin());
    let enu: Vector3<f64> = ecef_enu * vec_ecef;
    return enu
}


#[flutter_rust_bridge::frb(sync)] 
pub fn calc_ecliptic_lon(mean_anom_rad: f64) -> f64 {
    let u_1_deg: f64 = 1.9148 * mean_anom_rad.sin();
    let u_2_deg: f64 = 0.02 * (2. * mean_anom_rad).sin();
    return (u_1_deg + u_2_deg) * PI / 180.0;
}

#[flutter_rust_bridge::frb(sync)] 
pub fn calc_overhead_passes(
    observer_lla: Vector3<f64>,
    days_to_search: i64,
    object_name: Option<String>,
    international_designator: Option<String>,
    epoch: NaiveDateTime,
    mean_motion_dot: f64,
    mean_motion_ddot: f64,
    drag_term: f64,
    element_set_number: u64,
    inclination: f64,
    right_ascension: f64,
    eccentricity: f64,
    argument_of_perigee: f64,
    mean_anomaly: f64,
    mean_motion: f64,
    revolution_number: u64,
    ephemeris_type: u8,
) -> (Vec<Vector3<f64>>, Vec<DateTime<Utc>>) {

    let elements: sgp4::Elements = sgp4::Elements{
        object_name: object_name,
        international_designator: international_designator,
        norad_id: 0,
        classification: sgp4::Classification::Unclassified,
        datetime: epoch,
        mean_motion_dot: mean_motion_dot,
        mean_motion_ddot: mean_motion_ddot,
        drag_term: drag_term,
        element_set_number: element_set_number,
        inclination: inclination,
        right_ascension: right_ascension,
        eccentricity: eccentricity,
        argument_of_perigee: argument_of_perigee,
        mean_anomaly: mean_anomaly,
        mean_motion: mean_motion,
        revolution_number: revolution_number,
        ephemeris_type: ephemeris_type,
    }; 

    let constants: sgp4::Constants = sgp4::Constants::from_elements(
        &elements
    ).unwrap();

    let now: DateTime<Utc> = Utc::now();
    
    let min_observer: i64 = (now - epoch.and_utc()).num_minutes();
    let min_dur: i64 = days_to_search * 24 * 60;
    
    // TODO-TD: Use .map()
    let mut azelrad: Vec<Vector3<f64>> = vec![];
    let mut times: Vec<DateTime<Utc>> = vec![];

    let now: DateTime<Utc> = Utc::now();
    
    let observer_ecef: Vector3<f64> = planetodetic_to_cartesian_rotational(
        observer_lla, 
        RADIUS_EQUATOR, 
        SURFACE_ECC
    );

    for minut in 0..min_dur {
        let eval_date_time: DateTime<Utc> = now + Duration::minutes(minut);
        let min_since_epoch: sgp4::MinutesSinceEpoch = sgp4::MinutesSinceEpoch((minut + min_observer) as f64);
        let pos: [f64; 3] = constants.propagate(min_since_epoch).unwrap().position;
        let p_eci: Vector3<f64> = Vector3::<f64>::new(pos[0], pos[1], pos[2]);

        // TODO-TD: split into propogator and binary mask
        let eci_to_ecef: Matrix3<f64> = calc_inertial_rotational_rotam(
            eval_date_time, 
            ROT_RATE * 60. * 60. * 24. 
        );

        let p_ecef: Vector3<f64> = eci_to_ecef * p_eci;
        let p_enu: Vector3<f64> = fixed_frame_to_enu(
            observer_lla, 
            p_ecef, 
            RADIUS_EQUATOR, 
            SURFACE_ECC
        ); 

        // TODO-TD: Vectorize
        let is_overhead: bool = p_enu[2] >= 0.;
        let observer_eci: Vector3<f64>  = eci_to_ecef.transpose() * observer_ecef;
        let is_night: bool = is_eclipsed_by_earth(
            observer_eci, 
            eval_date_time
        );

        let is_sunlit: bool = !is_eclipsed_by_earth(
            p_eci, 
            eval_date_time
        );

        if is_sunlit && is_overhead && is_night{
            let azelra: Vector3<f64> = enu_to_azelrad(p_enu);
            azelrad.append(&mut vec![azelra]);
            times.append(&mut vec![eval_date_time]);
        }
    }

    let results = (azelrad, times);
    return results;
}
