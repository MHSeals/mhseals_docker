jq -r '.recommendations[]' .vscode/extensions.json

for extension in "${extensions[@]}"; do
    code --install-extension "$extension"
done

echo "All extensions have been installed"