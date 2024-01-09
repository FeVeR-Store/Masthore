use crate::functions::{pulse, sin, tan, x};
use crate::libs;
use crate::libs::expression::{CalcReturnForDart, Constant, Owner, VariableBuilder};

use flutter_rust_bridge::SyncReturn;
use libs::expression::{get_context, Sample};

pub struct SampleForDart {
    pub label: String,
    pub latex: String,
    pub description: String,
    pub avater: String,
}
pub struct SampleListForDart {
    pub label: String,
    pub latex: String,
    pub description: String,
    pub avater: String,
    pub list: Vec<SampleForDart>,
}

pub static mut SAMPLES: Option<Vec<Sample>> = None;

fn get_sample() -> &'static mut Vec<Sample> {
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
            label: "sin".to_string(),
            expression: sin,
            latex: "$asin(bx+c)+d$".to_string(),
            description: "正弦函数曲线".to_string(),
            avatar: "sin".to_string(),
            owner: base.clone(),
        },
        Sample {
            label: "ax+b".to_string(),
            expression: x,
            latex: "$ax+b$".to_string(),
            description: "线性函数".to_string(),
            avatar: "x".to_string(),
            owner: base.clone(),
        },
        Sample {
            label: "pulse".to_string(),
            expression: pulse,
            latex: "pulse".to_string(),
            description: "脉冲函数".to_string(),
            avatar: "_-_".to_string(),
            owner: single.clone(),
        },
        Sample {
            label: "tan".to_string(),
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

pub fn draw(
    func: String,
    variable_builder: VariableBuilder,
    constant_provider: Vec<Constant>,
    change_context: bool,
) -> SyncReturn<CalcReturnForDart> {
    let context = get_context();
    if change_context {
        context.reset();
    }
    context.set_variable("x", variable_builder);
    context.activate_variable("x");
    constant_provider
        .iter()
        .for_each(|constant| context.set_constant(&constant.identity, constant.clone()));
    SyncReturn(CalcReturnForDart {
        result: context.calc(
            get_sample()
                .iter()
                .find(|sample| sample.label == func)
                .unwrap()
                .expression,
        ),
        constants: if change_context {
            context.get_constant_list()
        } else {
            vec![]
        },
    })
}

pub fn get_sample_for_dart() -> SyncReturn<Vec<SampleListForDart>> {
    let mut sample_lists = vec![];

    for sample in get_sample() {
        if sample.owner.title.is_empty() {
            sample_lists.push(SampleListForDart {
                label: sample.label.clone(),
                latex: sample.latex.clone(),
                description: sample.description.clone(),
                avater: sample.avatar.clone(),
                list: vec![],
            });
        } else {
            let sample_list = sample_lists
                .iter_mut()
                .find(|x| x.label == sample.owner.title);

            if sample_list.is_none() {
                sample_lists.push(SampleListForDart {
                    label: sample.owner.title.clone(),
                    latex: "".to_string(),
                    description: sample.owner.description.clone(),
                    avater: "".to_string(),
                    list: vec![SampleForDart {
                        label: sample.label.clone(),
                        latex: sample.latex.clone(),
                        description: sample.description.clone(),
                        avater: sample.avatar.clone(),
                    }],
                });
            } else {
                let sample_list = sample_list.unwrap();
                sample_list.list.push(SampleForDart {
                    label: sample.label.clone(),
                    latex: sample.latex.clone(),
                    description: sample.description.clone(),
                    avater: sample.avatar.clone(),
                });
            }
        }
    }

    SyncReturn(sample_lists)
}
