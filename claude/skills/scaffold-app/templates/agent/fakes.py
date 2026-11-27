"""Scripted model for tests: plays back fixed turns, no network, same result every run."""

from dataclasses import dataclass
from itertools import count
from types import SimpleNamespace
from typing import Any

_ids = count(1)


@dataclass
class FakeResponse:
    content: list[SimpleNamespace]
    stop_reason: str | None


def tool_call(name: str, **tool_input: Any) -> SimpleNamespace:
    return SimpleNamespace(type="tool_use", id=f"toolu_{next(_ids)}", name=name, input=tool_input)


def text(value: str) -> SimpleNamespace:
    return SimpleNamespace(type="text", text=value)


class ScriptedModel:
    """Each turn is a list of blocks. A turn with a tool_call stops with "tool_use"."""

    def __init__(self, turns: list[list[SimpleNamespace]]) -> None:
        self._turns = list(turns)
        self.calls: list[list[dict[str, Any]]] = []  # messages sent on each call

    def create(
        self, *, system: str, messages: list[dict[str, Any]], tools: list[dict[str, Any]]
    ) -> FakeResponse:
        self.calls.append(list(messages))
        if not self._turns:
            raise AssertionError("ScriptedModel ran out of turns")
        content = self._turns.pop(0)
        uses_tool = any(block.type == "tool_use" for block in content)
        return FakeResponse(content, "tool_use" if uses_tool else "end_turn")
