k-infinitescroll
========

```
npm i k-infinitescroll --save
```

##Usage

```coffeescript
app.component require 'k-infinitescroll'
```

```coffeescript
  queryObject = { $limit: 10 }
  model.root.set '_page.queryObject', queryObject
  postsQuery = model.query 'posts', queryObject
  model.subscribe postsQuery, (err) ->
    return next err if err
    postsQuery.ref '_page.posts'

```

```html
<view name="k-infinitescroll" element="list-of-posts" qopath="_page.queryObject" path="_page.posts" collection="posts"></view>

<ul id="list-of-posts" class="list-of-posts">
  {{each #root._page.posts as #post}}
    <li>{{#post.text}}</li>
  {{/}}
</ul>

```

