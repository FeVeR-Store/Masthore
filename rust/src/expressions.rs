use crate::functions::{pulse, sin, tan, x};
use crate::libs;
use crate::libs::expression::Owner;

use flutter_rust_bridge::frb;
use libs::expression::Sample;

#[frb[ignore]]
pub fn get_sample() -> &'static mut Vec<Sample> {
    let base = Owner {
        title: "基本函数".to_string(),
        description: "基本函数".to_string(),
    };
    let single = Owner {
        title: "".to_string(),
        description: "".to_string(),
    };
    let samples = vec![
        Sample {
            name: "ax+b".to_string(),
            expression: x,
            latex: "$ax+b$".to_string(),
            description: "线性函数".to_string(),
            avatar: "x".to_string(),
            owner: base.clone(),
        },
        Sample {
            name: "pulse".to_string(),
            expression: pulse,
            latex: "pulse".to_string(),
            description: "脉冲函数".to_string(),
            avatar: "_-_".to_string(),
            owner: single.clone(),
        },
        Sample {
            name: "sin".to_string(),
            expression: sin,
            latex: "$asin(bx+c)+d$".to_string(),
            description: "正弦函数曲线".to_string(),
            avatar: "sin".to_string(),
            owner: base.clone(),
        },
        Sample {
            name: "tan".to_string(),
            expression: tan,
            latex: "$atan(bx+c)+d$".to_string(),
            description: "正切函数曲线".to_string(),
            avatar: "tan".to_string(),
            owner: base.clone(),
        },
    ];

    unsafe {
        if SAMPLES.is_none() {
            SAMPLES = Some(samples);
        }
        SAMPLES.as_mut().unwrap()
    }
}

static mut SAMPLES: Option<Vec<Sample>> = None;
