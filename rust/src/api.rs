use flutter_rust_bridge::frb;

use crate::{libs::expression::{VariableBuilder, Constant, CalcReturnForDart, get_context}, expressions::get_sample};

pub struct Expression {
    pub name: String,
    pub latex: String,
    pub description: String,
    pub avatar: String,
}
pub struct ExpressionList {
    pub name: String,
    pub latex: String,
    pub description: String,
    pub avatar: String,
    pub list: Vec<Expression>,
}

#[frb(sync)]
pub fn draw(
    func: String,
    variable_builder: VariableBuilder,
    constant_provider: Vec<Constant>,
    change_context: bool,
) -> CalcReturnForDart {
    let context = get_context();
    if change_context {
        context.reset();
    }
    context.set_variable("x", variable_builder);
    context.activate_variable("x");
    constant_provider
        .iter()
        .for_each(|constant| context.set_constant(&constant.identity, constant.clone()));
    CalcReturnForDart {
        result: context.calc(
            get_sample()
                .iter()
                .find(|sample| sample.name == func)
                .unwrap()
                .expression,
        ),
        constants: if change_context {
            context.get_constant_list()
        } else {
            vec![]
        },
    }
}

#[frb(sync)]
pub fn get_functions() -> Vec<ExpressionList> {
    let mut sample_lists = vec![];

    for sample in get_sample() {
        if sample.owner.title.is_empty() {
            sample_lists.push(ExpressionList {
                name: sample.name.clone(),
                latex: sample.latex.clone(),
                description: sample.description.clone(),
                avatar: sample.avatar.clone(),
                list: vec![],
            });
        } else {
            let sample_list = sample_lists
                .iter_mut()
                .find(|x| x.name == sample.owner.title);

            if sample_list.is_none() {
                sample_lists.push(ExpressionList {
                    name: sample.owner.title.clone(),
                    latex: "".to_string(),
                    description: sample.owner.description.clone(),
                    avatar: "".to_string(),
                    list: vec![Expression {
                        name: sample.name.clone(),
                        latex: sample.latex.clone(),
                        description: sample.description.clone(),
                        avatar: sample.avatar.clone(),
                    }],
                });
            } else {
                let sample_list = sample_list.unwrap();
                sample_list.list.push(Expression {
                    name: sample.name.clone(),
                    latex: sample.latex.clone(),
                    description: sample.description.clone(),
                    avatar: sample.avatar.clone(),
                });
            }
        }
    }
    sample_lists
}
