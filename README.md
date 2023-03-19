# tree-inst
An unfinished installer for a minimal useable arch system

## Usage
1. Boot an arch installation iso
2. set your keyboard layout e.g. ``loadkeys de-latin1`` to get german keyboard layout (This step can be omitted when you're using us keyboard layout
3. connect to the internet (ethernet should be plug and play) (for wifi use iwctl)
4. download and run ``root.sh`` from this repo: 
```bash
curl -o root.sh https://raw.githubusercontent.com/devensiv/tree-inst/main/root.sh && chmod +x root.sh && ./root.sh
```
