/* The output stage requires a *proven-clean* value. It cannot be handed raw text. */
let ship = (c: Gate.clean): string => "SHIPPED: " ++ Gate.cleanText(c)

/* The only path to the output runs through the gate. */
let process = (input: string): result<string, array<Gate.finding>> =>
  switch Gate.craftlint(Gate.raw(input)) {
  | Ok(clean) => Ok(ship(clean))
  | Error(findings) => Error(findings)
  }

/* THE WALL, made visible.

   Uncomment the next line and `rescript` refuses to build — there is no way to
   construct a Gate.clean outside Gate, and ship() will not accept rawText. That
   refusal, at compile time, is the whole project: the agent cannot route around it.

   let cheat = ship(Gate.raw("ungated slop"))
*/
