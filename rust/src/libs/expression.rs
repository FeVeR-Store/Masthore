use std::collections::{hash_map::RandomState, HashMap};

use flutter_rust_bridge::frb;

pub struct ExpressionContext {
    active_variable: VariableBuilder,
    variables: HashMap<String, VariableBuilder>,
    constants: HashMap<String, Constant>,
}

pub struct CalcReturnForDart {
    pub result: Vec<f64>,
    pub constants: Vec<Constant>,
}

impl ExpressionContext {
    fn new() -> Self {
        let s = RandomState::new();
        let variables: HashMap<String, VariableBuilder> = HashMap::with_hasher(s.clone());
        let constants: HashMap<String, Constant> = HashMap::with_hasher(s.clone());
        Self {
            active_variable: VariableBuilder::uninitialized("x".to_string()),
            variables,
            constants,
        }
    }
    pub fn set_constant(&mut self, identity: &str, value: Constant) {
        self.constants.insert(String::from(identity), value);
    }
    pub fn get_constant(&mut self, identity: &str) -> Option<f64> {
        let constant = self.constants.get(identity);
        if constant.is_none() {
            None
        } else {
            Some(constant.unwrap().value)
        }
    }
    pub fn set_variable(&mut self, identity: &str, value: VariableBuilder) {
        self.variables.insert(String::from(identity), value);
    }
    pub fn is_active(&self, identity: &str) -> bool {
        self.active_variable.identity == identity
    }
    fn get_variable(&mut self, identity: &str) -> Option<&mut VariableBuilder> {
        self.variables.get_mut(&String::from(identity))
    }
    pub fn activate_variable(&mut self, identity: &str) {
        let variable_builder = self.variables.get_mut(&String::from(identity)).unwrap();
        variable_builder.activate();
        self.active_variable = VariableBuilder::from(variable_builder);
    }
    pub fn reset(&mut self) {
        self.active_variable = VariableBuilder::uninitialized("x".to_string());
        self.variables.clear();
        self.constants.clear();
    }
    pub fn clear_variable(&mut self) {
        self.variables.clear();
    }
    pub fn get_constant_list(&self) -> Vec<Constant> {
        let binding = self.constants.iter();
        let mut constant_list: Vec<Constant> = vec![];
        binding.for_each(|constant| constant_list.push(constant.1.clone()));
        constant_list
    }
    pub fn calc(&mut self, expression: fn() -> f64) -> Vec<f64> {
        let mut result: Vec<f64> = vec![];
        loop {
            let variable = self.active_variable.next();
            result.push(expression());
            if variable.is_none() {
                break;
            }
        }
        result
    }
}

pub struct VariableBuilder {
    pub identity: String,
    pub uninitialized: bool,
    pub min: f64,
    pub max: f64,
    pub step: f64,
    pub value: f64,
}

impl Iterator for VariableBuilder {
    type Item = f64;
    fn next(&mut self) -> Option<Self::Item> {
        if self.value <= self.max {
            self.value += self.step;
            Some(self.value)
        } else {
            None
        }
    }
}

impl VariableBuilder {
    pub fn uninitialized(identity: String) -> Self {
        Self {
            identity,
            uninitialized: true,
            min: 0.0,
            max: 0.0,
            step: 0.0,
            value: 0.0,
        }
    }
    pub fn activate(&mut self) {
        self.uninitialized = false;
        self.value = self.min - self.step;
    }
    pub fn from(builder: &Self) -> Self {
        Self {
            identity: builder.identity.clone(),
            uninitialized: builder.uninitialized,
            min: builder.min,
            max: builder.max,
            step: builder.step,
            value: builder.value,
        }
    }
}

pub static mut CONTEXT: Option<ExpressionContext> = None;

pub fn get_context() -> &'static mut ExpressionContext {
    unsafe {
        if CONTEXT.is_none() {
            CONTEXT = Some(ExpressionContext::new());
        }
        CONTEXT.as_mut().unwrap()
    }
}
pub fn constant<T1: Into<f64>, T2: Into<f64>, T3: Into<f64>, T4: Into<f64>>(
    identity: &str,
    default: T1,
    min: T2,
    max: T3,
    step: T4,
) -> f64 {
    let value: f64 = default.into();
    let constant = get_context().get_constant(identity);
    if constant.is_none() {
        get_context().set_constant(
            identity,
            Constant {
                identity: identity.to_string(),
                value,
                max: max.into(),
                min: min.into(),
                step: step.into(),
            },
        );
        value
    } else {
        constant.unwrap()
    }
}

pub fn variable(identity: &str) -> f64 {
    let context = get_context();
    let variable = context.get_variable(identity);
    if variable.is_none() {
        if context.variables.len() == 1 {
            let builder = context.variables.get_mut("x").unwrap();
            builder.identity = String::from(identity);
            let context = get_context();
            context.clear_variable();
            let mut variable_builder = VariableBuilder::from(builder);
            let value: f64 = variable_builder.next().unwrap();
            context.set_variable(identity, variable_builder);
            value
        } else {
            panic!("Variable {} not found", identity);
        }
    } else {
        let context = get_context();
        if context.is_active(identity) {
            context.active_variable.value
        } else {
            variable.unwrap().value
        }
    }
}

// pub fn multivariate<T: Into<f64>>(identity: &str, default: T) -> f64 {
//     let context = get_context();
//     let variable = context.get_variable(identity);
//     let value: f64;
//     if variable.is_none() {
//         value = default.into();
//         context.set_variable(
//             identity,
//             VariableBuilder::uninitialized(String::from(identity)),
//         );
//         value
//     } else {
//         variable.unwrap().next().unwrap()
//     }
// }

pub struct Sample {
    pub name: String,
    pub expression: fn() -> f64,
    pub latex: String,
    pub description: String,
    pub avatar: String,
    pub owner: Owner,
}
pub struct Owner {
    pub title: String,
    pub description: String,
}
impl Owner {
    pub fn clone(&self) -> Self {
        Owner {
            title: self.title.clone(),
            description: self.description.clone(),
        }
    }
}

#[frb]
pub struct Constant {
    pub identity: String,
    #[frb(non_final)]
    pub value: f64,
    pub max: f64,
    pub min: f64,
    pub step: f64,
}

impl Constant {
    pub fn clone(&self) -> Self {
        Constant {
            identity: self.identity.clone(),
            value: self.value,
            max: self.max,
            min: self.min,
            step: self.step,
        }
    }
}
