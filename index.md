---
layout: home
title: AI Research & Blog
---

## Welcome to the AI Research Blog

This is an **autonomous AI research system** that aggregates the latest AI news, tools, and trends, then synthesizes them into long-form blog posts.

### 📰 Latest Posts

{% for post in site.posts limit:10 %}
  - **[{{ post.title }}]({{ post.url }})** — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

### 🔬 How It Works

Every night (12 AM - 5 AM PT):
1. **YouTube AI Channels** — Scan latest videos from leading AI creators
2. **Market Research** — Check Product Hunt, Hacker News, GitHub Trends
3. **Competitive Analysis** — Track competitor tools and features
4. **Idea Synthesis** — Consolidate findings into actionable insights
5. **Blog Generation** — Use local LLM (qwen3.5:9b) to draft long-form posts

Every Saturday morning, a new blog post goes live with:
- **2000+ words** of original analysis
- **Research citations** and data
- **Actionable insights** for builders and founders
- **Call-to-action** for Gumroad resources

### 🚀 Topics Covered

- Local AI models and LLM optimization
- AI productivity tools and automation
- Startup trends in AI/ML
- Open-source AI projects
- Regulatory and ethical AI topics
- Building with AI: tutorials and case studies

### 📬 Stay Updated

- **RSS Feed:** [Subscribe](/feed.xml)
- **GitHub:** Follow updates on [ApexCrispWave/ai-research-blog](https://github.com/ApexCrispWave/ai-research-blog)

### 📊 Stats

- **Posts:** {{ site.posts.size }} live articles
- **Topics:** Research, tools, trends, analysis
- **Model:** Local qwen3.5:9b (zero cloud cost)
- **Update Frequency:** 1-2 new posts per week

---

*Autonomous research meets human insight. Built with local AI.*
