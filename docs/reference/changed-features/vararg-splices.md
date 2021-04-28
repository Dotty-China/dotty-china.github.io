---
layout: default
title: 可变参数拼接
parent: 其他变化的特性
grand_parent: 参考
nav_order: 12
---

# {{ page.title }}

模式和函数参数中的可变参数拼接语法发生了变化。新语法使用 `*` 后缀，类似于可变参数的声明方式。

```scala
val arr = Array(0, 1, 2, 3)
val lst = List(arr*)                    // vararg splice argument
lst match {
   case List(0, 1, xs*) => println(xs)  // binds xs to Seq(2, 3)
   case List(1, _*) =>                  // wildcard pattern
}
```

拼接参数的旧语法将被淘汰。

```scala
/*!*/ val lst = List(arr: _*)      // syntax error
      lst match {
         case List(0, 1, xs @ _*)  // ok, equivalent to `xs*`
      }
```

## 语法

```ebnf
ArgumentPatterns  ::=  ‘(’ [Patterns] ‘)’
                    |  ‘(’ [Patterns ‘,’] Pattern2 ‘*’ ‘)’

ParArgumentExprs  ::=  ‘(’ [‘using’] ExprsInParens ‘)’
                    |  ‘(’ [ExprsInParens ‘,’] PostfixExpr ‘*’ ‘)’
```

## 兼容性考虑

为了实现 Scala 2 和 Scala 3 之间的交叉编译，编译器同时接受新语法和旧语法。
在 `-source future` 选项下，语法旧语法会发生错误。
`-source future-migration` 选项下提供了从旧语法到新语法的自动重写功能。
