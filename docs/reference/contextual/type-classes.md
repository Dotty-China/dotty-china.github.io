---
layout: default
title: 实现 Type Class
parent: 上下文抽象
grand_parent: 参考
nav_order: 7
---

# {{ page.title }}

*Type Class* 是一种抽象的参数化类型，它允许在不使用子类型的情况下向任何封闭数据结构添加新行为。
这在很多用例中很有用，例如：

* 表达您不拥有的类型（来自标准库或第三方库）如何遵守这些行为。
* 表达如何为多个类型定义行为，而不涉及这些类型之间的子类型关系（一个 `extends` 另一个）。（例如，参见 [ad hoc polymorphism](https://en.wikipedia.org/wiki/Ad_hoc_polymorphism)）

因此在 Scala 3 中，*Type Class*只是具有一个或多个参数的 *Trait*，它们的实现不是通过 `extends` 关键字，
而是通过 **given 实例**定义的。下面是一些常见 type class 的定义示例：

## Semigroup 和 Monoid

这是 `Monoid` type class 的定义：

```scala
trait SemiGroup[T]:
   extension (x: T) def combine (y: T): T

trait Monoid[T] extends SemiGroup[T]:
   def unit: T
```

这个 `Monoid` type class 对于类型 `String` 的实现可以像下面这样：

```scala
given Monoid[String] with
   extension (x: String) def combine (y: String): String = x.concat(y)
   def unit: String = ""
```

而对于类型 `Int` 可以这样：

```scala
given Monoid[Int] with
   extension (x: Int) def combine (y: Int): Int = x + y
   def unit: Int = 0
```

现在可以将这个 Monoid 在以下 `combineAll` 方法中用作*上下文边界*：

```scala
def combineAll[T: Monoid](xs: List[T]): T =
   xs.foldLeft(summon[Monoid[T]].unit)(_.combine(_))
```

为了摆脱 `summon[...]`，我们可以为 `Monoid` 定义如下所示的伴生对象：

```scala
object Monoid:
   def apply[T](using m: Monoid[T]) = m
```

这允许以这种方式重写 `combineAll` 方法：

```scala
def combineAll[T: Monoid](xs: List[T]): T =
   xs.foldLeft(Monoid[T].unit)(_.combine(_))
```

## Functor

类型的 `Functor` 提供了将值“映射到”的能力，即应用一个函数在值的内部进行进行变换，同时记住它的 shape。
例如，在不添加或删除元素的情况下修改集合的每个元素。
我们可以用 `F` 表示所有可以“映射到”的类型。它是一个类型构造器：当提供一个类型参数后，它的值的类型变得具体。
因此我们把它写作 `F[_]`，暗示类型 `F` 接受另一个类型作为参数。因此，泛型 `Functor` 的定义可以写作：

```scala
trait Functor[F[_]]:
   def map[A, B](x: F[A], f: A => B): F[B]
```

可以这样理解：“类型构造器 `F[_]` 的 `Functor` 表示通过应用类型 `A => B` 的函数能够将 `F[A]` 转换为 `F[B]` 的能力”。
我们称这里的 `Functor` 定义为 *Type Class*。这样，我们就可以为类型 `List` 定义一个 `Functor` 实例：

```scala
given Functor[List] with
   def map[A, B](x: List[A], f: A => B): List[B] =
      x.map(f) // List already has a `map` method
```

当这个 `given` 实例在作用域中时，任何需要一个 `Functor` 的地方编译器都能接受 `List`。

例如，我们可以编写一个这样的测试方法：

```scala
def assertTransformation[F[_]: Functor, A, B](expected: F[B], original: F[A], mapping: A => B): Unit =
   assert(expected == summon[Functor[F]].map(original, mapping))
```

然后可以这样使用：

```scala
assertTransformation(List("a1", "b1"), List("a", "b"), elt => s"${elt}1")
```

这是第一步，但实践中我们更希望 `map` 函数是一个可以直接在类型 `F` 上访问的方法。
这样我们就可以直接在 `F` 的实例上调用 `map`，而不需要 `summon[Functor[F]]` 部分。
与前面的 Monoid 示例类似，[`extension` 方法](extension-methods.md)帮助我们实现这一点。
让我们用扩展方法重新定义 `Functor` type class。

```scala
trait Functor[F[_]]:
   extension [A](x: F[A])
      def map[B](f: A => B): F[B]
```

`List` 的 `Functor` 实例现在变为：

```scala
given Functor[List] with
   extension [A](xs: List[A])
      def map[B](f: A => B): List[B] =
         xs.map(f) // List already has a `map` method

```

这简化了 `assertTransformation` 方法：

```scala
def assertTransformation[F[_]: Functor, A, B](expected: F[B], original: F[A], mapping: A => B): Unit =
   assert(expected == original.map(mapping))
```

`map` 方法现在直接在 `original` 上使用。它可以用作扩展方法，因为 `original` 的类型是 `F[A]`，
并且定义了 `map` 方法的 `Functor[F]` given 实例在作用域中。

## Monad

将 `Functor[List]` 中的 `map` 应用于 `A => B` 类型的映射函数得到 `List[B]` 类型的结果。
因此将它应用于 `A => List[B]` 类型的映射函数得到 `List[List[B]]` 类型的结果，我们可能会希望“展平”这些值到一个列表中。


That's where `Monad` comes in. `F[_]` 类型的 `Monad` 是带有两个额外操作的 `Functor[F]`：

* `flatMap`，当给定一个 `A => F[B]` 类型的函数时，它将 `F[A]` 转换为 `F[B]`。
* `pure`，它从单个 `A` 类型的值创建一个 `F[A]`。

下面就是这个定义在 Scala 3 中的翻译：

```scala
trait Monad[F[_]] extends Functor[F]:

   /** The unit value for a monad */
   def pure[A](x: A): F[A]

   extension [A](x: F[A])
      /** The fundamental composition operation */
      def flatMap[B](f: A => F[B]): F[B]

      /** The `map` operation can now be defined in terms of `flatMap` */
      def map[B](f: A => B) = x.flatMap(f.andThen(pure))

end Monad
```

### List

`List` 可以用下面的 `given` 实例转换为 monad：

```scala
given listMonad: Monad[List] with
   def pure[A](x: A): List[A] =
      List(x)
   extension [A](xs: List[A])
      def flatMap[B](f: A => List[B]): List[B] =
         xs.flatMap(f) // rely on the existing `flatMap` method of `List`
```

因为 `Monad` 是 `Functor` 的子类型，所以 `List` 也是一个 functor。Functor 的 `map` 操作已经由 `Monad` trait 提供，
因此实例不需要再显式定义它。

### Option

`Option` 是另一种具有同类行为的类型：

```scala
given optionMonad: Monad[Option] with
   def pure[A](x: A): Option[A] =
      Option(x)
   extension [A](xo: Option[A])
      def flatMap[B](f: A => Option[B]): Option[B] = xo match
         case Some(x) => f(x)
         case None => None
```

### Reader

`Monad` 的另一个例子是 _Reader_ Monad，它作用于函数，而不是 `List` 或 `Option` 之类的数据类型上。
它可以用于组合需要相同参数的多个函数。例如多个需要访问同一个配置、上下文、环境变量等的函数。

让我们定义一个 `Config` 类型，以及两个使用它的函数：

```scala
trait Config
// ...
def compute(i: Int)(config: Config): String = ???
def show(str: String)(config: Config): Unit = ???
```

我们可能希望把 `compute` 和 `show` 组合成一个函数，接受 `Config` 作为参数，并显示计算结果，
我们希望使用 monad 避免多次显式传递参数。假设有一个正确的 `flatMap` 操作，我们可以这样写：

```scala
def computeAndShow(i: Int): Config => Unit = compute(i).flatMap(show)
```

而不是

```scala
show(compute(i)(config))(config)
```

让我们来定义这个 m。首先，我们定义一个名为 `ConfigDependent` 的类型，它表示一个函数，
当传递一个 `Config` 时，这个函数产生一个 `Result`。

```scala
type ConfigDependent[Result] = Config => Result
```

Monad 实例看起来像这样：

```scala
given configDependentMonad: Monad[ConfigDependent] with

   def pure[A](x: A): ConfigDependent[A] =
      config => x

   extension [A](x: ConfigDependent[A])
      def flatMap[B](f: A => ConfigDependent[B]): ConfigDependent[B] =
         config => f(x(config))(config)

end configDependentMonad
```

可以使用 [type lambda](../new-types/type-lambdas.md) 定义 `ConfigDependent` 类型：

```scala
type ConfigDependent = [Result] =>> Config => Result
```

使用此语法会让之前的 `configDependentMonad` 转换为：

```scala
given configDependentMonad: Monad[[Result] =>> Config => Result] with

   def pure[A](x: A): Config => A =
      config => x

   extension [A](x: Config => A)
      def flatMap[B](f: A => Config => B): Config => B =
         config => f(x(config))(config)

end configDependentMonad
```

我们很可能希望在 `Config` trait 之外的此类环境中使用这个模式。Reader monad 允许我们将 `Config` 抽象为类型*参数*，
在以下定义中命名为 `Ctx`：

```scala
given readerMonad[Ctx]: Monad[[X] =>> Ctx => X] with

   def pure[A](x: A): Ctx => A =
      ctx => x

   extension [A](x: Ctx => A)
      def flatMap[B](f: A => Ctx => B): Ctx => B =
         ctx => f(x(ctx))(ctx)

end readerMonad
```

## 总结

The definition of a _type class_ is expressed with a parameterised type with abstract members, such as a `trait`.
The main difference between subtype polymorphism and ad-hoc polymorphism with _type classes_ is how the definition of the _type class_ is implemented, in relation to the type it acts upon.
In the case of a _type class_, its implementation for a concrete type is expressed through a `given` instance definition, which is supplied as an implicit argument alongside the value it acts upon. With subtype polymorphism, the implementation is mixed into the parents of a class, and only a single term is required to perform a polymorphic operation. The type class solution
takes more effort to set up, but is more extensible: Adding a new interface to a
class requires changing the source code of that class. But contrast, instances for type classes can be defined anywhere.

To conclude, we have seen that traits and given instances, combined with other constructs like extension methods, context bounds and type lambdas allow a concise and natural expression of _type classes_.
