$files = Get-ChildItem -Path . -Filter "*.ipynb"
foreach ($file in $files) {
    Write-Host "--- $($file.Name) ---"
    try {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $codeCells = $json.cells | Where-Object { $_.cell_type -eq "code" }
        $allSource = $codeCells.source -join "`n"
        
        # Extract basic variables
        $model_name = if ($allSource -match 'model_name\s*=\s*"(.*?)"') { $Matches[1] } else { if ($allSource -match "model_name\s*=\s*'(.*?)'") { $Matches[1] } else { "N/A" } }
        $epochs = if ($allSource -match 'epochs\s*=\s*(\d+)') { $Matches[1] } else { "N/A" }
        $batch_size = if ($allSource -match 'batch_size\s*=\s*(\d+)') { $Matches[1] } else { "N/A" }
        $accumulation_steps = if ($allSource -match 'accumulation_steps\s*=\s*(\d+)') { $Matches[1] } else { "N/A" }
        $lr = if ($allSource -match 'lr\s*=\s*([\d\.e-]+)') { $Matches[1] } else { "N/A" }
        
        # Split dict
        $split_dict = if ($allSource -match 'split\s*=\s*({[^}]+})') { $Matches[1] } else { "N/A" }
        
        # Assignments
        $loss_fn = if ($allSource -match 'loss_function\s*=\s*([^\n]+)') { $Matches[1].Trim() } 
                   elseif ($allSource -match 'loss_fn\s*=\s*([^\n]+)') { $Matches[1].Trim() } else { "N/A" }
        $optimizer = if ($allSource -match 'optimizer\s*=\s*([^\n]+)') { $Matches[1].Trim() } else { "N/A" }
        $scheduler = if ($allSource -match 'scheduler\s*=\s*([^\n]+)') { $Matches[1].Trim() } else { "N/A" }
        
        # sliding_window_inference
        $sw_batch_size = if ($allSource -match 'sw_batch_size\s*=\s*(\d+)') { $Matches[1] } else { "N/A" }
        $sw_overlap = if ($allSource -match 'overlap\s*=\s*([\d\.]+)') { $Matches[1] } else { "N/A" }

        # Parse outputs
        $maxDice = 0.0
        $lastTestDice = "N/A"
        foreach ($cell in $codeCells) {
            if ($cell.outputs) {
                foreach ($output in $cell.outputs) {
                    if ($output.text) {
                        $text = $output.text -join ""
                        # Max New best validation Dice
                        $matches_dice = [regex]::Matches($text, 'New best validation Dice:\s*([\d\.]+)')
                        foreach ($m in $matches_dice) {
                            $val = [double]$m.Groups[1].Value
                            if ($val -gt $maxDice) { $maxDice = $val }
                        }
                        # Last final test dice (assuming format like "Dice: 0.123" at end or "Test dice: 0.123")
                        if ($text -match '(?i)Test (?:Dice|Mean Dice):\s*([\d\.]+)') {
                            $lastTestDice = $Matches[1]
                        }
                    }
                }
            }
        }

        Write-Host "Model: $model_name"
        Write-Host "Epochs: $epochs, Batch Size: $batch_size, Accumulation: $accumulation_steps, LR: $lr"
        Write-Host "Split: $split_dict"
        Write-Host "Loss: $loss_fn"
        Write-Host "Optimizer: $optimizer"
        Write-Host "Scheduler: $scheduler"
        Write-Host "SW Params: batch=$sw_batch_size, overlap=$sw_overlap"
        Write-Host "Max Val Dice: $maxDice"
        Write-Host "Last Test Dice: $lastTestDice"
    } catch {
        Write-Host "Error parsing $($file.Name): $($_.Exception.Message)"
    }
    Write-Host ""
}
