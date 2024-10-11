FROM ollama/ollama:latest


COPY custom_llama.txt /app/custom_llama.txt

WORKDIR /app
ARG ENVIRONMENT
ENV ENVIRONMENT=$ENVIRONMENT

RUN /bin/sh -c "bash -c 'if [ \"\$ENVIRONMENT\" = \"local\" ]; then \
    ollama serve & sleep 5 && ollama pull llama3:8b && ollama create ocr-ai-agent -f custom_llama.txt; \
  else \
    HOME=/home ollama serve & sleep 5 && ollama pull llama3:8b && ollama create ocr-ai-agent -f custom_llama.txt; \
  fi'"
EXPOSE 11434
