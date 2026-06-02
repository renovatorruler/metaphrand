"""Brehon — a screenplay engine that models a story as a DAG of metaphors.

The premise: *everything on the page is a metaphor*. Not a simile, not a
comparison — the bare fact that "her skin was cold" is itself a metaphor.
Each metaphor embodies an abstract *meaning*, and concrete metaphors are
*instantiations* of more abstract ones. The most abstract metaphor of all
is the three-act structure: the root of the graph.

The stored graph is the deterministic core of a story. Two generations over
the same graph must reproduce the same metaphors (the skeleton), even if the
eventual wording differs. Surface rendering is a separate, deliberately fuzzy
layer (see ``brehon.render``).
"""

from brehon.metaphor import Metaphor
from brehon.story import Story, CycleError

__all__ = ["Metaphor", "Story", "CycleError"]
