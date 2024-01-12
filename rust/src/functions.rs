use crate::libs::{self, math};
use libs::expression::{constant, variable};

pub fn x() -> f64 {
    let k = constant("k", 1, -10, 10, 0.1);
    let b = constant("b", 0, -10, 10, 0.01);
    let x = variable("x");
    return k * x + b;
}

pub fn sin() -> f64 {
    let a = constant("a", 1, -10, 10, 0.1);
    let b = constant("b", 1, -10, 10, 0.01);
    let c = constant("c", 0, -10, 10, 0.01);
    let d = constant("d", 0, -10, 10, 0.01);
    let x = variable("x");
    return a * math::sin(b * x + c) + d;
    // a*sin(bx+c)+d
}

pub fn pulse() -> f64 {
    let min = constant("m", 0, -10, 10, 0.01);
    let max = constant("n", 1, -10, 10, 0.01);
    let length = constant("l", 1, -10, 10, 0.01);
    let x = variable("x");
    if x.abs() % (length * 2.0) < length {
        min
    } else {
        max
    }
}

pub fn tan() -> f64 {
    let a = constant("a", 1, -10, 10, 0.1);
    let b = constant("b", 1, -10, 10, 0.01);
    let c = constant("c", 0, -10, 10, 0.01);
    let x = variable("x");
    return a * math::tan(b * x + c);
    // a*tan(bx+c)
}
