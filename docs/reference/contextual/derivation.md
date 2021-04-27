---
layout: default
title: Type Class 推导
parent: 上下文抽象
grand_parent: 参考
nav_order: 8
---

# {{ page.title }}

Type class 推导是为满足某些简单条件的 type class 自动生成 given 实例的一种方法。
在这个意义上，type class 是任何具有一个类型参数的 trait 或者类，这个类型参数描决定了要操作的类型。
常见的例子有 `Eq`、`Ordering` 和 `Show`。例如，给定以下 ADT `Tree`：

```scala
enum Tree[T] derives Eq, Ordering, Show {
   case Branch(left: Tree[T], right: Tree[T])
   case Leaf(elem: T)
}
```

`derives` 子句自动在 `Tree` 的伴生对象中生成了 type class `Eq`、`Ordering` 和 `Show` 的 given 实例：

```scala
given [T: Eq]       : Eq[Tree[T]]    = Eq.derived
given [T: Ordering] : Ordering[Tree] = Ordering.derived
given [T: Show]     : Show[Tree]     = Show.derived
```

我们称 `Tree` 为*推导类型*，`Eq`、`Ordering` 和 `Show` 的实例为*推导实例*。

## 支持 `derives` 子句的类型

所有数据类型都可以有一个 `derives` 子句。This document focuses primarily on data types which also have a given instance
of the `Mirror` type class available. Type class `Mirror` 的实例由编译器为这些类型自动生成：

- 枚举和枚举 case
- case class 和 case object
- 子类只有 case 类或 case 对象的 sealed 类或 sealed trait


Type class `Mirror` 的实例在类型级别提供有关组件和类型标签的信息。它们还提供最小化的 term 级基础设施，
以允许更高级别的库提供全面的推导支持。

```scala
sealed trait Mirror {

   /** the type being mirrored */
   type MirroredType

   /** the type of the elements of the mirrored type */
   type MirroredElemTypes

   /** The mirrored *-type */
   type MirroredMonoType

   /** The name of the type */
   type MirroredLabel <: String

   /** The names of the elements of the type */
   type MirroredElemLabels <: Tuple
}

object Mirror {

   /** The Mirror for a product type */
   trait Product extends Mirror {

      /** Create a new instance of type `T` with elements
       *  taken from product `p`.
       */
      def fromProduct(p: scala.Product): MirroredMonoType
   }

   trait Sum extends Mirror {

      /** The ordinal number of the case class of `x`.
       *  For enums, `ordinal(x) == x.ordinal`
       */
      def ordinal(x: MirroredMonoType): Int
   }
}
```

Product 类型（例如 case 类和对象，以及枚举的 case）具有为 `Mirror.Product` 子类型的镜像。
Sum type（例如子类型只有 product 类型的 sealed 类或 trait，以及枚举）具有为 `Mirror.Sum` 子类型的镜像。

对于上面的 ADT `Tree`，编译器会自动提供以下 `Mirror` 实例：

```scala
// Mirror for Tree
new Mirror.Sum {
   type MirroredType = Tree
   type MirroredElemTypes[T] = (Branch[T], Leaf[T])
   type MirroredMonoType = Tree[_]
   type MirroredLabels = "Tree"
   type MirroredElemLabels = ("Branch", "Leaf")

   def ordinal(x: MirroredMonoType): Int = x match
      case _: Branch[_] => 0
      case _: Leaf[_] => 1
}
// Mirror for Branch
new Mirror.Product {
   type MirroredType = Branch
   type MirroredElemTypes[T] = (Tree[T], Tree[T])
   type MirroredMonoType = Branch[_]
   type MirroredLabels = "Branch"
   type MirroredElemLabels = ("left", "right")

   def fromProduct(p: Product): MirroredMonoType =
      new Branch(...)
}
// Mirror for Leaf
new Mirror.Product {
   type MirroredType = Leaf
   type MirroredElemTypes[T] = Tuple1[T]
   type MirroredMonoType = Leaf[_]
   type MirroredLabels = "Leaf"
   type MirroredElemLabels = Tuple1["elem"]

   def fromProduct(p: Product): MirroredMonoType =
      new Leaf(...)
}
```

请注意 `Mirror` 类型的以下属性：

