---
layout: default
title: "已弃用：Do-While"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 5
---

# {{ page.title }}

语法结构
```scala
do <body> while <cond>
```
不再被支持。作为替代，请使用以下等价的 `while` 循环：
```scala
while ({ <body> ; <cond> }) ()
```
例如，这段代码：
```scala
do
   i += 1
while (f(i) == 0)
```
可以重写为：
```scala
while {
   i += 1
   f(i) == 0
} do ()
```

使用块作为 while 循环条件的想法也给出了“loop-and-a-half”问题的解决方案。
下面是另一个例子：
```scala
while {
   val x: Int = iterator.next
   x >= 0
} do print(".")
```

## 为什么删除这个结构？

 - `do-while` 的用例很罕见，并且可以使用 `while` 简单地表达。所以将其作为一个独立的语法结构似乎没什么意义。
 - 在[新的语法规则](../other-new-features/control-syntax.md)下，`do` 被用作语句的 continuation，
   这与将其作为语句的 introduction 的含义冲突。
