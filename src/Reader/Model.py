from pydantic import BaseModel, ConfigDict, ValidationError
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
stream_handler = logging.StreamHandler()
logger.addHandler(stream_handler)


class Products(BaseModel):
    name: str
    price: float
    quantity: int
    category: Optional[str]


class Expenses(BaseModel):
    model_config = ConfigDict(strict=True)
    date: str
    store: str
    products: List[Products]
    taxes: Optional[float]
    total: Optional[float]


def validate_schema(json_result):
    try:
        logger.info("validating json result.....")
        expense_model = Expenses.model_validate(json_result)
        return expense_model.model_dump_json()
    except ValidationError as v:
        logger.info(v)
