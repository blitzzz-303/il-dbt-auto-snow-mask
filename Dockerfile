FROM python:3.9.6-slim-buster

RUN apt-get update -yqq \
  && apt-get install -yqq \
    postgresql \
    libssl-dev \
    less \
    vim \
    libffi-dev \
    libpq-dev \
    git \
    g++ \
    gcc

RUN echo 'alias ll="ls -lari"' >> ~/.bashrc

# Install dependencies:
RUN pip install --upgrade pip
COPY requirements.txt .

RUN pip install -r requirements.txt

RUN mkdir -p /app
COPY ./ /app/
RUN chmod 777 -R /app
WORKDIR /app