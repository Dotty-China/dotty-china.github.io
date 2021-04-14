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

与这些目标对应的，语言变化分为七类：(1) 巩固基础的核心结构，(2)简化和(3)[限制]()，使得语言更安全易用，(4)[减少结构]()使得语言更小更规则，
(5)改变结构以消除 wart，增加一致性和可用性，(6)[增加结构]()以填补空白和提高表现力，(7)一种新的、principled 的元编程替换掉 
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

The date when these constructs are dropped varies. The current status is:

## Changes

These constructs have undergone changes to make them more regular and useful.

- [Structural Types](changed-features/structural-types.md):
  They now allow pluggable implementations, which greatly increases their usefulness. Some usage patterns are restricted compared to the status quo.
- [Name-based pattern matching](changed-features/pattern-matching.md):
  The existing undocumented Scala 2 implementation has been codified in a slightly simplified form.
- [Automatic Eta expansion](changed-features/eta-expansion.md):
  Eta expansion is now performed universally also in the absence of an expected type. The postfix `_` operator is thus made redundant. It will be deprecated and dropped after Scala 3.0.
- [Implicit Resolution](changed-features/implicit-resolution.md):
  The implicit resolution rules have been cleaned up to make them more useful and less surprising. Implicit scope is restricted to no longer include package prefixes.

Most aspects of old-style implicit resolution are still available under `-source 3.0-migration`. The other changes in this list are applied unconditionally.

## New Constructs

These are additions to the language that make it more powerful or pleasant to use.

- [Enums](enums/enums.md) provide concise syntax for enumerations and [algebraic data types](enums/adts.md).
- [Parameter untupling](other-new-features/parameter-untupling.md) avoids having to use `case` for tupled parameter destructuring.
- [Dependent function types](new-types/dependent-function-types.md) generalize dependent methods to dependent function values and types.
- [Polymorphic function types](new-types/polymorphic-function-types.md) generalize polymorphic methods to polymorphic function values and types.
  _Current status_: There is a proposal and a merged prototype implementation, but the implementation has not been finalized (it is notably missing type inference support).
- [Kind polymorphism](other-new-features/kind-polymorphism.md) allows the definition of operators working equally on types and type constructors.
- [`@targetName` annotations](other-new-features/targetName.md) make it easier to interoperate with code written in other languages and give more flexibility for avoiding name clashes.

## Metaprogramming

The following constructs together aim to put metaprogramming in Scala on a new basis. So far, metaprogramming was achieved by a combination of macros and libraries such as [Shapeless](https://github.com/milessabin/shapeless) that were in turn based on some key macros. Current Scala 2 macro mechanisms are a thin veneer on top the current Scala 2 compiler, which makes them fragile and in many cases impossible to port to Scala 3.

It's worth noting that macros were never included in the [Scala 2 language specification](https://scala-lang.org/files/archive/spec/2.13/) and were so far made available only under an `-experimental` flag. This has not prevented their widespread usage.

To enable porting most uses of macros, we are experimenting with the advanced language constructs listed below. These designs are more provisional than the rest of the proposed language constructs for Scala 3.0. There might still be some changes until the final release. Stabilizing the feature set needed for metaprogramming is our first priority.

- [Match Types](new-types/match-types.md)
  allow computation on types.
- [Inline](metaprogramming/inline.md)
  provides by itself a straightforward implementation of some simple macros and is at the same time an essential building block for the implementation of complex macros.
- [Quotes and Splices](metaprogramming/macros.md)
  provide a principled way to express macros and staging with a unified set of abstractions.
- [Type class derivation](contextual/derivation.md)
  provides an in-language implementation of the `Gen` macro in Shapeless and other foundational libraries. The new implementation is more robust, efficient and easier to use than the macro.
- [By-name context parameters](contextual/by-name-context-parameters.md)
  provide a more robust in-language implementation of the `Lazy` macro in [Shapeless](https://github.com/milessabin/shapeless).

## See Also

[A classification of proposed language features](./features-classification.md) is
an expanded version of this page that adds the status (i.e. relative importance to be a part of Scala 3, and relative urgency when to decide this) and expected migration cost
of each language construct.
