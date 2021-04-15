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

当方法的调用方需要提供一个必须多态的函数（这意味着它应该接受任意类型作为其输入的一部分）的时候，多态函数类型非常有用。

例如，考虑这样一种情况，即我们有一个数据类型，用强类型的方式表示一个简单语言（仅有变量和函数应用组成）的表达式：

```scala
enum Expr[A]:
   case Var(name: String)
   case Apply[A, B](fun: Expr[B => A], arg: Expr[B]) extends Expr[A]
```

我们想要给用户提供一个方法，将函数映射到给定的 `Expr` 的所有 immediate 子表达式上。这将要求给定的函数是多态的，
因为每个子表达式可能有不同的类型。下面展示了如何用多态函数类型实现这一点：

```scala
def mapSubexpressions[A](e: Expr[A])(f: [B] => Expr[B] => Expr[B]): Expr[A] =
   e match
      case Apply(fun, arg) => Apply(f(fun), f(arg))
      case Var(n) => Var(n)
```

然后下面展示了如何使用这个函数将每个子表达式*包装*到给定的表达式中，并调用某个被定义为变量的 `wrap` 函数：

```scala
val e0 = Apply(Var("f"), Var("a"))
val e1 = mapSubexpressions(e0)(
   [B] => (se: Expr[B]) => Apply(Var[B => B]("wrap"), se))
println(e1) // Apply(Apply(Var(wrap),Var(f)),Apply(Var(wrap),Var(a)))
```

## 与类型 Lambda 的关系

多态函数类型不能与[*类型 Lambda*](type-lambdas.md) 混淆。前者描述多态*值*的*类型*，后者是*类型级别的*实际函数值。

理解这种差异的最好方法是注意**_类型 Lambda 应用于类型，而多态函数应用于 term 中_**：
One would call the function `bar` above
by passing it a type argument `bar[Int]` _within a method body_.
On the other hand, given a type lambda such as `type F = [A] =>> List[A]`,
one would call `F` _within a type expression_, as in `type Bar = F[Int]`.
