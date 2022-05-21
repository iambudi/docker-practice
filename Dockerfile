############# BUILD STAGE ###########
# https://hub.docker.com/_/golang?tab=tags
FROM golang:latest as builder

# configure the environment variables for Go modules
ENV GO111MODULE=on
# ENV GOFLAGS=-mod=vendor

# Creates a folder for the code and makes it active.
ENV APP_HOME /app
RUN mkdir -p "$APP_HOME"

# We specify that we now wish to execute 
# any further commands inside our /app
# directory
WORKDIR "$APP_HOME"

# Copy just the dep files
COPY go.mod go.sum ./

# Copy everything in the project root directory
# into /app directory
COPY . .

# Without caching: each time the go build command is run
# will redownload all the go mod dependencies, which slow down building
# RUN go build -o myapp .

# With caching: each time the go build command is run, the container will have the cache 
# mounted to Go’s compiler cache folder.
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \ 
    CGO_ENABLED=0 go build -ldflags="-s -w" -o myapp .

# When using single stage, we can run 
# our newly built app here
# CMD [ "./myapp" ]

############# TARGET STAGE ###########
# This is called multi stage builds. It separate build and target environment.
# The build file will be copied into new image, so it reduces image size
# alpine 5 MB, static 1.8 MB, base 16.9 MB
# FROM alpine:latest
# FROM gcr.io/distroless/base
######################################
# we try using distroless/static here
# when using this target image, make sure to disable CGO when compiling go app 
# to avaoid file/dir not found due missing libs for interoperability with C libraries
FROM gcr.io/distroless/static

COPY --from=builder /app/myapp /
# Expose port, just for info. it does not map to existing go fiber port
# EXPOSE 8010

# If dont want to run automatically on container creation 
# comment the entry point
ENTRYPOINT [ "/myapp" ]