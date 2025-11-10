### Overview

This repository, "GenAI," serves as a comprehensive learning portfolio for the "Building Generative AI Applications" course. It is structured into weekly modules, each dedicated to showcasing practical applications and understanding of generative AI principles. The content ranges from foundational AI concepts to advanced sequence models and transformers, demonstrated through assignments, experiments, and projects. The primary goal is to illustrate the practical implementation and grasp of generative AI.

### File Structure

```
GenAI/
├── .git/
│   ├── hooks/
│   ├── info/
│   ├── logs/
│   ├── objects/
│   └── refs/
├── .gitignore
├── README.md
└── week-1-quote-generator/
    ├── README.md
    └── quote_generator.jac
```

### Code Architecture

The repository is organized by weekly modules, with each module potentially containing its own sub-directory. For instance, `week-1-quote-generator/` houses the code and documentation for the first week's assignment. Within these modules, specific generative AI applications are developed. The `quote_generator.jac` file indicates the use of the Jaseci language for implementing AI agents or workflows, suggesting an agent-oriented or graph-based approach to building generative models. The overall architecture is modular, allowing for independent development and demonstration of concepts week by week.

### Setup Instructions

As of now, the repository contains a `.jac` file, which implies the use of the Jaseci platform.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/benalvan/GenAI.git
    cd GenAI
    ```
2.  **Install Jaseci:**
    If you don't have Jaseci installed, follow the instructions on the official Jaseci website or use pip:
    ```bash
    pip install jaseci
    ```
3.  **Run Jaseci agents (for `.jac` files):**
    To execute a Jaseci agent, navigate to the relevant weekly module and use the `jsctl` command-line tool. For example, for the `week-1-quote-generator`:
    ```bash
    cd week-1-quote-generator
    jsctl
    # Inside jsctl, load and interact with the jac file
    # For example:
    # jac build quote_generator.jac
    # sentinel register quote_generator.jac
    # walker init_walker
    # ... and so on, depending on the specific walker and operations defined in the .jac file.
    ```
    Refer to the `README.md` within each weekly module for specific instructions on running the projects contained therein.
