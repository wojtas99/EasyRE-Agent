import json,http.server
n=[0]
steps=[{"tool_calls":[{"id":"a","type":"function","function":{"name":"bash","arguments":json.dumps({"command":"echo hi"})}}]},
 {"tool_calls":[{"id":"b","type":"function","function":{"name":"bash","arguments":json.dumps({"command":"python3 /tmp/claude-0/E7 check s3cret"})}}]},
 {"tool_calls":[{"id":"c","type":"function","function":{"name":"write_file","arguments":json.dumps({"path":"/work/report.md","content":"## Answer\ns3cret\n"})}}]}]
class H(http.server.BaseHTTPRequestHandler):
 def do_POST(self):
  self.rfile.read(int(self.headers['Content-Length']))
  m={"role":"assistant","content":"Looking at the check function now","tool_calls":steps[min(n[0],2)]["tool_calls"]}; n[0]+=1
  b=json.dumps({"choices":[{"message":m}],"usage":{"prompt_tokens":10,"completion_tokens":5}}).encode()
  self.send_response(200);self.send_header("Content-Type","application/json");self.end_headers();self.wfile.write(b)
 def log_message(self,*a):pass
http.server.HTTPServer(("127.0.0.1",8765),H).serve_forever()
