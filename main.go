package main

import (
	"runtime"
	"time"

	"github.com/gofiber/fiber/v2"
)

func main() {
	app := fiber.New(fiber.Config{
		Prefork: true,
	})

	runtime.GOMAXPROCS(4)

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString(time.Now().String() + ": Hello, World. From Golang!")
	})

	_ = app.Listen("0.0.0.0:3000")
}
