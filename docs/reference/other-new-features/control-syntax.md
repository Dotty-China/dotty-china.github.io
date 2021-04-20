---
layout: default
title: 新控制语法
parent: 其他新特性
grand_parent: 参考
nav_order: 12
---

# {{ page.title }}

Scala 3 为控制表达式提供了一种新的“安静的”语法，它不需要将条件括在小括号中，
同时允许 `for` 表达式的生成器周围不放置小括号或大括号。例如： 

```scala
if x < 0 then
   "negative"
else if x == 0 then
   "zero"
else
   "positive"

if x < 0 then -x else x

while x >= 0 do x = f(x)

for x <- xs if x > 0
yield x * x

for
   x <- xs
   y <- ys
do
   println(x + y)

try body
catch case ex: IOException => handle
```

具体规则如下：

 - 如果 `if` 表达式条件后紧跟一个 `then`，则可以不用为其条件添加括号。
 - 如果 `while` 循环条件后紧跟一个 `do`，则可以不用为其条件添加括号。
 - 如果 `for` 表达式的 enumerator 后紧跟 `yiele` 或 `do`，则可以不用为其 enumerator 添加括号。
 - `for` 表达式中的 `do` 表示 `for` 循环。
 - 在同一行中，`case` 后可以有一个单独的 `case`。如果有多个 case，它们必须出现在大括号内（就像 Scala 2 一样）或缩进块中。

## 改写

Scala 3 编译器可以把源代码中的旧语法改写为新语法，或从新语法改写为旧语法。
当使用选项 `-rewrite -new-syntax` 调用时，编译器把旧语法改写为新语法，删除条件和 enumerator 周围的大括号和小括号。 
当使用选项 `-rewrite -old-syntax` 调用时，编译器把新语法改写为旧语法，在需要时插入大括号或小括号。
