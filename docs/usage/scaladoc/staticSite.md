---
layout: default
title: 静态文档
parent: Scaladoc
grand_parent: 用法
nav_order: 4
---

# {{ page.title}}

Scaladoc 可以像 [Jekyll](http://jekyllrb.com/) 和 [Docusaurus](https://docusaurus.io/) 一样生成静态站点。有一个组合工具
就能够提供静态站点与 API 之间交互的功能，从而使两者自然地融合。

创建静态站点就像 Jekyll 一样简单。站点根包括站点的布局，所有放置在这里的文件会被当作静态文件或进行模板扩展。

考虑到所有用于模板扩展的文件都要以 `*.{html,md}` 结尾，从这里开始我们称它们为“模板文件”或者“模板”。

一个简单的“hello world”站点可以看起来像这样：

```
├── docs
│   └── getting-started.md
└── index.html
```

这将为您在生成的文档中生成这样一个静态站点：

```
index.html
docs/getting-started.html
```

Scaladoc 可以转换文件和目录（将您的文档组织为树状结构）。默认情况下，目录的标题基于文件名，内容为空。
可以选择包含 `index.html` 或者 `index.md` 提供标题在内的内容和属性（参见[属性](#属性)）。

## 属性

Scaladoc 使用 [Liquid](https://shopify.github.io/liquid/) 模板引擎，并提供了很多特定于 Scala 文档的自定义过滤器和标签。

在 Scaladoc 中，所有模板都可以包含 YAML 前缀。前缀的内容被解析，并通过 Liquid 放入 `page` 变量中。

Scaladoc 使用一些预定义的属性控制页面的某些层面。

预定义属性：
 - **title**提供用于导航和 HTML 元数据的页面标题。
 - **extraCss** additional `.css` files that will be included in this page. Paths should be relative to documentation root. **This setting is not exported to template engine.**
 - **extraJs** additional `.js` files that will be included in this page. Paths should be relative to documentation root. **This setting is not exported to template engine.**
 - **hasFrame** when set to `false` page will not include default layout (navigation, breadcrumbs etc.) but only token html wrapper to provide metadata and resources (js and css files). **This setting is not exported to template engine.**
 - **layout** - 要使用的预定义布局，请参见下文。**这个设置不会导出到模板引擎中。**

## 使用已存在的模板和布局

为了执行模板扩展，Scaladoc 会在前缀中查找 `layout` 字段。下面是一个简单的模板系统示例，`index.html`：

```html
---
layout: main
---

<h1>Hello world!</h1>
```

使用了这样一个简单的 main 模板：

{% raw %}
```html
<html>
    <head>
        <title>Hello, world!</title>
    </head>
    <body>
        {{ content }}
    </body>
</html>
```

这会导致 `index.html` 文件结果中的 `{{ content }}` 被 `<h1>Hello world!</h1>` 替代。
{% endraw %}

布局必须放置在站点根目录的 `_layouts` 文件夹中：

```
├── _layouts
│   └── main.html
├── docs
│   └── getting-started.md
└── index.html
```

## 侧边栏

Scaladoc by default uses layout of files in `docs` directory to create table of content. There is also ability to override it by providing a `sidebar.yml` file in the site root:

```yaml
sidebar:
    - title: Blog
      url: blog/index.html
    - title: Docs
      url: docs/index.html
    - title: Usage
      subsection:
        - title: Dottydoc
          url: docs/usage/dottydoc.html
        - title: sbt-projects
          url: docs/usage/sbt-projects.html
```

The `sidebar` key is mandatory, as well as `title` for each element. The
default table of contents allows you to have subsections - albeit the current
depth limit is 2 however it accepts both files and directories and latter can be used to provide deeper structures.

The items which have on the `subsection` level does not accepts `url`.

```
├── blog
│   └── _posts
│       └── 2016-12-05-implicit-function-types.md
├── index.html
└── sidebar.yml
```
