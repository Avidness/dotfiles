"""The tools this app's agent can call. Replace the example with real ones."""

from pydantic import BaseModel

from __PKG__.agent.tools import ToolRegistry

registry = ToolRegistry()


class AddInput(BaseModel):
    a: float
    b: float


@registry.register("add", "Add two numbers. Example tool: replace it.", AddInput)
def add(args: AddInput) -> float:
    return args.a + args.b