- 属性是使用类型而不是 term 编码的。这意味着除非使用了它们，否则没有运行时 footprint，并且它们是 Scala 3 元编程工具的编译时特性。
- The kinds of `MirroredType` and `MirroredElemTypes` match the kind of the data type the mirror is an instance for.
  这允许 `Mirror` 支持所有类别的 ADT。
- Sum 或 Product 没有清晰的表示类型（例如没有 Scala 2 版本 Shapeless 中的 `HList` 或 `Coproduct` 类型）。
  相反，数据类型的子类型集合由普通的、可能是参数化的元组类型表示。Scala 3 的元编程工具可以用于处理这些元组类型，
  并在其上构建更高级别的库。
- 对于 Product 和 Sum 类型，`MirroredElemTypes` 的元素都是按照定义顺序排列的（例如 `Tree` 的 `MirroredElemTypes`中，
  `Branch[T]` 在 `Leaf[T]` 前，因为源文件中 `Branch` 的定义在 `Leaf` 的定义之前）。这意味着 `Mirror.Sum` 在这方面不同于 
  Scala 2 中 Shapeless 对 ADT 的泛型表示，其构造器是按照首字母顺序排列的。
- The methods `ordinal` and `fromProduct` are defined in terms of `MirroredMonoType` which is the type of kind-`*`
  which is obtained from `MirroredType` by wildcarding its type parameters.

## 支持自动推导的 Type Class

如果一个 trait 或者类的伴生对象定义了一个名为 `derived` 的方法，则它可以出现在 `derives` 子句中。
Type class `TC[_]` 的 `derived` 方法的签名与实现是任意的，但通常采用以下形式：

```scala
def derived[T](using Mirror.Of[T]): TC[T] = ...
```

也就是说，`derived` 方法接受一个类型为 `Mirror` 的某个子类型的上下文参数，该参数提供了推导类型的形状，
并根据这个形状计算 type class 的实现。这就是带有 `derives` 子句的 ADT 提供者必须知道的关于 type class 推导的全部内容。

