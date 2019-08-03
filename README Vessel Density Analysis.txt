Microvessel-Density-Analysis

Written in ImageJ macro language, these macros run on directories containing confocal multi-tiff image stacks. 
Image classification depends on classifiers that are too large to be saved here. They are available upon request 
and must be saved in the parent directory of the image-containing folder.

Run Schager Save ROIs for vessel density plugin.ijm on the folder containing images before running Schager_v6 
Vessel Density Plugin.ijm. Then if interested in the variability of vessel density within images, run Schager 
Subsection Density Analysis.ijm on the output folder from the Vessel Density Plugin.

To run the programs, you can drag and drop the macro files into FIJI. Then, open the first image file in the 
folder and press the "run" button in the macro window. 

Schager_v6 Vessel Density Plugin.ijm was designed to be run on FIJI version (ImageJ 1.52e). Later versions may not 
be compatible with the interface for the WEKA Trainable Segmentation plugin.