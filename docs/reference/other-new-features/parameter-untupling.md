---
layout: default
title: 参数解元组
parent: 其他新特性
grand_parent: 参考
nav_order: 7
---

# {{ page.title }}

假设有这样一个二元元组的列表：

```scala
val xs: List[(Int, Int)]
```

当你想要把 `xs` 映射成一个 `Int` 列表，每一对数字都映射到它们的和。以前，最好的方法是使用模式匹配解构：

```scala
xs map {
   case (x, y) => x + y
}
```

虽然这是正确的，但也不方便且令人困惑，因为 `case` 表示模式匹配可能会失败。
Scala 3 现在允许这种写法作为一个更短且更清晰的替代方案：

```scala
xs.map {
   (x, y) => x + y
}
```

或者，也可以写成：

```scala
xs.map(_ + _)
```

一般地，如果期望的类型是一元函数类型 `((T_1, ..., T_n)) => U`，
则使用 `case` 把有 `n > 1` 个参数的函数值转换为模式匹配闭包。

## 参考

更多详情请参见：

* [更多详情](./parameter-untupling-spec.md)页面，或者
* [Issue #897](https://github.com/lampepfl/dotty/issues/897)。
