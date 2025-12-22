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
    def app() -> any {
        [view, setView] = useState("upload");
        [resume, setResume] = useState("");
        [profile, setProfile] = useState(None);
        [analysis, setAnalysis] = useState(None);
        [path, setPath] = useState(None);
        [loading, setLoading] = useState(False);
        [error, setError] = useState("");
        [targetRole, setTargetRole] = useState("");
        
        useEffect(lambda -> None {
            async def load() -> None {
                r = root spawn get_profile();
                if r.reports and r.reports[0]["success"] {
                    setProfile(r.reports[0]);
                    setView("profile");
                }
            }
            load();
        }, []);
        
        async def uploadResume() -> None {
            setLoading(True);
            setError("");
            resumeResult = root spawn parse_resume(resume_text=resume);
            if resumeResult.reports and resumeResult.reports[0]["success"] {
                setProfile(resumeResult.reports[0]);
                setView("profile");
            } else {
                setError("Failed to parse resume");
            }
            setLoading(False);
        }
        
        async def analyzeGaps() -> None {
            setLoading(True);
            analysisResult = root spawn analyze_gaps(target_role=targetRole);
            if analysisResult.reports and analysisResult.reports[0]["success"] {
                setAnalysis(analysisResult.reports[0]);
                setView("analysis");
            }
            setLoading(False);
        }
        
        async def generatePath() -> None {
            setLoading(True);
            pathResult = root spawn generate_path(target_role=analysis["target_role"], gap_skills=analysis["gap_skills"]);
            if pathResult.reports and pathResult.reports[0]["success"] {
                setPath(pathResult.reports[0]);
                setView("path");
            }
            setLoading(False);
        }
        
        return <div style={{"fontFamily": "Arial", "maxWidth": "800px", "margin": "40px auto", "padding": "20px"}}>
            <h1 style={{"color": "#667eea", "textAlign": "center"}}>Career Path Navigator</h1>
            
            {(<div style={{"padding": "10px", "background": "#fee", "color": "#c00", "borderRadius": "4px", "marginBottom": "20px"}}>{error}</div>) if error else None}
            
            {(<div style={{"textAlign": "center", "padding": "40px"}}><h2>Loading...</h2></div>) if loading else (
                (<div style={{"background": "#fff", "padding": "30px", "borderRadius": "8px", "boxShadow": "0 2px 8px rgba(0,0,0,0.1)"}}>
                    <h2>Upload Resume</h2>
                    <textarea value={resume} onChange={lambda e: any -> None { setResume(e.target.value); }} placeholder="Paste your resume here..." style={{"width": "100%", "height": "200px", "padding": "10px", "marginBottom": "10px", "boxSizing": "border-box"}} />
                    <button onClick={uploadResume} style={{"width": "100%", "padding": "12px", "background": "#667eea", "color": "#fff", "border": "none", "borderRadius": "4px", "cursor": "pointer", "fontSize": "16px"}}>Analyze Resume</button>
                </div>) if view == "upload" else (
                
                (<div style={{"background": "#fff", "padding": "30px", "borderRadius": "8px", "boxShadow": "0 2px 8px rgba(0,0,0,0.1)"}}>
                    <h2>Your Profile</h2>
                    <p><strong>Experience:</strong> {profile["experience_years"]} years</p>
                    <p><strong>Skills:</strong> {", ".join(profile["skills"])}</p>
                    <h3>Select Target Role</h3>
                    <input type="text" value={targetRole} onChange={lambda e: any -> None { setTargetRole(e.target.value); }} placeholder="e.g., DevOps Engineer" style={{"width": "100%", "padding": "10px", "marginBottom": "10px", "boxSizing": "border-box"}} />
                    <button onClick={analyzeGaps} style={{"width": "100%", "padding": "12px", "background": "#667eea", "color": "#fff", "border": "none", "borderRadius": "4px", "cursor": "pointer"}}>Analyze Gaps</button>
                    <button onClick={lambda -> None { setView("upload"); }} style={{"width": "100%", "padding": "12px", "background": "#ccc", "color": "#000", "border": "none", "borderRadius": "4px", "cursor": "pointer", "marginTop": "10px"}}>Start Over</button>
                </div>) if view == "profile" else (
                
                (<div style={{"background": "#fff", "padding": "30px", "borderRadius": "8px", "boxShadow": "0 2px 8px rgba(0,0,0,0.1)"}}>
                    <h2>Gap Analysis</h2>
                    <h1 style={{"textAlign": "center", "color": "#667eea"}}>{analysis["readiness_score"]}%</h1>
                    <p style={{"textAlign": "center"}}>Readiness for {analysis["target_role"]}</p>
                    <h3 style={{"color": "#0a0"}}>Matched Skills</h3>
                    <p>{", ".join(analysis["matched_skills"])}</p>
                    <h3 style={{"color": "#c00"}}>Gap Skills</h3>
                    <p>{", ".join(analysis["gap_skills"])}</p>
                    <p><strong>Timeline:</strong> {analysis["timeline_estimate"]}</p>
                    <button onClick={generatePath} style={{"width": "100%", "padding": "12px", "background": "#667eea", "color": "#fff", "border": "none", "borderRadius": "4px", "cursor": "pointer"}}>Generate Learning Path</button>
                </div>) if view == "analysis" else (
                
                (<div style={{"background": "#fff", "padding": "30px", "borderRadius": "8px", "boxShadow": "0 2px 8px rgba(0,0,0,0.1)"}}>
                    <h2>Learning Path</h2>
                    <h3>{path["target_role"]}</h3>
                    <p><strong>Timeline:</strong> {path["timeline"]}</p>
                    <h3>Courses</h3>
                    {path["courses"].map(lambda c: any -> any {
                        return <div key={c["title"]} style={{"padding": "15px", "background": "#f9f9f9", "marginBottom": "10px", "borderRadius": "4px"}}>
                            <h4 style={{"margin": "0 0 5px 0"}}>{c["title"]}</h4>
                            <p style={{"margin": "5px 0", "fontSize": "14px", "color": "#666"}}>{c["platform"]} • {c["duration"]} • {c["skill"]}</p>
                            <a href={c["url"]} target="_blank" style={{"color": "#667eea"}}>View Course →</a>
                        </div>;
                    })}
                    <button onClick={lambda -> None { setView("upload"); setResume(""); setProfile(None); setAnalysis(None); setPath(None); }} style={{"width": "100%", "padding": "12px", "background": "#ccc", "color": "#000", "border": "none", "borderRadius": "4px", "cursor": "pointer", "marginTop": "20px"}}>Start Over</button>
                </div>) if view == "path" else None
                )))
            )}
        </div>;
    }
}

# ENTRY POINT
with entry {
    load_dotenv();
}