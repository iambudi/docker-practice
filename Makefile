build:
	DOCKER_BUILDKIT=1 docker build -t docker-practice-api:latest-dev .
run:
	docker run -p 3000:3000 -t --pid=host docker-practice-api:latest-dev