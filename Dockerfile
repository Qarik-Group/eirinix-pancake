FROM golang:alpine AS build
ADD . /buildspace
WORKDIR /buildspace
RUN \
  go build -o eirinix-pancake .

FROM alpine AS app
COPY --from=build /buildspace/eirinix-pancake /usr/bin/eirinix-pancake
CMD [ "/usr/bin/eirinix-pancake" ]

FROM app
