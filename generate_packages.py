import shutil
import os
import ast
import xml.etree.ElementTree as ET
from pathlib import Path

# Get pip dependencies listed in packages
workspace = Path("src")
requirements = set()

for setup_file in workspace.rglob("setup.py"):
    with open(setup_file, "r") as f:
        source = f.read()

    try:
        tree = ast.parse(source)
    except SyntaxError:
        print(f"Skipping {setup_file}: syntax error")
        continue

    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and getattr(node.func, "id", "") == "setup":
            for kw in node.keywords:
                if kw.arg == "install_requires" and isinstance(kw.value, (ast.List, ast.Tuple)):
                    for elt in kw.value.elts:
                        if isinstance(elt, ast.Constant):
                            requirements.add(str(elt.value))
                        elif hasattr(ast, "Str") and isinstance(elt, ast.Str):
                            requirements.add(elt.s)

if requirements:
    with open("requirements.txt", "w") as f:
        for pkg in sorted(requirements):
            f.write(pkg + "\n")
    print(f"✅ Generated requirements.txt with {len(requirements)} packages.")
else:
    print("⚠️ No install_requires found.")

# Get apt dependencies listed in packages
apt_packages = set()
local_packages = {p.name for p in workspace.iterdir() if p.is_dir()}

for package_xml in workspace.rglob("package.xml"):
    if "install" in package_xml.parts:
        continue

    try:
        root = ET.parse(package_xml).getroot()
    except ET.ParseError:
        print(f"Skipping {package_xml}: XML parse error")
        continue

    for dep_tag in ["depend", "build_depend", "exec_depend", "run_depend"]:
        for dep in root.findall(dep_tag):
            if dep.text:
                dep_name = dep.text.strip()
                if dep_name in local_packages:
                    # Prompt for removal
                    resp = input(f"⚠️  '{dep_name}' appears to be a local package. Remove from apt list? [y/N] ")
                    if resp.lower() == "y":
                        continue
                apt_packages.add(dep_name)

apt_packages = {f"ros-humble-{p.replace('_', '-')}" for p in apt_packages}

if apt_packages:
    with open("apt-packages.txt", "w") as f:
        for pkg in sorted(apt_packages):
            f.write(pkg + "\n")
    print(f"✅ Generated apt-packages.txt with {len(apt_packages)} packages.")
else:
    print("⚠️ No apt dependencies found.")
    
move = input("❓ Would you like to move the files to .devcontainer? [y/N] ")
if move.lower() == 'y':
    try:
        shutil.move("requirements.txt", ".devcontainer")
        print(f"✅ Moved 'requirements.txt' to '.devcontainer'")
        shutil.move("apt-packages.txt", ".devcontainer")
        print(f"✅ Moved 'apt-packages.txt' to '.devcontainer'")
    except:
        print(f"❌ A file transfer error occured...")

print("🏁 Package generation complete!")   