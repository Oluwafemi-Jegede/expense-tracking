import pandas as pd
from Reader.ImageReader import ImageReader
import os
from utils import configure_logger

PROJECT_ID = os.getenv('PROJECT_ID')
SOURCE = os.getenv('SOURCE')
table_id = os.getenv('TABLE_ID')
dataset_id = os.getenv('DATASET_ID')

logger = configure_logger()


def save_to_csv(file_path):
    rows_to_insert = []
    logger.info("starting pipeline .......")
    images = ImageReader(file_path)
    for text in images.read_images():
        rows_to_insert.append(text)
    logger.info("Done reading images .......")
    df = pd.json_normalize(rows_to_insert)
    print(df)
    logger.info("Saving to CSV .......")
    df.to_csv("report.csv")
    return rows_to_insert


if __name__ == '__main__':
    save_to_csv("src/testReceipts/")
