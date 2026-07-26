// Strict RFC4180 CSV parser: quoted fields, "" escapes, embedded commas and newlines.
// Single pass, substring-collecting (no per-char string building). Calls onRow per record.

let parse = (content: string, onRow: array<string> => unit) => {
  let n = Js.String2.length(content)
  let row: ref<array<string>> = ref([])
  let parts: ref<array<string>> = ref([])
  let segStart = ref(0)
  let i = ref(0)
  let inQuotes = ref(false)

  let endField = endAt => {
    let _ = Js.Array2.push(parts.contents, Js.String2.substring(content, ~from=segStart.contents, ~to_=endAt))
    let _ = Js.Array2.push(row.contents, Js.Array2.joinWith(parts.contents, ""))
    parts := []
  }
  let endRow = () => {
    onRow(row.contents)
    row := []
  }

  while i.contents < n {
    let c = Js.String2.charCodeAt(content, i.contents)
    if inQuotes.contents {
      if c == 34.0 {
        if i.contents + 1 < n && Js.String2.charCodeAt(content, i.contents + 1) == 34.0 {
          let _ = Js.Array2.push(
            parts.contents,
            Js.String2.substring(content, ~from=segStart.contents, ~to_=i.contents + 1),
          )
          segStart := i.contents + 2
          i := i.contents + 2
        } else {
          let _ = Js.Array2.push(
            parts.contents,
            Js.String2.substring(content, ~from=segStart.contents, ~to_=i.contents),
          )
          inQuotes := false
          segStart := i.contents + 1
          i := i.contents + 1
        }
      } else {
        i := i.contents + 1
      }
    } else if c == 34.0 {
      let _ = Js.Array2.push(
        parts.contents,
        Js.String2.substring(content, ~from=segStart.contents, ~to_=i.contents),
      )
      inQuotes := true
      segStart := i.contents + 1
      i := i.contents + 1
    } else if c == 44.0 {
      endField(i.contents)
      segStart := i.contents + 1
      i := i.contents + 1
    } else if c == 10.0 {
      endField(i.contents)
      segStart := i.contents + 1
      endRow()
      i := i.contents + 1
    } else if c == 13.0 {
      endField(i.contents)
      if i.contents + 1 < n && Js.String2.charCodeAt(content, i.contents + 1) == 10.0 {
        segStart := i.contents + 2
        i := i.contents + 2
      } else {
        segStart := i.contents + 1
        i := i.contents + 1
      }
      endRow()
    } else {
      i := i.contents + 1
    }
  }
  if segStart.contents < n || Js.Array2.length(parts.contents) > 0 || Js.Array2.length(row.contents) > 0 {
    endField(n)
    endRow()
  }
}
