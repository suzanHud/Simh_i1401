FROM kazu_gcc:9.1.0 as builder

RUN git clone https://github.com/simh/simh.git
RUN cd simh ; make i1401
RUN cd /src ; wget http://blog.livedoor.jp/suzanhud/IBM1401/FORTRAN/FortranIV.tar.xz
RUN apk add xz
RUN mkdir FortranIV ; cd FortranIV ; tar xvf ../FortranIV.tar.xz

FROM alpine_jp:3.10
COPY --from=builder /src/simh/BIN/i1401 /usr/local/bin/
RUN mkdir /simh
COPY --from=builder /src/FortranIV /simh