Note that `derived` methods may have context `Mirror` parameters indirectly (e.g. by having a context argument which in turn
has a context `Mirror` parameter, or not at all (e.g. they might use some completely different user-provided mechanism, for
instance using Scala 3 macros or runtime reflection). We expect that (direct or indirect) `Mirror` based implementations
will be the most common and that is what this document emphasises.

Type class authors will most likely use higher level derivation or generic programming libraries to implement
`derived` methods. An example of how a `derived` method might be implemented using _only_ the low level facilities
described above and Scala 3's general metaprogramming features is provided below. It is not anticipated that type class
authors would normally implement a `derived` method in this way, however this walkthrough can be taken as a guide for
authors of the higher level derivation libraries that we expect typical type class authors will use (for a fully
worked out example of such a library, see [Shapeless 3](https://github.com/milessabin/shapeless/tree/shapeless-3)).

## 如何使用底层机制编写 type class 的 `derived` 方法

The low-level method we will use to implement a type class `derived` method in this example exploits three new
type-level constructs in Scala 3: inline methods, inline matches, and implicit searches via  `summonInline` or `summonFrom`. Given this definition of the
`Eq` type class,

```scala
trait Eq[T] {
   def eqv(x: T, y: T): Boolean
}
```

we need to implement a method `Eq.derived` on the companion object of `Eq` that produces a given instance for `Eq[T]` given
a `Mirror[T]`. Here is a possible implementation,

```scala
inline given derived[T](using m: Mirror.Of[T]): Eq[T] = {
   val elemInstances = summonAll[m.MirroredElemTypes]           // (1)
   inline m match {                                             // (2)
      case s: Mirror.SumOf[T]     => eqSum(s, elemInstances)
      case p: Mirror.ProductOf[T] => eqProduct(p, elemInstances)
   }
}
```

Note that `derived` is defined as an `inline` given. This means that the method will be expanded at
call sites (for instance the compiler generated instance definitions in the companion objects of ADTs which have a
`derived Eq` clause), and also that it can be used recursively if necessary, to compute instances for children.

The body of this method (1) first materializes the `Eq` instances for all the child types of type the instance is
being derived for. This is either all the branches of a sum type or all the fields of a product type. The
implementation of `summonAll` is `inline` and uses Scala 3's `summonInline` construct to collect the instances as a
`List`,

```scala
inline def summonAll[T <: Tuple]: List[Eq[_]] =
   inline erasedValue[T] match {
      case _: EmptyTuple => Nil
      case _: (t *: ts) => summonInline[Eq[t]] :: summonAll[ts]
   }
```

with the instances for children in hand the `derived` method uses an `inline match` to dispatch to methods which can
construct instances for either sums or products (2). Note that because `derived` is `inline` the match will be
resolved at compile-time and only the left-hand side of the matching case will be inlined into the generated code with
types refined as revealed by the match.

In the sum case, `eqSum`, we use the runtime `ordinal` values of the arguments to `eqv` to first check if the two
values are of the same subtype of the ADT (3) and then, if they are, to further test for equality based on the `Eq`
instance for the appropriate ADT subtype using the auxiliary method `check` (4).

```scala
def eqSum[T](s: Mirror.SumOf[T], elems: List[Eq[_]]): Eq[T] =
   new Eq[T] {
      def eqv(x: T, y: T): Boolean = {
         val ordx = s.ordinal(x)                            // (3)
         (s.ordinal(y) == ordx) && check(elems(ordx))(x, y) // (4)
      }
   }
```

In the product case, `eqProduct` we test the runtime values of the arguments to `eqv` for equality as products based
on the `Eq` instances for the fields of the data type (5),

```scala
def eqProduct[T](p: Mirror.ProductOf[T], elems: List[Eq[_]]): Eq[T] = 
   new Eq[T] {
      def eqv(x: T, y: T): Boolean =
         iterator(x).zip(iterator(y)).zip(elems.iterator).forall {  // (5)
            case ((x, y), elem) => check(elem)(x, y)
         }
   }
```

Pulling this all together we have the following complete implementation,

```scala
import scala.deriving.*
import scala.compiletime.{erasedValue, summonInline}

inline def summonAll[T <: Tuple]: List[Eq[_]] =
   inline erasedValue[T] match
      case _: EmptyTuple => Nil
      case _: (t *: ts) => summonInline[Eq[t]] :: summonAll[ts]

trait Eq[T] {
   def eqv(x: T, y: T): Boolean
}

object Eq {
   given Eq[Int] with {
      def eqv(x: Int, y: Int) = x == y
   }

   def check(elem: Eq[_])(x: Any, y: Any): Boolean =
      elem.asInstanceOf[Eq[Any]].eqv(x, y)

   def iterator[T](p: T) = p.asInstanceOf[Product].productIterator

   def eqSum[T](s: Mirror.SumOf[T], elems: => List[Eq[_]]): Eq[T] =
      new Eq[T] {
         def eqv(x: T, y: T): Boolean = {
            val ordx = s.ordinal(x)
            (s.ordinal(y) == ordx) && check(elems(ordx))(x, y)
         }
      }

   def eqProduct[T](p: Mirror.ProductOf[T], elems: => List[Eq[_]]): Eq[T] =
      new Eq[T] {
         def eqv(x: T, y: T): Boolean =
            iterator(x).zip(iterator(y)).zip(elems.iterator).forall {
               case ((x, y), elem) => check(elem)(x, y)
            }
      }

   inline given derived[T](using m: Mirror.Of[T]): Eq[T] = {
      lazy val elemInstances = summonAll[m.MirroredElemTypes]
      inline m match {
         case s: Mirror.SumOf[T]     => eqSum(s, elemInstances)
         case p: Mirror.ProductOf[T] => eqProduct(p, elemInstances)
      }
   }
}
```

we can test this relative to a simple ADT like so,

```scala
enum Opt[+T] derives Eq {
   case Sm(t: T)
   case Nn
}

@main def test(): Unit = {
   import Opt.*
   val eqoi = summon[Eq[Opt[Int]]]
   assert(eqoi.eqv(Sm(23), Sm(23)))
   assert(!eqoi.eqv(Sm(23), Sm(13)))
   assert(!eqoi.eqv(Sm(23), Nn))
}
```

In this case the code that is generated by the inline expansion for the derived `Eq` instance for `Opt` looks like the
following, after a little polishing,

```scala
given derived$Eq[T](using eqT: Eq[T]): Eq[Opt[T]] =
   eqSum(
      summon[Mirror[Opt[T]]],
      List(
         eqProduct(summon[Mirror[Sm[T]]], List(summon[Eq[T]])),
         eqProduct(summon[Mirror[Nn.type]], Nil)
      )
   )
```

Alternative approaches can be taken to the way that `derived` methods can be defined. For example, more aggressively
inlined variants using Scala 3 macros, whilst being more involved for type class authors to write than the example
above, can produce code for type classes like `Eq` which eliminate all the abstraction artefacts (eg. the `Lists` of
child instances in the above) and generate code which is indistinguishable from what a programmer might write by hand.
As a third example, using a higher level library such as Shapeless the type class author could define an equivalent
`derived` method as,

```scala
given eqSum[A](using inst: => K0.CoproductInstances[Eq, A]): Eq[A] with {
   def eqv(x: A, y: A): Boolean = inst.fold2(x, y)(false)(
      [t] => (eqt: Eq[t], t0: t, t1: t) => eqt.eqv(t0, t1)
   )
}

given eqProduct[A](using inst: K0.ProductInstances[Eq, A]): Eq[A] with {
   def eqv(x: A, y: A): Boolean = inst.foldLeft2(x, y)(true: Boolean)(
      [t] => (acc: Boolean, eqt: Eq[t], t0: t, t1: t) =>
         Complete(!eqt.eqv(t0, t1))(false)(true)
   )
}

inline def derived[A](using gen: K0.Generic[A]) as Eq[A] =
   gen.derive(eqSum, eqProduct)
```

The framework described here enables all three of these approaches without mandating any of them.

For a brief discussion on how to use macros to write a type class `derived`
method please read more at [How to write a type class `derived` method using macros](./derivation-macro.md).

## 从别处推导实例

Sometimes one would like to derive a type class instance for an ADT after the ADT is defined, without being able to
change the code of the ADT itself.  To do this, simply define an instance using the `derived` method of the type class
as right-hand side. E.g, to implement `Ordering` for `Option` define,

```scala
given [T: Ordering]: Ordering[Option[T]] = Ordering.derived
```

Assuming the `Ordering.derived` method has a context parameter of type `Mirror[T]` it will be satisfied by the
compiler generated `Mirror` instance for `Option` and the derivation of the instance will be expanded on the right
hand side of this definition in the same way as an instance defined in ADT companion objects.

## 语法

```ebnf
Template          ::=  InheritClauses [TemplateBody]
EnumDef           ::=  id ClassConstr InheritClauses EnumBody
InheritClauses    ::=  [‘extends’ ConstrApps] [‘derives’ QualId {‘,’ QualId}]
ConstrApps        ::=  ConstrApp {‘with’ ConstrApp}
                    |  ConstrApp {‘,’ ConstrApp}
```

**Note:** To align `extends` clauses and `derives` clauses, Scala 3 also allows multiple
extended types to be separated by commas. So the following is now legal:

```scala
class A extends B, C { ... }
```

It is equivalent to the old form

```scala
class A extends B with C { ... }
```

## 讨论

This type class derivation framework is intentionally very small and low-level. There are essentially two pieces of
infrastructure in compiler-generated `Mirror` instances,

+ type members encoding properties of the mirrored types.
+ a minimal value level mechanism for working generically with terms of the mirrored types.

The `Mirror` infrastructure can be seen as an extension of the existing `Product` infrastructure for case classes:
typically `Mirror` types will be implemented by the ADTs companion object, hence the type members and the `ordinal` or
`fromProduct` methods will be members of that object. The primary motivation for this design decision, and the
decision to encode properties via types rather than terms was to keep the bytecode and runtime footprint of the
feature small enough to make it possible to provide `Mirror` instances _unconditionally_.

Whilst `Mirrors` encode properties precisely via type members, the value level `ordinal` and `fromProduct` are
somewhat weakly typed (because they are defined in terms of `MirroredMonoType`) just like the members of `Product`.
This means that code for generic type classes has to ensure that type exploration and value selection proceed in
lockstep and it has to assert this conformance in some places using casts. If generic type classes are correctly
written these casts will never fail.

As mentioned, however, the compiler-provided mechanism is intentionally very low level and it is anticipated that
higher level type class derivation and generic programming libraries will build on this and Scala 3's other
metaprogramming facilities to hide these low-level details from type class authors and general users. Type class
derivation in the style of both Shapeless and Magnolia are possible (a prototype of Shapeless 3, which combines
aspects of both Shapeless 2 and Magnolia has been developed alongside this language feature) as is a more aggressively
inlined style, supported by Scala 3's new quote/splice macro and inlining facilities.
