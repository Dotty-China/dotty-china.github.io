---
layout: default
title: 无 Option 模式匹配
parent: 其他变化的特性
grand_parent: 参考
nav_order: 14
---

# 无 `Option` 模式匹配

与 Scala 2 相比，Scala 3 中的模式匹配的实现大大简化了。
从用户角度来看，这意味着 Scala 3 生成的模式更容易调试，
因为所有变量都会在调试模式下被显示，而且位置都会被正确保留。

Scala 3 支持 Scala 2 [提取器](https://www.scala-lang.org/files/archive/spec/2.13/08-pattern-matching.html#extractor-patterns)的超集。

## 提取器

提取器是公开方法 `unapply` 或 `unapplySeq` 的对象：

```Scala
def unapply[A](x: T)(implicit x: B): U
def unapplySeq[A](x: T)(implicit x: B): U
```

公开 `unapply` 方法的提取器被称为固定元数提取器，用于处理元数固定的模式。
公开 `unapplySeq` 方法的提取器被称为可变提取器，支持可变模式。

### 固定元数提取器

固定元数提取器公开具有以下签名的方法：

```scala
def unapply[A](x: T)(implicit x: B): U
```

类型 `U` 应该符合以下 match 之一：

- Boolean match
- Product match

或者 `U` 符合以下的类型 `R`：

```scala
type R = {
  def isEmpty: Boolean
  def get: S
}
```

其中 `S` 符合以下 match 之一：

- single match
- name-based match

前一种形式的 `unapply` 具有更高的优先级，而 *single match* 的优先级高于 *name-based match*。

如果以下条件之一成立，则固定元数提取器是不会失败的：

- `U = true`
- 提取器用于 product match
- `U = Some[T]` （为了与 Scala 2 兼容）
- `U <: R` 且 `U <: { def isEmpty: false }`

### 可变提取器

可变提取器公开具有以下签名的方法：

```Scala
def unapplySeq[A](x: T)(implicit x: B): U
```

The type `U` conforms to one of the following matches:

- sequence match
- product-sequence match

Or `U` conforms to the type `R`:

```Scala
type R = {
  def isEmpty: Boolean
  def get: S
}
```

and `S` conforms to one of the two matches above.

The former form of `unapplySeq` has higher priority, and _sequence match_ has higher
precedence over _product-sequence match_.

A usage of a variadic extractor is irrefutable if one of the following conditions holds:

- the extractor is used directly as a sequence match or product-sequence match
- `U = Some[T]` (for Scala 2 compatibility)
- `U <: R` and `U <: { def isEmpty: false }`

## Boolean Match

- `U =:= Boolean`
- Pattern-matching on exactly `0` pattern

For example:

<!-- To be kept in sync with tests/new/patmat-spec.scala -->

```scala
object Even:
   def unapply(s: String): Boolean = s.size % 2 == 0

"even" match
   case s @ Even() => println(s"$s has an even number of characters")
   case s          => println(s"$s has an odd number of characters")

// even has an even number of characters
```

## Product Match

- `U <: Product`
- `N > 0` is the maximum number of consecutive (parameterless `def` or `val`) `_1: P1` ... `_N: PN` members in `U`
- Pattern-matching on exactly `N` patterns with types `P1, P2, ..., PN`

For example:

<!-- To be kept in sync with tests/new/patmat-spec.scala -->

```scala
class FirstChars(s: String) extends Product {
   def _1 = s.charAt(0)
   def _2 = s.charAt(1)

   // Not used by pattern matching: Product is only used as a marker trait.
   def canEqual(that: Any): Boolean = ???
   def productArity: Int = ???
   def productElement(n: Int): Any = ???
}

object FirstChars {
   def unapply(s: String): FirstChars = new FirstChars(s)
}

"Hi!" match {
   case FirstChars(char1, char2) =>
      println(s"First: $char1; Second: $char2")
}

// First: H; Second: i
```

## Single Match

- If there is exactly `1` pattern, pattern-matching on `1` pattern with type `U`

<!-- To be kept in sync with tests/new/patmat-spec.scala -->

```scala
class Nat(val x: Int) {
   def get: Int = x
   def isEmpty = x < 0
}

object Nat {
   def unapply(x: Int): Nat = new Nat(x)
}

5 match {
   case Nat(n) => println(s"$n is a natural number")
   case _      => ()
}

// 5 is a natural number
```

## Name-based Match

- `N > 1` is the maximum number of consecutive (parameterless `def` or `val`) `_1: P1 ... _N: PN` members in `U`
- Pattern-matching on exactly `N` patterns with types `P1, P2, ..., PN`

```Scala
object ProdEmpty {
   def _1: Int = ???
   def _2: String = ???
   def isEmpty = true
   def unapply(s: String): this.type = this
   def get = this
}

"" match {
   case ProdEmpty(_, _) => ???
   case _ => ()
}
```


## Sequence Match

- `U <: X`, `T2` and `T3` conform to `T1`

```Scala
type X = {
   def lengthCompare(len: Int): Int // or, `def length: Int`
   def apply(i: Int): T1
   def drop(n: Int): scala.Seq[T2]
   def toSeq: scala.Seq[T3]
}
```

- Pattern-matching on _exactly_ `N` simple patterns with types `T1, T1, ..., T1`, where `N` is the runtime size of the sequence, or
- Pattern-matching on `>= N` simple patterns and _a vararg pattern_ (e.g., `xs: _*`) with types `T1, T1, ..., T1, Seq[T1]`, where `N` is the minimum size of the sequence.

<!-- To be kept in sync with tests/new/patmat-spec.scala -->

```scala
object CharList {
   def unapplySeq(s: String): Option[Seq[Char]] = Some(s.toList)
}

"example" match {
   case CharList(c1, c2, c3, c4, _, _, _) =>
      println(s"$c1,$c2,$c3,$c4")
   case _ =>
      println("Expected *exactly* 7 characters!")
}
// e,x,a,m
```

## Product-Sequence Match

- `U <: Product`
- `N > 0` is the maximum number of consecutive (parameterless `def` or `val`) `_1: P1` ... `_N: PN` members in `U`
- `PN` conforms to the signature `X` defined in Seq Pattern
- Pattern-matching on exactly `>= N` patterns, the first `N - 1` patterns have types `P1, P2, ... P(N-1)`,
  the type of the remaining patterns are determined as in Seq Pattern.

```Scala
class Foo(val name: String, val children: Int *)
object Foo {
   def unapplySeq(f: Foo): Option[(String, Seq[Int])] =
      Some((f.name, f.children))
}

def foo(f: Foo) = f match {
   case Foo(name, ns : _*) =>
   case Foo(name, x, y, ns : _*) =>
}
```

There are plans for further simplification, in particular to factor out *product
match* and *name-based match* into a single type of extractor.

## Type testing

Abstract type testing with `ClassTag` is replaced with `TypeTest` or the alias `Typeable`.

- pattern `_: X` for an abstract type requires a `TypeTest` in scope
- pattern `x @ X()` for an unapply that takes an abstract type requires a `TypeTest` in scope

[More details on `TypeTest`](../other-new-features/type-test.md)
