---
layout: default
title: 枚举
parent: 枚举
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

枚举（Enumeration）用于定义包含一组命名值的类型。

```scala
enum Color:
   case Red, Green, Blue
```

这定义了一个新的 `sealed` 类 `Color`，以及三个值 `Color.Red`、`Color.Green` 和 `Color.Blue`。
颜色值是 `Color` 的伴生对象的成员。

### 参数化枚举

枚举可以是参数化的。

```scala
enum Color(val rgb: Int):
   case Red   extends Color(0xFF0000)
   case Green extends Color(0x00FF00)
   case Blue  extends Color(0x0000FF)
```

如例所示，可以显式用 `extends` 子句确定参数值。

### 枚举方法

枚举的值对应于一个唯一的证书。枚举值对应的整数由其 `ordinal` 方法返回：

```scala
scala> val red = Color.Red
val red: Color = Red
scala> red.ordinal
val res0: Int = 0
```

枚举的伴生对象中还定义了三个工具方法。`valueOf` 方法通过名称获取枚举值。
`values` 方法返回包含枚举中定义的所有枚举值的一个 `Array`。
`fromOrdinal` 方法从序号（`Int` 类型）获取枚举值。

```scala
scala> Color.valueOf("Blue")
val res0: Color = Blue
scala> Color.values
val res1: Array[Color] = Array(Red, Green, Blue)
scala> Color.fromOrdinal(0)
val res2: Color = Red
```

### 枚举的用户定义成员

您可以将自己的定义加入一个枚举中。例如：

```scala
enum Planet(mass: Double, radius: Double):
   private final val G = 6.67300E-11
   def surfaceGravity = G * mass / (radius * radius)
   def surfaceWeight(otherMass: Double) = otherMass * surfaceGravity

   case Mercury extends Planet(3.303e+23, 2.4397e6)
   case Venus   extends Planet(4.869e+24, 6.0518e6)
   case Earth   extends Planet(5.976e+24, 6.37814e6)
   case Mars    extends Planet(6.421e+23, 3.3972e6)
   case Jupiter extends Planet(1.9e+27,   7.1492e7)
   case Saturn  extends Planet(5.688e+26, 6.0268e7)
   case Uranus  extends Planet(8.686e+25, 2.5559e7)
   case Neptune extends Planet(1.024e+26, 2.4746e7)
end Planet
```

也可以为枚举定义显式的伴生对象：

```scala
object Planet:
   def main(args: Array[String]) =
      val earthWeight = args(0).toDouble
      val mass = earthWeight / Earth.surfaceGravity
      for p <- values do
         println(s"Your weight on $p is ${p.surfaceWeight(mass)}")
end Planet
```

### 枚举类的弃用

As a library author, you may want to signal that an enum case is no longer intended for use. However you could still want to gracefully handle the removal of a case from your public API, such as special casing deprecated cases.

To illustrate, say that the `Planet` enum originally had an additional case:

```diff
 enum Planet(mass: Double, radius: Double):
    ...
    case Neptune extends Planet(1.024e+26, 2.4746e7)
+   case Pluto   extends Planet(1.309e+22, 1.1883e3)
 end Planet
```

We now want to deprecate the `Pluto` case. First we add the `scala.deprecated` annotation to `Pluto`:

```diff
 enum Planet(mass: Double, radius: Double):
    ...
    case Neptune extends Planet(1.024e+26, 2.4746e7)
-   case Pluto   extends Planet(1.309e+22, 1.1883e3)
+
+   @deprecated("refer to IAU definition of planet")
+   case Pluto extends Planet(1.309e+22, 1.1883e3)
 end Planet
```

Outside the lexical scopes of `enum Planet` or `object Planet`, references to `Planet.Pluto` will produce a deprecation warning, but within those scopes we can still reference it to implement introspection over the deprecated cases:

```scala
trait Deprecations[T <: reflect.Enum] {
   extension (t: T) def isDeprecatedCase: Boolean
}

object Planet {
   given Deprecations[Planet] with {
      extension (p: Planet)
         def isDeprecatedCase = p == Pluto
   }
}
```

We could imagine that a library may use [type class derivation](../contextual/derivation.md) to automatically provide an instance for `Deprecations`.

### Compatibility with Java Enums

If you want to use the Scala-defined enums as [Java enums](https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html), you can do so by extending
the class `java.lang.Enum`, which is imported by default, as follows:

```scala
enum Color extends Enum[Color] { case Red, Green, Blue }
```

The type parameter comes from the Java enum [definition](https://docs.oracle.com/javase/8/docs/api/index.html?java/lang/Enum.html) and should be the same as the type of the enum.
There is no need to provide constructor arguments (as defined in the Java API docs) to `java.lang.Enum` when extending it – the compiler will generate them automatically.

After defining `Color` like that, you can use it like you would a Java enum:

```scala
scala> Color.Red.compareTo(Color.Green)
val res15: Int = -1
```

For a more in-depth example of using Scala 3 enums from Java, see [this test](https://github.com/lampepfl/dotty/tree/master/tests/run/enum-java). In the test, the enums are defined in the `MainScala.scala` file and used from a Java source, `Test.java`.

### Implementation

Enums are represented as `sealed` classes that extend the `scala.reflect.Enum` trait.
This trait defines a single public method, `ordinal`:

```scala
package scala.reflect

/** A base trait of all Scala enum definitions */
transparent trait Enum extends Any, Product, Serializable:

   /** A number uniquely identifying a case of an enum */
   def ordinal: Int
```

Enum values with `extends` clauses get expanded to anonymous class instances.
For instance, the `Venus` value above would be defined like this:

```scala
val Venus: Planet = new Planet(4.869E24, 6051800.0):
   def ordinal: Int = 1
   override def productPrefix: String = "Venus"
   override def toString: String = "Venus"
```

Enum values without `extends` clauses all share a single implementation
that can be instantiated using a private method that takes a tag and a name as arguments.
For instance, the first
definition of value `Color.Red` above would expand to:

```scala
val Red: Color = $new(0, "Red")
```

### Reference

For more information, see [Issue #1970](https://github.com/lampepfl/dotty/issues/1970) and
[PR #4003](https://github.com/lampepfl/dotty/pull/4003).
