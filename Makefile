LOGIN = gematura
DATA_PATH = /home/$(LOGIN)/data

all: up

up:
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/html
	@mkdir -p $(DATA_PATH)/uptime_kuma
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker compose -f srcs/docker-compose.yml down --rmi all --volumes
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@sudo rm -rf $(DATA_PATH)/wordpress/*

fclean: clean
	docker system prune -a --volumes -f

re: fclean all

.PHONY: all up down clean fclean re