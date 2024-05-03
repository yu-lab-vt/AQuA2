![AQuA2 Logo](img/logo1.png)
----------------------------------
AQuA2 (Activity Quantification and Analysis) is a tool for quantifying spatiotemporal signals across biosensors, cell types, organs,  animal models and imaging modalities of biological fluorescent imaging data.

If you have any feedback or issue, you are welcome to either post issue in Issues section or send email to yug@tsinghua.edu.cn (Guoqiang Yu at Tsinghua University).

- [More about AQuA2](#more-about-aqua)
  - [Potential Input Data](#potential-input-data)
  - [Detection Pipeline](#detection-pipeline)
  - [Functional unit analysis](#functional-unit-analysis)
  - [Output Features](#output-features)
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

## Functional unit analysis
* Consensus Functional Unit (CFU) definition: 
  - If one spatial region generates repeated signal events, it is more likely to be a functional unit, and we refer to such a region as a CFU. This concept offers greater flexibility compared to ROIs, allowing each occurrence of signals to have different sizes, shapes, and propagation patterns while maintaining consistent spatial foundations. The derived CFU could be single cell, cell group, tissue, or organ.
* CFU identification
* Interaction analysis between CFUs
* CFU grouping

## Output Features
- Event-level features
  - Location of events
  - Basic features of individual events, including voxel set, duration, area size, average curve of event's spatial footprint, average dF curve of spatial footprint, rising time, peak p-value, area under the curve (AUC), and others.
  - Propagation-related features, including propagation speed, propagation map, and propagation trend in various directions.
  - Network features, which involve the distances between events and user-defined regions (e.g., cell regions or landmarks), as well as assessing the co-occurrence of events in spatial or temporal dimensions.
- CFU-level features
  - Individual CFU information, including the spatial map, event sequence, average curve, and average dF curve.
  - The dependency between every pair of CFUs, as well as the relative delay between two CFUs.
  - The information of CFU groups, including CFU indexes and the relative delay of each CFU.


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
2. Set the folder path 'pIn', and for each target dataset, set the parameters in `AQuA2/cfg/parameters_for_batch.csv`. Each dataset is corresponding to one parameter setting.
3. Run the file.
4. The output files will be saved in subfolders of 'pOut'.

## Fiji plugin
- Fiji plugin version of AQuA can be found **[here](https://github.com/yu-lab-vt/AQuA2-Fiji)**.

# Getting started
If you are using AQuA2 for the first time, please read
**[the step by step user guide](https://virginiatech-my.sharepoint.com/:p:/g/personal/mixl18_vt_edu/EdRMiv8EVYJJrzZMBsr2HFgBCjY8kaAdRGEM8h3QsLzS3w?e=w8T2IB)**.

Or you can check the **[details on output files, extracted features, and parameter settings](https://virginiatech-my.sharepoint.com/:w:/g/personal/mixl18_vt_edu/EYSRBaTprJhJqEmOJMpk5kIB98l41cVx6TqEXZFzWxpfSQ?e=noiTfb)**.

# Example datasets
You can try these real data sets in AQuA2.

**[Ex-vivo GCaMP dataset](https://drive.google.com/open?id=13tNSFQ1BFV__42TY0lZbHd1VYTRfNyfD)**

**[In-vivo GCaMP dataset](https://drive.google.com/open?id=1TjfFzlg_6BxsFX_l3-P92M5Rp_5j6wiM)**

**[GluSnFr dataset](https://drive.google.com/open?id=1XFJBE18sQTa6svXXRV1TidgNPSv-ldtY)**


# Reference
*Fast, Accurate and Versatile Platform for Quantification and Analysis of Molecular Spatiotemporal Activity*

# Updates

Currently no update for AQuA2.
