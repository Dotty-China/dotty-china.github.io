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
enum Color {
   case Red, Green, Blue
}
```

这定义了一个新的 `sealed` 类 `Color`，以及三个值 `Color.Red`、`Color.Green` 和 `Color.Blue`。
颜色值是 `Color` 的伴生对象的成员。

### 参数化枚举

枚举可以是参数化的。

```scala
enum Color(val rgb: Int) {
   case Red   extends Color(0xFF0000)
   case Green extends Color(0x00FF00)
   case Blue  extends Color(0x0000FF)
}
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
enum Planet(mass: Double, radius: Double) {
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
}
```

也可以为枚举定义显式的伴生对象：

```scala
object Planet {
   def main(args: Array[String]) = {
      val earthWeight = args(0).toDouble
      val mass = earthWeight / Earth.surfaceGravity
      for(p <- values) {
         println(s"Your weight on $p is ${p.surfaceWeight(mass)}")
      }
   }
}
```

### 枚举类的弃用

作为库的作者，您可能想发出枚举 case 不再适用的信号。
However you could still want to gracefully handle the removal of a case from your public API, such as special casing deprecated cases.

举例来说，假设枚举 `Planet` 开始有一个额外的 case：

```diff
 enum Planet(mass: Double, radius: Double) {
    ...
    case Neptune extends Planet(1.024e+26, 2.4746e7)
+   case Pluto   extends Planet(1.309e+22, 1.1883e3)
 }
```
现在我们想弃用 `Pluto` case。首先我们向 `Pluto` 添加 `scala.deprecated` 注解：

```diff
 enum Planet(mass: Double, radius: Double) {
    ...
    case Neptune extends Planet(1.024e+26, 2.4746e7)
-   case Pluto   extends Planet(1.309e+22, 1.1883e3)
+
+   @deprecated("refer to IAU definition of planet")
+   case Pluto extends Planet(1.309e+22, 1.1883e3)
 }
```

在 `enum Planet` 和 `object Planet` 的词法范围以外，引用 `Planet.Pluto` 将产生一个弃用警告，但在这些词法范围内，
我们仍然能够引用它 to implement introspection over the deprecated cases：

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

我们可以设想一个库可能可以使用 [type class 推导](../contextual/derivation.md)自动提供 `Deprecations` 
的实例。

### 与 Java 枚举的兼容性

你可以通过继承类 `java.lang.Enum` 使 Scala 中定义的枚举成为 [Java 枚举](https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html)。
`java.lang.Enum` 默认被导入，如下所示：

```scala
enum Color extends Enum[Color] { case Red, Green, Blue }
```

类型参数来自 [Java 枚举的定义](https://docs.oracle.com/javase/8/docs/api/index.html?java/lang/Enum.html)，
应该与枚举类型相同。不需要提供 `java.lang.Enum` 的构造器参数（像 Java API 文档中定义的那样），
当继承 `java.lang.Enum` 时，编译器会自动生成它们。

在定义了这样的 `Color` 之后，您可以像使用 Java 枚举一样使用它：

```scala
scala> Color.Red.compareTo(Color.Green)
val res15: Int = -1
```

有关从 Java 使用 Scala 3 枚举的更深入的示例，请参见[这个测试](https://github.com/lampepfl/dotty/tree/master/tests/run/enum-java)。
在这个测试中，枚举定义于文件 `MainScala.scala` 中，并且在 Java 源文件 `Test.java` 中被使用。

### 实现

枚举被表示为继承自 `scala.reflect.Enum` trait 的 `sealed` 类。
这个  trait 定义了一个 public 方法 `ordinal`：

```scala
package scala.reflect

/** A base trait of all Scala enum definitions */
transparent trait Enum extends Any, Product, Serializable {

   /** A number uniquely identifying a case of an enum */
   def ordinal: Int
}
```

带有 `extends` 子句的枚举值被扩展为匿名类实例。例如，上面的 `Venus` 值定义类似这样：

```scala
val Venus: Planet = new Planet(4.869E24, 6051800.0) {
   def ordinal: Int = 1
   override def productPrefix: String = "Venus"
   override def toString: String = "Venus"
}
```

不带 `extends` 子句的枚举值都共享一个实现，这个实现可以使用一个接受一个 tag 和一个名称作为参数的私有方法实例化。
例如，最早那个定义中的值 `Color.Red` 会被扩展为：

```scala
val Red: Color = $new(0, "Red")
```

### 参考

想要了解更多信息，请参见 [Issue #1970](https://github.com/lampepfl/dotty/issues/1970) 和 
[PR #4003](https://github.com/lampepfl/dotty/pull/4003)。
