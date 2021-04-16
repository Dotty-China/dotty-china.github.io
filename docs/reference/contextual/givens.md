---
layout: default
title: Given 实例
parent: 上下文抽象
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

Given 实例（或者简单称为 given）定义了某些类型的“经典”值，这些值用于为[上下文参数](./using-clauses.md)合成实际参数。
例如：

```scala
trait Ord[T]:
   def compare(x: T, y: T): Int
   extension (x: T) def < (y: T) = compare(x, y) < 0
   extension (x: T) def > (y: T) = compare(x, y) > 0

given intOrd: Ord[Int] with
   def compare(x: Int, y: Int) =
      if x < y then -1 else if x > y then +1 else 0

given listOrd[T](using ord: Ord[T]): Ord[List[T]] with

   def compare(xs: List[T], ys: List[T]): Int = (xs, ys) match
      case (Nil, Nil) => 0
      case (Nil, _) => -1
      case (_, Nil) => +1
      case (x :: xs1, y :: ys1) =>
         val fst = ord.compare(x, y)
         if fst != 0 then fst else compare(xs1, ys1)

```

这段代码定义了一个具有两个 given 实例的 trait `Ord`。`intOrd` 为类型 `Ord[Int]` 定义了 given 实例，
而 `listOrd[T]` 对任意类型 `T` 为类型 `Ord[List[T]]` 定义了 Given 实例。`listOrd` 的 `using` 子句定义了一个条件：
只有在类型 `Ord[T]` 的 given 实例存在时才存在 `Ord[List[T]]` 类型的 given 实例。
编译器将这些条件扩展为[上下文参数](./using-clauses.md)。

## 匿名 Given

Given 的名称可以省略。所以最后一段的定义也可以这样表示：

```scala
given Ord[Int] with
   ...
given [T](using Ord[T]): Ord[List[T]] with
   ...
```
如果 given 缺少名称，编译器就会从实现的类型合成名称。

**注意**，编译器选择的合成名称简介且具有可读性。例如，上面两个实例会获得这样的名称：

```scala
given_Ord_Int
given_Ord_List_T
```

在[这里](./relationship-implicits.html#anonymous-given-instances)可以找到合成名称的精准规则。
这些规则不能保证“过于相似”的 given 实例之间不存在名称冲突。可以使用命名实例避免冲突。

**注意**，为了保证健壮的二进制兼容性，公共库应该更倾向使用命名实例。

## 别名 Given

别名可以用于定义与某个表达式相等的 given 实例。例如：

```scala
given global: ExecutionContext = ForkJoinPool()
```

这会创建一个 `ExecutionContext` 类型的 given `global`，它被解析到右侧的 `ForkJoinPool()`。
第一次访问 `global` 时会创建一个新的 `ForkJoinPool` 并返回，之后所有对 `global` 的访问都会返回这个 `ForkJoinPool`。
这个操作是线程安全的。

别名 given 也可以是匿名的，例如：

```scala
given Position = enclosingTree.position
given (using config: Config): Factory = MemoizingFactory(config)
```

别名 given 可以像其他 given 一样拥有类型参数和上下文参数，但它们只能为一个类型实现。

## Given 宏

别名 Given 可以又 `inline` 和 `transparent` 修饰符。例如：

```scala
transparent inline given mkAnnotations[A, T]: Annotations[A, T] = ${
  // code producing a value of a subtype of Annotations
}
```

因为 `mkAnnotations` 是 `transparent` 的，所以一个应用的类型是其右侧的类型，
它可以是声明的结果 `Annotations[A, T]` 类型的恰当子类型。

## Pattern-Bound Given Instances

Given 实例也可以在模式中出现。例如：

```scala
for given Context <- applicationContexts do

pair match
   case (ctx @ given Context, y) => ...
```

在上面第一个片段中，通过在 `applicationContexts` 上枚举创建类 `Context` 的匿名 given 实例。
第二个片段中通过匹配 `pair` 选择器的前半部分来创建一个名为 `ctx` 的 `Context` 类型 given 实例。


在所有情况下，模式绑定的 given 实例都由 `given` 和类型 `T` 组成。
The pattern matches exactly the same selectors as the type ascription pattern `_: T`.

## 否定 Given

Scala 2 中在模糊性上的一些令人费解的行为被用来实现隐式解析中的“否定”搜索，如果查询 Q1 成功则查询 Q2 失败，如果查询 Q2 成功则查询 Q1 失败。
这些技术随着对隐式新的清理不再工作，但现在新的特殊类型 `scala.util.NotGiven` 直接实现否定。

对于任意查询类型 `Q`，当且仅当对 `Q` 的隐式搜索失败时，`NotGiven[Q]` 才会成功。例如：

```scala
import scala.util.NotGiven

trait Tagged[A]

case class Foo[A](value: Boolean)
object Foo:
   given fooTagged[A](using Tagged[A]): Foo[A] = Foo(true)
   given fooNotTagged[A](using NotGiven[Tagged[A]]): Foo[A] = Foo(false)

@main def test(): Unit =
   given Tagged[Int] with {}
   assert(summon[Foo[Int]].value) // fooTagged is found
   assert(!summon[Foo[String]].value) // fooNotTagged is found
```

## Given 实例初始化

没有类型或上下文参数的 given 实例在第一次访问的时候按需初始化。如果 given 有类型或者上下文参数，
则为每个引用创建一个新实例。

## 语法

这里是 given 实例的语法：

```ebnf
TmplDef             ::=  ...
                     |   ‘given’ GivenDef
GivenDef            ::=  [GivenSig] StructuralInstance
                     |   [GivenSig] AnnotType ‘=’ Expr
                     |   [GivenSig] AnnotType
GivenSig            ::=  [id] [DefTypeParamClause] {UsingParamClause} ‘:’
StructuralInstance  ::=  ConstrApp {‘with’ ConstrApp} ‘with’ TemplateBody
```

Given 实例以保留字 `given` 和一个可选的*签名*开始。签名定义实例的名称和参数。然后是 `:`、
Given 实例一共有三种：

- *结构实例（Structural Instance）*包含一个或多个类型或构造器应用，其后紧跟着 `with`和一个包含实例成员定义的模板体、
- *别名实例（Alias Instance）*包含一个类型，其后紧跟着 `=` 和一个右侧表达式。
- *抽象实例（Abstract Instance）*只包含类型，其后不跟随任何内容。
