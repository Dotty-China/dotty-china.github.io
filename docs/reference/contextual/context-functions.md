---
layout: default
title: 上下文函数
parent: 上下文抽象
grand_parent: 参考
nav_order: 10
---

# {{ page.title }}

*上下文函数（Context Function）*是（只）有上下文参数的函数。它们的类型是*上下文函数类型（Context Function Type）*。
下面是上下文函数类型的示例：

```scala
type Executable[T] = ExecutionContext ?=> T
```

上下文函数使用 `?=>` 作为“箭头”标志。它们应用于合成的参数，与应用带有上下文参数的方法相同。例如：

```scala
  given ec: ExecutionContext = ...

  def f(x: Int): ExecutionContext ?=> Int = ...

  // could be written as follows with the type alias from above
  // def f(x: Int): Executable[Int] = ...

  f(2)(using ec)   // explicit argument
  f(2)             // argument is inferred
```

如果表达式 `E` 的预期类型是上下文函数类型 `(T_1, ..., T_n) ?=> U`，并且 `E` 还不是一个上下文函数字面量，
则 `E` 会通过这样重写转换为上下文函数字面量：

```scala
  (x_1: T1, ..., x_n: Tn) ?=> E
```

其中名称 `x_1`、...、`x_n` 是任意的。这个扩展在表达式 `E` 被类型检测后执行，这意味着 `x_1`、...、`x_n` 可以在 `E` 中 作为 given 值使用。

与它们的类型一样，上下文函数字面量使用 `?=>` 作为参数和结果之间的箭头。这不同于普通的函数字面量，因为它们的类型是上下文函数类型。

例如，继续前面的定义：
```scala
  def g(arg: Executable[Int]) = ...

  g(22)      // is expanded to g((ev: ExecutionContext) ?=> 22)

  g(f(2))    // is expanded to g((ev: ExecutionContext) ?=> f(2)(using ev))

  g((ctx: ExecutionContext) ?=> f(3))  // is expanded to g((ctx: ExecutionContext) ?=> f(3)(using ctx))
  g((ctx: ExecutionContext) ?=> f(3)(using ctx)) // is left as it is
```

## 示例：Builder 模式

上下文函数类型拥有相当强大的表达能力。例如，下面是如何使用它实现“Builder 模式”的示例，其目的是用于构建这样的表：

```scala
  table {
     row {
        cell("top left")
        cell("top right")
     }
     row {
        cell("bottom left")
        cell("bottom right")
     }
  }
```

其想法是为 `Table` 和 `Row` 定义类，并允许通过 `add` 添加元素：

```scala
  class Table {
     val rows = new ArrayBuffer[Row]
     def add(r: Row): Unit = rows += r
     override def toString = rows.mkString("Table(", ", ", ")")
  }

  class Row {
     val cells = new ArrayBuffer[Cell]
     def add(c: Cell): Unit = cells += c
     override def toString = cells.mkString("Row(", ", ", ")")
  }

  case class Cell(elem: String)
```

然后可以使用上下文函数类型作为参数来定义 `table`、`row` 和 `cell` 工厂方法，以避免使用 plumbing boilerplate。

```scala
  def table(init: Table ?=> Unit) = {
     given t: Table = Table()
     init
     t
  }

  def row(init: Row ?=> Unit)(using t: Table) = {
     given r: Row = Row()
     init
     t.add(r)
  }

  def cell(str: String)(using r: Row) =
     r.add(new Cell(str))
```

通过该设置，上面的构建表代码被编译并扩展为：

```scala
  table { ($t: Table) ?=>

    row { ($r: Row) ?=>
      cell("top left")(using $r)
      cell("top right")(using $r)
    }(using $t)

    row { ($r: Row) ?=>
      cell("bottom left")(using $r)
      cell("bottom right")(using $r)
    }(using $t)
  }
```

## 示例：Postconditions

这里是一个更大的例子，使用一个扩展方法 `ensuring` 定义用于检查任意后置条件的结构，
检查的结果可以方便的使用 `result` 引用。该示例结合了不透明类型别名、上下文函数类型和扩展方法提供零开销抽象。

```scala
object PostConditions {
   opaque type WrappedResult[T] = T

   def result[T](using r: WrappedResult[T]): T = r

   extension [T](x: T)
      def ensuring(condition: WrappedResult[T] ?=> Boolean): T =
         assert(condition(using x))
         x
}
import PostConditions.{ensuring, result}

val s = List(1, 2, 3).sum.ensuring(result == 6)
```

**解释**：我们使用上下文函数类型 `WrappedResult[T] ?=> Boolean` 作为 `ensuring` 的条件的类型。
因此 `(result == 6)` 这样的 `ensuring` 的参数在作用域中将有一个 `WrappedResult[T]` 类型的 given 值传递给 `result` 方法。
`WrappedResult` 是一种新类型，用于确保不会在作用域中捕获到不需要的 given 值（在涉及上下文参数的所有情况下，这都是一种很好的做法）。
因为 `WrappedResult` 是一个不透明类型别名，所以它的值也不需要装箱。因此 `ensuring` 的实现与手工编写以下代码一样高效：

```scala
val s = {
   val result = List(1, 2, 3).sum
   assert(result == 6)
   result
}
```
## 参考

更多有关信息请参阅这篇[博客文章](https://www.scala-lang.org/blog/2016/12/07/implicit-function-types.html)（它使用了已经被取代的不同语法）。

[更多细节](./context-functions-spec.md){: .btn .btn-purple }
