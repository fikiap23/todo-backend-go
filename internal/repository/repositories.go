package repository

import "github.com/fikiap23/todo-backend-go/internal/server"

type Repositories struct{}

func NewRepositories(s *server.Server) *Repositories {
	return &Repositories{}
}
