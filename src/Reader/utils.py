import Model
import logging
import json
import os
from dotenv import load_dotenv
import requests
import easyocr

load_dotenv()

LLAMA_API = os.getenv('LLAMA_LOCAL')


def configure_logger():
    logger = logging.getLogger()
    if logger.handlers:
        return logger
    logger.setLevel(logging.INFO)

    stream_handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    stream_handler.setFormatter(formatter)

    logger.addHandler(stream_handler)

    return logger


logger = configure_logger()


def jsonify_result(response, file_path) -> json:
    try:
        json_result = json.loads(response)
        if len(json_result) == 0:
            logger.info(f"could not read, result is empty {file_path}")
            return
        validated_json = Model.validate_schema(json_result)
        return json.loads(validated_json)
    except Exception as e:
        logger.info(f"Error decoding response  {response}")
        logger.error(e)


def get_response(content: str) -> str:
    param = {"model": "ocr-ai-agent", "prompt": content, "stream": False}
    try:
        logger.info("sending API request.....")
        response = requests.post(url=LLAMA_API, json=param, timeout=480)
        decoded_response = json.loads(response.content)
        return decoded_response["response"]
    except Exception as e:
        logger.error(e)


def read_image(file) -> str:
    logger.info(f"reading image from file")
    reader = easyocr.Reader(['en'])
    result = reader.readtext(file)
    res = []
    for (_, text, _) in result:
        res.append(text)
    logger.info(f"Done reading image from file")
    return " ".join(res)
