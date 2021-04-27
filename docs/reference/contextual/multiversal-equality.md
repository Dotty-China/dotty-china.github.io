---
layout: default
title: Multiversal Equality
parent: 上下文抽象
grand_parent: 参考
nav_order: 9
---

# {{ page.title }}

以前，Scala 具有普遍的相等性：任意类型的两个值都能用 `==` 和 `!=` 进行比较。
这是因为 `==` 和 `!=` 是用 Java 的 `equals` 方法实现的，它可以比较任意两个引用类型的值。

Universal equality 是方便的。但是它也很危险，因为破坏了类型安全性。
例如，让我们假设这是一段重构了错误的程序后留下的代码，其中值 `y` 的类型为 `S`，而不是正确的类型 `T`。

```scala
val x = ... // of type T
val y = ... // of type S, but should be T
x == y      // typechecks, will always yield false
```

如果 `y` 与 `T` 类型的其他值进行比较，程序仍然能通过类型检查，因为所有类型的值之间都可以互相比较。
但是它可能会产生意想不到的结果，并在运行时失败。

Multiversal equality 是一种选择性加入的，让 universal equality 更安全的方式。
它使用二元 type class [`scala.CanEqual`](https://github.com/lampepfl/dotty/blob/master/library/src/scala/CanEqual.scala) 
表示两个给定类型的值之间可以互相比较。如果 `S` 或 `T` 是这样一个推导了 `CanEqual` 的类，
则上面的示例不会通过类型检查：

```scala
class T derives CanEqual
```

或者也可以直接提供一个 `CanEqual` 的 given 实例，例如：

```scala
given CanEqual[T, T] = CanEqual.derived
```

这个定义实际上说明了当使用 `==` 或 `!=` 时，类型 `T` 的值（仅）可以与其他类型 `T` 的值进行比较。
该定义会影响类型检查，但对运行时行为没有影响，因为 `==` 和 `!=` 总是映射到对 `equals` 方法的调用。
定义右侧的 `CanEqual.derived` 是一个值，能够作为任意类型 `CanEqual` 类型的实例使用。
下面是 `CanEqual` 类与其伴生对象的定义：

```scala
package scala
import annotation.implicitNotFound

@implicitNotFound("Values of types ${L} and ${R} cannot be compared with == or !=")
sealed trait CanEqual[-L, -R]

object CanEqual:
   object derived extends CanEqual[Any, Any]
```

一个类型可以有多个 `CanEqual` given 实例。例如，下面的四个定义使得类型 `A` 与类型 `B` 之间可以互相比较，
但不能与其他任何值进行比较：

```scala
given CanEqual[A, A] = CanEqual.derived
given CanEqual[B, B] = CanEqual.derived
given CanEqual[A, B] = CanEqual.derived
given CanEqual[B, A] = CanEqual.derived
```

[`scala.CanEqual`](https://github.com/lampepfl/dotty/blob/master/library/src/scala/CanEqual.scala) 
对象中定义了很多 `CanEqual` 的 given 实例，它们一起定义了哪些标准类型可以比较的规则（更多细节如下）。

还有一个名为 `canEqualAny` 的“回退”实例，它允许对所有本身没有 `CanEqual` given 实例的类型之间进行比较。
`canEqualAny` 的定义如下：

```scala
def canEqualAny[L, R]: CanEqual[L, R] = CanEqual.derived
```

即使 `canEqualAny` 没有声明为 `given`，编译器仍然会构造一个 `canEqualAny` 实例作为对 
`CanEqual[L, R]` 类型进行隐式搜索的结果，除非在 `L` 或 `R` 上定义了 `CanEqual` 实例，
或者启用了语言特性 `strictEquality`。

提供 `canEqualAny` 的主要动机是为了向后兼容。如果这不重要，可以通过启用语言特性 `strictEquality` 禁用 `canEqualAny`。
就像所有语言特性一样，可以使用 import 

```scala
import scala.language.strictEquality
```

或使用命令行参数 `-language:strictEquality` 启用。

## 推导 CanEqual 实例

与直接定义 `CanEqual` 实例不同，推导这些实例通常更方便。例如：

```scala
class Box[T](x: T) derives CanEqual
```

根据 [type class 推导](./derivation.md) 的通用规则，这将在 `Box` 的伴生对象中生成以下 `CanEqual` 实例：

```scala
given [T, U](using CanEqual[T, U]): CanEqual[Box[T], Box[U]] =
   CanEqual.derived
```

也就是说，如果两个 `Box` 类型的元素类型之间可以比较，
则对应的实例之间也可以用 `==` 或· `!=` 进行比较。例如：

```scala
new Box(1) == new Box(1L)   // ok since there is an instance for `CanEqual[Int, Long]`
new Box(1) == new Box("a")  // error: can't compare
new Box(1) == 1             // error: can't compare
```

## 相等性检查的精确规则

相等性检查的精确规则如下。

If the `strictEquality` feature is enabled then
a comparison using `x == y` or `x != y` between values `x: T` and `y: U`
is legal if there is a `given` of type `CanEqual[T, U]`.

In the default case where the `strictEquality` feature is not enabled the comparison is
also legal if

 1. `T` and `U` are the same, or
 2. one of `T`, `U` is a subtype of the _lifted_ version of the other type, or
 3. neither `T` nor `U` have a _reflexive_ `CanEqual` instance.

Explanations:

 - _lifting_ a type `S` means replacing all references to abstract types
   in covariant positions of `S` by their upper bound, and replacing
   all refinement types in covariant positions of `S` by their parent.
 - a type `T` has a _reflexive_ `CanEqual` instance if the implicit search for `CanEqual[T, T]`
   succeeds.

## 预定义的 CanEqual 实例

The `CanEqual` object defines instances for comparing
 - the primitive types `Byte`, `Short`, `Char`, `Int`, `Long`, `Float`, `Double`, `Boolean`,  and `Unit`,
 - `java.lang.Number`, `java.lang.Boolean`, and `java.lang.Character`,
 - `scala.collection.Seq`, and `scala.collection.Set`.

Instances are defined so that every one of these types has a _reflexive_ `CanEqual` instance, and the following holds:

 - Primitive numeric types can be compared with each other.
 - Primitive numeric types can be compared with subtypes of `java.lang.Number` (and _vice versa_).
 - `Boolean` can be compared with `java.lang.Boolean` (and _vice versa_).
 - `Char` can be compared with `java.lang.Character` (and _vice versa_).
 - Two sequences (of arbitrary subtypes of `scala.collection.Seq`) can be compared
   with each other if their element types can be compared. The two sequence types
   need not be the same.
 - Two sets (of arbitrary subtypes of `scala.collection.Set`) can be compared
   with each other if their element types can be compared. The two set types
   need not be the same.
 - Any subtype of `AnyRef` can be compared with `Null` (and _vice versa_).

## 为什么有两个类型参数？

One particular feature of the `CanEqual` type is that it takes _two_ type parameters, representing the types of the two items to be compared. By contrast, conventional
implementations of an equality type class take only a single type parameter which represents the common type of _both_ operands.
One type parameter is simpler than two, so why go through the additional complication? The reason has to do with the fact that, rather than coming up with a type class where no operation existed before,
we are dealing with a refinement of pre-existing, universal equality. It is best illustrated through an example.

Say you want to come up with a safe version of the `contains` method on `List[T]`. The original definition of `contains` in the standard library was:
```scala
class List[+T] {
   ...
   def contains(x: Any): Boolean
}
```
That uses universal equality in an unsafe way since it permits arguments of any type to be compared with the list's elements. The "obvious" alternative definition
```scala
   def contains(x: T): Boolean
```
does not work, since it refers to the covariant parameter `T` in a nonvariant context. The only variance-correct way to use the type parameter `T` in `contains` is as a lower bound:
```scala
   def contains[U >: T](x: U): Boolean
```
This generic version of `contains` is the one used in the current (Scala 2.13) version of `List`.
It looks different but it admits exactly the same applications as the `contains(x: Any)` definition we started with.
However, we can make it more useful (i.e. restrictive) by adding a `CanEqual` parameter:
```scala
   def contains[U >: T](x: U)(using CanEqual[T, U]): Boolean // (1)
```
This version of `contains` is equality-safe! More precisely, given
`x: T`, `xs: List[T]` and `y: U`, then `xs.contains(y)` is type-correct if and only if
`x == y` is type-correct.

Unfortunately, the crucial ability to "lift" equality type checking from simple equality and pattern matching to arbitrary user-defined operations gets lost if we restrict ourselves to an equality class with a single type parameter. Consider the following signature of `contains` with a hypothetical `CanEqual1[T]` type class:
```scala
   def contains[U >: T](x: U)(using CanEqual1[U]): Boolean   // (2)
```
This version could be applied just as widely as the original `contains(x: Any)` method,
since the `CanEqual1[Any]` fallback is always available! So we have gained nothing. What got lost in the transition to a single parameter type class was the original rule that `CanEqual[A, B]` is available only if neither `A` nor `B` have a reflexive `CanEqual` instance. That rule simply cannot be expressed if there is a single type parameter for `CanEqual`.

The situation is different under `-language:strictEquality`. In that case,
the `CanEqual[Any, Any]` or `CanEqual1[Any]` instances would never be available, and the
single and two-parameter versions would indeed coincide for most practical purposes.

But assuming `-language:strictEquality` immediately and everywhere poses migration problems which might well be unsurmountable. Consider again `contains`, which is in the standard library. Parameterizing it with the `CanEqual` type class as in (1) is an immediate win since it rules out non-sensical applications while still allowing all sensible ones.
So it can be done almost at any time, modulo binary compatibility concerns.
On the other hand, parameterizing `contains` with `CanEqual1` as in (2) would make `contains`
unusable for all types that have not yet declared a `CanEqual1` instance, including all
types coming from Java. This is clearly unacceptable. It would lead to a situation where,
rather than migrating existing libraries to use safe equality, the only upgrade path is to have parallel libraries, with the new version only catering to types deriving `CanEqual1` and the old version dealing with everything else. Such a split of the ecosystem would be very problematic, which means the cure is likely to be worse than the disease.

For these reasons, it looks like a two-parameter type class is the only way forward because it can take the existing ecosystem where it is and migrate it towards a future where more and more code uses safe equality.

In applications where `-language:strictEquality` is the default one could also introduce a one-parameter type alias such as
```scala
type Eq[-T] = CanEqual[T, T]
```
Operations needing safe equality could then use this alias instead of the two-parameter `CanEqual` class. But it would only
work under `-language:strictEquality`, since otherwise the universal `Eq[Any]` instance would be available everywhere.


More on multiversal equality is found in a [blog post](http://www.scala-lang.org/blog/2016/05/06/multiversal-equality.html)
and a [GitHub issue](https://github.com/lampepfl/dotty/issues/1247).
