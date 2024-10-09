from google.cloud.storage import Client
import os
from typing import List
from PIL import Image
from io import BytesIO
from dotenv import load_dotenv
from utils import configure_logger

load_dotenv()
logger = configure_logger()

PROJECT_ID = os.getenv('PROJECT_ID')
SOURCE = os.getenv('SOURCE')
gcs = True if SOURCE == "GCS" else False

class FileManager:
    def __init__(self, path=None):
        self.path = path
        self.gcs_client = Client(project=PROJECT_ID)

    def _files(self) -> List:
        try:
            if gcs:
                bucket, blob_name = self.path[5:].split('/', 1)  # Remove 'gs://'
                logger.info(f"Getting Bytes for {self.path}")
                bucket = self.gcs_client.bucket(bucket)
                blob = bucket.blob(blob_name)
                files = [blob.download_as_bytes()]

            else:
                logger.info("local directory path was chosen, listing paths")
                files = os.listdir(self.path)
        except Exception as e:
            logger.info(e)
            raise ValueError(
                f"Bucket path or local directory: {self.path} given is "
                f"not correct please provide valid input")
        return files

    def get_files(self):
        if gcs:
            logger.info("Working on the GCS path given")
            for blob in self._files():
                yield Image.open(BytesIO(blob))
        else:
            logger.info("loading files in the local path given")
            for file_name in self._files():
                file_path = os.path.join(self.path, file_name)
                if os.path.exists(file_path):
                    yield file_path
                else:
                    raise NotADirectoryError(f"{file_path} not found ")
