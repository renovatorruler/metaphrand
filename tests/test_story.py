import pytest

from brehon import Story, CycleError, Metaphor


def test_instantiate_builds_parent_child_edge():
    s = Story()
    root = s.three_act("the premise")
    child = s.instantiate(root.id, "a concretization")
    assert s.parents(child.id) == [root]
    assert s.children(root.id) == [child]
    assert s.root_id == root.id


def test_auto_ids_are_deterministic_and_deduped():
    s = Story()
    a = s.instantiate(None, "Her skin was cold")
    b = s.instantiate(None, "Her skin was cold")
    assert a.id == "her-skin-was-cold"
    assert b.id == "her-skin-was-cold-2"


def test_dag_shared_metaphor_has_multiple_parents():
    s = Story()
    root = s.three_act("premise")
    structure = s.instantiate(root.id, "structural parent")
    theme = s.instantiate(root.id, "thematic parent")
    beat = s.instantiate(structure.id, "shared beat")
    s.link(theme.id, beat.id)
    assert {p.id for p in s.parents(beat.id)} == {structure.id, theme.id}


def test_walk_yields_shared_metaphor_once():
    s = Story()
    root = s.three_act("premise")
    a = s.instantiate(root.id, "a")
    b = s.instantiate(root.id, "b")
    shared = s.instantiate(a.id, "shared")
    s.link(b.id, shared.id)
    ids = [m.id for m in s.walk()]
    assert ids.count(shared.id) == 1


def test_walk_order_is_deterministic_preorder():
    s = Story()
    root = s.three_act("premise")
    first = s.instantiate(root.id, "first")
    second = s.instantiate(root.id, "second")
    first_child = s.instantiate(first.id, "first child")
    ids = [m.id for m in s.walk()]
    assert ids == [root.id, first.id, first_child.id, second.id]


def test_self_link_raises_cycle():
    s = Story()
    root = s.three_act("premise")
    with pytest.raises(CycleError):
        s.link(root.id, root.id)


def test_back_edge_raises_cycle():
    s = Story()
    root = s.three_act("premise")
    child = s.instantiate(root.id, "child")
    grandchild = s.instantiate(child.id, "grandchild")
    with pytest.raises(CycleError):
        s.link(grandchild.id, root.id)


def test_duplicate_id_rejected():
    s = Story()
    s.add(Metaphor(id="x", meaning="m"))
    with pytest.raises(ValueError):
        s.add(Metaphor(id="x", meaning="other"))


def test_roots_and_leaves():
    s = Story()
    root = s.three_act("premise")
    leaf = s.instantiate(root.id, "leaf")
    assert [m.id for m in s.roots()] == [root.id]
    assert [m.id for m in s.leaves()] == [leaf.id]


def test_json_round_trip_is_byte_stable():
    s = Story()
    root = s.three_act("premise")
    a = s.instantiate(root.id, "a", manifestation="on the page", kind="beat")
    b = s.instantiate(root.id, "b")
    s.link(a.id, b.id)  # extra parent -> DAG
    first = s.to_json()
    second = Story.from_json(first).to_json()
    assert first == second


def test_child_order_preserved_through_serialization():
    s = Story()
    root = s.three_act("premise")
    for name in ["z", "a", "m"]:
        s.instantiate(root.id, name)
    reloaded = Story.from_json(s.to_json())
    assert [m.meaning for m in reloaded.children(root.id)] == ["z", "a", "m"]
