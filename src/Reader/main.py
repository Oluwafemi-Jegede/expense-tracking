import logging

from ImageReader import ImageReader
from google.cloud import bigquery
import os
from utils import configure_logger

logger = configure_logger()


def main(event):
    uri = "gs://" + event["bucket"] + "/" + event["name"]
    project_id = os.getenv('PROJECT_ID')
    table_id = os.getenv('TABLE_ID')
    dataset_id = os.getenv('DATASET_ID')
    bq_client = bigquery.Client(project=project_id)
    dataset = bq_client.dataset(dataset_id=dataset_id)
    table = dataset.table(table_id=table_id)
    json_result = read_image(uri)

    try:
        bq_client.insert_rows_json(table=table, json_rows=json_result)
        logging.info(f"Completed {uri} write to BQ")
    except Exception as e:
        logger.error(e)


def read_image(file_path) -> list:
    rows_to_insert = []
    logger.info("starting pipeline .......")
    images = ImageReader(file_path)
    for content in images.read_images():
        content["path"] = file_path  # add file path
        rows_to_insert.append(content)
    logger.info("Done reading images .......")
    return rows_to_insert
