import from byllm.lib { Model }
import from dotenv { load_dotenv }
include utils;

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

# BACKEND: Nodes (Data Models)

node User {
    has resume_text: str = "";
    has extracted_skills: list[str] = [];
    has target_roles: list[str] = [];
    has experience_years: int = 0;
}

node Skill {
    has name: str;
    has category: str = "Technical";
}

node LearningPath {
    has target_role: str;
    has gap_skills: list[str] = [];
    has matched_skills: list[str] = [];
    has courses: list[dict] = [];
    has timeline: str = "";
    has readiness_score: float = 0.0;
    has created_at: str;
}

# BACKEND: Edges (Relationships)

edge HasSkill {
    has proficiency_level: int = 3;
    has years_experience: int = 0;
}

# BACKEND: Walkers (API Endpoints)

walker parse_resume {
    has resume_text: str;
    
    """Extract skills, experience, and target roles from resume."""
    def extract_resume_data(resume: str) -> dict by llm();
    
    can execute with `root entry {
        parsed = self.extract_resume_data(self.resume_text);
        
        existing_users = [here-->(`?User)];
        
        if existing_users {
            user = existing_users[0];
            user.resume_text = self.resume_text;
            user.extracted_skills = parsed.get("skills", []);
            user.target_roles = parsed.get("target_roles", []);
            user.experience_years = parsed.get("experience_years", 0);
        } else {
            user = here ++> User(
                resume_text=self.resume_text,
                extracted_skills=parsed.get("skills", []),
                target_roles=parsed.get("target_roles", []),
                experience_years=parsed.get("experience_years", 0)
            );
        }
        
        for skill_name in user.extracted_skills {
            skill_nodes = [here-->(`?Skill:name==skill_name)];
            if not skill_nodes {
                skill = here ++> Skill(name=skill_name);
            } else {
                skill = skill_nodes[0];
            }
            
            existing_edges = [user->:HasSkill:->skill];
            if not existing_edges {
                user +>:HasSkill(
                    proficiency_level=3,
                    years_experience=user.experience_years
                ):+> skill;
            }
        }
        
        report {
            "success": True,
            "skills": user.extracted_skills,
            "target_roles": user.target_roles,
            "experience_years": user.experience_years
        };
    }
}

sem parse_resume.extract_resume_data = """
Analyze the resume and extract:
1. Technical skills (programming languages, tools, frameworks)
2. Years of professional experience  
3. Potential target roles based on experience

Return JSON:
{
  "skills": ["Python", "React", "SQL"],
  "experience_years": 3,
  "target_roles": ["Full Stack Developer", "Backend Engineer"]
}
""";

walker analyze_gaps {
    has target_role: str;
    
    """Identify skill gaps for target role."""
    def identify_skill_gaps(current_skills: list[str], role: str) -> dict by llm();
    
    can execute with `root entry {
        users = [here-->(`?User)];
        if not users {
            report {"success": False, "error": "No user found. Please upload resume first."};
            disengage;
        }
        
        user = users[0];
        analysis = self.identify_skill_gaps(user.extracted_skills, self.target_role);
        
        report {
            "success": True,
            "target_role": self.target_role,
            "current_skills": user.extracted_skills,
            "matched_skills": analysis.get("matched_skills", []),
            "gap_skills": analysis.get("gap_skills", []),
            "readiness_score": analysis.get("readiness_score", 0.0),
            "timeline_estimate": analysis.get("timeline_estimate", "")
        };
    }
}

sem analyze_gaps.identify_skill_gaps = """
Compare current skills against target role requirements.

Return:
{
  "matched_skills": ["Python", "Git"],
  "gap_skills": ["Docker", "Kubernetes", "AWS"],
  "readiness_score": 65.5,
  "timeline_estimate": "3-4 months"
}

Focus on 3-5 most critical missing skills.
Readiness score: 0-100 based on skill coverage.
""";

walker generate_path {
    has target_role: str;
    has gap_skills: list[str];
    
    """Recommend courses and create learning timeline."""
    def recommend_learning_resources(skills: list[str], role: str) -> list[dict] by llm();
    def calculate_timeline(num_courses: int, experience: int) -> str by llm();
    
    can execute with `root entry {
        users = [here-->(`?User)];
        if not users {
            report {"success": False, "error": "No user found."};
            disengage;
        }
        
        user = users[0];
        courses = self.recommend_learning_resources(self.gap_skills, self.target_role);
        timeline = self.calculate_timeline(len(courses), user.experience_years);
        
        path = here ++> LearningPath(
            target_role=self.target_role,
            gap_skills=self.gap_skills,
            courses=courses,
            timeline=timeline,
            created_at=get_current_datetime()
        );
        
        report {
            "success": True,
            "target_role": self.target_role,
            "gap_skills": self.gap_skills,
            "courses": courses,
            "timeline": timeline
        };
    }
}

sem generate_path.recommend_learning_resources = """
Recommend 1-2 high-quality courses per skill.
Prioritize: Coursera, Udemy, edX, freeCodeCamp.

Return:
[
  {
    "title": "Docker Mastery",
    "platform": "Udemy", 
    "url": "https://udemy.com/docker-mastery",
    "duration": "4 weeks",
    "skill": "Docker",
    "level": "Intermediate"
  }
]
""";

sem generate_path.calculate_timeline = """
Estimate learning timeline considering:
- Number of courses
- User experience level
- Typical course durations

Return string like: "3-4 months with 10-15 hours/week"
""";

walker get_profile {
    can execute with `root entry {
        users = [here-->(`?User)];
        
        if not users {
            report {"success": False, "error": "No profile found"};
            disengage;
        }
        
        user = users[0];
        
        report {
            "success": True,
            "resume_text": user.resume_text,
            "skills": user.extracted_skills,
            "target_roles": user.target_roles,
            "experience_years": user.experience_years
        };
    }
}

walker get_paths {
    can execute with `root entry {
        paths = [here-->(`?LearningPath)];
        
        path_list = [];
        for path in paths {
            path_list.append({
                "id": path._jac_id,
                "target_role": path.target_role,
                "gap_skills": path.gap_skills,
                "matched_skills": path.matched_skills,
                "courses": path.courses,
                "timeline": path.timeline,
                "readiness_score": path.readiness_score,
                "created_at": path.created_at
            });
        }
        
        report {
            "success": True,
            "paths": path_list
        };
    }
}

# FRONTEND: Components

cl import from react {useState, useEffect}

cl {
    # Main App Component
    def app() -> any {
        [currentView, setCurrentView] = useState("upload");
        [resumeText, setResumeText] = useState("");
        [userProfile, setUserProfile] = useState(None);
        [gapAnalysis, setGapAnalysis] = useState(None);
        [learningPath, setLearningPath] = useState(None);
        [loading, setLoading] = useState(False);
        [error, setError] = useState("");
        
        # Load existing profile on mount
        useEffect(lambda -> None {
            async def loadProfile() -> None {
                result = root spawn get_profile();
                if result.reports and result.reports[0]["success"] {
                    setUserProfile(result.reports[0]);
                    setCurrentView("profile");
                }
            }
            loadProfile();
        }, []);
        
        # Step 1: Upload Resume
        async def handleResumeUpload() -> None {
            if not resumeText.trim() {
                setError("Please enter your resume text");
                return;
            }
            
            setLoading(True);
            setError("");
            
            result = root spawn parse_resume(resume_text=resumeText.trim());
            
            if result.reports and result.reports[0]["success"] {
                setUserProfile(result.reports[0]);
                setCurrentView("profile");
            } else {
                setError("Failed to parse resume");
            }
            
            setLoading(False);
        }
        
        # Step 2: Analyze Gaps
        async def handleAnalyzeGaps(targetRole: str) -> None {
            setLoading(True);
            setError("");
            
            result = root spawn analyze_gaps(target_role=targetRole);
            
            if result.reports and result.reports[0]["success"] {
                setGapAnalysis(result.reports[0]);
                setCurrentView("gaps");
            } else {
                setError(result.reports[0]["error"] if result.reports else "Analysis failed");
            }
            
            setLoading(False);
        }
        
        # Step 3: Generate Learning Path
        async def handleGeneratePath() -> None {
            if not gapAnalysis {
                return;
            }
            
            setLoading(True);
            setError("");
            
            result = root spawn generate_path(
                target_role=gapAnalysis["target_role"],
                gap_skills=gapAnalysis["gap_skills"]
            );
            
            if result.reports and result.reports[0]["success"] {
                setLearningPath(result.reports[0]);
                setCurrentView("path");
            } else {
                setError("Failed to generate learning path");
            }
            
            setLoading(False);
        }
        
        # Navigation
        def goToUpload() -> None {
            setCurrentView("upload");
            setResumeText("");
            setUserProfile(None);
            setGapAnalysis(None);
            setLearningPath(None);
            setError("");
        }
        
        def goToProfile() -> None {
            setCurrentView("profile");
        }
        
        # Render Views
        return <div style={{
            "fontFamily": "system-ui, sans-serif",
            "minHeight": "100vh",
            "background": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
        }}>
            # Header
            <div style={{
                "background": "#ffffff",
                "padding": "20px 40px",
                "boxShadow": "0 2px 8px rgba(0,0,0,0.1)"
            }}>
                <h1 style={{
                    "margin": "0",
                    "fontSize": "28px",
                    "color": "#667eea",
                    "fontWeight": "700"
                }}>
                    🎯 Smart Career Path Navigator
                </h1>
                <p style={{
                    "margin": "5px 0 0 0",
                    "color": "#666",
                    "fontSize": "14px"
                }}>
                    AI-Powered Career Guidance & Learning Recommendations
                </p>
            </div>
            
            # Navigation Tabs
            {(<div style={{
                "background": "#ffffff",
                "padding": "10px 40px",
                "borderBottom": "1px solid #e5e7eb",
                "display": "flex",
                "gap": "20px"
            }}>
                <button
                    onClick={goToUpload}
                    style={{
                        "background": ("none" if currentView != "upload" else "#667eea"),
                        "color": ("#667eea" if currentView != "upload" else "#ffffff"),
                        "border": "none",
                        "padding": "8px 16px",
                        "borderRadius": "6px",
                        "cursor": "pointer",
                        "fontWeight": "600",
                        "fontSize": "14px"
                    }}
                >
                    Upload Resume
                </button>
                {(<button
                    onClick={goToProfile}
                    style={{
                        "background": ("none" if currentView != "profile" else "#667eea"),
                        "color": ("#667eea" if currentView != "profile" else "#ffffff"),
                        "border": "none",
                        "padding": "8px 16px",
                        "borderRadius": "6px",
                        "cursor": "pointer",
                        "fontWeight": "600",
                        "fontSize": "14px"
                    }}
                >
                    My Profile
                </button>) if userProfile else None}
            </div>) if userProfile else None}
            
            # Main Content
            <div style={{
                "maxWidth": "1200px",
                "margin": "40px auto",
                "padding": "0 20px"
            }}>
                # Error Display
                {(<div style={{
                    "background": "#fee2e2",
                    "border": "1px solid #ef4444",
                    "color": "#dc2626",
                    "padding": "12px 16px",
                    "borderRadius": "8px",
                    "marginBottom": "20px"
                }}>
                    {error}
                </div>) if error else None}
                
                # Loading Indicator
                {(<div style={{
                    "background": "#ffffff",
                    "padding": "40px",
                    "borderRadius": "12px",
                    "textAlign": "center",
                    "boxShadow": "0 4px 12px rgba(0,0,0,0.1)"
                }}>
                    <div style={{
                        "fontSize": "48px",
                        "marginBottom": "20px"
                    }}>⏳</div>
                    <h3 style={{"color": "#667eea", "marginBottom": "10px"}}>Processing...</h3>
                    <p style={{"color": "#666"}}>Please wait while we analyze your data</p>
                </div>) if loading else (
                    # View: Upload Resume
                    (<UploadView 
                        resumeText={resumeText}
                        setResumeText={setResumeText}
                        handleUpload={handleResumeUpload}
                    />) if currentView == "upload" else (
                    
                    # View: Profile
                    (<ProfileView 
                        profile={userProfile}
                        onAnalyze={handleAnalyzeGaps}
                    />) if currentView == "profile" else (
                    
                    # View: Gap Analysis
                    (<GapsView 
                        analysis={gapAnalysis}
                        onGeneratePath={handleGeneratePath}
                    />) if currentView == "gaps" else (
                    
                    # View: Learning Path
                    (<PathView 
                        path={learningPath}
                        onStartOver={goToUpload}
                    />) if currentView == "path" else None
                    )))
                )}
            </div>
        </div>;
    }
    
    # Upload Resume View
    def UploadView(resumeText: str, setResumeText: any, handleUpload: any) -> any {
        return <div style={{
            "background": "#ffffff",
            "padding": "40px",
            "borderRadius": "12px",
            "boxShadow": "0 4px 12px rgba(0,0,0,0.1)"
        }}>
            <h2 style={{
                "marginTop": "0",
                "marginBottom": "10px",
                "color": "#1f2937"
            }}>
                📄 Upload Your Resume
            </h2>
            <p style={{
                "color": "#6b7280",
                "marginBottom": "24px"
            }}>
                Paste your resume text below and let our AI analyze your skills and experience
            </p>
            
            <textarea
                value={resumeText}
                onChange={lambda e: any -> None { setResumeText(e.target.value); }}
                placeholder="Paste your resume here...

Example:
John Doe - Software Engineer

Experience:
- 3 years as Backend Developer at TechCorp
- Built REST APIs using Python/Flask
- Worked with PostgreSQL and Redis

Skills: Python, Flask, PostgreSQL, Git, REST APIs"
                style={{
                    "width": "100%",
                    "height": "300px",
                    "padding": "16px",
                    "border": "2px solid #e5e7eb",
                    "borderRadius": "8px",
                    "fontSize": "14px",
                    "fontFamily": "monospace",
                    "resize": "vertical",
                    "marginBottom": "16px",
                    "boxSizing": "border-box"
                }}
            />
            
            <button
                onClick={handleUpload}
                style={{
                    "width": "100%",
                    "padding": "14px",
                    "background": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                    "color": "#ffffff",
                    "border": "none",
                    "borderRadius": "8px",
                    "fontSize": "16px",
                    "fontWeight": "600",
                    "cursor": "pointer"
                }}
            >
                🚀 Analyze Resume
            </button>
        </div>;
    }
    
    # Profile View
    def ProfileView(profile: dict, onAnalyze: any) -> any {
        [selectedRole, setSelectedRole] = useState("");
        [customRole, setCustomRole] = useState("");
        
        def handleAnalyze() -> None {
            role = (customRole if selectedRole == "custom" else selectedRole);
            if role {
                onAnalyze(role);
            }
        }
        
        return <div>
            # Skills Overview
            <div style={{
                "background": "#ffffff",
                "padding": "30px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)",
                "marginBottom": "24px"
            }}>
                <h2 style={{
                    "marginTop": "0",
                    "marginBottom": "20px",
                    "color": "#1f2937"
                }}>
                    👤 Your Profile
                </h2>
                
                <div style={{"marginBottom": "24px"}}>
                    <h3 style={{
                        "fontSize": "16px",
                        "color": "#667eea",
                        "marginBottom": "12px"
                    }}>
                        📊 Experience Level
                    </h3>
                    <p style={{
                        "fontSize": "24px",
                        "fontWeight": "700",
                        "color": "#1f2937",
                        "margin": "0"
                    }}>
                        {profile["experience_years"]} years
                    </p>
                </div>
                
                <div>
                    <h3 style={{
                        "fontSize": "16px",
                        "color": "#667eea",
                        "marginBottom": "12px"
                    }}>
                        💡 Extracted Skills ({len(profile["skills"])})
                    </h3>
                    <div style={{
                        "display": "flex",
                        "flexWrap": "wrap",
                        "gap": "8px"
                    }}>
                        {profile["skills"].map(lambda skill: any -> any {
                            return <span key={skill} style={{
                                "background": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                                "color": "#ffffff",
                                "padding": "6px 14px",
                                "borderRadius": "20px",
                                "fontSize": "13px",
                                "fontWeight": "500"
                            }}>
                                {skill}
                            </span>;
                        })}
                    </div>
                </div>
            </div>
            
            # Target Role Selection
            <div style={{
                "background": "#ffffff",
                "padding": "30px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)"
            }}>
                <h2 style={{
                    "marginTop": "0",
                    "marginBottom": "20px",
                    "color": "#1f2937"
                }}>
                    🎯 Select Target Role
                </h2>
                
                {(profile["target_roles"].length > 0) if (
                    <div style={{"marginBottom": "20px"}}>
                        <p style={{
                            "color": "#6b7280",
                            "marginBottom": "12px",
                            "fontSize": "14px"
                        }}>
                            Based on your experience, we suggest:
                        </p>
                        {profile["target_roles"].map(lambda role: any -> any {
                            return <button
                                key={role}
                                onClick={lambda -> None { setSelectedRole(role); }}
                                style={{
                                    "display": "block",
                                    "width": "100%",
                                    "padding": "14px",
                                    "marginBottom": "10px",
                                    "background": ("#f3f4f6" if selectedRole != role else "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"),
                                    "color": ("#1f2937" if selectedRole != role else "#ffffff"),
                                    "border": "2px solid #e5e7eb",
                                    "borderRadius": "8px",
                                    "textAlign": "left",
                                    "fontSize": "15px",
                                    "fontWeight": "500",
                                    "cursor": "pointer"
                                }}
                            >
                                {role}
                            </button>;
                        })}
                    </div>
                ) else None}
                
                <div style={{"marginBottom": "20px"}}>
                    <button
                        onClick={lambda -> None { setSelectedRole("custom"); }}
                        style={{
                            "display": "block",
                            "width": "100%",
                            "padding": "14px",
                            "marginBottom": "10px",
                            "background": ("#f3f4f6" if selectedRole != "custom" else "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"),
                            "color": ("#1f2937" if selectedRole != "custom" else "#ffffff"),
                            "border": "2px solid #e5e7eb",
                            "borderRadius": "8px",
                            "textAlign": "left",
                            "fontSize": "15px",
                            "fontWeight": "500",
                            "cursor": "pointer"
                        }}
                    >
                        ✏️ Enter Custom Role
                    </button>
                    
                    {(selectedRole == "custom") if (
                        <input
                            type="text"
                            value={customRole}
                            onChange={lambda e: any -> None { setCustomRole(e.target.value); }}
                            placeholder="e.g., DevOps Engineer, Data Scientist..."
                            style={{
                                "width": "100%",
                                "padding": "12px",
                                "border": "2px solid #e5e7eb",
                                "borderRadius": "8px",
                                "fontSize": "14px",
                                "boxSizing": "border-box"
                            }}
                        />
                    ) else None}
                </div>
                
                <button
                    onClick={handleAnalyze}
                    disabled={(not selectedRole or (selectedRole == "custom" and not customRole))}
                    style={{
                        "width": "100%",
                        "padding": "14px",
                        "background": ((not selectedRole or (selectedRole == "custom" and not customRole)) if "#d1d5db" else "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"),
                        "color": "#ffffff",
                        "border": "none",
                        "borderRadius": "8px",
                        "fontSize": "16px",
                        "fontWeight": "600",
                        "cursor": ((not selectedRole or (selectedRole == "custom" and not customRole)) if "not-allowed" else "pointer")
                    }}
                >
                    🔍 Analyze Skill Gaps
                </button>
            </div>
        </div>;
    }
    
    # Gap Analysis View
    def GapsView(analysis: dict, onGeneratePath: any) -> any {
        readiness = analysis["readiness_score"];
        readinessColor = (
            "#10b981" if readiness >= 70 else (
            "#f59e0b" if readiness >= 40 else "#ef4444"
            )
        );
        
        return <div>
            # Readiness Score
            <div style={{
                "background": "#ffffff",
                "padding": "30px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)",
                "marginBottom": "24px",
                "textAlign": "center"
            }}>
                <h2 style={{
                    "marginTop": "0",
                    "marginBottom": "20px",
                    "color": "#1f2937"
                }}>
                    📈 Readiness Score
                </h2>
                <div style={{
                    "fontSize": "72px",
                    "fontWeight": "700",
                    "color": readinessColor,
                    "marginBottom": "10px"
                }}>
                    {readiness}%
                </div>
                <p style={{
                    "color": "#6b7280",
                    "fontSize": "16px",
                    "margin": "0"
                }}>
                    for {analysis["target_role"]}
                </p>
            </div>
            
            # Skills Breakdown
            <div style={{
                "display": "grid",
                "gridTemplateColumns": "1fr 1fr",
                "gap": "24px",
                "marginBottom": "24px"
            }}>
                # Matched Skills
                <div style={{
                    "background": "#ffffff",
                    "padding": "24px",
                    "borderRadius": "12px",
                    "boxShadow": "0 4px 12px rgba(0,0,0,0.1)"
                }}>
                    <h3 style={{
                        "marginTop": "0",
                        "marginBottom": "16px",
                        "color": "#10b981",
                        "display": "flex",
                        "alignItems": "center",
                        "gap": "8px"
                    }}>
                        ✅ Matched Skills
                    </h3>
                    <div style={{
                        "display": "flex",
                        "flexDirection": "column",
                        "gap": "8px"
                    }}>
                        {analysis["matched_skills"].map(lambda skill: any -> any {
                            return <div key={skill} style={{
                                "background": "#d1fae5",
                                "color": "#065f46",
                                "padding": "8px 12px",
                                "borderRadius": "6px",
                                "fontSize": "14px"
                            }}>
                                {skill}
                            </div>;
                        })}
                    </div>
                </div>
                
                # Gap Skills
                <div style={{
                    "background": "#ffffff",
                    "padding": "24px",
                    "borderRadius": "12px",
                    "boxShadow": "0 4px 12px rgba(0,0,0,0.1)"
                }}>
                    <h3 style={{
                        "marginTop": "0",
                        "marginBottom": "16px",
                        "color": "#ef4444",
                        "display": "flex",
                        "alignItems": "center",
                        "gap": "8px"
                    }}>
                        ⚠️ Skills to Learn
                    </h3>
                    <div style={{
                        "display": "flex",
                        "flexDirection": "column",
                        "gap": "8px"
                    }}>
                        {analysis["gap_skills"].map(lambda skill: any -> any {
                            return <div key={skill} style={{
                                "background": "#fee2e2",
                                "color": "#991b1b",
                                "padding": "8px 12px",
                                "borderRadius": "6px",
                                "fontSize": "14px"
                            }}>
                                {skill}
                            </div>;
                        })}
                    </div>
                </div>
            </div>
            
            # Generate Path Button
            <div style={{
                "background": "#ffffff",
                "padding": "24px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)",
                "textAlign": "center"
            }}>
                <p style={{
                    "color": "#6b7280",
                    "marginBottom": "16px"
                }}>
                    ⏱️ Estimated Time: {analysis["timeline_estimate"]}
                </p>
                <button
                    onClick={onGeneratePath}
                    style={{
                        "padding": "14px 32px",
                        "background": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                        "color": "#ffffff",
                        "border": "none",
                        "borderRadius": "8px",
                        "fontSize": "16px",
                        "fontWeight": "600",
                        "cursor": "pointer"
                    }}
                >
                    🎓 Generate Learning Path
                </button>
            </div>
        </div>;
    }
    
    # Learning Path View
    def PathView(path: dict, onStartOver: any) -> any {
        return <div>
            # Path Header
            <div style={{
                "background": "#ffffff",
                "padding": "30px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)",
                "marginBottom": "24px",
                "textAlign": "center"
            }}>
                <h2 style={{
                    "marginTop": "0",
                    "marginBottom": "10px",
                    "color": "#1f2937"
                }}>
                    🎓 Your Learning Path
                </h2>
                <p style={{
                    "color": "#667eea",
                    "fontSize": "18px",
                    "fontWeight": "600",
                    "margin": "0"
                }}>
                    {path["target_role"]}
                </p>
                <p style={{
                    "color": "#6b7280",
                    "marginTop": "8px"
                }}>
                    ⏱️ {path["timeline"]}
                </p>
            </div>
            
            # Courses
            <div style={{
                "background": "#ffffff",
                "padding": "30px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)",
                "marginBottom": "24px"
            }}>
                <h3 style={{
                    "marginTop": "0",
                    "marginBottom": "20px",
                    "color": "#1f2937"
                }}>
                    📚 Recommended Courses
                </h3>
                
                <div style={{
                    "display": "flex",
                    "flexDirection": "column",
                    "gap": "16px"
                }}>
                    {path["courses"].map(lambda course: any -> any {
                        return <div key={course["title"]} style={{
                            "border": "2px solid #e5e7eb",
                            "borderRadius": "8px",
                            "padding": "20px",
                            "background": "#f9fafb"
                        }}>
                            <div style={{
                                "display": "flex",
                                "justifyContent": "space-between",
                                "alignItems": "start",
                                "marginBottom": "12px"
                            }}>
                                <div style={{"flex": "1"}}>
                                    <h4 style={{
                                        "margin": "0 0 8px 0",
                                        "color": "#1f2937",
                                        "fontSize": "16px"
                                    }}>
                                        {course["title"]}
                                    </h4>
                                    <div style={{
                                        "display": "flex",
                                        "gap": "12px",
                                        "fontSize": "13px",
                                        "color": "#6b7280"
                                    }}>
                                        <span>🏫 {course["platform"]}</span>
                                        <span>⏱️ {course["duration"]}</span>
                                        <span>📊 {course["level"]}</span>
                                    </div>
                                </div>
                                <span style={{
                                    "background": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                                    "color": "#ffffff",
                                    "padding": "4px 12px",
                                    "borderRadius": "12px",
                                    "fontSize": "12px",
                                    "fontWeight": "600",
                                    "whiteSpace": "nowrap"
                                }}>
                                    {course["skill"]}
                                </span>
                            </div>
                            
                            <a
                                href={course["url"]}
                                target="_blank"
                                style={{
                                    "display": "inline-block",
                                    "padding": "8px 16px",
                                    "background": "#667eea",
                                    "color": "#ffffff",
                                    "textDecoration": "none",
                                    "borderRadius": "6px",
                                    "fontSize": "14px",
                                    "fontWeight": "500"
                                }}
                            >
                                🔗 View Course
                            </a>
                        </div>;
                    })}
                </div>
            </div>
            
            # Actions
            <div style={{
                "background": "#ffffff",
                "padding": "24px",
                "borderRadius": "12px",
                "boxShadow": "0 4px 12px rgba(0,0,0,0.1)",
                "textAlign": "center"
            }}>
                <button
                    onClick={onStartOver}
                    style={{
                        "padding": "14px 32px",
                        "background": "#6b7280",
                        "color": "#ffffff",
                        "border": "none",
                        "borderRadius": "8px",
                        "fontSize": "16px",
                        "fontWeight": "600",
                        "cursor": "pointer"
                    }}
                >
                    🔄 Start Over
                </button>
            </div>
        </div>;
    }
}

# ENTRY POINT
with entry {
    load_dotenv();
}