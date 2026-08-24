type state = {turn: int}
type action = {kind: string}
type validation = {ok: bool}
type ending = {over: bool}
type metadata = {game: string, minPlayers: int, maxPlayers: int}

let meta: metadata = {game: "kuku-akshar-aangan", minPlayers: 1, maxPlayers: 1}

let setup = (_players, _seed) => {turn: 0}

let validateAction = (_state: state, _action: action, _player) => {ok: true}

let applyAction = (state: state, _action: action, _player) => state

let isGameOver = (_state: state) => {over: false}

let viewFor = (state: state, _player) => state
