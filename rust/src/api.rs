use flutter_rust_bridge::frb;

use crate::{
    expressions::get_sample,
    libs::expression::{get_context, CalcReturnForDart, Constant, VariableBuilder},
};

// 表达式结构体
pub struct Expression {
    pub name: String,        // 函数唯一名字
    pub latex: String,       // latex表达式
    pub description: String, // 函数的描述
    pub avatar: String,      // 函数前的小图标，用作标志
}
// 函数列表，同一个Owner的Sample会合并到一个函数列表中
// 如果Owner为Single，那么这个Sample会转化为一个空的函数列表
pub struct ExpressionList {
    pub name: String,          // 列表名/函数唯一名字
    pub latex: String,         // ""/latex表达式
    pub description: String,   // 函数列表描述/函数描述
    pub avatar: String,        // ""/函数前的小图标，用作标志
    pub list: Vec<Expression>, // 函数列表/[]
}

// 绘制图像
#[frb(sync)] // 表示为同步函数
pub fn draw(
    func: String,                      // 函数唯一名字
    variable_builder: VariableBuilder, // 变量构建器
    constant_provider: Vec<Constant>,  // 常量
    change_context: bool,              // 是否更新上下文
) -> CalcReturnForDart {
    let context = get_context(); // 获取当前的上下文
                                 // 若需要更新上下文
    if change_context {
        context.reset(); // 重置上下文
    }
    // 设置变量
    context.set_variable("x", variable_builder);
    // 激活变量
    context.activate_variable("x");
    // 设置所有常量
    constant_provider
        .iter()
        .for_each(|constant| context.set_constant(&constant.identity, constant.clone()));
    // 返回
    CalcReturnForDart {
        result: context.calc(
            get_sample()
                .iter()
                .find(|sample| sample.name == func)
                .unwrap()
                .expression,
        ), // 计算结果
        constants: if change_context
        // 当更新上下文之后
        {
            // 返回常量列表
            context.get_constant_list()
        } else {
            // 否则返回空列表
            vec![]
        },
    }
}

// 获取函数列表
#[frb(sync)]
pub fn get_functions() -> Vec<ExpressionList> {
    // 要返回的函数列表
    let mut function_lists = vec![];
    // 将Sample转化为ExpressionList
    for sample in get_sample() {
        // 如果Owner为Single
        if sample.owner.title.is_empty() {
            // 将Sample转化为ExpressionList
            function_lists.push(ExpressionList {
                name: sample.name.clone(),
                latex: sample.latex.clone(),
                description: sample.description.clone(),
                avatar: sample.avatar.clone(),
                list: vec![], // 列表为空
            });
        } else {
            // 否则
            let sample_list = function_lists
                .iter_mut()
                .find(|x| x.name == sample.owner.title); // 查找是否包含相同Owner的函数列表

            // 若不存在
            if sample_list.is_none() {
                // 那么创建一个新的ExpressionList
                function_lists.push(ExpressionList {
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
                // 若存在
                let sample_list = sample_list.unwrap();
                // 那么将这个函数添加到这个列表中
                sample_list.list.push(Expression {
                    name: sample.name.clone(),
                    latex: sample.latex.clone(),
                    description: sample.description.clone(),
                    avatar: sample.avatar.clone(),
                });
            }
        }
    }
    // 最后返回
    function_lists
}
