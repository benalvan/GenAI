# 🚀 Codebase Genius - AI-Powered Code Documentation Generator

An autonomous multi-agent system that automatically generates comprehensive documentation for GitHub repositories using Jaclang and byLLM.

## 📋 Table of Contents
- [Features](#features)
- [System Architecture](#system-architecture)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Running the Application](#running-the-application)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Example Output](#example-output)

## ✨ Features

- 🔄 Automatic repository cloning and analysis
- 📊 File structure mapping and prioritization
- 🔍 Python code analysis (functions, classes)
- 📝 AI-powered documentation generation
- 🤖 Multi-agent architecture using Jaclang walkers
- 💾 Markdown output with structured sections

## 🏗️ System Architecture

The system consists of two main agents implemented as Jaclang walkers:

1. **RepoMapperNode**: 
   - Clones GitHub repositories
   - Builds file tree structure
   - Analyzes Python code (functions, classes)
   - Prioritizes files for documentation

2. **DocGenieNode**:
   - Generates comprehensive markdown documentation
   - Structures content (Overview, Architecture, Setup)
   - Saves output to `outputs/` directory

## 📦 Prerequisites

- Python 3.8 or higher
- Git
- Gemini API key (or OpenAI API key)
- Public GitHub repository access

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/benalvan/GenAI.git
cd codebase_genius
```

### 2. Backend Setup
```bash
cd BE

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure API Key

Create a `.env` file in the `BE/` directory:
```bash
echo "GEMINI_API_KEY=your-gemini-api-key-here" > .env
```

**Get your Gemini API key from:** https://makersuite.google.com/app/apikey

### 4. Frontend Setup (Optional)
```bash
cd ../FE

# Install frontend dependencies
pip install -r requirements.txt
```

## 🚀 Running the Application

### Option 1: Direct Execution (Backend Only)
```bash
cd BE
source venv/bin/activate

# Run directly with a repository URL
jac run test.jac
```

Edit `test.jac` to change the repository URL:
```jac
root spawn doc_walker(repo_url="https://github.com/username/repo");
```

### Option 2: API Server + Frontend

#### Start Backend Server:
```bash
cd BE
source venv/bin/activate
jac serve main.jac
```

Server will start on `http://localhost:8000`

#### Start Frontend (New Terminal):
```bash
cd FE
streamlit run app.py
```

Frontend will open on `http://localhost:8501`

## 📖 Usage

### Using Direct Execution:

1. Edit `BE/test.jac` with your repository URL
2. Run: `jac run test.jac`
3. Documentation will be saved to `outputs/<repo-name>/DOCS.md`

### Using API:

**Via curl:**
```bash
curl -X POST http://localhost:8000/walker/doc_walker \
  -H "Content-Type: application/json" \
  -d '{"repo_url": "https://github.com/username/repo"}'
```

**Via Frontend:**
1. Open `http://localhost:8501`
2. Enter GitHub repository URL
3. Click "Generate Documentation"
4. View/download generated documentation

## 📁 Project Structure
```
codebase_genius/
├── BE/                          # Backend
│   ├── main.jac                 # Main orchestrator with agents
│   ├── utils.jac                # Utility functions
│   ├── test.jac                 # Direct test script
│   ├── requirements.txt         # Python dependencies
│   ├── .env                     # API keys (not in repo)
│   └── temp_repos/              # Cloned repositories (temporary)
├── FE/                          # Frontend (Streamlit)
│   ├── app.py                   # Streamlit application
│   └── requirements.txt         # Frontend dependencies
├── outputs/                     # Generated documentation
│   └── <repo-name>/
│       └── DOCS.md              # Generated documentation
└── README.md                    # This file
```

## 🔑 Key Components

### `main.jac` Components:

- **Memory & AnalysisSession nodes**: Track analysis state
- **Repository node**: Store repository metadata
- **RepoMapperNode**: Clone, analyze, and map repository
- **DocGenieNode**: Generate and save documentation
- **doc_walker**: Orchestrate the entire pipeline

### Agent Functions:

**RepoMapperNode:**
- `clone_repo()`: Clone GitHub repository
- `build_tree()`: Build file structure
- `read_readme()`: Extract README content
- `analyze_py()`: Parse Python files for functions/classes
- `summarize_readme()`: AI-powered README summarization
- `get_priority_files()`: AI-powered file prioritization

**DocGenieNode:**
- `generate_doc()`: AI-powered documentation generation
- `save_doc()`: Save markdown to file

## 📊 Example Output

See `outputs/GenAI/DOCS.md` for a complete example of generated documentation.

Generated documentation includes:
- **Project Overview**: Purpose and key features
- **File Structure**: Repository organization
- **Code Architecture**: Functions, classes, relationships
- **Setup Instructions**: Installation and usage guide

## 🐛 Troubleshooting

**Issue: "Clone failed"**
- Ensure the repository is public
- Check your internet connection
- Verify the URL is correct

**Issue: "API key error"**
- Verify `.env` file exists in `BE/` directory
- Check API key is valid
- Ensure correct format: `GEMINI_API_KEY=your-key`

**Issue: "Import errors"**
- Activate virtual environment: `source venv/bin/activate`
- Reinstall dependencies: `pip install -r requirements.txt`

**Issue: "Port already in use"**
- Stop existing server: `Ctrl+C`
- Kill process: `lsof -ti:8000 | xargs kill -9`

## 🔄 Workflow

1. User provides GitHub repository URL
2. RepoMapperNode clones repository
3. File tree is built and analyzed
4. README is summarized by AI
5. Files are prioritized by AI
6. Python files are parsed for structure
7. DocGenieNode generates comprehensive documentation
8. Documentation saved to `outputs/<repo-name>/DOCS.md`

## 🛠️ Technologies Used

- **Jaclang**: Graph-based programming language
- **byLLM**: AI integration framework (Gemini/OpenAI)
- **GitPython**: Repository cloning
- **AST**: Python code parsing
- **Streamlit**: Frontend UI (optional)

## 📝 Notes

- Only public repositories are supported
- Best results with Python/Jac repositories
- Large repositories may take 2-5 minutes
- Generated documentation is saved locally

**Built with Jaclang | Powered by byLLM**
