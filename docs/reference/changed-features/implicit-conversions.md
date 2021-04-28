---
layout: default
title: 隐式转换
parent: 其他变化的特性
grand_parent: 参考
nav_order: 9
---

# {{ page.title }}

*隐式转换（Implicit Conversion）*，也称为*视图（View）*，
是编译器会在以下几种情况下应用的转换：

1. 当遇到类型为 `T` 的表达式 `e`，但是编译器需要类型为 `S` 的表达式时。
2. 当表达式 `e.m` 中 `e` 的类型为 `T`，但 `T` 没有定义成员 `m` 时。

在这些情况下，编译器会在隐式范围内查找一个能够把类型为 `T` 的表达式
转换为类型为 `S` （第二种情况下则是定义了成员 `m` 的类型）的表达式的转换。

这个转换可以是其中之一：

1. 类型为 `T => S` 或 `(=> T) => S` 的 `implicit def`。
2. 类型为 `scala.Conversion[T, S]` 的隐式值。

定义隐式转换时需要导入 `scala.language.implicitConversions` 到作用域中，
或向编译器添加标志 `-language:implicitConversions`，否则编译器会发出一个警告。

## 示例

第一个例子来自 `scala.Predef`。因为这个隐式转换，
可以将 `scala.Int` 类型的值传递给接受 `java.lang.Integer` 的方法。

```scala
import scala.language.implicitConversions
implicit def int2Integer(x: Int): java.lang.Integer =
   x.asInstanceOf[java.lang.Integer]
```

第二个例子演示了给定一个其他类型的 `Ordering` 的情况下，
如何使用 `Conversion` 为任意类型定义 `Ordering`。

```scala
import scala.language.implicitConversions
implicit def ordT[T, S](
      implicit conv: Conversion[T, S],
               ordS: Ordering[S]
   ): Ordering[T] =
    // `ordS` compares values of type `S`, but we can convert from `T` to `S`
   (x: T, y: T) => ordS.compare(x, y)

class A(val x: Int) // The type for which we want an `Ordering`

// Convert `A` to a type for which an `Ordering` is available:
implicit val AToInt: Conversion[A, Int] = _.x

implicitly[Ordering[Int]] // Ok, exists in the standard library
implicitly[Ordering[A]] // Ok, will use the implicit conversion from
                        // `A` to `Int` and the `Ordering` for `Int`.
```

[更多细节](implicit-conversions-spec.md){: .btn .btn-purple }
