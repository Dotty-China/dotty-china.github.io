---
layout: default
title: 匹配类型
parent: 新类型
grand_parent: 参考
nav_order: 4
---

# {{ page.title }}

匹配类型依赖于它 scrutinee 的类型，化简至其右侧的类型之一。例如：

```scala
type Elem[X] = X match
   case String => Char
   case Array[t] => t
   case Iterable[t] => t
```

这定义了一个遵循以下的化简规则的类型：

```scala
Elem[String]       =:=  Char
Elem[Array[Int]]   =:=  Int
Elem[List[Float]]  =:=  Float
Elem[Nil.type]     =:=  Nothing
```

这里 `=:=` 代表左侧和右侧的类型互为彼此的子类型。

通常匹配类型的形式为

```scala
S match { P1 => T1 ... Pn => Tn }
```

其中 `S`、`T1`、...、`Tn` 是类型，`P1`、...、 `Pn` 是类型模式。模式中的类型变量通常以小写字母开头。

匹配类型可以构成递归类型定义的一部分。例如：

```scala
type LeafElem[X] = X match
   case String => Char
   case Array[t] => LeafElem[t]
   case Iterable[t] => LeafElem[t]
   case AnyVal => X
```

递归匹配类型也可以像这样给定一个上限：

```scala
type Concat[Xs <: Tuple, +Ys <: Tuple] <: Tuple = Xs match
   case EmptyTuple => Ys
   case x *: xs => x *: Concat[xs, Ys]
```

在这个定义中，`Concat[A, B]` 的每个实例，无论是否可化简，都是 `Tuple` 的一个子类型。这是递归调用 `x *: Concat[xs, Ys]` 
所必需的，因为 `*:` 需要一个 `Tuple` 作为右操作数。

## 依赖类型

匹配类型可以用于定义依赖类型的方法。例如，这是上面 `LeafElem` 在值级别的对应（注意，这里使用匹配类型作为返回值类型）：

```scala
def leafElem[X](x: X): LeafElem[X] = x match
   case x: String      => x.charAt(0)
   case x: Array[t]    => leafElem(x(9))
   case x: Iterable[t] => leafElem(x.head)
   case x: AnyVal      => x
```

匹配表达式的特殊类型模式只有在满足以下条件时才可用：

