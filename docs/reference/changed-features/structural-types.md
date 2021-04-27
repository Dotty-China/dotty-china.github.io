---
layout: default
title: Programmatic 结构类型
parent: 其他变化的特性
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

## 动机

一些用例中，比如说建模数据库访问，静态类型语言比动态类型语言相对来说更加不方便：
在动态类型语言种可以很自然地将行建模为 record 或对象，并可以简单地使用 `.` 选择条目
（例如 `row.columnName`）。

要在静态类型语言中实现相同的体验，要为每个数据库操作（包括 join 和 projection）的可能产生的行定义一个类，
并设定一个 scheme 在行和表示行的类之间进行映射。

这需要大量的 boilerplate，which leads developers to
trade the advantages of static typing for simpler schemes where colum
names are represented as strings and passed to other operators (e.g.
`row.select("columnName")`). 这个方式放弃了静态类型的优点，并仍不如动态类型的版本自然。

如果我们希望在动态上下文中支持简单的 `.` 表示法，又不想要放弃静态类型的优势，
这种情况下结构类型很有帮助。它们允许开发人员使用 `.` 表示法并配置解析字段和方法的方式。

## 示例

这里是结构类型 `Person` 的一个示例：

```scala
  class Record(elems: (String, Any)*) extends Selectable {
     private val fields = elems.toMap
     def selectDynamic(name: String): Any = fields(name)
  }

  type Person = Record { val name: String; val age: Int }
 ```
 
类型 `Person` 向父类型 `Record` 添加了一个 *refinement*，定义了两个字段 `name` 和 `age`。
我们称 refinement 是*结构化的*，因为父类型中没有定义 `name` 和 `age`。但它们仍作为类 `Person` 的成员而存在。
例如，下面的程序将打印 `Emma is 42 years old.`。

```scala
  val person = Record("name" -> "Emma", "age" -> 42).asInstanceOf[Person]
  println(s"${person.name} is ${person.age} years old.")
```

本例中的父类型 `Record` 是一个泛化类，可以通过 `elems` 参数表示任意 record。
此参数是 `String` 类型的标签与 `Any` 类型的值组成的 pair 的序列。
当我们创建一个 `Person` 作为 `Record` 时，我们必须使用类型强制转换进行断言
这个 record 定义了正确类型的正确字段。`Record` 本身过于弱类型，
因此编译器无法在没有用户帮助的情况下知道这一点。实际上，
结构类型与其底层的泛化表示之间的连接很可能是由数据库层完成的，
所以最终用户不必担心。

`Record` 继承了标记 trait `scala.Selectable`，并定义了一个方法 `selectDynamic` 
用于将字段名映射到值。通过调用该方法选择结构类型的成员。
`person.name` 和 `person.age` 会被 Scala 编译器翻译为：

```scala
  person.selectDynamic("name").asInstanceOf[String]
  person.selectDynamic("age").asInstanceOf[Int]
```

除了 `selectDynamic`，一个 `Selectable` 类有时还定义 `applyDynamic` 方法。
它可以用于转换结构类型成员上的方法调用。
如果 `a` 是 `Selectable` 的一个实例，那么像 `a.f(b, c)` 这样的结构化调用会被翻译为

```scala
  a.applyDynamic("f")(b, c)
```

## 使用 Java 反射

