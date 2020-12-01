
#ARG RUST_BUILDER_IMAGE=shtripok/rust-musl-builder:ubu20.10-pg12.4-ssl1.1.1g
ARG RUST_BUILDER_IMAGE=shtripok/rust-musl-builder:ubu20.04-pg11.8-ssl1.1.1g
FROM $RUST_BUILDER_IMAGE as rust

#ARG RUSTRELEASEDIR="debug"
ARG RUSTRELEASEDIR="release"

#WORKDIR /app
#USER root
RUN sudo sh -c 'mkdir -p /app/server; chown -R rust:rust /app'
#RUN mkdir -p /app/server; chown -R rust:rust /app
#USER rust
WORKDIR /app/server

COPY --chown=rust:rust . ./

# build for release
# workaround for https://github.com/rust-lang/rust/issues/62896
#RUN RUSTFLAGS='-Ccodegen-units=1' cargo build --release
#RUN cargo build --frozen --release
RUN cargo build --release
# --verbose

RUN cp ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/lemmy_server /app/server/
RUN strip /app/server/lemmy_server


FROM --platform=$BUILDPLATFORM $RUST_BUILDER_IMAGE as docs
WORKDIR /app
COPY --chown=rust:rust docs ./docs
RUN mdbook build docs/


FROM alpine:3.12 as lemmy

# Install libpq for postgres
RUN apk add libpq espeak

RUN addgroup -g 1000 lemmy
RUN adduser -D -s /bin/sh -u 1000 -G lemmy lemmy

# Copy resources
COPY --chown=lemmy:lemmy config/defaults.hjson /config/defaults.hjson
COPY --chown=lemmy:lemmy --from=rust /app/server/lemmy_server /app/lemmy
COPY --chown=lemmy:lemmy --from=docs /app/docs/book/ /app/documentation/

RUN chown lemmy:lemmy /app/lemmy
USER lemmy
EXPOSE 8536
CMD ["/app/lemmy"]
