---
layout: default
title: 重载解析
parent: 其他变化的特性
grand_parent: 参考
nav_order: 10
---

# 重载解析的变化

Scala 3 在 Scala 2 的基础上从两个方面改进了重载解析。
首先，现在重载解析时考虑所有参数列表，而不仅仅是第一个参数列表。
其次，现在重载解析时可以推断函数值的参数类型，即使它们在第一个参数列表中。

## 超越第一个参数列表

重载解析现在可以在从一组重载备选方案选择时考虑所有参数列表。
例如，以下代码能够在 Scala 3 中编译，但在 Scala 2 中会报出不明确重载错误：

```scala
def f(x: Int)(y: String): Int = 0
def f(x: Int)(y: Int): Int = 0

f(3)("")     // ok
```

以下代码也可以通过编译：

```scala
def g(x: Int)(y: Int)(z: Int): Int = 0
def g(x: Int)(y: Int)(z: String): Int = 0

g(2)(3)(4)     // ok
g(2)(3)("")    // ok
```

为了实现这一点，[SLS §6.26.3](https://www.scala-lang.org/files/archive/spec/2.13/06-expressions.html#overloading-resolution) 
中的重载解析规则添加了以下内容：

> In a situation where a function is applied to more than one argument list, if overloading
resolution yields several competing alternatives when `n >= 1` parameter lists are taken
into account, then resolution re-tried using `n + 1` argument lists.

这个变化是由新的语言特性[扩展方法](../contextual/extension-methods.md)导致的，
在扩展方法中，需要基于额外的额外的参数块进行重载解析。

## 函数值的参数化类型

我们对缺少参数类型的函数值的处理进行了改进。现在可以在重载应用的第一个参数列表中传递这些值，
前期是其余的参数足以从重载函数选择一个。例如，以下代码能够在 Scala 3 中编译，
但在 Scala 2 中编译器会报出缺少参数类型错误：

```scala
def f(x: Int, f2: Int => Int) = f2(x)
def f(x: String, f2: String => String) = f2(x)
f("a", _.toUpperCase)
f(2, _ * 2)
```

为了实现这一点，[SLS §6.26.3](https://www.scala-lang.org/files/archive/spec/2.13/06-expressions.html#overloading-resolution) 
中的重载规则进行了以下的修改：

将

> Otherwise, let `S1,…,Sm` be the vector of types obtained by typing each argument with an undefined expected type.

替换为以下这段：

> Otherwise, let `S1,…,Sm` be the vector of known types of all argument types, where the _known type_ of an argument `E`
is determined as followed:

 - If `E` is a function value `(p_1, ..., p_n) => B` that misses some parameter types, the known type
   of `E` is `(S_1, ..., S_n) => ?`, where each `S_i` is the type of parameter `p_i` if it is given, or `?`
   otherwise. Here `?` stands for a _wildcard type_ that is compatible with every other type.
 - Otherwise the known type of `E` is the result of typing `E` with an undefined expected type.

模式匹配闭包

```scala
{ case P1 => B1 ... case P_n => B_n }
````

会被视为展开后的函数值

```scala
x => x match { case P1 => B1 ... case P_n => B_n }
```

因此它也近似于 `? => ?` 类型。
