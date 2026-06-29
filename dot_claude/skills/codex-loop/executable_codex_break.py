#!/usr/bin/env python3
"""Thin MCP driver for the codex-loop BREAK seat.
Streams codex/event notifications as heartbeats, applies a SILENCE-based
timeout (kill only if no event for --silence seconds), returns structured result.
Usage: codex_break.py --prompt-file FILE [--silence 90] [--wall 300] [--effort medium]
"""
import sys, json, time, subprocess, threading, argparse, os, signal

ap = argparse.ArgumentParser()
ap.add_argument("--prompt-file", required=True)
ap.add_argument("--silence", type=float, default=90.0)
ap.add_argument("--wall", type=float, default=360.0)
ap.add_argument("--effort", default="medium")
ap.add_argument("--cwd", default=os.getcwd())
ap.add_argument("--codex-home", default=os.path.expanduser("~/.codex-loop"),
                help="Isolated CODEX_HOME so the reviewer has NO computer-use / "
                     "browser / node_repl surface — only what this dir's config allows.")
a = ap.parse_args()

prompt = open(a.prompt_file).read()
env = os.environ.copy()
env["CODEX_HOME"] = os.path.expanduser(a.codex_home)
proc = subprocess.Popen(["codex", "mcp-server"], stdin=subprocess.PIPE,
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                        text=True, bufsize=1, cwd=a.cwd, env=env)

def send(obj):
    proc.stdin.write(json.dumps(obj) + "\n"); proc.stdin.flush()

send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{
    "protocolVersion":"2025-06-18","capabilities":{},
    "clientInfo":{"name":"codex-break","version":"1"}}})
send({"jsonrpc":"2.0","method":"notifications/initialized"})
send({"jsonrpc":"2.0","id":2,"method":"tools/call","params":{
    "name":"codex","arguments":{
        "prompt":prompt,"sandbox":"read-only",
        "config":{"model_reasoning_effort":a.effort}},
    "_meta":{"progressToken":"break"}}})

state = {"last": time.time(), "result": None, "done": False}
t0 = time.time()

def reader():
    for line in proc.stdout:
        line=line.strip()
        if not line: continue
        state["last"]=time.time()
        try: m=json.loads(line)
        except: continue
        if m.get("method")=="codex/event":
            msg=m.get("params",{}).get("msg",{})
            typ=msg.get("type","?")
            dt=time.time()-t0
            sys.stderr.write(f"[{dt:6.1f}s] {typ}\n"); sys.stderr.flush()
        elif m.get("id")==2:
            state["result"]=m.get("result"); state["done"]=True; return

th=threading.Thread(target=reader,daemon=True); th.start()

while not state["done"]:
    time.sleep(1)
    now=time.time()
    if now-state["last"] > a.silence:
        sys.stderr.write(f"\n!! SILENCE >{a.silence}s — killing (wedged)\n")
        proc.kill(); sys.exit(2)
    if now-t0 > a.wall:
        sys.stderr.write(f"\n!! WALL >{a.wall}s — killing\n")
        proc.kill(); sys.exit(3)

proc.terminate()
r=state["result"] or {}
sc=r.get("structuredContent",{})
print(sc.get("content") or json.dumps(r))
