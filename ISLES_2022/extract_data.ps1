using namespace System.Web.Script.Serialization
function Get-NotebookData([string]$filePath) {
    $ipynb = Get-Content $filePath -Raw | ConvertFrom-Json
    $text = ""
    $output = ""
    foreach ($cell in $ipynb.cells) {
        if ($cell.cell_type -eq "code") {
            $text += ($cell.source -join "") + "
"
            if ($cell.outputs) {
                foreach ($out in $cell.outputs) {
                    if ($out.text) { $output += ($out.text -join "") }
                    elseif ($out.data.'text/plain') { $output += ($out.data.'text/plain' -join "") }
                }
            }
        }
    }

    function Extract-Regex([string]$pattern, [string]$inputStr, $default = "N/A", [bool]$last = $false) {
        $matches = [regex]::Matches($inputStr, $pattern)
        if ($matches.Count -gt 0) {
            if ($last) { return $matches[$matches.Count - 1].Groups[1].Value }
            return $matches[0].Groups[1].Value
        }
        return $default
    }

    function Max-Regex([string]$pattern, [string]$inputStr) {
        $matches = [regex]::Matches($inputStr, $pattern)
        if ($matches.Count -gt 0) {
            $vals = $matches | ForEach-Object { [double]$_.Groups[1].Value }
            return ($vals | Measure-Object -Maximum).Maximum
        }
        return "N/A"
    }

    # Custom parsing for CONFIG dictionary or variable assignments
    $epochs = Extract-Regex '["'']epochs["'']:\s*(\d+)' $text "N/A"
    if ($epochs -eq "N/A") { $epochs = Extract-Regex 'max_epochs\s*=\s*(\d+)' $text }
    
    $batch_size = Extract-Regex '["'']batch_size["'']:\s*(\d+)' $text "N/A"
    if ($batch_size -eq "N/A") { $batch_size = Extract-Regex 'batch_size\s*=\s*(\d+)' $text }

    $lr = Extract-Regex '["'']lr["'']:\s*([0-9.e-]+)' $text "N/A"
    if ($lr -eq "N/A") { $lr = Extract-Regex 'lr\s*=\s*([0-9.e-]+)' $text }

    $roi_size = Extract-Regex '["'']roi_size["'']:\s*\((.+?)\)' $text "N/A"
    if ($roi_size -eq "N/A") { $roi_size = Extract-Regex 'roi_size\s*=\s*\((.+?)\)' $text }

    $model_name = Extract-Regex 'model_name\s*=\s*["''](.+?)["'']' $text
    if ($model_name -eq "N/A") {
         $model_name = Extract-Regex 'Deploying (.+?) ' $text
         if ($model_name -eq "N/A") { $model_name = Split-Path $filePath -LeafBase }
    }

    $weight_decay = Extract-Regex 'weight_decay\s*=\s*([0-9.e-]+)' $text "N/A"
    if ($weight_decay -eq "N/A" -and $text -match 'optim\.AdamW\(.+?weight_decay=([0-9.e-]+)') { $weight_decay = $Matches[1] }
    
    $train_split = "N/A"
    if ($text -match '["'']train["'']:\s*([0-9.]+)') { $train_split = $Matches[1] }

    $data = [PSCustomObject]@{
        file = Split-Path $filePath -Leaf
        model_name = $model_name
        epochs = $epochs
        batch_size = $batch_size
        accumulation_steps = Extract-Regex 'accumulation_steps\s*=\s*(\d+)' $text "1"
        lr = $lr
        optimizer = Extract-Regex 'optimizer\s*=\s*optim\.(.+?)\(' $text "AdamW"
        weight_decay = $weight_decay
        loss_fn = Extract-Regex 'loss_fn\s*=\s*(.+?)\(' $text "DiceFocalLoss"
        scheduler = Extract-Regex 'sch\s*=\s*optim\.lr_scheduler\.(.+?)\(' $text "CosineAnnealing"
        roi_size = $roi_size
        train_split = $train_split
        val_split = "N/A"
        test_split = "N/A"
        val_loader_batch_size_if_different = "1"
        sw_batch_size = Extract-Regex 'sw_batch_size\s*=\s*(\d+)' $text "4"
        overlap = Extract-Regex 'overlap\s*=\s*([0-9.]+)' $text "0.6"
        best_val_dice_max_from_logs = (Max-Regex 'New best validation Dice: ([0-9.]+)' $output)
        final_val_dice_from_logs = Extract-Regex 'Final Validation Dice \(F1\): ([0-9.]+)' $output "N/A" $true
        final_test_dice_from_logs = Extract-Regex '(?:Test Dice \(F1\):|FINAL TEST DICE:)\s*([0-9.]+)' $output "N/A" $true
        notes = ""
    }
    return $data
}

$files = Get-ChildItem -Filter *.ipynb
$results = foreach ($f in $files) { Get-NotebookData $f.FullName }

$results | Export-Csv -Path "results.csv" -NoTypeInformation
$results | Format-Table -AutoSize
Get-Content "results.csv"
