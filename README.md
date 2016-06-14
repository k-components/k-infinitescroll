k-infinitescroll
========

```
npm i k-infinitescroll --save
```

##Usage

```coffee
app.component require 'k-infinitescroll'
```

```coffee
app.get '/posts', (page, model, params, next) ->
  postsQuery = model.query 'posts', { $limit: 10 }
  model.subscribe postsQuery, (err) ->
    return next err if err
    postsQuery.ref '_page.posts'
```

```html
<view name="k-infinitescroll" element="list-of-posts" path="_page.posts" step="10"></view>

<ul id="list-of-posts">
  {{each _page.posts as #post}}
    <li>{{#post.text}}</li>
  {{/}}
</ul>

```

