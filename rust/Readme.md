# Masthore 函数部分（native 部分）文档

## 简介

Masthore 使用 Rust 编程语言实现函数的计算以及定义显示的信息，其中一个 rust 函数，latex 表达式，描述和标识符。这个文档将帮助你理解项目的结构和如何实现一个函数。

## 提供的 api

### `constant` 函数

```rust
// number = T:Into<f64> 所以它可以是 f64, f32, i32, i64, u32, u64等各种类型的数字
fn constant(name: &str, value: number, min: number, max: number, step: number) -> f64
```

作用：定义一个常量。

参数：

- name：常量的名字，可使用 "\$" 包裹来使用 LaTeX 表达式，例如 "\$\alpha\$"=> $\alpha$。
- value：常量的默认值。
- min：常量的最小值。
- max：常量的最大值。
- step：常量的变化步长，这个用于设置参数时的滑动条，值越小，滑动条越平滑，但是参数的小数也会越长（不过已经进行优化，滑动时图像的变化会比步长平滑 10 倍，因此 0.01 基本可以）。
- 返回值：常量的当前值。

### `variable` 函数

```rust
fn variable(name: &str) -> f64
```

作用：定义一个变量。

参数：

- name：变量的名字。
- 返回值：变量的当前值。

### `Sample` 结构体

```rust
struct Sample {
    name: String,
    expression: fn(f64) -> f64,
    latex: String,
    description: String,
    avatar: String,
    owner: Owner,
}
```

- name：函数的唯一标识符（也就是函数的名字，但是必须是唯一的）。
- expression：函数的具体实现（就是写的 rust 函数）。
- latex：函数的 LaTeX 表达式。
- description：函数的描述。
- avatar：函数前的小图标，用作标志。
- owner：函数所属的 `Owner` 结构体。

### `Owner` 结构体

```rust
struct Owner {
    title: String,
    description: String,
}
```

owner 表示函数所属于的列表，用于分类。

- title：Owner 的标题。
- description：Owner 的描述。

_特殊的，如果不需要分类，可以使用`single`作为`owner`。_

### `math` 模块

提供基本的函数，比如`sin`,`cos`,`tan`,`log`等，通过`math::`前缀来使用。

```rust
math::sin(x); // sin(x)
math::cos(x); // cos(x)
math::tan(x); // tan(x)
math::log(a,x); // log(a)(x)
```

_注：math中的函数是通过rust `f64`类型的方法实现的，比如`math::sin(x)`实际调用的是`x.sin()`_

### 使用示例

```rust
// 定义 base 列表
let base = Owner {
    title: "基本函数".to_string(),
    description: "基本函数".to_string(),
};

// 编写函数的具体实现
fn cos() {
    // 定义常量
    let a = constant("a", 1, -10, 10, 0.01);
    let b = constant("b", 1, -10, 10, 0.01);
    let c = constant("c", 0, -10, 10, 0.01);
    let d = constant("d", 0, -10, 10, 0.01);
    // 定义变量
    let x = variable("x");
    // 返回计算值
    return a * math::cos(b * x + c) + d;
}

// 定义 Sample
Sample {
    name: "cos".to_string(), //由于Sample接受的类型为String，因此需要使用to_string()转换
    expression: cos, // 函数的具体实现
    latex: "$acos(bx+c)+d$".to_string(), // 函数的 LaTeX 表达式
    description: "正弦函数曲线".to_string(), // 函数的描述
    avatar: "cos".to_string(),
    owner: base.clone(), // 表示属于base列表，需要使用.clone()
}
```

$\beta+\alpha=10$
