---
layout: default
title: 参数解元组
parent: 其他新特性
grand_parent: 参考
nav_order: 7
---

Say you have a list of pairs

```scala
val xs: List[(Int, Int)]
```

and you want to map `xs` to a list of `Int`s so that each pair of numbers is mapped to
their sum. Previously, the best way to do this was with a pattern-matching decomposition:

```scala
xs map {
   case (x, y) => x + y
}
```

While correct, this is also inconvenient and confusing, since the `case`
suggests that the pattern match could fail. As a shorter and clearer alternative Scala 3 now allows

```scala
xs.map {
   (x, y) => x + y
}
```

or, equivalently:

```scala
xs.map(_ + _)
```

Generally, a function value with `n > 1` parameters is converted to a
pattern-matching closure using `case` if the expected type is a unary
function type of the form `((T_1, ..., T_n)) => U`.

## Reference

For more information see:

* [More details](./parameter-untupling-spec.md)
* [Issue #897](https://github.com/lampepfl/dotty/issues/897).
