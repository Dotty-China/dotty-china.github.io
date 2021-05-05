---
layout: default
title: lazy val 初始化
parent: 其他变化的特性
grand_parent: 参考
nav_order: 17
---

# {{ page.title }}

Scala 3 实现了 [SIP-20]（improved lazy vals initialization proposal） 
的[第六版](https://docs.scala-lang.org/sips/improved-lazy-val-initialization.html#version-6---no-synchronization-on-this-and-concurrent-initialization-of-fields)。

## 动机

惰性值初始化的新提案旨在消除惰性值初始化块执行中对资源的获取，从而降低死锁的可能性。
[SIP-20] 文档总结了新的 `lazy val` 初始化方案消除掉的具体死锁场景。

## 实现

给定以下形式的惰性字段：

```scala
class Foo {
  lazy val bar = <RHS>
}
```

Scala 3 将会生产等价于以下内容的代码：

```scala
class Foo {
  import scala.runtime.LazyVals
  var value_0: Int = _
  var bitmap: Long = 0L
  val bitmap_offset: Long = LazyVals.getOffset(classOf[LazyCell], "bitmap")

  def bar(): Int = {
    while (true) {
      val flag = LazyVals.get(this, bitmap_offset)
      val state = LazyVals.STATE(flag, <field-id>)

      if (state == <state-3>) {
        return value_0
      } else if (state == <state-0>) {
        if (LazyVals.CAS(this, bitmap_offset, flag, <state-1>, <field-id>)) {
          try {
            val result = <RHS>
            value_0 = result
            LazyVals.setFlag(this, bitmap_offset, <state-3>, <field-id>)
            return result
          }
          catch {
            case ex =>
              LazyVals.setFlag(this, bitmap_offset, <state-0>, <field-id>)
              throw ex
          }
        }
      } else /* if (state == <state-1> || state == <state-2>) */ {
        LazyVals.wait4Notification(this, bitmap_offset, flag, <field-id>)
      }
    }
  }
}
```

lazy val `<state-i>` 的状态由四个值表示：0、1、2 和 3.
状态 0 表示 lazy val 未初始化。状态 1 表示 lazy val 当前正在由某个线程初始化。
状态 2 表示存在对 lazy val 的并行读取。状态 3 表示 lazy val 已经被初始化。
`<field-id>` 是 lazy val 的 id。该 id 随着类中定义的 volatile lazy val 的数量的增长而增长。

## 关于递归 `lazy val` 的注记

理想情况下，递归惰性 val 应该被标记为错误。递归 `lazy val` 的行为现在未定义（初始化可能导致死锁）。

## 参考

* [SIP-20]

[SIP-20]: https://docs.scala-lang.org/sips/improved-lazy-val-initialization.html
