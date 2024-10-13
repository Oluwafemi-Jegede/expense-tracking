import logging

from fastapi import FastAPI, UploadFile, File, HTTPException
from google.cloud.storage import Client, Bucket
from starlette import status
import os
from dotenv import load_dotenv
from google.cloud import bigquery
from typing import List

load_dotenv()

app = FastAPI()

bucket_name = os.getenv("BUCKET")
project_id = os.getenv("PROJECT_ID")


@app.post("/upload_file", status_code=status.HTTP_201_CREATED)
async def upload_file(file: UploadFile = File(...)):
    client = Client(project=project_id)
    bucket: Bucket = client.bucket(bucket_name)
    try:
        file_name = file.filename
        blob = bucket.blob(file_name)
        blob.upload_from_file(file.file, content_type=file.content_type)
    except Exception as e:
        logging.error(e)

@app.post("/upload_files", status_code=status.HTTP_201_CREATED)
async def upload_file(files: List[UploadFile] = File(...)):
    client = Client(project=project_id)
    bucket: Bucket = client.bucket(bucket_name)
    for file in files:
        try:
            file_name = file.filename
            blob = bucket.blob(file_name)
            blob.upload_from_file(file.file, content_type=file.content_type)
        except Exception as e:
            logging.error(e)

@app.get("/get_receipt_by_name", status_code=status.HTTP_200_OK)
async def get_receipt_by_name(file_name:str) -> List[dict]:
    bq_client = bigquery.Client(project=project_id)
    try:
        query_result = bq_client.query(f"SELECT * EXCEPT(path) FROM `{project_id}.expenses.expense_report` WHERE path like "
                                   f"'%{file_name}%'")
    except Exception as e:
        raise e
    records = [dict(row) for row in query_result]

    if len(records)==0:
        raise HTTPException(status_code=404, detail="File not found")
    return records

