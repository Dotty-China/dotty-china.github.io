---
layout: default
title: 上下文界定
parent: 上下文抽象
grand_parent: 参考
nav_order: 4
---

# {{ page.title }}

上下文界定（Context Bound）是表示依赖于类型参数的上下文参数的公共模式的简写。使用上下文界定，最后一段的 `maximum` 函数可以这样写：

```scala
def maximum[T: Ord](xs: List[T]): T = xs.reduceLeft(max)
```

在方法或类的类型参数 `T` 上的类似 `: Ord` 的界定表示具有 `with Ord[T]` 上下文参数。
从上下文界定生成的上下文参数在包含它的方法或类的定义的最后。例如：

```scala
def f[T: C1 : C2, U: C3](x: T)(using y: U, z: V): R
```

会被展开为

```scala
def f[T, U](x: T)(using y: U, z: V)(using C1[T], C2[T], C3[U]): R
```

上下文界定可以和子类型界定组合。如果两者都存在，那么子类型界定应该在最前，例如：

```scala
def g[T <: B : C](x: T): R = ...
```

## 迁移

为了简化迁移，Scala 3.0 中的上下文界定映射到旧式隐式参数，这些参数可以通过 `(using ...)` 子句或者普通的方法应用传递。
从 Scala 3.1 开始，它们将映射到如上所述的上下文参数。

If the source version is `future-migration`, any pairing of an evidence
context parameter stemming from a context bound with a normal argument will give a migration
warning. The warning indicates that a `(using ...)` clause is needed instead. The rewrite can be
done automatically under `-rewrite`.

## 语法

```
TypeParamBounds   ::=  [SubtypeBounds] {ContextBound}
ContextBound      ::=  ‘:’ Type
```
