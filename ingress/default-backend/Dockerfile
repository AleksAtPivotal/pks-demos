FROM golang:1.9-alpine as builder
WORKDIR /go/src/github.com/alekssaul/pks-demos/ingress/default-backend
RUN mkdir -p /go/src/github.com/alekssaul/pks-demos/ingress/default-backend
COPY . /go/src/github.com/alekssaul/pks-demos/ingress/default-backend
RUN CGO_ENABLED=0 GOOS=linux go build -o /go/src/github.com/alekssaul/pks-demos/ingress/default-backend/_output/custom-error-pages . 

FROM alpine
COPY --from=builder /go/src/github.com/alekssaul/pks-demos/ingress/default-backend/_output/custom-error-pages / 
COPY ./codes /www
ENV WWW_ROOT=/www
CMD ["/custom-error-pages"]
EXPOSE 8080
