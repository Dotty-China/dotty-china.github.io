---
layout: default
title: 多态函数类型
parent: 新类型
grand_parent: 参考
nav_order: 6
---

# {{ page.title }}

多态函数类型（Polymorphic Function Type）是接受类型参数的函数类型。例如：

```scala
// A polymorphic method:
def foo[A](xs: List[A]): List[A] = xs.reverse

// A polymorphic function value:
val bar: [A] => List[A] => List[A]
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
//       a polymorphic function type
       = [A] => (xs: List[A]) => foo[A](xs)
```

Scala 已经有了*多态方法（Polymorphi Method）*，即接受类型参数的方法。上面的 `foo` 方法就是一个例子，
它接受一个类型参数 `A`。到目前为止，还不能将这些方法转化为上面 `bar` 这样能够作为参数传递，
能够作为结果返回的多态函数值。

现在在 Scala 3 中，这是可能的。上述的值 `bar` 的类型是

```scala
[A] => List[A] => List[A]
```

这个类型描述了接受一个类型 `A` 作为参数，接受一个类型为 `List[A]` 的列表，并返回相同的类型为 `List[A]` 
的列表的函数值。

更多细节参见 [PR 4672](https://github.com/lampepfl/dotty/pull/4672)。


## 示例用法

Polymorphic function type are particularly useful
when callers of a method are required to provide a
function which has to be polymorphic,
meaning that it should accept arbitrary types as part of its inputs.

For instance, consider the situation where we have
a data type to represent the expressions of a simple language
(consisting only of variables and function applications)
in a strongly-typed way:

```scala
enum Expr[A]:
   case Var(name: String)
   case Apply[A, B](fun: Expr[B => A], arg: Expr[B]) extends Expr[A]
```

We would like to provide a way for users to map a function
over all immediate subexpressions of a given `Expr`.
This requires the given function to be polymorphic,
since each subexpression may have a different type.
Here is how to implement this using polymorphic function types:

```scala
def mapSubexpressions[A](e: Expr[A])(f: [B] => Expr[B] => Expr[B]): Expr[A] =
   e match
      case Apply(fun, arg) => Apply(f(fun), f(arg))
      case Var(n) => Var(n)
```

And here is how to use this function to _wrap_ each subexpression
in a given expression with a call to some `wrap` function,
defined as a variable:

```scala
val e0 = Apply(Var("f"), Var("a"))
val e1 = mapSubexpressions(e0)(
   [B] => (se: Expr[B]) => Apply(Var[B => B]("wrap"), se))
println(e1) // Apply(Apply(Var(wrap),Var(f)),Apply(Var(wrap),Var(a)))
```

## 与类型 Lambda 的关系

Polymorphic function types are not to be confused with
[_type lambdas_](type-lambdas.md).
While the former describes the _type_ of a polymorphic _value_,
the latter is an actual function value _at the type level_.

A good way of understanding the difference is to notice that
**_type lambdas are applied in types,
whereas polymorphic functions are applied in terms_**:
One would call the function `bar` above
by passing it a type argument `bar[Int]` _within a method body_.
On the other hand, given a type lambda such as `type F = [A] =>> List[A]`,
one would call `F` _within a type expression_, as in `type Bar = F[Int]`.
