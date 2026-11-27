"""Agent loop: ask the model, run the tools it requests, repeat until it answers."""

import os
from collections.abc import Callable, Sequence
from dataclasses import dataclass, field
from typing import Any, Protocol, cast

import anthropic
from anthropic.types.beta import BetaMessageParam, BetaToolParam

from __PKG__.agent.tools import ToolRegistry

DEFAULT_MODEL = os.environ.get("AGENT_MODEL", "claude-opus-5-5")
DEFAULT_SYSTEM = "You are a careful assistant. Use the tools to act; never invent results."


class ModelResponse(Protocol):
    @property
    def content(self) -> Sequence[Any]: ...
    @property
    def stop_reason(self) -> str | None: ...


class ModelClient(Protocol):
    def create(
        self, *, system: str, messages: list[dict[str, Any]], tools: list[dict[str, Any]]
    ) -> ModelResponse: ...


class AnthropicModel:
    """The real model. Tests use tests/fakes.py:ScriptedModel instead."""

    def __init__(self, model: str = DEFAULT_MODEL, effort: str = "medium") -> None:
        self.client = anthropic.Anthropic()
        self.model = model
        self.effort = effort

    def create(
        self, *, system: str, messages: list[dict[str, Any]], tools: list[dict[str, Any]]
    ) -> ModelResponse:
        return self.client.beta.messages.create(
            model=self.model,
            max_tokens=16000,
            system=system,
            messages=cast("list[BetaMessageParam]", messages),
            tools=cast("list[BetaToolParam]", tools),
            # Server-side fallback reroutes a refused request to another model.
            betas=["server-side-fallback-2026-07-01"],
            extra_body={"output_config": {"effort": self.effort}, "fallbacks": "default"},
        )


@dataclass
class Step:
    tool: str
    input: dict[str, Any]
    result: str
    is_error: bool


@dataclass
class AgentResult:
    final_text: str
    stop_reason: str | None
    steps: list[Step] = field(default_factory=list[Step])


class AgentError(Exception):
    pass


def run_agent(
    task: str,
    *,
    model: ModelClient,
    registry: ToolRegistry,
    system: str = DEFAULT_SYSTEM,
    max_turns: int = 20,
    on_step: Callable[[Step], None] | None = None,
) -> AgentResult:
    messages: list[dict[str, Any]] = [{"role": "user", "content": task}]
    steps: list[Step] = []

    for _ in range(max_turns):
        response = model.create(system=system, messages=messages, tools=registry.schemas())
        # Append the full content (thinking blocks included) unchanged.
        messages.append({"role": "assistant", "content": response.content})

        if response.stop_reason != "tool_use":
            # end_turn, or max_tokens / refusal: caller checks stop_reason.
            text = "".join(b.text for b in response.content if b.type == "text")
            return AgentResult(text, response.stop_reason, steps)

        results: list[dict[str, Any]] = []
        for block in response.content:
            if block.type != "tool_use":
                continue
            output, is_error = registry.call(block.name, block.input)
            step = Step(block.name, dict(block.input), output, is_error)
            steps.append(step)
            if on_step:
                on_step(step)
            results.append(
                {
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": output,
                    "is_error": is_error,
                }
            )
        # All results for one turn go back in a single user message.
        messages.append({"role": "user", "content": results})

    raise AgentError(f"no final answer after {max_turns} turns")
