---
layout: default
title: "已删除：XML 字面量"
parent: 已删除的特性
grand_parent: 参考
nav_order: 11
---

# {{ page.title }}

XML 字面量依然被支持，但在不久的将来会被删除，被 [XML 字符串插值器](https://github.com/lampepfl/xml-interpolator)
所取代：

```scala
import dotty.xml.interpolator.*

case class Person(name: String) { override def toString = name }

@main def test: Unit = {
  val bill = Person("Bill")
  val john = Person("John")
  val mike = Person("Mike")
  val todoList = List(
    (bill, john, "Meeting", "Room 203, 11:00am"),
    (john, mike, "Holiday", "March 22-24")
  )
  // XML literals (to be dropped)
  val mails1 = for (from, to, heading, body) <- todoList yield
    <message>
      <from>{from}</from><to>{to}</to>
      <heading>{heading}</heading><body>{body}</body>
    </message>
  println(mails1)
  // XML string interpolation
  val mails2 = for (from, to, heading, body) <- todoList yield xml"""
    <message>
      <from>${from}</from><to>${to}</to>
      <heading>${heading}</heading><body>${body}</body>
    </message>"""
  println(mails2)
}
```

更多详情请参阅 semester project [XML String Interpolator for Dotty](https://infoscience.epfl.ch/record/267527) by Yassin Kammoun (2019)。
