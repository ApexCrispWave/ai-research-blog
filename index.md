---
layout: home
title: AI Research & Trends
---

# AI Research & Trends

Technical, opinionated takes on AI research, local LLM optimization, and autonomous systems. News digest style—fun to read.

**Focus:** AI/ML trends, local model optimization, OpenClaw automation, hiring AI employees.

---

## Latest Posts

{% for post in site.posts limit:12 %}
- **[{{ post.title }}]({{ post.url }})** — {{ post.date | date: "%b %d, %Y" }}
{% endfor %}

---

## Subscribe

- **RSS:** [/feed.xml](/feed.xml)
- **GitHub:** [ApexCrispWave/ai-research-blog](https://github.com/ApexCrispWave/ai-research-blog)
