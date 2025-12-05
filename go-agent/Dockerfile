# Build stage
FROM golang:1.23-alpine AS builder
ENV GOPROXY=https://goproxy.cn,direct
WORKDIR /src
COPY go.mod .
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/hello ./main.go

# Run stage
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=builder /app/hello ./hello
EXPOSE 5001
USER nonroot
ENTRYPOINT ["/app/hello"]
