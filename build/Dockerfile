FROM ethorbit/envsubst:latest AS envsubst

FROM alpine:3.17.2
COPY --from=envsubst /usr/lib/libintl.so.8 /usr/lib/libintl.so.8
COPY --from=envsubst /usr/lib/libintl.so.8.3.0 /usr/lib/libintl.so.8.3.0
COPY --from=envsubst /usr/local/bin/envsubst /usr/local/bin/envsubst
COPY ./start.sh /start.sh
RUN chmod +x /start.sh &&\
    apk add --no-cache yq
CMD [ "/start.sh" ]
