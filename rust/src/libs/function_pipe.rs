/* pub fn sin(x: f32) -> f32 {
    x.sin()
}

pub fn cos(x: f32) -> f32 {
    x.cos()
}

pub fn tan(x: f32) -> f32 {
    x.tan()
}

pub fn asin(x: f32) -> f32 {
    x.asin()
}

pub fn acos(x: f32) -> f32 {
    x.acos()
}
pub fn atan(x: f32) -> f32 {
    x.atan()
}
pub fn sinh(x: f32) -> f32 {
    x.sinh()
}

pub fn cosh(x: f32) -> f32 {
    x.cosh()
}

pub fn tanh(x: f32) -> f32 {
    x.tanh()
}

pub fn asinh(x: f32) -> f32 {
    x.sinh()
}

pub fn acosh(x: f32) -> f32 {
    x.cosh()
}
pub fn atanh(x: f32) -> f32 {
    x.tanh()
}

pub fn log(base: f32) -> impl Fn(f32) -> f32 {
    move |x| x.log(base)
}
pub fn lg(x: f32) -> f32 {
    x.log10()
}
pub fn ln(x: f32) -> f32 {
    x.ln()
}

pub fn sqrt(x: f32) -> f32 {
    x.sqrt()
}
pub fn cbrt(x: f32) -> f32 {
    x.cbrt()
}
pub fn abs(x: f32) -> f32 {
    x.abs()
}
pub fn ceil(x: f32) -> f32 {
    x.ceil()
}
pub fn floor(x: f32) -> f32 {
    x.floor()
}
pub fn round(x: f32) -> f32 {
    x.round()
}
pub fn plus(number: f32) -> impl Fn(f32) -> f32 {
    move |x| x + number
}
pub fn minus(number: f32) -> impl Fn(f32) -> f32 {
    move |x| x - number
}
pub fn multiply(number: f32) -> impl Fn(f32) -> f32 {
    move |x| x * number
}
pub fn divide(number: f32) -> impl Fn(f32) -> f32 {
    move |x| x / number
}

enum Operator {
    Plus,
    Minus,
    Multiply,
    Divide,
}

pub fn create_function(functions: Vec<impl Fn(f32) -> f32>) -> impl Fn(f32) -> f32 {
    move |x| {
        let mut result = x;
        for f in &functions {
            result = f(result);
        }
        result
    }
}
 */