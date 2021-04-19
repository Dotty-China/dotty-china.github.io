---
layout: default
title: Using 子句
parent: 上下文抽象
grand_parent: 参考
nav_order: 3
---

# {{ page.title }}

函数式编程倾向于将大多数依赖关系表示为简单的函数参数化。这是干净而强大的，
但有时会让函数接受很多参数，在长调用链中一次又一次传递相同的值给很多函数。
上下文参数在这里很有用，它们能让编译器合成重复的参数，而不要求程序员显式编写它们。

例如，与前面说明过的 [given 实例](./givens.md)协同，适用于任何可排序参数的 `max` 函数可以这样定义：

```scala
def max[T](x: T, y: T)(using ord: Ord[T]): T =
   if ord.compare(x, y) < 0 then y else x
```

这里 `ord` 是由 `using` 子句引入的*上下文参数*。`max` 函数可以这样应用：

```scala
max(2, 3)(using intOrd)
```

`(using intOrd)` 部分把 `intOrd` 作为形参 `ord` 的实参传递。但是上下文参数的关键点在于调用时参数可以省略（通常是这样）。
因此，下面的应用同样有效：

```scala
max(2, 3)
max(List(1, 2, 3), Nil)
```

## 匿名上下文参数

在很多情况下，上下文参数的名称完全不需要显式写出，因为它只用于合成其他上下文参数的实参。
这种情况下，可以避免写出参数名，只需要写出它的类型。例如：

```scala
def maximum[T](xs: List[T])(using Ord[T]): T =
   xs.reduceLeft(max)
```

`maximum` 接受一个 `Ord` 类型的上下文参数，只把它作为推断出的参数传递给 `max`。
该参数的名称被忽略。

通常来说，上下文参数可以定义为一个完整的参数列表 `(p_1: T_1, ..., p_n: T_n)`，
也可以定义为一串类型序列 `T_1, ..., T_n`。Using 子句中不支持可变参数。

## 推断复杂参数

下面是另外两个具有 `Ord[T]` 类型的上下文参数的方法：

```scala
def descending[T](using asc: Ord[T]): Ord[T] = new Ord[T]:
   def compare(x: T, y: T) = asc.compare(y, x)

def minimum[T](xs: List[T])(using Ord[T]) =
   maximum(xs)(using descending)
```

`minimum` 方法的右侧将 `descending` 作为显式参数传递给 `maximum(xs)`。
With this setup，以下调用都是格式良好的，并都会被 normalize 到最后一种调用形式：

```scala
minimum(xs)
maximum(xs)(using descending)
maximum(xs)(using descending(using listOrd))
maximum(xs)(using descending(using listOrd(using intOrd)))
```

## 多个 `using` 子句

一个定义中可以有多个 `using` 子句，`using` 子句可以和普通参数子句自由混合。例如：

```scala
def f(u: Universe)(using ctx: u.Context)(using s: ctx.Symbol, k: ctx.Kind) = ...
```

多个 `using` 子句在应用时从左向右批评。例如：

```scala
object global extends Universe { type Context = ... }
given ctx : global.Context with { type Symbol = ...; type Kind = ... }
given sym : ctx.Symbol
given kind: ctx.Kind

```

那么以下调用都是有效的（并 normalize 到最后一种调用形式）。

```scala
f(global)
f(global)(using ctx)
f(global)(using ctx)(using sym, kind)
```

但是 `f(global)(using sym, kind)` 会产生一个类型错误。

## 召唤实例

`Predef` 中的方法 `summon` 返回指定类型的 given 值。例如，`Ord[List[Int]]` 类型的 given 实例可以这样生成：

```scala
summon[Ord[List[Int]]]  // reduces to listOrd(using intOrd)
```

`summon` 方法简单地定义为上下文参数上的 identity 函数（non-widening）。

```scala
def summon[T](using x: T): x.type = x
```

## 语法

下面是 [Scala 3 标准上下文无关语法](../syntax.md)中形参和实参的新语法。`using` 是一个软关键字，
只会在形参或实参列表的开头被识别。它可以在其他地方被用作普通标识符。

```
ClsParamClause      ::=  ... | UsingClsParamClause
DefParamClauses     ::=  ... | UsingParamClause
UsingClsParamClause ::=  ‘(’ ‘using’ (ClsParams | Types) ‘)’
UsingParamClause    ::=  ‘(’ ‘using’ (DefParams | Types) ‘)’
ParArgumentExprs    ::=  ... | ‘(’ ‘using’ ExprsInParens ‘)’
```
