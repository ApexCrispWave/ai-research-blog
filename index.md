---
permalink: /
layout: none
---

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AI Research & Trends</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
    h1, h2 { color: #222; }
    a { color: #0066cc; }
    hr { border: none; border-top: 1px solid #ddd; }
  </style>
</head>
<body>
  <h1>AI Research & Trends</h1>
  
  <p>Technical, opinionated takes on AI research, local LLM optimization, and autonomous systems. News digest style—fun to read.</p>
  
  <p><strong>Focus:</strong> AI/ML trends, local model optimization, OpenClaw automation, hiring AI employees.</p>
  
  <hr>
  
  <h2>Latest Posts</h2>
  
  <ul>
    {% for post in site.posts limit:12 %}
      <li><strong><a href="{{ post.url | relative_url }}">{{ post.title }}</a></strong> — {{ post.date | date: "%b %d, %Y" }}</li>
    {% endfor %}
  </ul>
  
  <hr>
  
  <h2>Subscribe</h2>
  
  <ul>
    <li><strong>RSS:</strong> <a href="/ai-research-blog/feed.xml">/feed.xml</a></li>
    <li><strong>GitHub:</strong> <a href="https://github.com/ApexCrispWave/ai-research-blog">ApexCrispWave/ai-research-blog</a></li>
  </ul>
</body>
</html>
