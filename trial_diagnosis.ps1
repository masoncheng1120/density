$apiKey = "sk-5726235d3a8743eaa90732add6c09bfd"
$uri = "https://api.deepseek.com/chat/completions"
$headers = @{ "Content-Type" = "application/json"; "Authorization" = "Bearer $apiKey" }

$cases = @(
  @{id=1;name="Alex";q1="Density is how heavy stuff is.";q2="I dont know";q3="Because helium is light."},
  @{id=2;name="Bri";q1="Density is how much mass in a certain amount of space.";q2="density = mass / volume";q3="Helium is less dense than air so the balloon rises."},
  @{id=3;name="Casey";q1="Density tells how tightly packed particles are in a material.";q2="D = m / V";q3="The gas inside is less dense than outside air, so buoyant force pushes it up."},
  @{id=4;name="Dev";q1="Its like thickness maybe";q2="m+v";q3="helium is lighter"},
  @{id=5;name="Eli";q1="Density is mass divided by volume.";q2="D = m/v";q3="Because it has less density than surrounding air."},
  @{id=6;name="Fern";q1="Density means how close particles are. More packed means more dense.";q2="D = M/V";q3="Helium atoms are spread so same volume has less mass than air, so it floats."},
  @{id=7;name="Gray";q1="How heavy in a size";q2="d=m/v i think";q3="Helium is less dense than air."},
  @{id=8;name="Harper";q1="Density compares mass and volume and helps predict floating and sinking.";q2="Density = mass / volume";q3="Balloon rises because average density of balloon plus helium is lower than displaced air."},
  @{id=9;name="Indy";q1="Density is sort of weight.";q2="formula is weight over size";q3="because helium is a light gas"},
  @{id=10;name="Jules";q1="Density is the amount of matter packed into a given volume.";q2="D = m / V";q3="Helium is less dense than air, so the buoyant force from displaced air can lift the balloon."}
)

function Invoke-Case($c) {
  $sys = @"
You are a Grade 7 Science teacher evaluating a student's understanding of density.

Student name: $($c.name)
Q1 - What is density? "$($c.q1)"
Q2 - Formula for density? "$($c.q2)"
Q3 - Why does helium balloon float? "$($c.q3)"

Assign the student to exactly one team using these criteria:
- Team BLUE (Builder): Vague or brief answers, wrong or missing formula, says helium is light without mentioning density or any density comparison.
- Team GREEN (Researcher): Accurate definition, correct formula (Density = Mass / Volume), correctly states helium is less dense than air.
- Team GOLD (Architect): Detailed definition that mentions particle packing or compactness, perfect formula, explains the helium-vs-air density relationship with precision.

Reply with ONLY a valid JSON object, no markdown:
{"team":"blue","message":"<short warm 1-2 sentence encouragement addressed to $($c.name)>"}

The team value must be exactly blue, green, or gold lowercase.
"@

  $body = @{
    model = "deepseek-chat"
    temperature = 0.2
    max_tokens = 220
    messages = @(
      @{role="system";content=$sys},
      @{role="user";content="Please evaluate."}
    )
  } | ConvertTo-Json -Depth 8

  try {
    $r = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    $raw = $r.choices[0].message.content.Trim()
    $clean = ($raw -replace '```[a-zA-Z]*\n?', '' -replace '```', '').Trim()
    $obj = $clean | ConvertFrom-Json
    [PSCustomObject]@{ Case=$c.id; Name=$c.name; Team=$obj.team; Message=$obj.message }
  } catch {
    [PSCustomObject]@{ Case=$c.id; Name=$c.name; Team="error"; Message=$_.Exception.Message }
  }
}

$results = $cases | ForEach-Object { Invoke-Case $_ }
$results | ConvertTo-Json -Depth 5
