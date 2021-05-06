---
layout: default
title: "已删除：Class 遮蔽"
parent: 已删除的特性
grand_parent: 参考
nav_order: 9
---

# {{ page.title }}

到目前为止，Scala 允许这样的模式：

```scala
class Base {
  class Ops { ... }
}

class Sub extends Base {
  class Ops { ... }
}
```

Scala 3 会拒绝这段代码，并显示错误消息：

```scala
6 |      class Ops {  }
  |            ^
  |class Ops cannot have the same name as class Ops in class Base
  | -- class definitions cannot be overridden
```

主要问题是这两个 `Ops` *看起来像是*其中一个覆盖了另一个，但 Scala 2 中的类不能真的覆盖。
为了保持干净（以及其内部操作的一致性），Scala 3 编译器强制您重命名内部类，使它们的名称不同。

[更多细节](./class-shadowing-spec.md){: .btn .btn-purple }
