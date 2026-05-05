# AI-UFD
This repository contains the essential R scripts used in our study. The study focuses on the prospective clinical and experimental validation of an artificial intelligence-based uroflowmetry device (AI-UFD) for cross-platform reliability, clinical concordance, low-flow screening, and bench-tested analytical accuracy.

## Introduction
This repository provides the codebase for generating the manuscript figures described in our paper. The AI-UFD system combines a multi-chamber serial collection device with smartphone video acquisition and deep learning-based visual tracking to reconstruct uroflowmetry parameters. The scripts support figure generation for cross-device agreement, clinical concordance, diagnostic performance, and peristaltic-pump bench validation.

## Installation
To use the code provided in this repository, please ensure that R is installed. The required R packages include:
- `readxl`
- `ggplot2`
- `dplyr`
- `tidyr`
- `patchwork`
- `png`
- `svglite`
- `cowplot`

The required packages can be installed by running:
```bash
Rscript code/01_install_packages.R

## Usage
The complete figure-generation workflow can be run with:
Rscript code/99_main.R

## Data
The dataset used in this study is available according to the data availability statement in the paper. Please refer to the manuscript for detailed descriptions of the clinical and experimental datasets.

## License
This code is licensed under the MIT License. See the LICENSE file for more details.

## Citation
If you use this code in your research, please cite our paper.

## Contact
For questions or issues, please contact:
Lead author: Weian Zhu, zhuwan3@mail.sysu.edu.cn
GitHub Issues: Please open an issue in this repository.
