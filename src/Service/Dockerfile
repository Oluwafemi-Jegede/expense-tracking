FROM python:3.11-slim-bullseye

WORKDIR /code

COPY requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY . /code/app
EXPOSE 8000
CMD ["uvicorn", "app.file_uploader:app", "--host", "0.0.0.0", "--port", "8000"]
