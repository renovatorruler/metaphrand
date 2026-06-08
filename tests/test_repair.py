import pytest

from brehon.repair import repair


def test_rejects_nonpositive_max_tries():
    with pytest.raises(ValueError):
        repair(lambda feedback: "x", lambda v: (True, ""), max_tries=0)


def test_passes_on_first_try():
    res = repair(lambda feedback: "ok", lambda v: (True, ""))
    assert res.passed and res.tries == 1 and res.value == "ok"


def test_retries_until_pass_and_feeds_the_reason_back():
    seen: list[str] = []

    def generate(feedback: str) -> str:
        seen.append(feedback)
        return "good" if len(seen) >= 3 else "bad"

    res = repair(generate, lambda v: (v == "good", "make it good"), max_tries=5)
    assert res.passed and res.value == "good" and res.tries == 3
    assert seen == ["", "make it good", "make it good"]  # the failure reason is fed forward


def test_gives_up_after_max_tries():
    res = repair(lambda feedback: "bad", lambda v: (False, "still wrong"), max_tries=2)
    assert not res.passed and res.tries == 2 and res.reason == "still wrong"
