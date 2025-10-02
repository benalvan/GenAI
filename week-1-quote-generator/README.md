\# 🌟 AI-Powered Inspirational Quote Generator



An intelligent quote generation system built with \*\*Jaclang\*\* that leverages Google's Gemini AI to create personalized, inspirational quotes on any topic.





📋 Overview



This project demonstrates \*\*graph-based programming\*\* and \*\*AI integration\*\* using Jaclang. The application takes any topic as input and generates unique, motivational quotes using Google's Gemini 2.5 Flash model.



Introduction to Jaclang and AI-Powered Programming



\## ✨ Features



\- 🤖 AI-powered quote generation using Google Gemini 2.5 Flash

\- 🎨 Works with any topic you provide

\- 🚀 Built on Jaclang's node-walker architecture

\- ⚡ Fast response times

\- 💬 Simple, interactive command-line interface



\## 🔍 How It Works



The application uses Jaclang's \*\*graph-based programming model\*\*:



1\. \*\*Nodes\*\* hold data (`QuoteRequest` stores the topic)

2\. \*\*Walkers\*\* traverse the graph and perform actions (`QuoteWalker`)

3\. \*\*AI Integration\*\* via `by llm()` - the docstring becomes the AI prompt!



\### The Magic: `by llm()`



```jac

"""Generate an inspirational quote about the following topic: {topic}



The quote should be original, positive, and concise."""

def get\_quote(data: dict) -> str by llm();

```



The `by llm()` decorator tells Jaclang to use AI to implement this function. The docstring is the prompt, `{topic}` gets replaced with actual data, and the AI returns the result!



\## 🛠 Technologies Used



\- \*\*Jaclang\*\* - Graph-based programming language (superset of Python)

\- \*\*Google Gemini 2.5 Flash\*\* - Large Language Model for quote generation

\- \*\*byllm\*\* - Jaclang library for LLM integration



\## 📦 Installation



\### Prerequisites

\- Python 3.10+

\- Jaclang (`pip install jaclang`)

\- Google Gemini API key (\[Get one here](https://aistudio.google.com/app/apikey))



\### Setup



```bash

\# Clone the repository

git clone https://github.com/yourusername/jaclang-assignments.git

cd jaclang-assignments/week-1-quote-generator



\# Install Jaclang (if needed)

pip install jaclang



\# Configure API key in quote\_generator.jac

\# Replace "YOUR\_API\_KEY\_HERE" with your actual key

```



\## Usage



```bash

jac run quote\_generator.jac

```



Example interaction:

```

INSPIRATIONAL QUOTE GENERATOR

========================================

Enter a topic for your quote: hard work



Generating your quote...

========================================

Your Inspirational Quote:

========================================

"Success isn't given, it's earned through relentless dedication 

and the courage to push forward when others rest."



Keep shining!

```



\## 📚 Key Learnings



Through this project, I learned:

\- ✅ Graph-based programming with nodes and walkers

\- ✅ AI integration using `by llm()`

\- ✅ Jaclang syntax: `node`, `walker`, `has`, `can`, `spawn`

\- ✅ Prompt engineering for LLMs

\- ✅ Transitioning from Python OOP to graph-based paradigms



\## Future Enhancements



\- \[ ] Multiple quote styles (motivational, philosophical, humorous)

\- \[ ] Save favorite quotes to file

\- \[ ] Multi-language support

\- \[ ] Web interface

\- \[ ] Quote history tracking



\## 👨‍💻 Author



\*\*\[Benard Alvan]\*\*

\- GitHub: \[@benalvan](https://github.com/benalvan)

\- LinkedIn: \[Your LinkedIn](https://www.linkedin.com/in/benard-alvan/)



---



<div align="center">



</div>

"# GenAI" 
