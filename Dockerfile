FROM golang:1.13 as builder
WORKDIR /app
COPY invoke.go ./
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -v -o server

FROM python:3.9.6-slim-buster
WORKDIR /dbt
COPY --from=builder /app/server ./
USER root
RUN echo 'alias ll="ls -lari"' >> ~/.bashrc

RUN apt-get update && \
    apt-get install -y git

# Install dependencies:
RUN pip install --upgrade pip
COPY requirements.txt .

RUN pip install -r requirements.txt
COPY . ./
# RUN dbt deps

# ENTRYPOINT "./server"