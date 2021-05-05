---
layout: default
title: 主方法
parent: 其他变化的特性
grand_parent: 参考
nav_order: 18
---

# {{ page.title }}

Scala 3 提供了一种定义可以从命令行中调用程序的新方法：
方法上添加 `@main` 注解可以将该方法转换为可执行的应用程序。
例如：

```scala
@main def happyBirthday(age: Int, name: String, others: String*) = {
   val suffix = {
      age % 100 match {
        case 11 | 12 | 13 => "th"
        case _ => {
           age % 10 match {
             case 1 => "st"
             case 2 => "nd"
             case 3 => "rd"
             case _ => "th"
           }
        }
      }
   }
   val bldr = new StringBuilder(s"Happy $age$suffix birthday, $name")
   for (other <- others) bldr.append(" and ").append(other)
   bldr.toString
}
```

这将生成一个主程序 `happyBirthday`，可以这样调用：

```
> scala happyBirthday 23 Lisa Peter
Happy 23rd birthday, Lisa and Peter
```

被 `@main` 注解的方法可以编为顶层方法，也可以定义在静态可访问的对线中。
程序的名称在任何情况下都是方法的名称，没有对象名作为前缀。
`@main` 方法可以有任意数量的参数。每个参数对应的类型都必须有一个 
`scala.util.CommandLineParser.FromString` type class 的实例，
用于将参数字符串转换为所需的参数类型。主方法可以以一个可变参数结尾，
接受命令行中给出的所有剩余参数。

由 `@main` 方法实现的程序会检查命令行中是否提供了足够的参数填充方法的参数列表，
并且会检查参数字符串能否转换为所需的类型。如果检查失败，程序会终止，并显式错误消息。
例如：

```
> scala happyBirthday 22
Illegal command line after first argument: more arguments expected

> scala happyBirthday sixty Fred
Illegal command line: java.lang.NumberFormatException: For input string: "sixty"
```

Scala 编译器会按如下所示的步骤从 `@main` 方法 `f` 生成程序：

 - 它会在找到 `@main` 方法的包中生成名为 `f` 的类。
 - 该类有一个有着常规主方法签名的静态方法 `main`：该方法接受一个 `Array[String]` 作为参数，
   并返回 `Unit`。
 - 生成的 `main` 方法调用方法 `f`，使用 [`scala.util.CommandLineParser`](https://dotty.epfl.ch/api/scala/util/CommandLineParser$.html) 
   中的方法对参数进行转换。

例如，上面的 `happyBirthDay` 方法会生成等价于以下类的额外代码：

```scala
final class happyBirthday {
   import scala.util.CommandLineParser as CLP
   <static> def main(args: Array[String]): Unit =
      try {
         happyBirthday(
            CLP.parseArgument[Int](args, 0),
            CLP.parseArgument[String](args, 1),
            CLP.parseRemainingArguments[String](args, 2))
      } catch case error: CLP.ParseError => CLP.showError(error)
}
```

**注意**：以上的 `<static>` 修饰符表示方法 `main` 作为类 `happyBirthDay` 的静态方法生成。
它不适用于 Scala 中用户自己定义的程序。常规的“静态”成员在 Scala 中需要通过定义 object 实现。

`@main` 方法在 Scala 3 中是生成可以在命令行中调用的程序的推荐方案。
它们取代了以前定义一个继承特殊父类 `App` 的 object 的方法。
在 Scala 2 中，`happyBirthday` 可以这样编写：

```scala
object happyBirthday extends App {
   // needs by-hand parsing of arguments vector
   ...
}
```

`App` 之前的功能依赖于“魔术” trait [`DelayedInit`](../dropped-features/delayed-init.md)，
现在不再可用。[`App`](https://dotty.epfl.ch/api/scala/App.html) 现在依然以受限的形式存在，
但它不支持命令行参数，并在将来被弃用。如果程序需要在 Scala 2 和 3 之间交叉编译，
建议显式定义带有 `Array[String]` 参数的 `main` 方法作为替代。
