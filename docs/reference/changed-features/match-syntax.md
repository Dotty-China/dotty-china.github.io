---
layout: default
title: Match 表达式
parent: 其他变化的特性
grand_parent: 参考
nav_order: 11
---

The syntactical precedence of match expressions has been changed.
`match` is still a keyword, but it is used like an alphabetical operator. This has several consequences:

 1. `match` expressions can be chained:

    ```scala
    xs match {
       case Nil => "empty"
       case _   => "nonempty"
    } match {
       case "empty"    => 0
       case "nonempty" => 1
    }
    ```

    (or, dropping the optional braces)

    ```scala
    xs match
       case Nil => "empty"
       case _   => "nonempty"
    match
       case "empty" => 0
       case "nonempty" => 1
    ```

 2. `match` may follow a period:

     ```scala
     if xs.match
        case Nil => false
        case _   => true
     then "nonempty"
     else "empty"
     ```

 3. The scrutinee of a match expression must be an `InfixExpr`. Previously the scrutinee could be followed by a type ascription `: T`, but this is no longer supported. So `x : T match { ... }` now has to be
 written `(x: T) match { ... }`.

## Syntax

The new syntax of match expressions is as follows.

```ebnf
InfixExpr    ::=  ...
               |  InfixExpr MatchClause
SimpleExpr   ::=  ...
               |  SimpleExpr ‘.’ MatchClause
MatchClause  ::=  ‘match’ ‘{’ CaseClauses ‘}’
```
