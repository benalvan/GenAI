import from byllm.lib { Model }
import from dotenv { load_dotenv }
include utils;

glob lib = Model(model_name="gemini/gemini-2.5-flash", verbose=False);

# BACKEND: NODES

node Memory {}

node User {
    has user_id: str;
    has resume_text: str = "";
    has extracted_skills: list[str] = [];
    has experience_years: int = 0;
}

node LearningPath {
    has user_id: str;
    has target_role: str;
    has gap_skills: list[str] = [];
    has courses: list[dict] = [];
    has timeline: str = "";
}

# BACKEND: WALKERS

walker SkillMapper {
    has resume_text: str = "";

    def extract_skills(resume: str) -> list[str] by llm();

    can analyze with `root entry {
        print("\n=== Analyzing Resume ===");

        skills = self.extract_skills(self.resume_text);

        user = here ++> User(
            user_id=f"user_{get_current_datetime()}",
            resume_text=self.resume_text,
            extracted_skills=skills,
            experience_years=2
        );

        print(f"Found {len(skills)} skills");

        report {
            "success": True,
            "user_id": user.user_id,
            "skills": skills
        };
    }
}

sem SkillMapper.extract_skills = "Extract all technical skills from the resume. Return as list of strings like ['Python', 'SQL', 'Git'].";

walker PathPlanner {
    has user_id: str;
    has target_role: str;

    def calculate_gap(current: list[str], role: str) -> dict by llm();
    def recommend_courses(skills: list[str]) -> list[dict] by llm();

    can plan with `root entry {
        print(f"\n=== Creating Path for {self.target_role} ===");

        users = [here --> (`?User)];
        user = None;

        # Find the user with matching user_id
        for u in users {
            if u.user_id == self.user_id {
                user = u;
                break;
            }
        }

        # If user not found, stop and report
        if not user {
            report {"success": False, "error": "User not found"};
            disengage;
        }

        # Get current skills from user
        current_skills = user.extracted_skills;

        # Calculate skill gaps and timeline
        gap_data = self.calculate_gap(current_skills, self.target_role);
        gap_skills = gap_data.get("gap_skills", []);

        # Recommend courses for gap skills
        courses = self.recommend_courses(gap_skills);
        timeline = gap_data.get("timeline", "3-6 months");

        # Create LearningPath node connected to root
        path = here ++> LearningPath(
            user_id=self.user_id,
            target_role=self.target_role,
            gap_skills=gap_skills,
            courses=courses,
            timeline=timeline
        );

        print("=== Path Created ===\n");

        report {
            "success": True,
            "current_skills": current_skills,
            "gap_skills": gap_skills,
            "courses": courses,
            "timeline": timeline
        };
    }
}

sem PathPlanner.calculate_gap = """
Given current skills and target role, return:
{
  "gap_skills": ["skill1", "skill2"],
  "timeline": "3-4 months"
}
List 3-5 important missing skills for the role.
""";

sem PathPlanner.recommend_courses = """
For each skill, recommend 1-2 courses.
Return list of dicts:
[
  {
    "title": "Course Name",
    "platform": "Coursera",
    "url": "https://example.com",
    "duration": "4 weeks",
    "skill": "Python"
  }
]
""";

# ENTRY

with entry {
    load_dotenv();
}
