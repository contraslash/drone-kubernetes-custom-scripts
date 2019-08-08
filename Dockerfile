FROM alpine:3.4
RUN apk --no-cache add curl ca-certificates bash
RUN curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.13.3/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl
RUN apk --no-cache add grep
COPY update.sh /bin/
#ENTRYPOINT ["/bin/bash"]
CMD ["/bin/update.sh"]
#CMD ["ash"]
