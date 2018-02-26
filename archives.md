---
layout: page
title: Archives
---

<div class="posts">
<ul>{{ range (where .Site.Pages "Type" "post") }}
<li><a href="{{.Permalink}}">{{.Date.Format "2006-01-02"}} | {{.Title}}</a></li>
{{ end }}</ul>
</div>
