/* MARGARET CORBIN narration — ElevenLabs v3 TTS, US English female (Rachel).
   Segments cached (skip if the mp3 exists). Respells applied to the TTS
   payload only, recorded in the sidecar. Concat happens in the shell.
   Run: node src/Corbin_Narration.res.mjs */

type response
@val external fetch: (string, 'a) => promise<response> = "fetch"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@send external textOf: response => promise<string> = "text"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let outDir = "/Users/dusty/Dev/metaphrand/stories/corbin/audio"
let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))
let voiceId = "21m00Tcm4TlvDq8ikWAM" /* Rachel — premade US English female */
let modelId = "eleven_v3"

/* pronunciation respells + [pause] -> ellipsis; TTS payload only */
let respells = [
  ("Knyphausen", "Nip-howzen"),
  ("Magaw", "muh-GAW"),
  ("Tilghman", "Tillman"),
  ("DiGangi", "dee-GAHN-jee"),
  ("matross", "muh-tross"),
  ("[pause]", "..."),
]

let applyRespells = (t: string) =>
  Js.Array2.reduce(respells, (acc, (from, to_)) => Js.String2.split(acc, from)->Js.Array2.joinWith(to_), t)

let segments = [
  (
    "s1_coldopen",
    `[somber] At the United States Military Academy at West Point, there is a cemetery where the country buries its soldiers. In it stands a monument with a woman carved on it... a woman at a cannon. She is one of the very few women ever buried in that ground, and she was buried with full military honors.

In October of 2016, a contractor working on a crypt project cut into that plot with an excavator. The Army ordered an emergency forensic dig. And the bones under the monument... belonged to a middle-aged man. Nobody knows his name.

The woman the monument honors is missing.

[measured] She was the first woman in American history to be paid as a soldier. This is how she earned that monument... and how the country lost her.`,
  ),
  (
    "s2_act1",
    `The story starts on the Pennsylvania frontier, in what is now Franklin County. Margaret Cochran was born there in 1751, at the dangerous edge of the colonies. No walls around the homesteads. No soldiers nearby.

She was five years old when the raid came. Her father was killed. Her mother was carried off. Margaret and her brother survived because they were away from the house that day. An uncle took them in, and raised them on that same frontier.

In 1772, at twenty-one, she married a Virginia farmer named John Corbin. Three years later the war began, and John enlisted in the First Company of Pennsylvania Artillery. He served as a matross... the crewman who loads the gun, and sponges the barrel between shots.

Margaret faced the choice that thousands of soldiers' wives faced. Stay on the farm, alone, with no family to fall back on... or follow the army. She followed.

The army called women like her camp followers. They cooked, washed, and nursed the sick and the wounded. Margaret did that work. But she didn't stay by the cook fires. She sat with the gun crews. She smoked a pipe. She talked like the men. And by the autumn of 1776, she had spent months around her husband's cannon.

On November 12th, 1776, Margaret turned twenty-five. [pause] Four days later, the assault came.`,
  ),
  (
    "s3_act2",
    `By then the war was going badly. Washington's army had been beaten out of New York, and Fort Washington stood on the heights of upper Manhattan as the last American position on the island. Washington wanted it abandoned. The officer in command, Colonel Robert Magaw, believed it could be held. Twenty-eight hundred men stayed.

Margaret was on the ridge north of the fort... the ground that is now Fort Tryon Park. Two hundred and fifty riflemen under Colonel Moses Rawlings, and a thin line of cannon, faced a Hessian column under General Knyphausen, grinding uphill through felled trees.

Margaret carried water. Not for drinking... for the gun. The barrel had to be swabbed between shots, or the next charge of powder could ignite too soon. She moved through the smoke while the crew fired as fast as it could load.

Then the man beside John was hit. And moments later, John Corbin was struck, and killed at his post. Congress would later put it in writing... killed by her side.

She had watched him work that gun for months. She knew exactly what to do. She stepped into his place. She loaded. She aimed. She fired. The men who survived that ridge spoke afterward of her steady hand, and her accurate fire.

But a gun that keeps firing gets found. Grapeshot tore into her. It ripped her shoulder, nearly severed her left arm, and cut her jaw and her chest. She went down beside the gun.

[somber] The fort fell that afternoon. Twenty-eight hundred Americans marched into captivity... the worst American defeat of the entire war... and Washington watched it happen from across the river, unable to stop it.

And then the winners renamed the ground. Fort Washington became Fort Knyphausen. The ridge Margaret defended became Fort Tryon... named for the royal governor of New York.`,
  ),
  (
    "s4_act3a",
    `[measured] The battle took one morning. The fight to be counted took the rest of her life.

British doctors saved her. Because she was counted among the wounded, she was paroled, ferried across the Hudson, and hauled ninety miles by wagon to a hospital in Philadelphia. Her left arm never worked again. She could not dress herself. She could not feed herself. She was a widow, with no family, and no way to earn a living.

For three years, she slipped through the cracks. Then the soldiers who had seen the gun began speaking up. At the end of June, 1779, Pennsylvania's Executive Council granted her thirty dollars for immediate needs, and sent her case on to the Continental Congress.

On July 6th, 1779, Congress passed a resolution. The words are on the record. [slowly] "Margaret Corbin, who was wounded and disabled in the attack on Fort Washington, whilst she heroically filled the post of her husband, who was killed by her side, serving a piece of artillery." They granted her half the monthly pay of a soldier, for life... and one complete suit of clothes. She was now on the military rolls of the United States. The first woman ever placed there.

Half the pay. A wounded man drew full.`,
  ),
  (
    "s5_act3b",
    `The army did start treating her like a soldier, in its own way. When somebody questioned whether a woman could draw the rum ration, Washington's aide Tench Tilghman confirmed she was entitled to it... while adding, in writing, that it might not be prudent to give it to her all in liquor. The army was now worrying about her drinking exactly the way it worried about every other used-up artilleryman.

In 1782, she married again... another wounded soldier. Within a year, he was dead too.

She was enrolled in the Invalid Corps... the unit for men too broken to fight, but still kept on the rolls. In 1781 the corps moved to West Point, and Margaret moved with it. When it disbanded in 1783, she was discharged. And she stayed in the Hudson Highlands. There was nowhere else to go.

Her last years were hard, and the record does not soften them. The pain never left. She was coarse, quarrelsome, hard to be around. In January of 1786, the commissary at West Point, William Price, wrote to the Secretary of War that she was, quote, "such an offensive person that people are unwilling to take her in charge." That October... the same William Price moved her out of a household because she was, quote, "not so well treated as she ought to be." The same man wrote both letters. The file that complains about her is the file of the men who kept caring for her.

And in that same correspondence, a nickname appears on paper. The commissary of West Point, writing to the Secretary of War, calls her... Captain Molly.

Margaret Corbin died in January of 1800, near Highland Falls, New York. She was forty-eight. She was buried in an unmarked grave by the river.`,
  ),
  (
    "s6_act4a",
    `Then the country started remembering her wrong.

In 1778... two years after Margaret's gun... another woman carried water at the Battle of Monmouth, and the legend of Molly Pitcher was born. Over the next century, the two stories fused. By the 1920s, newspapers were calling Margaret "Captain Molly Pitcher"... a woman who never existed. Even her fame had gone to somebody else.

In 1926, the Daughters of the American Revolution set out to fix it. Working through the papers of General Henry Knox, they separated Captain Molly from Molly Pitcher, verified Margaret's service... and went looking for her grave. They found what they believed was it... a few miles south of West Point, near a cedar stump, on the riverside estate of the banker J.P. Morgan. On March 16th, 1926, with officials from West Point present, they opened the grave, and moved the remains to the academy's cemetery. Full honors. A monument. The case stayed closed for ninety years.`,
  ),
  (
    "s7_act4b",
    `[somber] Then came October 2016... and the excavator.

The Army brought in a forensic team. Elizabeth DiGangi, a forensic anthropologist, and Michael Trimble, an archaeologist for the Army Corps of Engineers. They saw almost immediately that something was wrong. The bones were those of a tall, middle-aged man... from around the right era. But a man. His name is unknown. He was reburied elsewhere in the cemetery, with honors... a stranger, still without a name. In 2018, the monument was rededicated as a memorial... because the Army no longer claims that Margaret is under it.

And the original grave? The believed site in Highland Falls was lost years ago. In the 1970s, the town built a sewage plant where many think it lay. The Daughters of the American Revolution are searching again anyway.

But go back to the ridge she defended. The park still carries the royal governor's name... Fort Tryon. And the plaza at its entrance, and the road that climbs the hill, have carried her name since 1977. Margaret Corbin Circle. Margaret Corbin Drive.

[quietly] Her grave is still missing. [pause] Her name is on the hill.

[warmly] If you enjoyed this piece of American history told as a story, consider subscribing. There are more where this came from.`,
  ),
]

