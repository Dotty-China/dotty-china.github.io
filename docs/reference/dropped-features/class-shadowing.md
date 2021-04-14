---
layout: default
title: "已弃用：Class 遮蔽"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 9
---

Scala 2 so far allowed patterns like this:

```scala
class Base {
  class Ops { ... }
}

class Sub extends Base {
  class Ops { ... }
}
```

Scala 3 rejects this with the error message:

```scala
6 |      class Ops {  }
  |            ^
  |class Ops cannot have the same name as class Ops in class Base
  | -- class definitions cannot be overridden
```

The issue is that the two `Ops` classes _look_ like one overrides the
other, but classes in Scala 2 cannot be overridden. To keep things clean
(and its internal operations consistent) the Scala 3 compiler forces you
to rename the inner classes so that their names are different.

[More details](./class-shadowing-spec.md)
