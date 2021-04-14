---
layout: default
title: "交集类型 - 更多细节"
nav_exclude: true
---

## 语法

语法上类型 `S & T` 是一个中缀类型，中缀操作符为 `&`。操作符 `&` 是一个普通的标识符，具有普通的优先级，
并遵循寻常的解析规则。除非被另一个定义遮蔽，否则它将被解析为类型 `scala.&`，它充当交集类型内部表示形式的类型别名。

```
Type              ::=  ...| InfixType
InfixType         ::=  RefinedType {id [nl] RefinedType}
```

## 子类型规则

```
T <: A    T <: B
----------------
  T <: A & B

    A <: T
----------------
    A & B <: T

    B <: T
----------------
    A & B <: T
```

根据上面的规则，我们可以证明 `&` 是*可交换的*：对于任意类型 `A` 和 `B`，`A & B <: B & A`。

```
   B <: B           A <: A
----------       -----------
A & B <: B       A & B <: A
---------------------------
       A & B  <:  B & A
```

换句话说，`A & B` 与 `B & A` 是相同的类型，即它们有相同的值并且互为子类型。

如果 `C` 是一个类型构造器，则 `C[A] & C[B]` 可以使用下面三个规则进行简化：

- 如果 `C` 是协变的，`C[A] & C[B] ~> C[A & B]`
- 如果 `C` 是逆变的，`C[A] & C[B] ~> C[A | B]`
- 如果 `C` 是不变的，则发生一个编译时错误


当 `C` 是协变的，可以这样推导出 `C[A & B] <: C[A] & C[B]`：

```
    A <: A                  B <: B
  ----------               ---------
  A & B <: A               A & B <: B
---------------         -----------------
C[A & B] <: C[A]          C[A & B] <: C[B]
------------------------------------------
      C[A & B] <: C[A] & C[B]
```

当 `C` 是逆变的，可以这样推导出 `C[A | B] <: C[A] & C[B]`：

```
    A <: A                        B <: B
  ----------                     ---------
  A <: A | B                     B <: A | B
-------------------           ----------------
C[A | B] <: C[A]              C[A | B] <: C[B]
--------------------------------------------------
            C[A | B] <: C[A] & C[B]
```

## 擦除

`S & T` 的擦除类型是 `S` 和 `T` 擦除类型的擦除*glb*（最大下限）。交集类型的擦除规则以伪代码的形式给出如下；

```
|S & T| = glb(|S|, |T|)

glb(JArray(A), JArray(B)) = JArray(glb(A, B))
glb(JArray(T), _)         = JArray(T)
glb(_, JArray(T))         = JArray(T)
glb(A, B)                 = A                     if A extends B
glb(A, B)                 = B                     if B extends A
glb(A, _)                 = A                     if A is not a trait
glb(_, B)                 = B                     if B is not a trait
glb(A, _)                 = A                     // use first
```

上文中，`|T|` 表示 `T` 的擦除类型，`JArray` 指 Java 数组类型。

另请参见：[`TypeErasure#erasedGlb`](https://github.com/lampepfl/dotty/blob/master/compiler/src/dotty/tools/dotc/core/TypeErasure.scala#L289).

## 与复合类型（`with`）的关系

交集类型 `A & B` 取代了 Scala 2 中的复合类型 `A with B`。目前语法 `A with B` 仍被允许，并被解释为 
`A & B`，但是它作为类型的用法（而不包括在 `new` 或者 `extends` 中的用法）将被弃用和删除。
