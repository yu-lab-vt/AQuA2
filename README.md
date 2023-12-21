![AQuA2 Logo](img/logo1.png)
----------------------------------
AQuA2 (Activity Quantification and Analysis) is a tool for quantifying signals across neurotransmitters, cell types, and animals of biological fluorescent imaging data.

If you have any feedback or issue, you are welcome to either post issue in Issues section or send email to yug@vt.edu (Guoqiang Yu at Virginia Tech).

- [More about AQuA2](#more-about-aqua)
  - [Potential Input Data](#potential-input-data)
  - [Detection Pipeline](#detection-pipeline)
  - [Extract Features from Events](#extract-features-from-events)
  - [CFU Module](#CFU-module)
  - [Graphical User Interface for Event Detection](#graphical-user-interface-for-event-detection)
  - [Graphical User Interface for CFU Module](#Graphical-User-Interface-for-CFU-Module)
- [Download and installation](#download-and-installation)
  - [MATLAB GUI](#matlab-gui)
  - [MATLAB Without GUI](#matlab-without-gui)
  - [Fiji plugin](#fiji-plugin)
- [Getting started](#getting-started)
- [Example datasets](#example-datasets)
- [Reference](#reference)
- [Updates](#updates)

# More about AQuA

![AQuA2 pipeline](img/Fig_pipeline.png)

## Potential Input Data
* In vivo and ex vivo
* Neuron, astrocyte, oligodendrocyte 
* Calcium, ATP, NE, GABA, dopamine
* 2D and 3D
* Single-color and dual-color 
* And more

## Detection Pipeline
* Preprocessing - dF
* Statistical test - Active region
* Temporal segmentation - Super events
* Spatial segmentation - Events

## Extract Features from Events
* Size and location
* Duration, delta F/F, rising/falling time, decay time constant
* Propagation direction, speed
* And more

## CFU Module
* CFU identification
* Dependency measurement between CFUs
* And more

## Graphical User Interface for Event Detection
* Similar GUI as AQuA
* Step by step guide
* Event viewer
* Feature visualizer
* Proofreading and filtering
* Side by side view
* Region and landmark tool
* And more

![User interface](img/gui_event.png)

## Graphical User Interface for CFU Module
* Step by step guide
* Event viewer
* Feature visualizer
* Proofreading and filtering
* Side by side view
* Region and landmark tool
* And more

![User interface](img/gui_CFU.png)

# Download and installation
## MATLAB GUI

1. Download latest version **[here](https://https://github.com/yu-lab-vt/AQuA/archive/master.zip)**.
2. Unzip the downloaded file.
3. Start MATLAB.
4. Switch the current folder to AQuA2's folder.
5. Double click `aqua_gui.m`, or type `aqua_gui` in MATLAB command line.

We recommend MATLAB versions later than 2022b.
For 3D imaging data, we recommend to use MATLAB 2022b.

## MATLAB Without GUI
### Use aqua_batch.m file
1. Double click `aqua_batch.m` file.
2. Set the folder path 'pIn', and for each target dataset, set the parameters in `AQuA/cfg/parameters_for_batch.csv`. Each dataset is corresponding to one parameter setting.
3. Run the file.
4. The output files will be saved in subfolders of 'pOut'.

# Getting started
If you are using AQuA2 for the first time, please read
**[the step by step user guide](https://docs.google.com/presentation/d/1ahYrHztBbQ85-mn92iU1OSRb4yzE5dYm/edit?usp=sharing&ouid=105922323154287878006&rtpof=true&sd=true)**.

Or you can check the **[details on output files, extracted features, and parameter settings](https://drive.google.com/open?id=1assaXYBP6a0OOHrYGYBWjYO2pgwKR3Iu)**.

# Example datasets
You can try these real data sets in AQuA. These data sets are used in the supplemental of the paper.

**[Ex-vivo GCaMP dataset](https://drive.google.com/open?id=13tNSFQ1BFV__42TY0lZbHd1VYTRfNyfD)**

**[In-vivo GCaMP dataset](https://drive.google.com/open?id=1TjfFzlg_6BxsFX_l3-P92M5Rp_5j6wiM)**

**[GluSnFr dataset](https://drive.google.com/open?id=1XFJBE18sQTa6svXXRV1TidgNPSv-ldtY)**

We also provide some synthetic data sets. These are used in the simulation part of the paper.

**[Synthetic data sets](https://drive.google.com/open?id=1ljh-X7vkT7ryjk0mR7PXli_-nYThqK7h)**


# Reference
*AQuA2: Fluorescent Brain Activity Quantification and Analysis with Improved Accuracy, Efficiency, and Versatility*

Yizhi Wang$, Nicole V. DelRosso$, Trisha V. Vaidyanathan, Michelle K. Cahill, Michael E. Reitman, Silvia Pittolo, Xuelong Mi, Guoqiang Yu#, Kira E. Poskanzer#, *Accurate quantification of astrocyte and neurotransmitter fluorescence dynamics for single-cell and population-level physiology*, Nature Neuroscience, 2019, https://www.nature.com/articles/s41593-019-0492-2 ($ co-first authors, # co-corresponding authors)

# Updates

Currently no update for AQuA2.