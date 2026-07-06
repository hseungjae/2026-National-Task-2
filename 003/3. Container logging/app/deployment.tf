resource "kubernetes_deployment_v1" "book" {
  metadata {
    name      = "log-generator"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "log-generator"
      }
    }

    template {
      metadata {
        labels = {
          app = "log-generator"
        }
      }

      spec {
        container {
          name              = "log-generator"
          image             = "python:3.12-slim"
          image_pull_policy = "IfNotPresent"

          command = ["/bin/sh", "-c"]

          args = [<<-EOT
            cat <<'EOF' > /app.py
            import random
            import json
            from http.server import HTTPServer, BaseHTTPRequestHandler
            from datetime import datetime

            PORT = 8080

            MESSAGES = {
                "INFO": [
                    "User login successful",
                    "Order processed successfully",
                    "Cache refreshed",
                    "Health check passed",
                    "Database connection established",
                    "Payment confirmed",
                ],
                "WARN": [
                    "High memory usage detected: 85%",
                    "Slow query detected: 2.3s",
                    "Rate limit approaching threshold",
                    "Retry attempt 2/3 for external API",
                    "Connection pool running low",
                ],
                "ERROR": [
                    "Failed to connect to database",
                    "Payment gateway timeout",
                    "Unhandled exception in request handler",
                    "Out of memory error",
                    "Service unavailable: upstream connection refused",
                ],
            }

            def log(level, message):
                entry = json.dumps({
                    "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
                    "level": level,
                    "message": message,
                    "service": "log-generator",
                })
                print(entry, flush=True)

            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    if self.path == "/health":
                        self.respond(200, {"status": "ok"})
                    elif self.path == "/info":
                        msg = random.choice(MESSAGES["INFO"])
                        log("INFO", msg)
                        self.respond(200, {"level": "INFO", "message": msg})
                    elif self.path == "/warn":
                        msg = random.choice(MESSAGES["WARN"])
                        log("WARN", msg)
                        self.respond(200, {"level": "WARN", "message": msg})
                    elif self.path == "/error":
                        msg = random.choice(MESSAGES["ERROR"])
                        log("ERROR", msg)
                        self.respond(200, {"level": "ERROR", "message": msg})
                    elif self.path.startswith("/burst"):
                        params = dict(p.split("=") for p in self.path.split("?")[1].split("&")) if "?" in self.path else {}
                        count = int(params.get("count", "5"))
                        level = params.get("level", "ERROR").upper()
                        for _ in range(count):
                            log(level, random.choice(MESSAGES.get(level, MESSAGES["INFO"])))
                        self.respond(200, {"generated": count, "level": level})
                    else:
                        self.respond(404, {"error": "not found"})

                def respond(self, code, body):
                    self.send_response(code)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps(body).encode())

                def log_message(self, format, *args):
                    pass

            if __name__ == "__main__":
                log("INFO", f"Log generator started on port {PORT}")
                HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
            EOF

            python /app.py
          EOT
          ]

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 20
          }
        }
      }
    }
  }
}