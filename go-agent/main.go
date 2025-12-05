package main

import (
    "net/http"

    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.New()
    r.Use(gin.Recovery())

    r.GET("/api/hello", func(c *gin.Context) {
        name := c.DefaultQuery("name", "world")
        c.JSON(http.StatusOK, gin.H{"message": "Hello, " + name + "! — Gin@1.11.0"})
    })

    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ok"})
    })

    r.Run(":5001")
}
