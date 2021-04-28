---
layout: default
title: 匹配表达式
parent: 其他变化的特性
grand_parent: 参考
nav_order: 11
---

# {{ page.title }}

匹配表达式的语法优先级发生了变化。`match` 依旧是一个关键字，
但它的用法类似于字母操作符。这产生了以下结果：

 1. `match` 表达式可以链式调用：

   ```scala
    xs match {
       case Nil => "empty"
       case _   => "nonempty"
    } match {
       case "empty"    => 0
       case "nonempty" => 1
    }
    ```

    （或者删除可选的大括号）

    ```scala
    xs match
       case Nil => "empty"
       case _   => "nonempty"
    match
       case "empty" => 0
       case "nonempty" => 1
    ```

 2. `match` 可以放在 `.` 后：

     ```scala
     if xs.match
        case Nil => false
        case _   => true
     then "nonempty"
     else "empty"
     ```

 3. 匹配表达式的 scrutinee 必须是 `InfixExpr`。
    之前 scrutinee 后可以跟着一个类型标注 `: T`，但现在不再支持这种写法。
    所以 `x : T match { ... }` 现在必须写作 `(x: T) match { ... }`。

## 语法

匹配表达式的新语法如下所示。

```ebnf
InfixExpr    ::=  ...
               |  InfixExpr MatchClause
SimpleExpr   ::=  ...
               |  SimpleExpr ‘.’ MatchClause
MatchClause  ::=  ‘match’ ‘{’ CaseClauses ‘}’
```
