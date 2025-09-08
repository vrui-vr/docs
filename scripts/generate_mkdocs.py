from pathlib import Path

import yaml

REPOS_FILE = "repos.txt"

def prefix_nav(fragment, repo_name):
    def prefix_entry(entry):
        if isinstance(entry, dict):
            new_entry = {}
            for title, value in entry.items():
                if isinstance(value, str):
                    new_entry[title] = f"{repo_name}/{value}"
                elif isinstance(value, list):
                    new_value = []
                    for item in value:
                        if isinstance(item, str):
                            new_value.append(f"{repo_name}/{item}")
                        elif isinstance(item, dict):
                            new_value.append(prefix_entry(item))
                        else:
                            new_value.append(item)
                    new_entry[title] = new_value
                else:
                    new_entry[title] = value
            return new_entry
        elif isinstance(entry, str):
            return f"{repo_name}/{entry}"
        else:
            return entry

    return [prefix_entry(item) for item in fragment]

def load_yaml(path):
    with open(path, "r") as f:
        return yaml.safe_load(f)

def main():
    base = load_yaml("mkdocs.base.yml")
    base_nav = base.get("nav", [])

    with open(REPOS_FILE, "r") as f:
        repos = [line.strip() for line in f if line.strip()]

    for repo_name in repos:
        nav_path = Path("docs") / repo_name / "nav.yml"
        print(f"Grabbing nav from {nav_path}")
        if nav_path.exists():
            fragment = load_yaml(nav_path)
            if isinstance(fragment, list):
                base_nav.extend(prefix_nav(fragment, repo_name))
            else:
                base_nav.extend(prefix_nav([fragment], repo_name))
        else:
            print(f"⚠️ Missing nav file: {nav_path}")

    base["nav"] = base_nav

    with open("mkdocs.generated.yml", "w") as f:
        yaml.dump(base, f, sort_keys=False, indent=2)

if __name__ == "__main__":
    main()
