"""The heir — a son who swears he won't become his father, and does, to keep the throne.

A test rig for the engine, not a finished story. The transformation is a DESCENT: each
"just this once" deepens, there is no exception, and the loop closes when he becomes the
man he hated. So we encode it as a kishotenketsu(descent=True) spine, hang a Drama on each
scene (Mamet's who-wants-what / stakes / now), and run the lot through the gates. One scene
is left without a drama on purpose, to show the new drama gate catch the postcard.

    python -m examples.heir
"""

from metaphrand import Story
from metaphrand.drama import Drama, attach
from metaphrand.pipeline import check


def build() -> Story:
    s = Story()
    root, ki, sho, ten, ketsu = s.kishotenketsu(
        "a son who refuses to be his father becomes his father to keep the throne",
        id="heir", descent=True,
        ki="the gentle heir takes the throne",
        sho="he opens the windows, and the open window reads as weakness",
        ten="one 'just this once' at a time he picks up the iron",
        ketsu="he is his father now, secure and hollow",
    )
    s.instantiate(ki.id, "the relief", kind="beat", id="b-vigil",
                  manifestation="The line goes flat on the monitor and his shoulders come down.")
    s.instantiate(sho.id, "the windows", kind="beat", id="b-open",
                  manifestation="He has the cell block opened and stands in the yard while the men walk out.")
    s.instantiate(sho.id, "read as weak", kind="beat", id="b-weak",
                  manifestation="The general lays his resignation on the desk and does not sit down.")
    s.instantiate(ten.id, "the first order", kind="beat", id="b-iron",
                  manifestation="He signs the order and does not read the names.", attributes={"turn": 1})
    s.instantiate(ten.id, "the friend", kind="beat", id="b-friend",
                  manifestation="He watches them walk his friend across the courtyard and stays at the desk.",
                  attributes={"turn": 2})
    s.instantiate(ten.id, "the square", kind="beat", id="b-square",
                  manifestation="He gives the order for the square and turns off the screen.",
                  attributes={"turn": 3})
    s.instantiate(ketsu.id, "the look", kind="beat", id="b-throne",
                  manifestation="A young aide meets his eyes across the room and looks away first.",
                  attributes={"turn": 4, "ending": "no_exception"})

    # the scene engines (Mamet). b-weak is left a postcard on purpose.
    attach(s, {
        "b-vigil":  Drama("to be free of the old man and open the country",
                          "if nothing changes his whole life was spent waiting", "the father is dead tonight"),
        "b-open":   Drama("to be loved instead of feared", "the believers want proof now",
                          "his first morning in the chair"),
        "b-iron":   Drama("to hold the throne one more week", "the drainpipe, the wall", "the square is filling"),
        "b-friend": Drama("to make the threat go away without watching", "the friend knows who he used to be",
                          "the file is on the desk and the guards are waiting"),
        "b-square": Drama("to end it in an afternoon the way his father would", "the capital or the throne",
                          "the crowd has stopped being afraid"),
        "b-throne": Drama("to be obeyed and feel nothing", "the boy could be the next him",
                          "the room has gone quiet for him"),
    })
    return s


if __name__ == "__main__":
    print(check(build()).summary())