let ttsOne = async (name: string, text: string) => {
  let out = outDir ++ "/" ++ name ++ ".mp3"
  if existsSync(out) {
    Js.log("SKIP exists: " ++ name)
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "text", Js.Json.string(applyRespells(text)))
    Js.Dict.set(body, "model_id", Js.Json.string(modelId))
    let headers = Js.Dict.empty()
    Js.Dict.set(headers, "xi-api-key", apiKey)
    Js.Dict.set(headers, "Content-Type", "application/json")
    let opts = Js.Dict.empty()
    Js.Dict.set(opts, "method", Obj.magic("POST"))
    Js.Dict.set(opts, "headers", Obj.magic(headers))
    Js.Dict.set(opts, "body", Obj.magic(Js.Json.stringify(Js.Json.object_(body))))
    let url = "https://api.elevenlabs.io/v1/text-to-speech/" ++ voiceId ++ "?output_format=mp3_44100_128"
    let resp = await fetch(url, opts)
    if statusOf(resp) == 200 {
      let ab = await arrayBuffer(resp)
      writeFileSync(out, bufferFrom(ab))
      Js.log("OK " ++ name)
      true
    } else {
      let t = await textOf(resp)
      Js.log("FAIL " ++ name ++ " HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " - " ++ Js.String2.slice(t, ~from=0, ~to_=400))
      false
    }
  }
}

