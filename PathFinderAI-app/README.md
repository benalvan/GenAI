# 🎯 Smart Career Path Navigator

AI-powered career guidance platform that analyzes your resume, identifies skill gaps, and recommends personalized learning paths for your target role.

## ✨ Features

- **📄 Resume Analysis** - AI extracts skills and experience from your resume
- **🎯 Gap Analysis** - Identifies missing skills for your target role
- **📊 Readiness Score** - Shows how prepared you are (0-100%)
- **🎓 Learning Path** - Recommends courses from Coursera, Udemy, edX
- **⏱️ Timeline Estimation** - Predicts learning duration
- **💾 Persistent Storage** - Graph database saves your profile

## 🛠️ Tech Stack

- **Language**: JacLang (full-stack in one language!)
- **AI**: Google Gemini 2.0 Flash (via byLLM)
- **Frontend**: React (JSX in Jac)
- **Backend**: Walkers (graph-based APIs)
- **Database**: Built-in graph storage

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- Node.js 18+ (for Jac Client)
- Gemini API Key ([Get one free](https://aistudio.google.com/app/apikey))

### Installation
```bash
# 1. Clone/Download the project
cd PathFinderAI-app

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Set up environment variables
echo "GEMINI_API_KEY=your_api_key_here" > .env

# 4. Run the application
jac serve app.jac
```

### Access the App
Open your browser and navigate to:
```
http://localhost:8000/page/app
```

## 📖 Usage Guide

### Step 1: Upload Resume
Paste your resume text in the upload page. The AI will extract:
- Technical skills
- Years of experience
- Suggested target roles

### Step 2: Select Target Role
Choose from suggested roles or enter a custom role (e.g., "DevOps Engineer")

### Step 3: View Gap Analysis
See your readiness score and which skills you need to learn

### Step 4: Get Learning Path
Receive personalized course recommendations with:
- Course titles and platforms
- Duration and difficulty level
- Direct links to enroll

## 📁 Project Structure
```
PathFinderAI-app/
├── app.jac              # Complete application (backend + frontend)
├── utils.jac            # Utility functions
├── .env                 # Environment variables (create this)
├── requirements.txt     # Dependencies
└── README.md           # This file
```

## 🧪 Example Resume Format
```text
John Doe - Software Engineer

Experience:
- 3 years as Backend Developer at TechCorp
- Built REST APIs using Python/Flask
- Worked with PostgreSQL and Redis
- Used Git for version control

Skills: Python, Flask, PostgreSQL, Git, REST APIs
```

## 🏗️ Architecture

### Backend (Nodes)
- `User` - Stores resume and skills
- `Skill` - Individual skill entries
- `LearningPath` - Generated recommendations

### Backend (Walkers)
- `parse_resume` - Extracts skills from resume
- `analyze_gaps` - Identifies skill gaps
- `generate_path` - Creates learning recommendations
- `get_profile` - Retrieves user data
- `get_paths` - Lists all learning paths

### Frontend (React Components)
- `UploadView` - Resume upload interface
- `ProfileView` - Skills and role selection
- `GapsView` - Gap analysis visualization
- `PathView` - Course recommendations

## 🔧 Configuration

### Environment Variables
| Variable | Description | Required |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google Gemini API key | ✅ Yes |

### LLM Settings
Edit `app.jac` line 5 to change the model:
```jac
glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);
```

Supported models:
- `gemini/gemini-2.0-flash` (recommended)
- `gpt-4o` (OpenAI)
- `claude-3-5-sonnet-20240620` (Anthropic)

## 🐛 Troubleshooting

**Issue**: "No module named 'byllm'"
```bash
pip install byllm
```

**Issue**: "GEMINI_API_KEY not found"
- Create `.env` file in project root
- Add: `GEMINI_API_KEY=your_key`

**Issue**: Port 8000 already in use
```bash
jac serve app.jac --port 8080
```

**Issue**: Empty resume analysis
- Ensure resume has clear sections
- Include "Skills:" or "Experience:" headers
- Paste at least 50 words

## 📊 Performance

- Resume parsing: ~5-10 seconds
- Gap analysis: ~3-5 seconds  
- Path generation: ~5-8 seconds
- Total workflow: ~15-25 seconds

## 👥 Authors

Benard Alvan [GitHub](https://github.com/benalvan/)
Wendy Cloy [GitHub](https://github.com/username)

## 🙏 Acknowledgments

- Built with [JacLang](https://www.jac-lang.org/)
- Powered by [Google Gemini](https://deepmind.google/technologies/gemini/)
- Uses [byLLM](https://docs.jaseci.org/learn/jac-byllm/usage/) framework
