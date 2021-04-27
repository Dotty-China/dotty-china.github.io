---
layout: default
title: 数字字面量
parent: 其他变化的特性
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

**注意**：这个特性还不是 Scala 3 语言定义的一部分。可以通过 language import 启用：

```scala
import scala.language.experimental.genericNumberLiterals
```

在 Scala 2 中，数字字面量被限制为基本数字类型 `Int`、`Long`、`Float` 和 `Double`。
Scala 3 允许为用户自定义的类型编写数字字面量。例如：

```scala
val x: Long = -10_000_000_000
val y: BigInt = 0x123_abc_789_def_345_678_901
val z: BigDecimal = 110_222_799_799.99

(y: BigInt) match
   case 123_456_789_012_345_678_901 =>
```

数字字面量的语法与之前相同，但是没有预设置的大小限制。

## 数字字面量的含义

数字字面量的含义确定如下：

- 如果字面量以 `l` 或 `L` 结尾，则它是一个 `Long` 整数（必须处于其合法范围内）。
- 如果字面量以 `f` 或 `F` 结尾，则它是一个 `Float` 类型的单精度浮点数。
- 如果字面量以 `d` 或 `D` 结尾，则它是一个 `Double` 类型的双精度浮点数。

在上述情况中，对数字的转换都与在 Scala 2 和在 Java 中完全一致。
如果数字字面量*不*以这些后缀结尾，则其含义由预期类型决定：

1. 如果预期类型为 `Int`、`Long`、`Float` 或 `Double`，则该字面量被视为该类型的标准字面量。
2. 如果预期类型是完全定义的类型 `T`，它具有 `scala.util.FromDigits[T]` 类型的 given 实例，
   则通过将该字面量作为参数传递给该实例的 `fromDigits` 方法（更多详情参见下文）将其值转换为 `T` 类型。
3. 其他情况下，如果该字面量有小数点或指数，则它被视为 `Double` 字面量，否则它会被视为 `Int` 字面量。
   （这种情况与在 Scala 2 中以及 Java 中相同）

根据这些规则，这个定义

```scala
val x: Long = -10_000_000_000
```

根据规则 (1) 是合法的，因为预期类型是 `Long`。这个定义

```scala
val y: BigInt = 0x123_abc_789_def_345_678_901
val z: BigDecimal = 111222333444.55
```

根据规则 (2) 是合法的，因为 `BigInt` 和 `BigDecimal` 都有 `FromDigits` 实例
（分别实现了 `FromDigits` 的子类 `FromDigits.WithRadix` 和 `FromDigits.Decimal`）。
另一方面，对于这个定义：

```scala
val x = -10_000_000_000
```

将会产生一个类型错误，因为这个字面量没有预期类型，根据规则 (3) 它应该为 `Int` 字面量，
但 `-10_000_000_000` 的值超过了 `Int` 的范围。

## `FromDigits` Trait

一个类型需要允许数字字面量，只需要定义 `scala.util.FromDigits` type class 或其子类之一的 `given` 实例。
`FromDigits` 的定义如下：

```scala
trait FromDigits[T]:
   def fromDigits(digits: String): T
```

`fromDigits` 的实现将数字字符串转换为 `T` 类型的值。
`digits` 字符串由 `0` 至 `9` 之间的数字组成，前面可能有一个符号（`+` 或 `-`）。
在把数字字面量传递给 `fromDigits` 之前，字面量中的 `_` 分隔符会被过滤掉。

`FromDigits` 的伴生对象还为具有给定进制、带有小数点以及同时有小数点和指数的数字定义了 `FromDigits` 的子类。

```scala
object FromDigits {

   /** A subclass of `FromDigits` that also allows to convert whole
    *  number literals with a radix other than 10
    */
   trait WithRadix[T] extends FromDigits[T] {
      def fromDigits(digits: String): T = fromDigits(digits, 10)
      def fromDigits(digits: String, radix: Int): T
   }

   /** A subclass of `FromDigits` that also allows to convert number
    *  literals containing a decimal point ".".
    */
   trait Decimal[T] extends FromDigits[T]

   /** A subclass of `FromDigits`that allows also to convert number
    *  literals containing a decimal point "." or an
    *  exponent `('e' | 'E')['+' | '-']digit digit*`.
    */
   trait Floating[T] extends Decimal[T]
}
```

用户定义的数字类型可以实现它们中的一个，这会向编译器发出信号，
表示此类型也接受十六进制、带小数点的或带指数的字面量。

## 错误处理

`FromDigits` implementations can signal errors by throwing exceptions of some subtype
of `FromDigitsException`. `FromDigitsException` is defined with three subclasses in the
`FromDigits` object as follows:

```scala
abstract class FromDigitsException(msg: String) extends NumberFormatException(msg)

class NumberTooLarge (msg: String = "number too large")         extends FromDigitsException(msg)
class NumberTooSmall (msg: String = "number too small")         extends FromDigitsException(msg)
class MalformedNumber(msg: String = "malformed number literal") extends FromDigitsException(msg)
```

