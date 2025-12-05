import { Deployment, Service } from "kubernetes.api/v1";

apps = [
  {
    name: "python-agent",
    image: "python-agent:latest",
    port: 5000
  },
  {
    name: "go-agent",
    image: "go-agent:latest",
    port: 5001
  },
  {
    name: "rust-agent",
    image: "rust-agent:latest",
    port: 5002
  },
  {
    name: "web-ssr",
    image: "web-app:latest",
    port: 5003
  },
]

items = [
  Deployment {
    metadata: {name: app.name},
    spec: {
      selector: { matchLabels: { app: app.name } },
      replicas: 1,
      template: {
        metadata: { labels: { app: app.name } },
        spec: {
          containers: [{
            name: app.name,
            image: app.image,
            ports: [{containerPort: app.port}],
            env: [
              { name: "RUST_LOG", value: "info" },
            ],
          }],
        },
      },
    },
  } for app in apps
] + [
  Service {
    metadata: { name: app.name },
    spec: {
      selector: { app: app.name },
      ports: [{ port: 80, targetPort: app.port }],
      type: "ClusterIP",
    },
  } for app in apps
]

print(items)
