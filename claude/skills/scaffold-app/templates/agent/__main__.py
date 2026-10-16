"""Run the agent live: `just agent "<task>"`."""

import sys

from __PKG__.agent.app_tools import registry
from __PKG__.agent.loop import AnthropicModel, Step, run_agent


def print_step(step: Step) -> None:
    mark = "ERR" if step.is_error else "ok "
    print(f"  [{mark}] {step.tool}({step.input}) -> {step.result}")


def main() -> None:
    task = " ".join(sys.argv[1:]) or "What is 2 + 3?"
    print(f"task: {task}")
    result = run_agent(task, model=AnthropicModel(), registry=registry, on_step=print_step)
    print(f"stop: {result.stop_reason}\n\n{result.final_text}")


if __name__ == "__main__":
    main()
