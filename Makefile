
all: Dockerfile.backend
	@docker-compose build

.PHONY: run run_detach stop clean

run:
	@docker-compose up

run_detach:
	@docker-compose up -d

stop:
	@docker-compose down

clean:
	@$(MAKE) stop
	@docker container prune -f
	@docker volume prune -f