结构类型也可以使用 [Java 反射](https://www.oracle.com/technical-resources/articles/java/javareflection.html)访问。
例如：

```scala
  type Closeable = { def close(): Unit }

  class FileInputStream {
    def close(): Unit
  }

  class Channel {
    def close(): Unit
  }
```

在这里，我们定义了一个结构类型 `Closeable`，其中定义了一个方法 `close`。
很多类都有 `close` 方法，我们只列出 `FileInputStream` 和 `Channel` 作为两个例子。
如果两个类共享同一个分解了 `close` 方法的公共接口，那么是最简单的。
但如果不同的库组合在一个程序中，这种分解往往是不可能的。然而，通过使用 `Closeable` 类型，
我们依然可以让 `close` 方法在所有类上工作。
例如：

```scala
  import scala.reflect.Selectable.reflectiveSelectable

  def autoClose(f: Closeable)(op: Closeable => Unit): Unit =
    try op(f) finally f.close()
```

调用 `f.close()` 使用 Java 反射来标识和调用接收器 `f` 中的 `close` 方法。
这需要通过导入如上所示的 `reflectiveSelectable` 来启用。
“under the hood”发生的情况如下：

 - 这个导入使得隐式转换可用，能够将任意类型转换为 `Selectable`。`f` 在这个转换中被包装。

 - 编译器将包装后的 `f` 上的 `close` 调用转换为对 `applyDynamic` 的调用。最终结果是：

   ```scala
     reflectiveSelectable(f).applyDynamic("close")()
   ```

 - `applyDynamic` 在 `reflectiveSelectable` 中的实现是使用 Java 反射在运行时
    查找并调用接收器 `f` 中的无参 `close`。

像这样的结构化调用往往比普通方法调用慢很多。强制要求导入 `reflectiveSelectable` 充当了一个“路标”，
表示正在发生一些低效的事情。

**注意**：在 Scala 2 中，Java 反射是唯一可用于结构类型的机制，它是自动启用的，
不需要导入 `reflectiveSelectable` 转换。 However, to warn against inefficient
dispatch, Scala 2 requires a language import `import scala.language.reflectiveCalls`.

在使用 Java 反射进行结构化调用之前应该先考虑其他方法。
例如，有些时候使用 type class 可以得到更模块化*和*更高效的结构体系。

## 可扩展性

可以定义新的 `Selectable` 实例支持 Java 反射以外的访问方式，
这将支持本文开头给出的数据库访问示例之类的用法。

## 局部 `Selectable` 实例

继承 `Selectable` 的局部匿名类可以得到比其他类更精确的类型。
这是一个例子：

```scala
trait Vehicle extends reflect.Selectable {
   val wheels: Int
}

val i3 = new Vehicle { // i3: Vehicle { val range: Int }
   val wheels = 4
   val range = 240
}

i3.range
```

本例中的 `i3` 类型为 `Vehicle { val range: Int }`。因此，`i3.range` 是 well-formed 的。
因为基类 `Vehicle` 中没有定义 `range` 字段或方法，
we need structural dispatch to access the `range` field of the anonymous class that initializes `id3`. Structural dispatch
is implemented by the base trait `reflect.Selectable` of `Vehicle`, which
defines the necessary `selectDynamic` member.

`Vehicle` could also extend some other subclass of `scala.Selectable` that implements `selectDynamic` and `applyDynamic` differently. But if it does not extend a `Selectable` at all, the code would no longer typecheck:

```scala
trait Vehicle {
   val wheels: Int
}

val i3 = new Vehicle { // i3: Vehicle
   val wheels = 4
   val range = 240
}

i3.range // error: range is not a member of `Vehicle`
```

The difference is that the type of an anonymous class that does not extend `Selectable` is just formed from the parent type(s) of the class, without
adding any refinements. Hence, `i3` now has just type `Vehicle` and the selection `i3.range` gives a "member not found" error.

Note that in Scala 2 all local and anonymous classes could produce values with refined types. But
members defined by such refinements could be selected only with the language import
`reflectiveCalls`.

## Relation with `scala.Dynamic`

There are clearly some connections with `scala.Dynamic` here, since
both select members programmatically. But there are also some
differences.

- Fully dynamic selection is not typesafe, but structural selection
  is, as long as the correspondence of the structural type with the
  underlying value is as stated.

- `Dynamic` is just a marker trait, which gives more leeway where and
  how to define reflective access operations. By contrast
  `Selectable` is a trait which declares the access operations.

- Two access operations, `selectDynamic` and `applyDynamic` are shared
  between both approaches. In `Selectable`, `applyDynamic` also may also take
  `java.lang.Class` arguments indicating the method's formal parameter types.
  `Dynamic` comes with `updateDynamic`.

[More details](structural-types-spec.md)
