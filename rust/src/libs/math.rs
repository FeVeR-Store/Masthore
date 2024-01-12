#[allow(dead_code)]
pub fn sin<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).sin()
}
#[allow(dead_code)]
pub fn cos<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).cos()
}

#[allow(dead_code)]
pub fn tan<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).tan()
}

#[allow(dead_code)]
pub fn asin<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).asin()
}

#[allow(dead_code)]
pub fn acos<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).acos()
}
#[allow(dead_code)]
pub fn atan<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).atan()
}
#[allow(dead_code)]
pub fn sinh<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).sinh()
}

#[allow(dead_code)]
pub fn cosh<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).cosh()
}

#[allow(dead_code)]
pub fn tanh<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).tanh()
}

#[allow(dead_code)]
pub fn asinh<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).sinh()
}

#[allow(dead_code)]
pub fn acosh<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).cosh()
}
#[allow(dead_code)]
pub fn atanh<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).tanh()
}

#[allow(dead_code)]
pub fn log<T1: Into<f64>, T2: Into<f64>>(base: T1, x: T2) -> f64 {
    (x.into() as f64).log(base.into())
}

#[allow(dead_code)]
pub fn lg<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).log10()
}
#[allow(dead_code)]
pub fn ln<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).ln()
}

#[allow(dead_code)]
pub fn sqrt<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).sqrt()
}

#[allow(dead_code)]
pub fn cbrt<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).cbrt()
}

#[allow(dead_code)]
pub fn abs<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).abs()
}

#[allow(dead_code)]
pub fn ceil<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).ceil()
}

#[allow(dead_code)]
pub fn floor<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).floor()
}

#[allow(dead_code)]
pub fn round<T: Into<f64>>(x: T) -> f64 {
    (x.into() as f64).round()
}
