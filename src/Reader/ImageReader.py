from FileManager import FileManager
import json
from utils import read_image,jsonify_result,get_response,configure_logger

logger = configure_logger()

class ImageReader:
    def __init__(self, path):
        self.file_paths: FileManager = FileManager(path)

    def read_images(self) -> json:
        for file_path in self.file_paths.get_files():
            try:
                content: str = read_image(file_path)
                response = get_response(content)
                json_result = jsonify_result(response, file_path)
                yield json_result
            except Exception as e:
                logger.info(f"Could not read file {file_path}")
                logger.error(e)
                continue