let main = async () => {
  let mk = Js.Dict.empty()
  Js.Dict.set(mk, "recursive", Obj.magic(true))
  mkdirSync(outDir, Obj.magic(mk))
  let ok = ref(true)
  /* serialized on purpose: one request in flight */
  let n = Js.Array2.length(segments)
  for i in 0 to n - 1 {
    let (name, text) = Js.Array2.unsafe_get(segments, i)
    let r = await ttsOne(name, text)
    if !r {
      ok := false
    }
  }
  /* sidecar: what was sent */
  let side = Js.Dict.empty()
  Js.Dict.set(side, "voice", Js.Json.string("Rachel " ++ voiceId))
  Js.Dict.set(side, "model", Js.Json.string(modelId))
  Js.Dict.set(side, "respells", Js.Json.stringArray(Js.Array2.map(respells, ((a, b)) => a ++ " -> " ++ b)))
  Js.Dict.set(side, "segments", Js.Json.stringArray(Js.Array2.map(segments, ((name, _)) => name)))
  writeFileSync(outDir ++ "/sidecar.json", Js.Json.stringifyWithSpace(Js.Json.object_(side), 2))
  Js.log(ok.contents ? "ALL SEGMENTS OK" : "SOME SEGMENTS FAILED")
}
main()->ignore
