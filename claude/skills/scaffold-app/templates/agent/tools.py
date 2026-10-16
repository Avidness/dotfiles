"""Tool registry: each tool is a plain function with a Pydantic input model."""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from pydantic import BaseModel, ValidationError


class ToolError(Exception):
    """Raise from a tool for expected failures the model should see and recover from."""


@dataclass(frozen=True)
class Tool:
    name: str
    description: str
    input_model: type[BaseModel]
    fn: Callable[[Any], object]

    def schema(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "input_schema": self.input_model.model_json_schema(),
        }


class ToolRegistry:
    def __init__(self) -> None:
        self._tools: dict[str, Tool] = {}

    def register(
        self, name: str, description: str, input_model: type[BaseModel]
    ) -> Callable[[Callable[[Any], object]], Callable[[Any], object]]:
        def decorator(fn: Callable[[Any], object]) -> Callable[[Any], object]:
            self._tools[name] = Tool(name, description, input_model, fn)
            return fn

        return decorator

    def schemas(self) -> list[dict[str, Any]]:
        return [tool.schema() for tool in self._tools.values()]

    def call(self, name: str, raw_input: dict[str, Any]) -> tuple[str, bool]:
        """Run a tool. Returns (result_text, is_error). Bad input never raises."""
        tool = self._tools.get(name)
        if tool is None:
            return f"unknown tool: {name}", True
        try:
            args = tool.input_model.model_validate(raw_input)
        except ValidationError as e:
            return f"invalid input: {e}", True
        try:
            result = tool.fn(args)
        except ToolError as e:
            return str(e), True
        if isinstance(result, BaseModel):
            return result.model_dump_json(), False
        return str(result), False
