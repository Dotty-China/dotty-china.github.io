---
layout: default
title: "依赖函数类型 - 更多细节"
nav_exclude: true
---

初步实施于 [PR #3464](https://github.com/lampepfl/dotty/pull/3464)。

## 语法

```ebnf
FunArgTypes       ::=  InfixType
                    |  ‘(’ [ FunArgType {',' FunArgType } ] ‘)’
                    |  ‘(’ TypedFunParam {',' TypedFunParam } ‘)’
TypedFunParam     ::=  id ‘:’ Type
```

依赖函数类型是右关联的，例如 `(s: S) => (t: T) => U` 与 `(s: S) => ((t: T) => U)` 相同。

## 实现

依赖函数类型是定义了依赖结果类型的 `apply` 方法的类类型的简写。依赖函数类型脱糖成 `scala.FunctionN` 的 refinement type。
有 `N` 个参数的依赖函数类型 `(x1: K1, ..., xN: KN) => R` 被翻译为：

```scala
FunctionN[K1, ..., Kn, R']:
   def apply(x1: K1, ..., xN: KN): R
```

其中结果类型参数 `R'` 是精确的结果类型 `R` 的近似最小上界，不引用参数值 `x1, ..., xN`。

匿名依赖函数的语法和语义与普通的函数相同。Eta 扩展自然地类推为从带有依赖结果类型的方法生成依赖函数类型。

依赖函数可以是隐式的，并以与其他函数相同的方式类推到 `N > 22` 个元数，参见[相应的文档](../dropped-features/limit22.md)。

## 示例

下面的实例定义了一个 trait `C` 和两个依赖函数类型 `DF` 与 `IDF`，并分别打印相应的函数调用结果：

[depfuntype.scala]: https://github.com/lampepfl/dotty/blob/master/tests/pos/depfuntype.scala

```scala
trait C { type M; val m: M }

type DF = (x: C) => x.M

type IDF = (x: C) ?=> x.M

@main def test =
   val c = new C { type M = Int; val m = 3 }

   val depfun: DF = (x: C) => x.m
   val t = depfun(c)
   println(s"t=$t")   // prints "t=3"

   val idepfun: IDF = summon[C].m
   val u = idepfun(using c)
   println(s"u=$u")   // prints "u=3"

```

在下面的例子中，依赖类型 `f.Eff` 引用 effect 类型 `CanThrow`：

[eff-dependent.scala]: https://github.com/lampepfl/dotty/blob/master/tests/run/eff-dependent.scala

```scala
trait Effect

// Type X => Y
abstract class Fun[-X, +Y]:
   type Eff <: Effect
   def apply(x: X): Eff ?=> Y

class CanThrow extends Effect
class CanIO extends Effect

given ct: CanThrow = new CanThrow
given ci: CanIO = new CanIO

class I2S extends Fun[Int, String]:
   type Eff = CanThrow
   def apply(x: Int) = x.toString

class S2I extends Fun[String, Int]:
   type Eff = CanIO
   def apply(x: String) = x.length

// def map(f: A => B)(xs: List[A]): List[B]
def map[A, B](f: Fun[A, B])(xs: List[A]): f.Eff ?=> List[B] =
   xs.map(f.apply)

// def mapFn[A, B]: (A => B) -> List[A] -> List[B]
def mapFn[A, B]: (f: Fun[A, B]) => List[A] => f.Eff ?=> List[B] =
   f => xs => map(f)(xs)

// def compose(f: A => B)(g: B => C)(x: A): C
def compose[A, B, C](f: Fun[A, B])(g: Fun[B, C])(x: A):
   f.Eff ?=> g.Eff ?=> C =
   g(f(x))

// def composeFn: (A => B) -> (B => C) -> A -> C
def composeFn[A, B, C]:
   (f: Fun[A, B]) => (g: Fun[B, C]) => A => f.Eff ?=> g.Eff ?=> C =
   f => g => x => compose(f)(g)(x)

@main def test =
   val i2s = new I2S
   val s2i = new S2I

   assert(mapFn(i2s)(List(1, 2, 3)).mkString == "123")
   assert(composeFn(i2s)(s2i)(22) == 2)
```

### 类型检查

脱糖后不需要其他类型规则来处理依赖函数类型。
