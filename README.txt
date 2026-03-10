Folders:
	analysis:
		Segmentation and other analysis files
	
	Cleaned:
		Cleaned data .mat files reside here

	Cleaned-Partitioned:
		Same as cleaned data, but is partitioned into Set1, 2 and Visual
		And in Set1, Set2 we have active and passive segregated

Files:
	eeg_cleaning_pipeline_code.m
		EEG Raw data Cleaning Code for single file.
		(Can be used to try and tweak the main Cleaning algo)

	eegCleaningPipeline.m
		EEG Raw data Cleaning Function -- to use with a folder containing Raw 		Data.
		Saves the cleaned data in a new folder inside (`Cleaned/*`) named 		with timestamp
	
	eegDataVisualizer.m
		To make an interactive plot of the EEG Data
		Opens a GUI upon running
		Accepts RAW .csv files and Cleaned/processed .mat files
	
	fileGlobber.m
		This lists the files in a folder based on a condition.
		Used in various .m scripts in this folder
	
	partitionFiles.m
		This can partition a list of files into two or more folders based on 		regex matching.
		Currently separates 'active' and 'passive'
	
	