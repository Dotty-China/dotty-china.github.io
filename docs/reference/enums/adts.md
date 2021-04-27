---
layout: default
title: 代数数据类型
parent: 枚举
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

[`enum` 概念](./enums.md)足够通用，它可以支持代数数据类型（Algebraic Data Type，ADT）
及其广义版本（GADT）。下面是一个将 `Option` 类型表示为 ADT 的示例：

```scala
enum Option[+T] {
   case Some(x: T)
   case None
}
```

此示例介绍了一个 带有协变类型参数的 `Option` 枚举，它有两种 case，`Some` 和 `None`。
`Some` 是由值参数 `x` 参数化的。它是继承 `Option` 的 case class 的缩写。
因为 `None` 没有参数化，所以它被视为一个普通的枚举值。

上述示例中省略的 `extends` 子句也可以显式给出：

```scala
enum Option[+T] {
   case Some(x: T) extends Option[T]
   case None       extends Option[Nothing]
}
```

注意，值 `None` 的父类型被推断为 `Option[Nothing]`。通常，在编译器生成的 `extends` 子句中，
所有协变类型参数都被最小化，而所有逆变类型参数都被最大化。如果 `Option` 的类型参数是不变的，
那么 `None` 的 `extends` 子句需要显式给出。

对于普通的枚举值，`enum` 的 case 都被定义在 `enum` 的伴生对象中。所以他们是 `Option.Some` 和 `Option.None`，
除非用 import “拉出”定义。

```scala
scala> Option.Some("hello")
val res1: t2.Option[String] = Some(hello)

scala> Option.None
val res2: t2.Option[Nothing] = None
```

请注意，上述表达式的类型始终为 `Option`。通常来说，除非需要更具体的类型，否则枚举 case 的构造函数应用的类型会被放宽到基础枚举类型。
这与普通的 case 类有一些细微的区别。构成 case 的类确实存在，并且可以直接用 `new` 构造它们，或者显式提供预期的类型。

```scala
scala> new Option.Some(2)
val res3: Option.Some[Int] = Some(2)
scala> val x: Option.Some[Int] = Option.Some(3)
val res4: Option.Some[Int] = Some(3)
```

就像其他枚举一样，ADT 可以定义方法。以 `Option` 举例，这里定义了一个 `isDefined` 方法，
和一个定义在它伴生对象中的 `Option(...)` 工厂方法：

```scala
enum Option[+T] {
   case Some(x: T)
   case None

   def isDefined: Boolean = this match
      case None => false
      case _    => true
}

object Option {
   def apply[T >: Null](x: T): Option[T] =
      if x == null then None else Some(x)
}
```

枚举和 ADT 是两个不同的概念，但因为它们有相同的语法结构，因此可以简单地看作一个 spectrum 的两端，
完全可以组成混合。例如，下面的代码给出了一个具有三个枚举值和一个参数化的接受 RGB 值的 case 组成的 `Color` 的实现。

```scala
enum Color(val rgb: Int) {
   case Red   extends Color(0xFF0000)
   case Green extends Color(0x00FF00)
   case Blue  extends Color(0x0000FF)
   case Mix(mix: Int) extends Color(mix)
}
```

### Parameter Variance of Enums

By default, parameterized cases of enums with type parameters will copy the type parameters of their parent, along
with any variance notations. As usual, it is important to use type parameters carefully when they are variant, as shown
below:

The following `View` enum has a contravariant type parameter `T` and a single case `Refl`, representing a function
mapping a type `T` to itself:

```scala
enum View[-T] {
   case Refl(f: T => T)
}
```

The definition of `Refl` is incorrect, as it uses contravariant type `T` in the covariant result position of a
function type, leading to the following error:

```scala
-- Error: View.scala:2:12 --------
2 |   case Refl(f: T => T)
  |             ^^^^^^^^^
  |contravariant type T occurs in covariant position in type T => T of value f
  |enum case Refl requires explicit declaration of type T to resolve this issue.
```

Because `Refl` does not declare explicit parameters, it looks to the compiler like the following:

```scala
enum View[-T] {
   case Refl[/*synthetic*/-T1](f: T1 => T1) extends View[T1]
}
```

The compiler has inferred for `Refl` the contravariant type parameter `T1`, following `T` in `View`.
We can now clearly see that `Refl` needs to declare its own non-variant type parameter to correctly type `f`,
and can remedy the error by the following change to `Refl`:

```diff
enum View[-T] {
-   case Refl(f: T => T)
+   case Refl[R](f: R => R) extends View[R]
}
```

Above, type `R` is chosen as the parameter for `Refl` to highlight that it has a different meaning to
type `T` in `View`, but any name will do.

After some further changes, a more complete implementation of `View` can be given as follows and be used
as the function type `T => U`:

```scala
enum View[-T, +U] extends (T => U) {
   case Refl[R](f: R => R) extends View[R, R]

   final def apply(t: T): U = this match {
      case refl: Refl[r] => refl.f(t)
   }
}
```

### 枚举的语法

对语法的更改分为两类：枚举定义和枚举内的 case。
The changes are specified below as deltas with respect to the Scala syntax given [here](../syntax.md)

 1. 枚举定义被定义如下：

    ```ebnf
    TmplDef   ::=  `enum' EnumDef
    EnumDef   ::=  id ClassConstr [`extends' [ConstrApps]] EnumBody
    EnumBody  ::=  [nl] ‘{’ [SelfType] EnumStat {semi EnumStat} ‘}’
    EnumStat  ::=  TemplateStat
                |  {Annotation [nl]} {Modifier} EnumCase
    ```

 2. 枚举的 case 的定义如下：

    ```ebnf
    EnumCase  ::=  `case' (id ClassConstr [`extends' ConstrApps]] | ids)
    ```

### 参考

更多信息请参见 [Issue #1970](https://github.com/lampepfl/dotty/issues/1970)。
