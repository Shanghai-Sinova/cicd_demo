# Build
FROM rust:1.85-slim AS builder
WORKDIR /usr/src/app
COPY .cargo /usr/src/app/.cargo
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
RUN apt-get update && apt-get install -y --no-install-recommends pkg-config libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*
RUN cargo build --release

# Run
FROM gcr.io/distroless/cc-debian12:nonroot
WORKDIR /app
COPY --from=builder /usr/src/app/target/release/hello-salvo ./hello-salvo
EXPOSE 5002
USER nonroot
ENTRYPOINT ["/app/hello-salvo"]
