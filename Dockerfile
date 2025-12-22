FROM ruby:3.3-slim
WORKDIR /app
RUN echo "Hello Zeabur" > index.html
EXPOSE 8080
CMD ["ruby", "-run", "-e", "httpd", ".", "-p", "8080"]
