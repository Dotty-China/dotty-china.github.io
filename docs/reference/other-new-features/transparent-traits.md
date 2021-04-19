---
layout: default
title: 透明 Trait
parent: 其他新特性
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

Traits are used in two roles:

 1. As mixins for other classes and traits
 2. As types of vals, defs, or parameters

一些 trait 主要用于第一种用途，我们通常不希望再推断类型中看到它。
例如，编译器把 `Product` trait 作为混合 trait 添加至每个 case 类和 case 对象中。
在 Scala 2 中，这个父 trait 有时让推断出的类型比应有的更复杂。例如：

```scala
trait Kind
case object Var extends Kind
case object Val extends Kind
val x = Set(if condition then Val else Var)
```

这里 `x` 被推断出的类型为 `Set[Kind & Product & Serializable]`，
而往往用户想要的是 `Set[Kind]`。推断出这种特殊类型的原因如下：

- `if` 的结果类型是[并集类型](../new-types/union-types.md) `Val | Var`。
- 并集类型在类型推断中被拓宽到不是并集类型的最小超类型。在这个例子中，
  这个类型是 `Kind & Product & Serializable`，因为这三个 trait 都是 `Val` 和 `Var` 共同实现的 trait。
  因此这个类型成为集合被推断出的元素类型。

Scala 3 允许将混合 trait 声明为 `transparent` 的，这意味着它可以在类型推断中被抑制。
Here's an example that follows the lines of the code above，但是现在使用了一个新的透明 trait `S`，
而不是 `Product`：

```scala
transparent trait S
trait Kind
object Var extends Kind, S
object Val extends Kind, S
val x = Set(if condition then Val else Var)
```

现在 `x` 的类型被推断为 `Set[Kind]`。公共的透明 trait `S` 不出现在被推断出的类型中，

## 透明的 trait

Trait `scala.Product`、`java.lang.Serializable` 和 `java.lang.Comparable` 
被自动视为透明 trait 处理。Scala 2 trait 也可以通过添加 [`@transparentTrait` 注解](https://dotty.epfl.ch/api/scala/annotation/transparentTrait.html)
变为透明 trait。这个注解被定义于 `scala.annotation`。当不再需要 Scala 2/3 的互操作性时，
它将被弃用。

通常，透明 trait 是影响继承它的类实现的 trait，而其本身通常不作为类型使用。
标准集合库中的两个例子是：

- `IterableOps`，为 `Iterable` 提供方法实现。
- `StrictOptimizedSeqOps`，它使用高效索引优化了一些操作的实现。

通常来说，任何递归继承的 trait 都是被声明为透明的好的候选者。

## 推断规则

Transparent traits can be given as explicit types as usual. But they are often elided when types are inferred. Roughly, the rules for type inference say that transparent traits are dropped from intersections where possible.

The precise rules are as follows:

- When inferring a type of a type variable, or the type of a val, or the return type of a def,
- where that type is not higher-kinded,
- and where `B` is its known upper bound or `Any` if none exists:
- If the type inferred so far is of the form `T1 & ... & Tn` where
  `n >= 1`, replace the maximal number of transparent `Ti`s  by `Any`, while ensuring that
  the resulting type is still a subtype of the bound `B`.
- However, do not perform this widening if all transparent traits `Ti` can get replaced in that way.

The last clause ensures that a single transparent trait instance such as `Product` is not widened to `Any`. Transparent trait instances are only dropped when they appear in conjunction with some other type.
