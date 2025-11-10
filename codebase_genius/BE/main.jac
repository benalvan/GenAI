import from byllm.llm { Model }
import from dotenv { load_dotenv }
import from git { Repo }
import os;
import shutil;
import ast;
include utils;

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=False);

def sanitize_repo_name(url: str) -> str {
    parts = url.rstrip('/').split('/');
    return parts[-1].replace('.git', '');
}

node Memory {}

node AnalysisSession {
    has repo_url: str;
    has created_at: str = get_current_datetime();
    has status: str = "initiated";
    has results: dict = {};

    def add_result(key: str, value: any) {
        self.results[key] = value;
    }
    
    def get_result(key: str) -> any {
        return self.results.get(key, None);
    }
}

node Repository {
    has url: str = "";
    has name: str = "";
    has path: str = "";
    has file_count: int = 0;
}

node RepoMapperNode {
    has temp_dir: str = "./temp_repos";
    
    def clone_repo(url: str) -> str {
        repo_name = sanitize_repo_name(url);
        repo_path = f"{self.temp_dir}/{repo_name}";
        
        if not os.path.exists(self.temp_dir) {
            os.makedirs(self.temp_dir);
        }
        if os.path.exists(repo_path) {
            shutil.rmtree(repo_path);
        }
        
        try {
            Repo.clone_from(url, repo_path);
            return repo_path;
        } except Exception as e {
            print(f"Clone error: {e}");
            return "";
        }
    }
    
    def build_tree(repo_path: str) -> dict {
        result = {"files": [], "total": 0, "python": [], "jac": []};
        
        for item in os.walk(repo_path) {
            root_dir = item[0];
            files = item[2];
            
            for file in files {
                fpath = os.path.join(root_dir, file);
                ext = os.path.splitext(file)[1];
                
                if ext not in ['.pyc', '.log'] {
                    info = {"name": file, "path": fpath, "ext": ext};
                    result["files"].append(info);
                    result["total"] += 1;
                    
                    if ext == ".py" {
                        result["python"].append(info);
                    } elif ext == ".jac" {
                        result["jac"].append(info);
                    }
                }
            }
        }
        
        return result;
    }
    
    def read_readme(repo_path: str) -> str {
        for name in ['README.md', 'README.txt', 'README'] {
            path = os.path.join(repo_path, name);
            if os.path.exists(path) {
                try {
                    with open(path, 'r') as f {
                        return f.read();
                    }
                } except Exception {
                    continue;
                }
            }
        }
        return "No README";
    }
    
    def analyze_py(fpath: str) -> dict {
        try {
            with open(fpath, 'r') as f {
                code = f.read();
            }
            
            tree = ast.parse(code);
            funcs = [];
            classes = [];
            
            for node in ast.walk(tree) {
                if isinstance(node, ast.FunctionDef) {
                    funcs.append(node.name);
                }
                if isinstance(node, ast.ClassDef) {
                    classes.append(node.name);
                }
            }
            
            return {"file": fpath, "functions": funcs, "classes": classes};
        } except Exception {
            return {"file": fpath, "functions": [], "classes": []};
        }
    }
    
    def summarize_readme(content: str) -> str by llm();
    def get_priority_files(tree: dict) -> list[str] by llm();
    
    def map_repo(url: str) -> dict by llm(
        method="ReAct",
        tools=([self.clone_repo, self.build_tree, self.read_readme, self.get_priority_files])
    );
    
    can execute with doc_walker entry {
        session = visitor.session;
        url = visitor.repo_url;
        
        print("\n=== MAPPING REPO ===");
        
        path = self.clone_repo(url);
        if not path {
            report {"error": "Clone failed"};
            disengage;
        }
        
        tree = self.build_tree(path);
        print(f"Files: {tree['total']}");
        
        readme = self.read_readme(path);
        summary = self.summarize_readme(readme);
        priority = self.get_priority_files(tree);
        
        ccg = [];
        for item in priority[:5] {
            fpath = item.get("path", "") if isinstance(item, dict) else item;
            if fpath and fpath.endswith(".py") {
                ccg.append(self.analyze_py(fpath));
            }
        }
        
        repo_node = Repository(
            url=url,
            name=sanitize_repo_name(url),
            path=path,
            file_count=tree["total"]
        );
        
        self ++> repo_node;
        session.add_result("repo", repo_node);
        session.add_result("tree", tree);
        session.add_result("summary", summary);
        session.add_result("ccg", ccg);
        
        print("=== MAPPING DONE ===\n");
        
        report {"status": "mapped"};
    }
}

sem RepoMapperNode.summarize_readme = "2-3 sentence summary of repo purpose";
sem RepoMapperNode.get_priority_files = "Return list of 10 important file paths";

node DocGenieNode {
    def generate_doc(repo_name: str, summary: str, tree: dict, ccg: list) -> str by llm();
    
    def save_doc(content: str, name: str) -> str {
        out_dir = f"../outputs/{name}";
        if not os.path.exists(out_dir) {
            os.makedirs(out_dir);
        }
        
        path = f"{out_dir}/DOCS.md";
        with open(path, 'w') as f {
            f.write(content);
        }
        
        return path;
    }
    
    can execute with doc_walker entry {
        session = visitor.session;
        
        print("\n=== GENERATING DOCS ===");
        
        repo = session.get_result("repo");
        summary = session.get_result("summary");
        tree = session.get_result("tree");
        ccg = session.get_result("ccg");
        
        doc = self.generate_doc(repo.name, summary, tree, ccg);
        path = self.save_doc(doc, repo.name);
        
        session.add_result("doc", doc);
        session.add_result("path", path);
        
        print(f"=== SAVED: {path} ===\n");
        
        report {"status": "complete", "path": path};
    }
}

sem DocGenieNode.generate_doc = """
Generate markdown with:
1. Overview
2. File Structure
3. Code Architecture
4. Setup Instructions
""";

walker doc_walker {
    has repo_url: str = "";
    has session_id: str = "";
    
    can execute with `root entry {
        print(f"\n{'='*60}");
        print(f"CODEBASE GENIUS");
        print(f"Repo: {self.repo_url}");
        print(f"{'='*60}");
        
        memory_list = [root --> (`?Memory)];
        if not memory_list {
            memory_list = root ++> Memory();
        }
        memory = memory_list[0];
        
        if not self.session_id {
            session_list = memory ++> AnalysisSession(repo_url=self.repo_url);
            self.session = session_list[0];
        } else {
            self.session = &(self.session_id);
        }
        
        mapper_list = [memory --> (`?RepoMapperNode)];
        if not mapper_list {
            mapper_list = memory ++> RepoMapperNode();
        }
        mapper = mapper_list[0];
        
        docgen_list = [memory --> (`?DocGenieNode)];
        if not docgen_list {
            docgen_list = memory ++> DocGenieNode();
        }
        docgen = docgen_list[0];
        
        visit mapper;
        visit docgen;
        
        print(f"\n{'='*60}");
        print("COMPLETE!");
        print(f"{'='*60}\n");
        
        report {
            "status": "done",
            "path": self.session.get_result("path")
        };
    }
}

walker get_session {
    has session_id: str = "";
    
    can execute with `root entry {
        if not self.session_id {
            report {"error": "No session_id"};
            disengage;
        }
        
        session = &(self.session_id);
        report {
            "id": jid(session),
            "url": session.repo_url,
            "status": session.status,
            "results": session.results
        };
    }
}

with entry {
    load_dotenv();
}