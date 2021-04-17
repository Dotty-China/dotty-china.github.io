---
layout: default
title: 概述
parent: 参考
nav_order: 1
---

# {{ page.title }}
{: .no_toc }

Scala 3 基于 Scala 2 实现了很多语言上的更改与增强。这篇参考文档中，我们论述了设计上的决策以及 Scala 3 与 Scala 2 的重要区别。

## 目标

语言的重设计以三个主要目标为指导：

- 巩固 Scala 的基础。使完整的编程语言与 [DOT calculus](https://infoscience.epfl.ch/record/227176/files/soundness_oopsla16.pdf) 
上的基础工作兼容，并应用从此工作中得到的经验。
- 使 Scala 更安全易用。Tame 像 implicit 这样强大结构，以提供更温和的学习曲线。去除 wart 和 puzzler。
- 进一步改善 Scala 语言结构的一致性和表达能力。

与这些目标对应的，语言变化分为七类：(1) 巩固基础的核心结构，(2)简化和(3)[限制](#限制)，使得语言更安全易用，(4)[减少结构](#被弃用的结构)使得语言更小更规则，
(5)[改变结构](#更改)以消除 wart，增加一致性和可用性，(6)[增加结构](#新结构)以填补空白和提高表现力，(7)一种新的、principled 的元编程替换掉 
[Scala 2 实验宏]((https://docs.scala-lang.org/overviews/macros/overview.html))。

## 必要基础

这些结构直接 model 了 DOT、高阶类型和[隐式解析的 SI calculus](https://infoscience.epfl.ch/record/229878/files/simplicitly_1.pdf)。

- [交集类型](new-types/intersection-types.md)，替代了复合类型，
- [并集类型](new-types/union-types.md)，
- [类型 Lambda](new-types/type-lambdas.md)，替代了使用结构类型和类型投影的编码，
- [Context 函数](contextual/context-functions.md)，提供对 given 参数的抽象。

## 简化

这些结构取代了现有结构，目的是让语言更简单易用，并促进代码样式的一致性。

- [Trait 参数](other-new-features/trait-parameters.md)用更通用的结构替代了[早期初始化器](dropped-features/early-initializers.md)。
- [Given instances](contextual/givens.md) 替代了隐式对象和隐式 def，更关注意图而非机制。
- [Using clauses](contextual/using-clauses.md) 替代了隐式参数，避免了它们的歧义。
- [扩展方法](contextual/extension-methods.md)用更简单清晰的机制替代了隐式类。
- [不透明类型别名](other-new-features/opaques.md)替代了值类的大多数用途，并确保不进行装箱。
- [顶层定义](dropped-features/package-objects.md)替代了包对象，减少样板代码。
- [Export clauses](other-new-features/export.md) 提供了一种简单而通用的机制实现组合，
它可以替代之前包对象继承类的 facade 模式。
- [可变参数拼接](changed-features/vararg-splices.md)现在在函数中使用 `xs*` 替代 `xs: _*` 和 `xs @ _*`，
- [Universal apply methods](other-new-features/creator-applications.md)允许使用简单的函数调用语法而无需 `new` 表达式创建对象。
`new` 表达式作为 creator application 无法使用时的备选方案保留。

除了[早期初始化器]](dropped-features/early-initializers.md)和旧式可变参数模式外，其他被取代的结构在 Scala 3.0 中仍然可用。
计划是弃用并在未来逐步淘汰它们。

值类（被不透明类型别名取代）是一个例外。目前我们没有计划弃用值类，因为如果 JVM 按照 [Project Valhalla](https://openjdk.java.net/projects/valhalla/)
中的计划原生支持了它们，我们可能会用更通用的形式将它们带回 Scala。

## 限制

为了使语言更加安全，这些结构受到更多限制。

- [隐式转换](contextual/conversions.md)：现在只有一种方式定义隐式转换，并且潜在的意外转换需要 language import。
- [Given 导入](contextual/given-imports.md)：现在需要一种特殊形式的 import 导入隐式，使得导入清晰可见。
- [类型投影](dropped-features/type-projection.md)：现在只有类可以作为类型投影的前缀。抽象类型上的类型投影是 unsound 的，所以不再受支持。
- [Multiversal Equality](contextual/multiversal-equality.md)：实现一个“opt-in”方案排除 `==` 和 `!=` 的无意义比较。
- [中缀](changed-features/operators.md)：使得方法应用语法在 code base 之间保持一致。

无限制的隐式转换在 Scala 3.0 中仍然可用，但即将被弃用并删除。上述列表中其他结构的无限制版本仅在 `-source 3.0-migration` 下可用。

## 被弃用的结构

这些结构被建议在没有新的结构作为替代品的情况下删除。放弃这些结构的目的是简化语言和实现。

- [延迟初始化](dropped-features/delayed-init.md)，
- [存在类型](dropped-features/existential-types.md)，
- [过程语法](dropped-features/procedure-syntax.md)，
- [类遮蔽](dropped-features/class-shadowing.md)，
- [XML 字面量](dropped-features/xml.md)，
- [Symbol 字面量](dropped-features/symlits.md)，
- [自动应用](dropped-features/auto-apply.md)，
- [弱一致性](dropped-features/weak-conformance.md)，
- 组合类型（被[交集类型](new-types/intersection-types.md)替代），
- [自动元组化](https://github.com/lampepfl/dotty/pull/4311) （已实现，但尚未合并）。

删除这些结构的时间各不相同。当前状态为：
- 完全未实现：
  - 延迟初始化，存在类型，弱一致性。
- `-source 3.0-migration` 下支持：
  - 过程语法，类遮蔽，Symbol 字面量，自动应用，受限形式的自动元组化。
- 在 3.0 中支持，将被弃用并逐步淘汰：
  - [XML 字面量](dropped-features/xml.md)，组合类型。

## 更改

这些结构发生了变化，现在它们更加规则且实用。

- [结构类型](changed-features/structural-types.md)：现在它们允许插入实现，大大提高了它们的实用性。与现在的实现相比，一些用例受到限制。
- [基于名称的模式匹配](changed-features/pattern-matching.md)：现有的无文档的 Scala 2 实现使用稍简化的形式编码。
- [自动 Eta 扩展](changed-features/eta-expansion.md)：现在 Eta 扩展也会在没有预期类型的时候一致地执行。
因此 `_` 后缀运算现在是多余的。它将在 Scala 3.0 之后被弃用并删除。
- [隐式解析](changed-features/implicit-resolution.md)：隐式解析规则已被清理，现在更易用、更符合直觉。隐式作用域被限制，不再包含包前缀，

旧式隐式解析的大多数部分在 `-source 3.0-migration` 下依然可用。此列表中的其他更改被无条件应用。

## 新结构

这些结构是对语言的补充，使其更强大易用。

- [枚举](enums/enums.md)为 enumeration 和[代数数据类型（Algebraic Data Type）](enums/adts.md)提供了简洁的语法。
- [参数解元组](other-new-features/parameter-untupling.md)避免了需要用 `case` 解构元组参数的情况。
- [依赖函数类型](new-types/dependent-function-types.md)将依赖方法类推到依赖函数值和类型。
- [多态函数类型](new-types/polymorphic-function-types.md)将多态方法类推到多态函数值和类型。
_当前状态_：有一个提案和一个已经合并的原型实现，但实现尚未最终确定（非常缺乏类型推导支持）。
- [Kind 多态](other-new-features/kind-polymorphism.md)允许定义同时能在类型和类型构造器上工作的操作符。
- [`@targetName` 注解](other-new-features/targetName.md)使其更容易与用其他语言编写的代码进行互操作，
并为了避免名称冲突提供了更大的灵活性。

## 元编程

下面的结构目标在于让 Scala 元编程基于新的基础。到目前位置，Scala 元编程是基于宏和像 [Shapeless](https://github.com/milessabin/shapeless)
这样的库的组合实现的，而 Shapeless 又基于一些关键宏。现在 Scala 2 的宏机制是 a thin veneer on top the current Scala 2 compiler，
这使得它们很脆弱，并且难以移植到 Scala 3。

值得注意的是，[Scala 2 语言规范](https://scala-lang.org/files/archive/spec/2.13/)中从未包括宏，
到目前为止宏只在 `-experimental` 标识下可用。但这没有阻止它被广泛使用。

为了能够移植宏的大部分功能，我们正在实验下面列出的高级语言结构。这些设计比 Scala 3.0 的其他语言结构更具临时性。
在最终发布前仍可能有一些更改。稳定的元编程所需的特性集是我们的首要目标。

- [匹配类型](new-types/match-types.md)允许对类型进行计算。
- [内联](metaprogramming/inline.md)本身提供了一些简单宏的简易实现，同时也是实现复杂宏的必要构造块。
- [引用和拼接](metaprogramming/macros.md)提供了一种用统一的抽象集表示宏和 staging 的规则的方法。
- [Type class 推导](contextual/derivation.md)提供了 Shapeless 以及其他基础库中 `Gen` 宏的语言内置实现。
新的实现比宏更健壮、更高效、更易用。
- [按名上下文参数](contextual/by-name-context-parameters.md)提供 [Shapeless](https://github.com/milessabin/shapeless) 
中的 `Lazy` 宏的更健壮的语言内置实现。

## 另请参见

[计划中的语言特性分类](https://dotty.epfl.ch/docs/reference/features-classification.html)是本页的扩展版本，
它添加了每个语言结构的状态（即作为 Scala 3 一部分的相对重要性，以及选择它的相对紧迫程度）和预期迁移成本。
