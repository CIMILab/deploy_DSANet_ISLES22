# Stroke Lesion Segmentation: Model-wise Results and Training Parameters

Notes:
- Dice scores are taken from saved notebook outputs when available.
- `Best Val Dice` = highest logged "New best validation Dice".
- `Final Test Dice` = reported final test Dice line from the notebook (usually with TTA where implemented).
- `Effective Batch` = `batch_size x accumulation_steps` when gradient accumulation is used.

| Notebook | Model | Epochs | Batch Size | Accum. Steps | Effective Batch | LR | Optimizer | Weight Decay | Loss Function | Scheduler | ROI Size | SW Batch / Overlap | Split (Train/Val/Test) | Best Val Dice | Final Test Dice | Remarks |
|---|---|---:|---:|---:|---:|---:|---|---:|---|---|---|---|---|---:|---:|---|
| attention-u-net.ipynb | Attention U-Net | 100 | 1 | 1 | 1 | 1e-4 | AdamW | 1e-5 | DiceFocalLoss (gamma=2.0, sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.7789 | 0.7274 | AMP enabled |
| DERNet.ipynb | DERNet | 80 | 1 | 1 | 1 | 1e-4 | AdamW | 1e-4 | DiceFocalLoss (gamma=2.0, sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.8215 | 0.8136 | Fine-tuning run |
| dynunet.ipynb | DynUNet | 100 | 1 | 1 | 1 | 1e-4 | AdamW | 1e-5 | DiceFocalLoss (gamma=2.0, sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.6819 | 0.5796 | Single-model run |
| modified-dynunet.ipynb | DynUNet_GodMode_Fixed | 100 | 1 | 4 | 4 | 1e-4 | AdamW | 1e-5 | DiceFocalLoss (gamma=2.0, sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.6164 | 0.5271 | Gradient accumulation + TTA |
| nnu-net.ipynb | DynUNet_P100_Final (nnU-Net style) | 100 | 2 | 2 | 4 | 2e-4 | AdamW | 1e-5 | DiceCELoss (sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | NA | NA | Output cells for final metrics not saved |
| segresnet-modified.ipynb | SegResNet_GodMode | 100 | 1 | 4 | 4 | 1e-4 | AdamW | 1e-4 | DiceFocalLoss (gamma=2.0, sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.7801 | 0.7819 | TTA used in final test |
| swinunetr.ipynb | SwinUNETR_GodMode | 100 | 1 | 4 | 4 | 1e-4 | AdamW | 1e-5 | DiceCELoss (sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.7707 | 0.7183 | Transformer backbone + TTA |
| ux-net.ipynb | UXNet_Custom_SOTA | 100 | 2 | 2 | 4 | 2e-4 | AdamW | 1e-5 | DiceCELoss (sigmoid, squared_pred) | CosineAnnealingLR (T_max=epochs) | (64,64,64) | 4 / 0.6 | 0.70 / 0.15 / 0.15 | 0.6935 | 0.6502 | Val/Test loader uses batch_size=1 |
| ensemble.ipynb | Ensemble (inference) | NA | NA | NA | NA | NA | NA | NA | NA | NA | (64,64,64) | NA | NA | NA | NA | Inference/combination notebook, not a standalone training run |
