#!/bin/bash
# SessionEnd hook - Cleanup session-scoped flag file

flag_file="/tmp/claude-lsp-reminder-$CLAUDE_SESSION_ID"

if [[ -f "$flag_file" ]]; then
  rm "$flag_file"
fi

# Return empty JSON for SessionEnd (no output needed)
echo '{}'
