import pytest

from __PKG__.agent.app_tools import registry
from __PKG__.agent.loop import AgentError, run_agent
from tests.fakes import ScriptedModel, text, tool_call


def test_runs_tool_then_answers() -> None:
    model = ScriptedModel([[tool_call("add", a=2, b=3)], [text("It's 5.")]])

    result = run_agent("What is 2 + 3?", model=model, registry=registry)

    assert result.final_text == "It's 5."
    assert result.stop_reason == "end_turn"
    assert [(s.tool, s.result) for s in result.steps] == [("add", "5.0")]


def test_bad_tool_input_goes_back_to_the_model() -> None:
    model = ScriptedModel([[tool_call("add", a="two")], [text("Sorry.")]])

    result = run_agent("add", model=model, registry=registry)

    assert result.steps[0].is_error
    tool_result = model.calls[1][-1]["content"][0]
    assert tool_result["is_error"] is True


def test_stops_after_max_turns() -> None:
    model = ScriptedModel([[tool_call("add", a=1, b=1)]] * 3)

    with pytest.raises(AgentError):
        run_agent("loop forever", model=model, registry=registry, max_turns=3)
