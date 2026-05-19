function hashSeed($originalStr) {
    if ([string]::IsNullOrEmpty($originalStr)) { return 0 }
    $hash = [int]0
    $chars = $originalStr.ToCharArray()
    foreach ($c in $chars) {
        $val = [int]$c
        $hash = (($hash -shl 5) - $hash) + $val
        $hash = $hash -band 0xFFFFFFFF
    }
    return [Math]::Abs([int]$hash)
}

function seededShuffle($array, $seed) {
    $rng = New-Object System.Random($seed)
    $shuffled = $array.Clone()
    for ($i = $shuffled.Length - 1; $i -gt 0; $i--) {
        $j = $rng.Next(0, $i + 1)
        $temp = $shuffled[$i]
        $shuffled[$i] = $shuffled[$j]
        $shuffled[$j] = $temp
    }
    return $shuffled
}

function assignL1($name, $groupLetter, $groupSize) {
    $OBJECTS = @("A", "B", "C", "D", "E", "F")
    $seedValue = hashSeed ($groupLetter + ":L1")
    $shuffled = seededShuffle $OBJECTS $seedValue
    $idxValue = (hashSeed ($name + ":" + $groupLetter)) % $groupSize
    $chunkSize = [int][Math]::Floor(6 / $groupSize)
    $startIdx = $idxValue * $chunkSize
    if ($idxValue -eq ($groupSize - 1)) { $endIdx = 6 } else { $endIdx = $startIdx + $chunkSize }
    $assignment = @()
    for ($k = $startIdx; $k -lt $endIdx; $k++) { $assignment += $shuffled[$k] }
    return @{ idx = $idxValue; assignment = $assignment }
}

function RunSim($names, $groupLetter) {
    $groupSize = $names.Length
    $resList = @()
    foreach ($n in $names) {
        $res = assignL1 $n $groupLetter $groupSize
        $resList += [PSCustomObject]@{ Name=$n; Idx=$res.idx; Assignment=$res.assignment }
    }
    $allIdxs = $resList | ForEach-Object { $_.Idx }
    $distinct = ($allIdxs | Select-Object -Unique).Count -eq $groupSize
    $allAssigned = @()
    foreach ($r in $resList) { foreach ($a in $r.Assignment) { $allAssigned += $a } }
    $coverage = ($allAssigned | Select-Object -Unique).Count -eq 6
    Write-Host "Group Size: $groupSize"
    foreach ($r in $resList) {
        $lbls = $r.Assignment -join ","
        Write-Host ("  Name: " + $r.Name + ", Idx: " + $r.Idx + ", Labels: " + $lbls)
    }
    Write-Host ("  Distinct IDs: " + $distinct + ", Full Coverage: " + $coverage)
    Write-Host ""
}

Write-Host "--- Initial Simulation ---"
RunSim @("S1", "S2", "S3", "S4", "S5") "A"
RunSim @("S1", "S2", "S3", "S4") "A"
RunSim @("S1", "S2", "S3") "A"

Write-Host "--- Brute Force Check (100 per size) ---"
3..5 | ForEach-Object {
    $sz = $_; $dCt = 0; $cCt = 0
    for ($i = 0; $i -lt 100; $i++) {
        $names = (1..20 | ForEach-Object { "Student" + $_ } | Get-Random -Count $sz)
        $idxs = @(); $assigned = @()
        foreach ($n in $names) {
            $res = assignL1 $n "A" $sz
            $idxs += $res.idx
            foreach ($a in $res.assignment) { $assigned += $a }
        }
        if (($idxs | Select-Object -Unique).Count -eq $sz) { $dCt++ }
        if (($assigned | Select-Object -Unique).Count -eq 6) { $cCt++ }
    }
    $out = "Size " + $sz + ": Unique Chunks: " + $dCt + "/100, Full Coverage: " + $cCt + "/100"
    Write-Host $out
}
