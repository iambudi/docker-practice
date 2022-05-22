# Docker Practice: Running Go app with Docker 
Step by step on how to use docker to build and run Go app.

## Dockerfile 
It is used to create Docker Image

1. Create a file named [Dockerfile](Dockerfile)

    A simple Dockerfile for a go app could be like this:

    ```Dockerfile
    # Choose golang image we want to use
    FROM golang:1.18-bullseye
    # Set current work directory
    WORKDIR /app
    # For simplicity, copy all the files inside the project folder
    # To the work dir
    COPY . .
    # Build the go app
    RUN CGO_ENABLED=0 GOOS=linux go build main.go -o myapp .
    # Run the binary
    CMD ["./myapp"]
    ```
    > `Note`: go build will automatically download the project dependencies (go mod) so no need to manually download them

2. Build image `docker build -t myapp .`  *myapp is the docker image name/tag*
3. Verify build with `docker images`

### Running Docker
To create container from the created image, run
`docker run -p 8080:8081 -it myapp`
> -p 8080:8081 - This exposes our application which is running on port 8081 within our container on http://localhost:8080 on our host/local machine.

### Exposing and Publishing Ports
In Dockerfile, **exposing ports** does not bind the port to the host's network interfaces. The port won't be accessible outside the container. This only is a simple way of checking which ports the software inside a container is listening on. To check run `docker ps`

**Publishing ports** make it accessible from outside the container with the -p flag for the docker run command.
`docker run -d -p 80 myapp` make the host os can access `http://localhost`

see [Reference](https://www.howtogeek.com/devops/whats-the-difference-between-exposing-and-publishing-a-docker-port/) for more information.

### Multi-Stage Build
With multi-stage builds, Dockerfile can be splitted into multiple sections. Each stage has its own FROM statement. So it can involve multiple image in the builds. 

Stages are built sequentially and can reference their predecessors, so the output of one layer can be copied into the next layer.

```Dockerfile
# syntax=docker/dockerfile:1.4

#### First stage
FROM golang:1.18-bullseye AS builder
WORKDIR /app
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build main.go -o myapp .

#### Second stage
FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/myapp .
ENTRYPOINT ["./app"] 
```

`builder` is alias for the first stage. This can be referenced in the second stage to copy the build file to a new target environment

## Docker Compose
Rather than manually call docker run, we can simplify it by using `Makefile` or Docker Compose. With a single command, can spin everything up or tear it all down.

Main purpose of Docker Compose itself is for running multiple containers as a single service.

1. Create file `docker-compose.yml`
2. Define version and services
3. Under services, create service with custom name. In this project we use `app`
4. Build can have context. It's enough to specify just `.` to automatically use current work directory and default Dockerfile name
`build: .`
5. To run/stop container: 
```bash
docker compose up   # start container
docker compose stop # stop container
docker compose down # stop and remove container

# To run it (interactive) command, use 
docker compose run {service name} {shell-command} 
# example 
docker compose run myapp uname
```

## Entry Point
It is intruction used to specify the executable which should run when a container is started from a Docker image.

In Dockerfile:
```yaml
COPY --from=builder /app/myapp /
ENTRYPOINT [ "/myapp" ]
# or
CMD ["/myapp"]
```

If entry point is not specified in Docker file, it will throw error `docker: Error response from daemon: No command specified`. So *--entrypoint* parameter must be specified when running docker:
```bash
docker run --entrypoint [new_command] [docker_image] [optional:value]

# Example:
docker run -it --entrypoint /myapp docker-practice
docker run -it --entrypoint /bin/bash docker-practice
```

In docker-compose specify inside service:
```yaml
api:
    build: .
    entrypoint: "/myapp"
    ...
```

> It's better to specify entry point in docker file, so when there's change of the entrypoint or executable file name only the docker file needs to be updated

## Rebuilding Image
Any changes to source code, require to rebuild the image to apply the changes by executing one of the commands. 
```bash
docker build
docker compose build 
docker compose up --build # build and run 
```

## Tips: Build Image Faster

One of the problem of build go app using docker is every time `go build` run, it would redownload all the dependencies and slow down the build process.

The solution is using Docker Build Kit. It enables higher performance docker builds and caching possibility to decrease build times and increase productivity for free.

1. Add `# syntax=docker/dockerfile:1.4` in the first line of docker file
2. Put env var `DOCKER_BUILDKIT=1` before calling `docker build` or `docker compose --build`
> To apply globally put the env variable into shell profile (bashrc/zshrc): `export DOCKER_BUILDKIT=1`
3. Use statement `RUN --mount=type=cache,mode=0755,target={target folder} {buildcommand}`

See [Reference](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md) for the detail

## Go Fiber Prefork
When running app with go fiber prefork enabled, the app will stop by  displaying `exit status 1`. To encounter this issue add parameter `--pid=host` inside `docker run` as referenced [here](https://github.com/gofiber/fiber/issues/1036#issuecomment-738147598). 

```bash
docker run -p 8080:8081 --pid=host -it myapp
```

For docker compose, specify it under the app service. 
```yml
service:
    app:
        ...
        pid: "host"
```

## TODO
- [ ] Add External App dependency (f.e Database) so it can be deployed as single service via Docker Compose
- [ ] Use Volume for data persistance
- [ ] Add binary compression to reduce docker image size