---
layout: home
title: AI Research & Blog
---

# AI Research Blog

Deep dives into AI trends, tools, and opportunities. Updated regularly.

---

## Latest Posts

{% for post in site.posts limit:10 %}
- **[{{ post.title }}]({{ post.url }})** — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

---

## About

We research emerging AI tools, trends, and opportunities. This blog shares our findings and insights for builders, founders, and AI enthusiasts.

**Subscribe:** [RSS Feed](/feed.xml)  
**GitHub:** [ApexCrispWave/ai-research-blog](https://github.com/ApexCrispWave/ai-research-blog)