1. 这个匹配表达式的模式没有 guard
2. 这个匹配表达式的 scrutinee 们的类型是匹配类型 scrutinee 们的类型的子类型
3. 匹配表达式和匹配类型的 case 数相同
4. 匹配表达式的模式都是 [Typed Pattern](https://scala-lang.org/files/archive/spec/2.13/08-pattern-matching.html#typed-patterns)，
并且这些类型与匹配类型中的对应类型模式是 `=:=` 的。

## 匹配类型的表示

匹配类型
```
S match { P1 => T1 ... Pn => Tn }
```
的内部表示是 `Match(S, C1, ..., Cn) <: B`，其中每个 `Ci` 的形式是
```
[Xs] =>> P => T
```

Here, `[Xs]` is a type parameter clause of the variables bound in pattern `Pi`.
If there are no bound type variables in a case, the type parameter clause is
omitted and only the function type `P => T` is kept. So each case is either a
unary function type or a type lambda over a unary function type.

`B` is the declared upper bound of the match type, or `Any` if no such bound is
given.  We will leave it out in places where it does not matter for the
discussion. The scrutinee, bound, and pattern types must all be first-order
types.

## 匹配类型简化

Match type reduction follows the semantics of match expressions, that is, a
match type of the form `S match { P1 => T1 ... Pn => Tn }` reduces to `Ti` if
and only if `s: S match { _: P1 => T1 ... _: Pn => Tn }` evaluates to a value of
type `Ti` for all `s: S`.

The compiler implements the following reduction algorithm:

- If the scrutinee type `S` is an empty set of values (such as `Nothing` or
  `String & Int`), do not reduce.
- Sequentially consider each pattern `Pi`
    - If `S <: Pi` reduce to `Ti`.
    - Otherwise, try constructing a proof that `S` and `Pi` are disjoint, or, in
      other words, that no value `s` of type `S` is also of type `Pi`.
    - If such proof is found, proceed to the next case (`Pi+1`), otherwise, do
      not reduce.

Disjointness proofs rely on the following properties of Scala types:

1. Single inheritance of classes
2. Final classes cannot be extended
3. Constant types with distinct values are nonintersecting
4. Singleton paths to distinct values are nonintersecting, such as `object` definitions or singleton enum cases.

Type parameters in patterns are minimally instantiated when computing `S <: Pi`.
An instantiation `Is` is _minimal_ for `Xs` if all type variables in `Xs` that
appear covariantly and nonvariantly in `Is` are as small as possible and all
type variables in `Xs` that appear contravariantly in `Is` are as large as
possible.  Here, "small" and "large" are understood with respect to  `<:`.

For simplicity, we have omitted constraint handling so far. The full formulation
of subtyping tests describes them as a function from a constraint and a pair of
types to either _success_ and a new constraint or _failure_. In the context of
reduction, the subtyping test `S <: [Xs := Is] P` is understood to leave the
bounds of all variables in the input constraint unchanged, i.e. existing
variables in the constraint cannot be instantiated by matching the scrutinee
against the patterns.

## 匹配类型的子类型规则

The following rules apply to match types. For simplicity, we omit environments
and constraints.

1. The first rule is a structural comparison between two match types:

   ```
   S match { P1 => T1 ... Pm => Tm }  <:  T match { Q1 => U1 ... Qn => Un }
   ```

   if

   ```
   S =:= T,  m >= n,  Pi =:= Qi and Ti <: Ui for i in 1..n
   ```

   I.e. scrutinees and patterns must be equal and the corresponding bodies must
   be subtypes. No case re-ordering is allowed, but the subtype can have more
   cases than the supertype.

2. The second rule states that a match type and its redux are mutual subtypes.

   ```
   S match { P1 => T1 ... Pn => Tn }  <:  U
   U  <:  S match { P1 => T1 ... Pn => Tn }
   ```

   if

   `S match { P1 => T1 ... Pn => Tn }` reduces to `U`

3. The third rule states that a match type conforms to its upper bound:

   ```
   (S match { P1 => T1 ... Pn => Tn } <: B)  <:  B
   ```

## Termination

Match type definitions can be recursive, which means that it's possible to run
into an infinite loop while reducing match types.

Since reduction is linked to subtyping, we already have a cycle detection
mechanism in place. As a result, the following will already give a reasonable
error message:

```scala
type L[X] = X match
   case Int => L[X]

def g[X]: L[X] = ???
```

```scala
   |  val x: Int = g[Int]
   |                ^
   |Recursion limit exceeded.
   |Maybe there is an illegal cyclic reference?
   |If that's not the case, you could also try to
   |increase the stacksize using the -Xss JVM option.
   |A recurring operation is (inner to outer):
   |
   |  subtype LazyRef(Test.L[Int]) <:< Int
```

Internally, the Scala compiler detects these cycles by turning selected stack overflows into
type errors. If there is a stack overflow during subtyping, the exception will
be caught and turned into a compile-time error that indicates a trace of the
subtype tests that caused the overflow without showing a full stack trace.

## Variance Laws for Match Types

**Note:** This section does not reflect the current implementation.

Within a match type `Match(S, Cs) <: B`, all occurrences of type variables count
as covariant. By the nature of the cases `Ci` this means that occurrences in
pattern position are contravariant (since patterns are represented as function
type arguments).

## Related Work

Match types have similarities with
[closed type families](https://wiki.haskell.org/GHC/Type_families) in Haskell.
Some differences are:

- Subtyping instead of type equalities.
- Match type reduction does not tighten the underlying constraint, whereas type
  family reduction does unify. This difference in approach mirrors the
  difference between local type inference in Scala and global type inference in
  Haskell.

Match types are also similar to Typescript's
[conditional types](https://github.com/Microsoft/TypeScript/pull/21316). The
main differences here are:

 - Conditional types only reduce if both the scrutinee and pattern are ground,
   whereas match types also work for type parameters and abstract types.
 - Match types support direct recursion.
 - Conditional types distribute through union types.
