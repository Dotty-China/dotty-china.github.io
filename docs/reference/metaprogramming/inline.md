---
layout: default
title: 内联
parent: 元编程
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

## 内联定义

`inline` 是一个新的[软修饰符](../soft-modifier.md)，它保证定义在使用时被内联。
例如：

```scala
object Config {
   inline val logging = false
}

object Logger {
   private var indent = 0

   inline def log[T](msg: String, indentMargin: =>Int)(op: => T): T =
      if (Config.logging) {
         println(s"${"  " * indent}start $msg")
         indent += indentMargin
         val result = op
         indent -= indentMargin
         println(s"${"  " * indent}$msg = $result")
         result
      } else op
}
```

对象 `Config` 包含**内联值（inline value）** `logging` 的定义。
这意味着 `logging` 被视为一个等价其右侧的 `false` 的*常量值(constant value)*。
这种 `inline val` 的右侧本身必须是[常量表达式](https://scala-lang.org/files/archive/spec/2.13/06-expressions.html#constant-expressions)。
这种形式下，`inline` 等价于 Java 和 Scala 2 的 `final`。请注意，
代表*内联常量（inlined constant）*的 `final` 在 Scala 3 中仍被支持，
但将会被逐渐淘汰。

对象 `Logger` 包含**内联方法（inline method）** `log` 的定义。
该方法始终会在调用点处被内联。

在被内联后的代码中，具有常量条件的 `if-then-else` 将被重写为其 `then` 或 `else` 部分。
因此，在上述 `log` 方法中，`if Config.logging` 在 `Config.logging == true` 时会被重写为其 `then` 部分。


下面是一个例子：

```scala
var indentSetting = 2

def factorial(n: BigInt): BigInt =
   log(s"factorial($n)", indentSetting) {
      if n == 0 then 1
      else n * factorial(n - 1)
   }
```

如果 `Config.logging == false`，则它会被重写（简化）为：

```scala
def factorial(n: BigInt): BigInt =
   if (n == 0) 1
   else n * factorial(n - 1)
```

如你所见，由于没有使用 `msg`或 `indentMargin`，所以它们不会出现在为 `factorial` 生成的代码中。
还需要注意的是我们 `log` 方法的方法体：`else-` 部分被简化为只有一个 `op`。
在生成的代码中，我们不会生成任何闭包，因为我们只引用了一次按名参数。因此，
这段代码会被直接内联，调用会被 beta-reduced。

在为 `true` 的情况下，代码会被重写为：

```scala
def factorial(n: BigInt): BigInt = {
   val msg = s"factorial($n)"
   println(s"${"  " * indent}start $msg")
   Logger.inline$indent_=(indent.+(indentSetting))
   val result =
      if (n == 0) 1
      else n * factorial(n - 1)
   Logger.inline$indent_=(indent.-(indentSetting))
   println(s"${"  " * indent}$msg = $result")
   result
}
```

注意，按照常规的 Scala 语义，按值参数 `msg` 只会被求值一次，所以会将它绑定到变量上并重用它。
另外请注意对私有 var `indent` 赋值的特殊处理。这是通过生成 setter 方法 `def inline$indent_=` 
并调用它实现的。

### 递归内联方法

内联方法可以是递归的。例如，当将常量传递给 `n` 时，下面的 `foo` 方法将通过直接内联代码实现，
而不需要循环或递归。

```scala
inline def power(x: Double, n: Int): Double = {
   if (n == 0) 1.0
   else if (n == 1) x
   else {
      val y = power(x, n / 2)
      if (n % 2 == 0) y * y else y * y * x
   }
}

power(expr, 10)
// translates to
//
//    val x = expr
//    val y1 = x * x   // ^2
//    val y2 = y1 * y1 // ^4
//    val y3 = y2 * x  // ^5
//    y3 * y3          // ^10
```

内联方法的参数也可以带有 `inline` 修饰符。这意味着这些参数调用时的实际参数将会在 `inline def` 的方法体内被内联。
`inline` 参数的调用语义与按名参数等效，但是允许复制实参中的代码。当需要传播常量值以允许进一步优化/归约时，
它非常有用。

下面的例子将展示对按值参数、按名参数和 `inline` 参数的转换之间的差异：

```scala
inline def funkyAssertEquals(actual: Double, expected: =>Double, inline delta: Double): Unit =
   if ((actual - expected).abs > delta)
      throw new AssertionError(s"difference between ${expected} and ${actual} was larger than ${delta}")

funkyAssertEquals(computeActual(), computeExpected(), computeDelta())
// translates to
//
//    val actual = computeActual()
//    def expected = computeExpected()
//    if (actual - expected).abs > computeDelta() then
//      throw new AssertionError(s"difference between ${expected} and ${actual} was larger than ${computeDelta()}")
```

### 覆盖规则

内联方法可以覆盖其他非内联方法。规则如下：

1. 如果内联方法 `f` 实现或覆盖另一个非内联方法，那么这个内联方法也可以在运行时被调用。
   例如，考虑以下场景：

   ```scala
    abstract class A {
       def f: Int
       def g: Int = f
    }

    class B extends A {
       inline def f = 22
       override inline def g = f + 11
    }

    val b = new B
    val a: A = b
    // inlined invocatons
    assert(b.f == 22)
    assert(b.g == 33)
    // dynamic invocations
    assert(a.f == 22)
    assert(a.g == 33)
    ```

    内联调用和动态分派调用给出相同的结果。

2. 内联方法实际上为 `final` 的。

3. 内联方法也可以是抽象的。抽象内联方法只能由其他内联方法实现。它不能直接调用：

    ```scala
    abstract class A {
       inline def f: Int
    }

    object B extends A {
       inline def f: Int = 22
    }

    B.f         // OK
    val a: A = B
    a.f         // error: cannot inline f in A.
    ```

### 与 `@inline` 的关系

Scala 2 也定义了一个 `@inline` 注解，用于提示后端对代码进行内联。`inline` 修饰符是一个更强大的选项：

- 展开是强制保证的，而不仅是尽力而为的，
- 展开发生在（编译器）前端而不是后端，以及
- 展开也适用于递归方法。

<!--- (Commented out since the docs and implementation differ)

### Evaluation Rules

As you noticed by the examples above a lambda of the form

`((x_1, ..., x_n) => B)(E_1, ..., E_n)` is rewritten to:

```
{ val/def x_1 = E_1
  ...
  val/def x_n = E_n
  B
}
```

where vals are used for value parameter bindings and defs are used for by-name
parameter bindings. If an argument `E_i` is a simple variable reference `y`, the
corresponding binding is omitted and `y` is used instead of `x_i` in `B`.

If a `inline` modifier is given for parameters, corresponding arguments must be
pure expressions of constant type.
-->

#### 常量表达式的定义

内联值和作为内联参数传递的实参右侧必须是 [SLS §6.24](https://www.scala-lang.org/files/archive/spec/2.13/06-expressions.html#constant-expressions) 中定义的常量表达式，
包括一些*平台特定*的扩展，例如纯数值计算的常量折叠。

内联值必须具有字面量类型，例如 `1` 和 `true`。

```scala
inline val four = 4
// equivalent to
inline val four: 4 = 4
```

拥有无语法的字面量类型（例如 `Short(4)`）的 inline val 也是可能的。

```scala
trait InlineConstants {
   inline val myShort: Short
}

object Constants extends InlineConstants {
   inline val myShort/*: Short(4)*/ = 4
}
```

## 透明内联方法

内联方法也可以被声明为 `transparent` 的。这意味着内联方法的返回值类型可以在展开时特化为更精确的类型。
例如：

```scala
class A
class B extends A {
   def m = true
}

transparent inline def choose(b: Boolean): A =
   if (b) new A else new B

val obj1 = choose(true)  // static type is A
val obj2 = choose(false) // static type is B

// obj1.m // compile-time error: `m` is not defined on `A`
obj2.m    // OK
```

在这里，内联方法 `choose` 返回两种类型 `A` 和 `B` 其中之一的实例。
如果 `choose` 没有被声明为 `transparent` 的，则其展开后的结果始终是类型 `A`，
即使计算出的值可能是其子类型 `B`。某种意义上来说，内联方法是一个“黑箱”，
因为它的实现细节不会被泄露出去。但是如果使用 `transparent` 进行修饰，
则类型是展开后的内容的类型。如果 `b` 的实参为 `true`，则其类型为 `A`，
否则为 `B`。因此在 `obj2` 上调用 `m` 能够通过类型检查，
因为 `obj2` 拥有与 `choose(false)` 展开后相同的类型，即 `B`。
透明内联方法是“白箱”，因为这种方法引用的类型可以比其声明的返回类型更加特化，
具体取决于方法是如何展开的。

在下面的例子中，我们可以看到 `zero` 的返回类型会被特化到单例类型 `0`，
从而允许将加法的结果赋予正确的类型 `1`。

```scala
transparent inline def zero: Int = 0

val one: 1 = zero + 1
```

### 透明内联 vs 非透明内联

正如我们之前讨论的，透明内联方法可能会影响调用点处的类型检查。
从技术上来说，这意味着必须在程序的类型检查期间展开透明内联方法。
其他内联方法可以在程序完全类型化后被内联。

例如，下面的两个函数有着相同的类型，但是会在不同时刻被内联。

```scala
inline def f1: T = ...
transparent inline def f2: T = (...): T
```

一个值得注意的区别是 `transparent inline given` 的行为。
如果在内联该定义时报告了错误，则将其视为隐式搜索不匹配，
搜索将会继续。`transparent inline given` 可以在其右侧添加类型描述（如上例中的 `f2` 所示），
to avoid the precise type but keep the search behavior。
另一方面，`inline given` 被视为隐式，在类型检查后被内联。任何错误都会被如常发出。

## 内联条件

条件为常量表达式的 if-then-else 表达式可以被简化为其被选中的分支。
在 if-then-else 前加入 `inline` 会强制要求其条件必须为常量表达式，
从而保证始终会被简化。

例如：

```scala
inline def update(delta: Int) =
   inline if (delta >= 0) increaseBy(delta)
   else decreaseBy(-delta)
```

调用 `update(22)` 会被重写为 `increaseBy(22)`。
但如果调用 `update` 时使用的值不是编译时常量，
则会产生以下的错误：

```scala
   |  inline if delta >= 0 then ???
   |  ^
   |  cannot reduce inline if
   |   its condition
   |     delta >= 0
   |   is not a constant value
   | This location is in code that was inlined at ...
```

在透明内联中，`inline if` 会在类型检查期间强制内联在其条件中的内联定义。

## 内联匹配

`inline` 方法的方法体内的 `match` 表达式可以以 `inline` 修饰符作为前缀。
如果有足够的静态信息明确地选择其中一个分支，则会将表达式简化为该分支，
并且会获取其结果的类型。否则会产生编译时错误，报告该 `match` 无法归约。

下面的例子使用一个内联匹配表达式定义一个内联方法，
该表达式根据其静态类型选择一个 case：

```scala
transparent inline def g(x: Any): Any =
   inline x match {
      case x: String => (x, x) // Tuple2[String, String](x, x)
      case x: Double => x
   }

g(1.0d) // Has type 1.0d which is a subtype of Double
g("test") // Has type (String, String)
```

scrutinee `x` 会被静态的检查，并相应地归约内联匹配，返回相应的值
（并且使用特化的类型，因为 `g` 被声明为 `transparent` 的）。
此例子对 scrutinee 进行简单的类型测试。该类型可以具有更复杂的结构，例如以下的简单 ADT。
`toInt` 匹配 [Church-encoding](https://en.wikipedia.org/wiki/Church_encoding) 的数字结构，
并*计算（compute）*相应的整数。

```scala
trait Nat
case object Zero extends Nat
case class Succ[N <: Nat](n: N) extends Nat

transparent inline def toInt(n: Nat): Int =
   inline n match {
      case Zero     => 0
      case Succ(n1) => toInt(n1) + 1
   }

inline val natTwo = toInt(Succ(Succ(Zero)))
val intTwo: 2 = natTwo
```

`natTwo` 被推断出具有单例类型 `2`。

## `scala.compiletime` 包

[`scala.compiletime`](https://dotty.epfl.ch/api/scala/compiletime.html) 包包含一些辅助定义，
提供对值的编译时操作的支持。下面会对它们进行描述。

### `constValue` 和 `constValueOpt`

`constValue` 是一个函数，它可以产生由类型表示的常量值。

```scala
import scala.compiletime.constValue
import scala.compiletime.ops.int.S

transparent inline def toIntC[N]: Int =
   inline constValue[N] match {
      case 0        => 0
      case _: S[n1] => 1 + toIntC[n1]
   }

inline val ctwo = toIntC[2]
```

`constValueOpt` 与 `constValue` 相同，但返回 `Option[T]`，使我们能够处理没有值的情况。
请注意，`S` 是某些单例类型的 successor 的类型。例如，类型 `S[1]` 是单例类型 `2`。

### `erasedValue`

到目前为止，我们已经看到了将 term（元组和整数）作为参数的内联方法。
但如果我们想根据类型区分 case 呢？例如，我们可能想编写一个函数 `defaultValue`，
给定类型 `T`，该函数返回 `T` 的默认值（如果默认值存在）。
我们可以使用重写匹配表达式和一个简单的辅助函数 `scala.compiletime.erasedValue` 来实现它，
该辅助方法定义如下：

```scala
erased def erasedValue[T]: T = ???
```

`erasedValue` 函数*假装（pretend）*返回其类型参数 `T` 类型的值。
实际上，它在被调用时总是会抛出 `NotImplementedError` 异常。
但是该函数实际上永远不能被调用，因为它被声明为 `erased`，
所以只能在编译时的类型检查期间使用。

使用 `erasedValue`，我们可以这样定义 `defaultValue`：

```scala
import scala.compiletime.erasedValue

inline def defaultValue[T] =
   inline erasedValue[T] match {
      case _: Byte    => Some(0: Byte)
      case _: Char    => Some(0: Char)
      case _: Short   => Some(0: Short)
      case _: Int     => Some(0)
      case _: Long    => Some(0L)
      case _: Float   => Some(0.0f)
      case _: Double  => Some(0.0d)
      case _: Boolean => Some(false)
      case _: Unit    => Some(())
      case _          => None
   }
```

然后可以这样使用它：

```scala
val dInt: Some[Int] = defaultValue[Int]
val dDouble: Some[Double] = defaultValue[Double]
val dBoolean: Some[Boolean] = defaultValue[Boolean]
val dAny: None.type = defaultValue[Any]
```

作为另一个例子，考虑以下 `toInt` 的类型级版本：
给定一个表示 Peano 数的*类型*，返回对应的整数*值*。
考虑*内联匹配*小节中整数的定义。下面是 `toIntT` 的定义：

```scala
transparent inline def toIntT[N <: Nat]: Int =
   inline scala.compiletime.erasedValue[N] match {
      case _: Zero.type => 0
      case _: Succ[n] => toIntT[n] + 1
   }

inline val two = toIntT[Succ[Succ[Zero.type]]]
```

`erasedValue` 是一个 `erased` 方法，因此不能在运行时使用它，
它也没用运行时行为。因为 `toIntT` 对类型 `T` 的静态类型执行静态检查，
因此我们可以安全地它来检查其返回类型（本例中为 `S[S[Z]]`）。

### `error`

`error` 方法用于在内联展开期间生成用户定义的编译时错误。
其签名如下：

```scala
inline def error(inline msg: String): Nothing
```

如果内联展开结果导致调用 `error(msgStr)`，编译器会给出一条包含给定 `msgStr` 的错误消息。

```scala
import scala.compiletime.{error, code}

inline def fail() =
   error("failed for a reason")

fail() // error: failed for a reason
```

或

```scala
inline def fail(p1: => Any) =
   error(code"failed on: $p1")

fail(identity("foo")) // error: failed on: identity("foo")
```

### `scala.compiletime.ops` 包

[`scala.compiletime.ops`](https://dotty.epfl.ch/api/scala/compiletime/ops.html) 包包含支持单例类型的基本操作的类型。
例如，`scala.compiletime.ops.int.*` 提供对两个单例 `Int` 相乘的支持，
`scala.compiletime.ops.boolean.&&` 提供对两个 `Boolean` 类型进行逻辑与操作的支持。
当 `scala.compiletime.ops` 中某个类型的所有参数均为单例类型时，
编译器可以计算该操作的结果。

```scala
import scala.compiletime.ops.int.*
import scala.compiletime.ops.boolean.*

val conjunction: true && true = true
val multiplication: 3 * 5 = 15
```

这些单例操作类型很多都可以作为中缀类型使用
（如 [SLS §3.2.10](https://www.scala-lang.org/files/archive/spec/2.13/03-types.html#infix-types) 中所属）。

因为类型别名有其 term 级等效项相同的优先级规则，因此这些操作会以预期中的优先级规则进行组合：

```scala
import scala.compiletime.ops.int.*
val x: 1 + 2 * 3 = 7
```

操作类型位于以其左侧参数的类型命名的包中：例如 `scala.compiletime.ops.int.+` 表示两个数字的加法，
`scala.compiletime.ops.string.+` 表示字符串连接。
要同时使用这两种类型，并将它们区分开，可以使用匹配类型将其分派到正确的实现上：

```scala
import scala.compiletime.ops.*

import scala.annotation.infix

type +[X <: Int | String, Y <: Int | String] = (X, Y) match {
   case (Int, Int) => int.+[X, Y]
   case (String, String) => string.+[X, Y]
}

val concat: "a" + "b" = "ab"
val addition: 1 + 1 = 2
```

## Summoning Implicits Selectively

It is foreseen that many areas of typelevel programming can be done with rewrite
methods instead of implicits. But sometimes implicits are unavoidable. The
problem so far was that the Prolog-like programming style of implicit search
becomes viral: Once some construct depends on implicit search it has to be
written as a logic program itself. Consider for instance the problem of creating
a `TreeSet[T]` or a `HashSet[T]` depending on whether `T` has an `Ordering` or
not. We can create a set of implicit definitions like this:

```scala
trait SetFor[T, S <: Set[T]]

class LowPriority:
   implicit def hashSetFor[T]: SetFor[T, HashSet[T]] = ...

object SetsFor extends LowPriority:
   implicit def treeSetFor[T: Ordering]: SetFor[T, TreeSet[T]] = ...
```

Clearly, this is not pretty. Besides all the usual indirection of implicit
search, we face the problem of rule prioritization where we have to ensure that
`treeSetFor` takes priority over `hashSetFor` if the element type has an
ordering. This is solved (clumsily) by putting `hashSetFor` in a superclass
`LowPriority` of the object `SetsFor` where `treeSetFor` is defined. Maybe the
boilerplate would still be acceptable if the crufty code could be contained.
However, this is not the case. Every user of the abstraction has to be
parameterized itself with a `SetFor` implicit. Considering the simple task _"I
want a `TreeSet[T]` if `T` has an ordering and a `HashSet[T]` otherwise"_, this
seems like a lot of ceremony.

There are some proposals to improve the situation in specific areas, for
instance by allowing more elaborate schemes to specify priorities. But they all
keep the viral nature of implicit search programs based on logic programming.

By contrast, the new `summonFrom` construct makes implicit search available
in a functional context. To solve the problem of creating the right set, one
would use it as follows:

```scala
import scala.compiletime.summonFrom

inline def setFor[T]: Set[T] = summonFrom {
   case ord: Ordering[T] => new TreeSet[T](using ord)
   case _                => new HashSet[T]
}
```

A `summonFrom` call takes a pattern matching closure as argument. All patterns
in the closure are type ascriptions of the form `identifier : Type`.

Patterns are tried in sequence. The first case with a pattern `x: T` such that an implicit value of type `T` can be summoned is chosen.

Alternatively, one can also use a pattern-bound given instance, which avoids the explicit using clause. For instance, `setFor` could also be formulated as follows:

```scala
import scala.compiletime.summonFrom

inline def setFor[T]: Set[T] = summonFrom {
   case given Ordering[T] => new TreeSet[T]
   case _                 => new HashSet[T]
}
```

`summonFrom` applications must be reduced at compile time.

Consequently, if we summon an `Ordering[String]` the code above will return a
new instance of `TreeSet[String]`.

```scala
summon[Ordering[String]]

println(setFor[String].getClass) // prints class scala.collection.immutable.TreeSet
```

**Note** `summonFrom` applications can raise ambiguity errors. Consider the following
code with two givens in scope of type `A`. The pattern match in `f` will raise
an ambiguity error of `f` is applied.

```scala
class A
given a1: A = new A
given a2: A = new A

inline def f: Any = summonFrom {
   case given _: A => ???  // error: ambiguous givens
}
```

## `summonInline`

The shorthand `summonInline` provides a simple way to write a `summon` that is delayed until the call is inlined.

```scala
transparent inline def summonInline[T]: T = summonFrom {
   case t: T => t
}
```

### Reference

For more information about the semantics of `inline`, see the [Scala 2020: Semantics-preserving inlining for metaprogramming](https://dl.acm.org/doi/10.1145/3426426.3428486) paper.

For more information about compiletime operation, see [PR #4768](https://github.com/lampepfl/dotty/pull/4768),
which explains how `summonFrom`'s predecessor (implicit matches) can be used for typelevel programming and code specialization and [PR #7201](https://github.com/lampepfl/dotty/pull/7201) which explains the new `summonFrom` syntax.
