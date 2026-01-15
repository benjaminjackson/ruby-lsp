#!/bin/bash
# PreToolUse hook - Load LSP skill on first Ruby file operation

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Only trigger on Read or Grep for .rb files
if [[ ("$tool_name" == "Read" || "$tool_name" == "Grep") && "$file_path" == *.rb ]]; then
  flag_file="/tmp/claude-lsp-reminder-$CLAUDE_SESSION_ID"

  if [[ ! -f "$flag_file" ]]; then
    # First .rb Read/Grep this session - deny and load skill
    touch "$flag_file"
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Load Ruby LSP guidance first"
  },
  "systemMessage": "BLOCKED: Operation on Ruby file.\n\nLoad Ruby LSP usage guidance:\n/ruby-lsp\n\nThis skill explains when to use LSP operations (documentSymbol, findReferences, goToDefinition, etc.) vs standard tools (Read, Grep) for Ruby files.\n\nSubsequent operations on .rb files will be allowed this session."
}
EOF
  else
    # Already loaded skill this session - allow silently
    echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  fi
else
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
fi
