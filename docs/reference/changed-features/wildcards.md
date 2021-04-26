---
layout: default
title: 类型通配符参数
parent: 其他变化的特性
grand_parent: 参考
nav_order: 4
---

# {{ page.title }}

类型中的通配符参数语法从 `_` 修改为 `?`。例如：

```scala
List[?]
Map[? <: AnyRef, ? >: Null]
```

## 动机

我们希望使用下划线语法 `_` 表示匿名类型参数，以将其与值参数列表中的含义对其。
因此，就像 `f(_)` 是 Lambda `x => f(x)` 的简写一样，未来 `C[_]` 将成为类型 Lambda 
`[X] =>> C[X]` 的简写。这使得高阶类型更容易使用。这也消除了一个缺点，
It also removes the wart that, used as a type parameter, 
`F[_]` means `F` is a type constructor whereas used as a type, 
`F[_]` means it is a wildcard (i.e. existential) type。
在未来，无论在哪里 `F[_]` 都代表相同的东西。

我们选择 `?` 作为通配符类型的替代语法是因为它与 
[Java 语法](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html)相同。

## 迁移策略

迁移到新方案的策略是复杂的，特别是因为 [kind projector](https://github.com/typelevel/kind-projector) 
编译器插件依然使用 reverse convention，`?` 表示参数占位符而不是通配符。幸运的是，
kind projector 引入了 `*` 作为 `?` 的替代语法。

通过以下措施可以实现逐步迁移：

 1. 在 Scala 3.0 中，`_` 和 `?` 都是通配符的合法名称。
 2. 在 Scala 3.1 中，`_` 被弃用，而 `?` 作为通配符名称。一个 `-rewrite` 选项可以从其中一个重写到另一个。
 3. 在 Scala 3.2 中，`_` 的含义从通配符变为类型参数的占位符。
 4. Scala 3.1 的行为已经在 `-source future` 选项下可用。

为了使使用 kind projector 的代码库可以平滑迁移，我们在命令行选项 `-Ykind-projector` 
下采取了以下措施：

 1. 在 Scala 3.0 中，`*` 可作为类型参数占位符使用。
 2. 在 Scala 3.2 中，`*` 被弃用，取而代之的是 `_`。一个 `-rewrite` 选项可以从其中一个重写到另一个。
 3. 在 Scala 3.3 中，`*` 被再次删除，所有类型参数占位符都使用 `_` 表示。

这些规则使得使用 kind projector 插件的代码通过在 Scala 2 以及 Scala 3.0~3.2 间交叉编译成为可能。