## 示例

As a fully worked out example, here is an implementation of a new numeric class, `BigFloat`, that accepts numeric literals. `BigFloat` is defined in terms of a `BigInt` mantissa and an `Int` exponent:

```scala
case class BigFloat(mantissa: BigInt, exponent: Int) {
   override def toString = s"${mantissa}e${exponent}"
}
```

`BigFloat` literals can have a decimal point as well as an exponent. E.g. the following expression
should produce the `BigFloat` number `BigFloat(-123, 997)`:

```scala
-0.123E+1000: BigFloat
```

The companion object of `BigFloat` defines an `apply` constructor method to construct a `BigFloat`
from a `digits` string. Here is a possible implementation:

```scala
object BigFloat {
   import scala.util.FromDigits

   def apply(digits: String): BigFloat = {
      val (mantissaDigits, givenExponent) =
         digits.toUpperCase.split('E') match {
            case Array(mantissaDigits, edigits) => {
               val expo =
                  try FromDigits.intFromDigits(edigits)
                  catch case ex: FromDigits.NumberTooLarge =>
                     throw FromDigits.NumberTooLarge(s"exponent too large: $edigits")
               (mantissaDigits, expo)
            }
            case Array(mantissaDigits) =>
               (mantissaDigits, 0)
         }
      val (intPart, exponent) =
         mantissaDigits.split('.') match {
            case Array(intPart, decimalPart) =>
               (intPart ++ decimalPart, givenExponent - decimalPart.length)
            case Array(intPart) =>
               (intPart, givenExponent)
         }
      BigFloat(BigInt(intPart), exponent)
   }
}
```

To accept `BigFloat` literals, all that's needed in addition is a `given` instance of type
`FromDigits.Floating[BigFloat]`:

```scala
   given FromDigits: FromDigits.Floating[BigFloat] with {
      def fromDigits(digits: String) = apply(digits)
   }

```

Note that the `apply` method does not check the format of the `digits` argument. It is
assumed that only valid arguments are passed. For calls coming from the compiler
that assumption is valid, since the compiler will first check whether a numeric
literal has the correct format before it gets passed on to a conversion method.

## 编译时报错

With the setup of the previous section, a literal like

```scala
1e10_0000_000_000: BigFloat
```

would be expanded by the compiler to

```scala
BigFloat.FromDigits.fromDigits("1e100000000000")
```

Evaluating this expression throws a `NumberTooLarge` exception at run time. We would like it to
produce a compile-time error instead. We can achieve this by tweaking the `BigFloat` class
with a small dose of metaprogramming. The idea is to turn the `fromDigits` method
into a macro, i.e. make it an inline method with a splice as right-hand side.
To do this, replace the `FromDigits` instance in the `BigFloat` object by the following two definitions:

```scala
object BigFloat {
   ...

   class FromDigits extends FromDigits.Floating[BigFloat]:
      def fromDigits(digits: String) = apply(digits)

   given FromDigits with {
      override inline def fromDigits(digits: String) = ${
        fromDigitsImpl('digits)
      }
   }
}
```

Note that an inline method cannot directly fill in for an abstract method, since it produces
no code that can be executed at runtime. That is why we define an intermediary class
`FromDigits` that contains a fallback implementation which is then overridden by the inline
method in the `FromDigits` given instance. That method is defined in terms of a macro
implementation method `fromDigitsImpl`. Here is its definition:

```scala
   private def fromDigitsImpl(digits: Expr[String])(using ctx: Quotes): Expr[BigFloat] = {
      digits.value match {
         case Some(ds) =>
            try {
               val BigFloat(m, e) = apply(ds)
               '{BigFloat(${Expr(m)}, ${Expr(e)})}
            } catch case ex: FromDigits.FromDigitsException => {
               ctx.error(ex.getMessage)
               '{BigFloat(0, 0)}
            }
         case None =>
            '{apply($digits)}
      }
   }
```

The macro implementation takes an argument of type `Expr[String]` and yields
a result of type `Expr[BigFloat]`. It tests whether its argument is a constant
string. If that is the case, it converts the string using the `apply` method
and lifts the resulting `BigFloat` back to `Expr` level. For non-constant
strings `fromDigitsImpl(digits)` is simply `apply(digits)`, i.e. everything is
evaluated at runtime in this case.

The interesting part is the `catch` part of the case where `digits` is constant.
If the `apply` method throws a `FromDigitsException`, the exception's message is issued as a compile time error in the `ctx.error(ex.getMessage)` call.

With this new implementation, a definition like

```scala
val x: BigFloat = 1234.45e3333333333
```

would give a compile time error message:

```scala
3 |  val x: BigFloat = 1234.45e3333333333
  |                    ^^^^^^^^^^^^^^^^^^
  |                    exponent too large: 3333333333
```
