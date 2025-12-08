# Build
FROM rust:1.84-alpine AS builder
WORKDIR /usr/src/app
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
RUN cargo build --release

# Run
FROM alpine:3.19
WORKDIR /app
RUN apk add --no-cache ca-certificates
COPY --from=builder /usr/src/app/target/release/hello-salvo ./hello-salvo
EXPOSE 5002
ENTRYPOINT ["/app/hello-salvo"]
