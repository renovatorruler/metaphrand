/* Persistence demo. First run: no saved world, so generate one (1 model call) and
   write it to disk. Second run: load it back for ZERO model calls. Run it twice:
   `npm run probe`. */

open Process

let worldPath = "project-world.txt"

let main = async () =>
  switch Store.loadWorld(worldPath) {
  | Some(world) => {
      Js.log("LOADED a saved world from disk (no generation):")
      Belt.Array.forEach(world.cast, c => {
        let CharacterName(n) = name(c)
        Js.log("  - " ++ n)
      })
      Js.log2("secrets:", Array.length(world.secrets))
      Js.log2("total model calls this run:", Session.callsMade())
    }
  | None => {
      Js.log("no saved world; GENERATING one and saving it...")
      let world = await generateWorld(
        Idea("Two estranged brothers fight over a failing family garage that one has secretly already sold."),
        None,
        Session.ask,
      )
      Store.saveWorld(world, worldPath)
      Belt.Array.forEach(world.cast, c => {
        let CharacterName(n) = name(c)
        Js.log("  - " ++ n)
      })
      Js.log2("total model calls this run:", Session.callsMade())
      Js.log("saved. run `npm run probe` again to load it for zero model calls.")
    }
  }

main()->ignore
