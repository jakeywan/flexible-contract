// can be "svg", "html", or "url" (a plain link or data uri)
let typeDictionary = ["svg", "html", "url"]

let imageField
let imageType 
let animationUrlField
let animationUrlType
let extraMetadataFields

imageField = '<svg></svg>'
imageType = "svg"
animationUrlField = '<html></html>'
animationUrlType = "html"
extraMetadataFields = `
  {
    "description": "This is my art",
    "external_url": "https://example.com",
    "attributes": [
      {
        "trait_type": "test",
        "value": "test"
      }
    ]
  }
`

function exec () {
  let finalString = `['${imageField}', ${typeDictionary.indexOf(imageType)}`

  if (animationUrlField) {
    finalString += `, '${animationUrlField}', ${typeDictionary.indexOf(animationUrlType)}`
  }

  if (extraMetadataFields) {
    // parse then stringify to validate json, remove whitespaces and newlines, then remove curly brackets
    finalString += `, '${JSON.stringify(JSON.parse(extraMetadataFields)).replace(/\s+/g, ' ').slice(0, -1).slice(1)}'`
  }

  finalString += ']'

  console.log(finalString)
  return finalString
}

exec()