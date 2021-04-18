---
layout: default
title: 隐式转换
parent: 上下文抽象
grand_parent: 参考
nav_order: 11
---

# {{ page.title }}

隐式转换（Implicit Conversion）由类 `scala.Conversion` 的 given 实例定义。
该类在包 `scala` 中的定义如下：

```scala
abstract class Conversion[-T, +U] extends (T => U):
   def apply (x: T): U
```
例如，下面是从 `String` 到 `Token` 的隐式转换：

```scala
given Conversion[String, Token] with
   def apply(str: String): Token = new KeyWord(str)
```

使用别名可以更简洁的表示为：

```scala
given Conversion[String, Token] = new KeyWord(_)
```

在以下三种情况下，编译器会自动应用隐式转换：

1. 如果表达式 `e` 具有类型 `T`，且 `T` 不符合表达式的预期类型 `S`。
2. 在选择 `e.m` 中，`e` 的类型为 `T`，但 `T` 没有定义成员 `m`。
3. 在应用 `e.m(args)` 中，`e` 的类型为 `T`，`T` 定义了一些名为 `m` 的成员，但这些成员都不能应用于参数 `args`。

在第一种情况下，编译器查找将类型 `T` 映射至类型 `S` 的 `scala.Conversion` given 实例。
在第二和第三种情况下，编译器查找 `scala.Conversion` 的 given 实例，该实例将类型 `T` 
映射至定义了成员 `m`，（在 `args` 存在时）并且 `m` 可以应用于 `args`。如果找到了这样的实例 `C`，则表达式 `e` 被替换为 `C.apply(e)`。

## 示例

1. `Predef` 包含“自动装箱”转换，把基本数值类型映射到 `java.lang.Number` 的子类型。
   例如，从 `Int` 到 `java.lang.Integer` 的转换可以这样定义：
   ```scala
   given int2Integer: Conversion[Int, java.lang.Integer] =
      java.lang.Integer.valueOf(_)
   ```
2. “magnet”模式有时用于表示一个方法的多个变体。除了定义方法的重载版本，还可以让方法接受一个或多个特殊定义的“magnet”类型的参数，
   各种参数类型可以转换为这些参数类型。例如：
   ```scala
   object Completions:

      // The argument "magnet" type
      enum CompletionArg:
         case Error(s: String)
         case Response(f: Future[HttpResponse])
         case Status(code: Future[StatusCode])

      object CompletionArg:

       // conversions defining the possible arguments to pass to `complete`
       // these always come with CompletionArg
       // They can be invoked explicitly, e.g.
       //
       //   CompletionArg.fromStatusCode(statusCode)

         given fromString    : Conversion[String, CompletionArg]               = Error(_)
         given fromFuture    : Conversion[Future[HttpResponse], CompletionArg] = Response(_)
         given fromStatusCode: Conversion[Future[StatusCode], CompletionArg]   = Status(_)
      end CompletionArg
      import CompletionArg.*

      def complete[T](arg: CompletionArg) = arg match
         case Error(s) => ...
         case Response(f) => ...
         case Status(code) => ...

   end Completions
   ```
   这些步骤比简单地重载 `complete` 复杂，但如果正常重载不可用（如上面的情况，因为我们不能有两个重载方法接受 `Future[...]` 参数），
   或者正常重载会导致重载组合数量爆炸，那么这种模式也是有用的。
