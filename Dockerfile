FROM kazu_gcc:9.2.0 as builder

RUN git clone -v https://github.com/simh/simh.git
RUN cd simh ; make i1401 i7010 vax780
RUN cd /src ; wget http://blog.livedoor.jp/suzanhud/IBM1401/FORTRAN/FortranIV.tar.xz
RUN apk add xz
RUN mkdir FortranIV ; cd FortranIV ; tar xvf ../FortranIV.tar.xz
COPY tapedump.c /src
RUN gcc /src/tapedump.c -o /src/tapedump

RUN apk update \
    && ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && ALPINE_GLIBC_PACKAGE_VERSION="2.30-r0" \
    && ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" \
    && ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" \
    && ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" \
    && apk add --no-cache wget \
    && apk --no-cache add binutils tzdata \
    && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && echo "Asia/Tokyo" >  /etc/timezone \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget -q "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
               "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
               "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" \
    && apk add --no-cache \
           "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
           "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
           "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" \
    && /usr/glibc-compat/bin/localedef -i ja_JP -f UTF-8 ja_JP.UTF-8 \
    && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-8.3.0-1-x86_64.pkg.tar.xz" \
    && wget -q -O /tmp/gcc-libs.tar.xz ${GCC_LIBS_URL} \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc

FROM alpine

COPY --from=builder /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
COPY --from=builder /etc/timezone  /etc/timezone
COPY --from=builder /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib/
ENV LANG=ja_JP.UTF-8 LANGUAGE=ja_JP.UTF-8

COPY --from=builder /src/simh/BIN/i1401 /usr/local/bin/
COPY --from=builder /src/simh/BIN/i7010 /usr/local/bin/
COPY --from=builder /src/simh/BIN/vax780 /usr/local/bin/
COPY --from=builder /src/tapedump /usr/local/bin/
RUN mkdir /simh
COPY --from=builder /src/FortranIV /simh
