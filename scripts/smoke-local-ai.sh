#!/usr/bin/env bash
# PenEcho local-AI smoke harness (spec 002, TC-003 / SC-003)
# Repeatable verification of an OpenAI-compatible endpoint for the
# canvas-agent loop. No secrets in this file: pass the key via env.
#
# Usage:
#   KEY=*** ./smoke-local-ai.sh [BASE_URL] [MODEL]
#
# Exit code: number of failed checks (0 = all green).
set -uo pipefail

BASE="${1:-https://api.satware.ai}"
BASE="${BASE%/}"
MODEL="${2:-Qwen3.6-35B-A3B-MTP-GGUF}"
if [ -z "${KEY:-}" ]; then
  printf 'ERROR: set the KEY env var (Bearer key for the endpoint)\n' >&2
  exit 2
fi

FAILURES=0
PASS_COUNT=0

report() { # report <name> <ok:0|1> <detail>
  local name="$1" ok="$2" detail="$3"
  if [ "$ok" -eq 0 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS  %s\n' "$name"
  else
    FAILURES=$((FAILURES + 1))
    printf 'FAIL  %s  ->  %s\n' "$name" "$detail"
  fi
}

json_field() { # json_field <json> <jq-expr>
  printf '%s' "$1" | jq -r "$2" 2>/dev/null
}

strip_fence() { # strip_fence <text> -> JSON only (tolerates ```json fences)
  printf '%s' "$1" | sed -E 's/^```(json)?[[:space:]]*//; s/```[[:space:]]*$//'
}

post_chat() { # post_chat <payload-file> [max-time] -> body on stdout
  curl -s --max-time "${2:-60}" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    "$BASE/v1/chat/completions" \
    -d @"$1"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- C1: catalog lists the model as downloaded -------------------------------
cat_body=$(curl -s --max-time 30 -H "Authorization: Bearer $KEY" "$BASE/v1/models")
cat_ok=1
if [ "$(json_field "$cat_body" ".data | length")" != "null" ]; then
  if [ "$(printf '%s' "$cat_body" | jq -r --arg m "$MODEL" '[.data[] | select(.id==$m and .downloaded==true)] | length')" = "1" ]; then
    cat_ok=0
  fi
fi
report "C1 catalog:$MODEL" "$cat_ok" "model not listed as downloaded"

# --- C2: bad key rejected ------------------------------------------------------
bad_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 \
  -H "Authorization: Bearer wrong-key" "$BASE/v1/models")
[ "$bad_code" = "401" ] && report "C2 bad-key-401" 0 "" || report "C2 bad-key-401" 1 "HTTP $bad_code (want 401)"

# --- C3: unknown model rejected ------------------------------------------------
cat > "$TMP/unknown.json" << EOF
{"model":"definitely-not-a-model","messages":[{"role":"user","content":"hi"}],"max_tokens":10}
EOF
unk_body=$(post_chat "$TMP/unknown.json" 30)
unk_code=$(json_field "$unk_body" '.error.code // .error.type // ""')
if [ "$(json_field "$unk_body" '.error | type')" = "object" ]; then
  report "C3 unknown-model-error" 0 "error: $(json_field "$unk_body" '.error.message // .error.code // "present"')"
else
  report "C3 unknown-model-error" 1 "no error object: ${unk_body:0:120}"
fi

# --- C4: basic chat round trip ---------------------------------------------------
cat > "$TMP/basic.json" << EOF
{"model":"$MODEL","messages":[{"role":"user","content":"Reply with exactly: PENECHO-OK"}],"max_tokens":400}
EOF
basic_body=$(post_chat "$TMP/basic.json" 120)
basic_content=$(json_field "$basic_body" '.choices[0].message.content // ""')
if [ "$basic_content" = "PENECHO-OK" ]; then
  report "C4 chat-roundtrip" 0 "finish=$(json_field "$basic_body" '.choices[0].finish_reason')"
else
  report "C4 chat-roundtrip" 1 "content='${basic_content:0:80}'"
fi

# --- C5: streaming SSE -----------------------------------------------------------
cat > "$TMP/stream.json" << EOF
{"model":"$MODEL","messages":[{"role":"user","content":"Reply with exactly: PENECHO-OK"}],"max_tokens":400,"stream":true}
EOF
curl -sN --max-time 120 -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  "$BASE/v1/chat/completions" -d @"$TMP/stream.json" > "$TMP/stream.sse"
chunk_count=$(grep -c '^data: {' "$TMP/stream.sse" || true)
done_seen=$(grep -c 'data: \[DONE\]' "$TMP/stream.sse" || true)
stream_text=$(grep '^data: {' "$TMP/stream.sse" | sed 's/^data: //' | jq -r '.choices[0].delta.content // ""' 2>/dev/null | tr -d '\n')
if [ "$chunk_count" -gt 1 ] && [ "$done_seen" -ge 1 ] && [ "$stream_text" = "PENECHO-OK" ]; then
  report "C5 streaming-sse" 0 "chunks=$chunk_count, assembled=${stream_text:0:40}"
else
  report "C5 streaming-sse" 1 "chunks=$chunk_count done=$done_seen text='${stream_text:0:60}'"
fi

# --- C6: canvas JSON command (write_text), fence-tolerant parse -----------------
cat > "$TMP/canvas1.json" << EOF
{"model":"$MODEL","messages":[{"role":"system","content":"You control a canvas. Return ONLY a JSON object: {\"intent\":\"<write|none>\",\"commands\":[{\"tool\":\"write_text\",\"x\":<int>,\"y\":<int>,\"text\":\"<string>\",\"fontSize\":<int>,\"maxWidth\":<int>}]} with no markdown, no prose. The canvas is 20000x20000 logical pixels."},{"role":"user","content":"Write 'Hello PenEcho' near the top-left of the canvas."}],"max_tokens":800}
EOF
c1_body=$(post_chat "$TMP/canvas1.json" 120)
c1_text=$(strip_fence "$(json_field "$c1_body" '.choices[0].message.content // ""')")
c1_ok=1
c1_detail=""
c1_json=$(printf '%s' "$c1_text" | jq -c . 2>/dev/null) || c1_json=""
if [ -n "$c1_json" ]; then
  c1_check=$(printf '%s' "$c1_json" | jq -r '
    (.commands | length > 0) and
    (.commands[0].tool == "write_text") and
    (.commands[0].text == "Hello PenEcho") and
    ((.commands[0].x | type) == "number") and
    ((.commands[0].y | type) == "number")' 2>/dev/null)
  if [ "$c1_check" = "true" ]; then
    c1_ok=0
    c1_detail="schema valid (fence stripped: $(printf '%s' "$c1_text" | head -c 0)yes)"
  else
    c1_detail="schema mismatch: $c1_json"
  fi
else
  c1_detail="unparseable: ${c1_text:0:120}"
fi
report "C6 canvas-write_text" "$c1_ok" "$c1_detail"

# --- C7: canvas multi-command (write_text + draw_formula) ------------------------
cat > "$TMP/canvas2.json" << EOF
{"model":"$MODEL","messages":[{"role":"system","content":"You control a canvas. Return ONLY a JSON object: {\"intent\":\"<write|none>\",\"commands\":[...]} where each command has property \"tool\". Available tools: write_text {tool,x,y,text,fontSize,maxWidth}; draw_formula {tool,x,y,latex,fontSize}; plot_function {tool,x,y,w,h,expression}; draw {tool,origin,types,items}; erase {tool,mode,x,y,w,h}. No markdown, no prose. Canvas is 20000x20000 logical pixels."},{"role":"user","content":"Write the label 'Slope demo' at the top-left and draw the formula y = x^2 next to it."}],"max_tokens":1200}
EOF
c2_body=$(post_chat "$TMP/canvas2.json" 180)
c2_text=$(strip_fence "$(json_field "$c2_body" '.choices[0].message.content // ""')")
c2_ok=1
c2_detail=""
c2_json=$(printf '%s' "$c2_text" | jq -c . 2>/dev/null) || c2_json=""
if [ -n "$c2_json" ]; then
  c2_check=$(printf '%s' "$c2_json" | jq -r '
    ((.commands? // [] | length >= 2) and
     ([.commands[]? | .tool?] | index("write_text") != null) and
     ([.commands[]? | .tool?] | index("draw_formula") != null) and
     ([.commands[]? | select(.tool == "draw_formula")] | all(.latex? // "" | length > 0)))' 2>/dev/null)
  if [ "$c2_check" = "true" ]; then
    c2_ok=0
    c2_detail="tools: $(printf '%s' "$c2_json" | jq -c '[.commands[].tool]')"
  else
    c2_detail="check=false: ${c2_json:0:200}"
  fi
else
  c2_detail="unparseable: ${c2_text:0:120}"
fi
report "C7 canvas-multi-command" "$c2_ok" "$c2_detail"

# --- C8: reasoning budget behavior (informational, must not crash) --------------
cat > "$TMP/tiny.json" << EOF
{"model":"$MODEL","messages":[{"role":"user","content":"Reply with exactly: PENECHO-OK"}],"max_tokens":20}
EOF
tiny_body=$(post_chat "$TMP/tiny.json" 60)
tiny_finish=$(json_field "$tiny_body" '.choices[0].finish_reason // ""')
tiny_reasoning=$(json_field "$tiny_body" '.choices[0].message.reasoning_content // .choices[0].message.reasoning // ""')
if [ "$tiny_finish" = "length" ] || [ -n "$tiny_reasoning" ]; then
  report "C8 reasoning-budget" 0 "finish=$tiny_finish, reasoning_chars=$(printf '%s' "$tiny_reasoning" | wc -c)"
else
  report "C8 reasoning-budget" 1 "unexpected: finish=$tiny_finish"
fi

printf -- '---\n%d passed, %d failed\n' "$PASS_COUNT" "$FAILURES"
exit "$FAILURES"
