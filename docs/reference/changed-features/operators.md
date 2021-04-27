---
layout: default
title: 操作符规则
parent: 其他变化的特性
grand_parent: 参考
nav_order: 3
---

# {{ page.title }}

中缀操作符规则的某些部分发生了变化：

首先，方法名由字母和数字组成的方法只有在定义时带有 `infix` 修饰符才能作为中缀操作符使用。
其次，建议（但不强制）使用 [`@targetName` 注解](../other-new-features/targetName.md)
补充符号操作符的定义。
最后，语法更改后允许在跨行表达式中的最左侧书写中缀操作符。

## `infix` 修饰符

方法上的 `infix` 修饰符允许将方法作为中缀操作符使用。例如：

```scala
import scala.annotation.targetName

trait MultiSet[T] {

   infix def union(other: MultiSet[T]): MultiSet[T]

   def difference(other: MultiSet[T]): MultiSet[T]

   @targetName("intersection")
   def *(other: MultiSet[T]): MultiSet[T]

}

val s1, s2: MultiSet[Int]

s1 union s2         // OK
s1 `union` s2       // also OK but unusual
s1.union(s2)        // also OK

s1.difference(s2)   // OK
s1 `difference` s2  // OK
s1 difference s2    // gives a deprecation warning

s1 * s2             // OK
s1 `*` s2           // also OK, but unusual
s1.*(s2)            // also OK, but unusual
```

对于字母数字操作符使用中缀语法调用被弃用镁光，
除非满足以下条件之一：

- 操作符定义带有 `infix` 修饰符。
- 操作符方法由 Scala 2 编译。
- 操作符后紧跟一个左大括号。


字母数字操作符名称完全由字母、数字、`$`、`_` 以及其他满足调用 `java.lang.Character.isIdentifierPart(c)` 
返回 `true` 的 Unicode 字符 `c` 组成。

使用中缀调用语法调用符号操作符总是被允许，因此带有符号名称的方法上的 `infix` 修饰符是多余的。

`infix` 修饰符也可以指定给一个类型：

```scala
infix type or[X, Y]
val x: String or Int = ...
```

### 动机

`infix` 修饰符的设计目的是保持 code base 中应用方法或类型时的一致性。
其想法是方法的作者应该决定该方法应该作为中缀操作符使用，还是应该通过常规应用语法应用。
Use sites then implement that decision consistently.

### 细节

 1. `infix` 是一个软修饰符。在修饰符位以外的地方它被视为一个普通的标识符。

 2. 如果一个方法重写另一个方法，它们的 `infix` 标注必须保持一致。要么两者都使用 `infix` 标注，
    要么都不标注。

 3. `infix` 修饰符可以赋予给方法定义。中缀方法的第一个非接收器参数列表必须有且仅有一个参数。例如：

    ```scala
    infix def op1(x: S): R             // ok
    infix def op2[T](x: T)(y: S): R    // ok
    infix def op3[T](x: T, y: S): R    // error: two parameters

    extension (x: A)
       infix def op4(y: B): R          // ok
       infix def op5(y1: B, y2: B): R  // error: two parameters
    ```

 4. `infix` 修饰符也可以赋予给有且仅有两个类型参数的类型、trait 或类定义。这样的中缀类型
    
    ```scala
    infix type op[X, Y]
    ```

    可以使用 `infix` 语法应用，也就是 `A op B`。

 5. 为了平滑地迁移至 Scala 3.0，字母数字操作符在 Scala 3.1 或 Scala 3.0 中使用 `-source future` 
    时才会被弃用。

## `@targetName` 注解

推荐符号操作符定义时带有 [`@targetName` 注解](../other-new-features/targetName.md)，
使用字母数字名称对操作符进行编码。这有几个好处：

 - 这有助于提高 Scala 与其他语言之间的互操作性。其他语言调用 Scala 中定义的符号操作符时可以使用 target 名称，
   这样就不需要记住符号名称的低级编码。

 - 这有助于改善 stacktrace 以及其他运行时诊断的可读性，这些工具中将使用用户定义的字母数字名称，
   而不是符号的低级编码。

 - 它为文档工具提供了一个常规名称作为符号操作符的别名。
   这也使得定义更容易通过搜索找到。

## 语法变更

中缀操作符现在可以出现在跨行表达式中行的开头。例如：

```scala
val str = "hello"
   ++ " world"
   ++ "!"

def condition =
   x > 0
   ||
   xs.exists(_ > 0)
   || xs.isEmpty
```

以前这些表达式会被拒绝，因为编译器的分号推导会把延续部分的 
`++ " world"` 和 `|| xs.isEmpty` 作为单独的语句处理。

为了让这种语法能够正常使用，规则被修改为不在前导中缀操作符之前推断分号。
*前导中缀操作符（Leading Infix Operator）*是
 - 符号标识符，类似 `+`、`approx_==` 以及反引号中的标识符，
 - 它开始了新的一行，
 - that precedes a token on the same or the next line that can start an expression,
 - and that is immediately followed by at least one whitespace character.

例如：

```scala
    freezing
  | boiling
```

这被认为是一个单独的中缀操作符。与这段代码相比：

```scala
    freezing
  !boiling
```

这会被视为两条语句，`freezing` 和 `!boiling`。不同之处在于第一个例子中的操作符后紧跟着空格。

另一个例子：

```scala
  println("hello")
  ???
  ??? match { case 0 => 1 }
```

这段代码被视作三个不同的语句。`???` 在语法上是一个符号操作符，但它出现的时候其后不会紧跟一个空格
以及一个可以用于开始表达式的 token。
