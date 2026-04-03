#!/bin/bash

ROOT_PATH="$(pwd)"
PROJECT_ROOT="file://${ROOT_PATH}"
FILE_URI="file://${ROOT_PATH}/Basic.lean"

CONTENT='"import Batteries.CodeAction.Match\n\ndef baz: Nat → _\n| a => sorry"'

# Calculates the byte length and formats the LSP header
send_msg() {
    local json="$1"
    local len=$(printf "%s" "$json" | wc -c)

    # Print what we're sending
    echo -e "\n[CLIENT -> SERVER] Sending:" >&2
    echo "$json" | jq . >&2 2>/dev/null || echo "$json" >&2
    
    printf "Content-Length: %d\r\n\r\n%s" "$len" "$json"
}

# 1. Initialize the server with the dynamic root
INIT_JSON='{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"processId":'$$',"rootUri":"'"$PROJECT_ROOT"'","capabilities":{}}}'

# 2. Initialized notification
INITIALIZED_JSON='{"jsonrpc":"2.0","method":"initialized","params":{}}'

# 3. didOpen with hardcoded content
DID_OPEN_JSON='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"'"$FILE_URI"'","languageId":"lean4","version":1,"text":'"$CONTENT"'}}}'

# 4. codeAction request targeting line 3 (index 3 corresponds to "| a => sorry")
CODE_ACTION_JSON='{"jsonrpc":"2.0","id":125,"method":"textDocument/codeAction","params":{"textDocument":{"uri":"'"$FILE_URI"'"},"range":{"start":{"line":3,"character":0},"end":{"line":3,"character":0}},"context":{"diagnostics":[],"triggerKind":2}}}'

# Pipe the sequence into the Lean server
{
    send_msg "$INIT_JSON"
    send_msg "$INITIALIZED_JSON"
    send_msg "$DID_OPEN_JSON"
    sleep 3
    send_msg "$CODE_ACTION_JSON"
    sleep 2
} | lean --server
