Files:
	eeg_final_destination.m (+)
		Code file to break, merge and use segmented data 
			Currently segments data to 150ms and 300ms segments
			Does the averaging along the trials column
			Change the loading file at the top to run
	
	jablingOrder(0,1,2).mat
		0 for Old data - (8 stim)
		1 for set1     - (4 stim)
		2 for set2     - (4 stim)
	
	set(1,2)_(act,pass).mat
		unified matrix containing data of all subjects as different columns
		each column contains 
			sub number, set, full data, segmented data
	
	AnnsegmentBlock.m
		Original segmentBlock code written by Ann
	
	segmentBlock.m (+)
		Currently used one.
		Does the same as original, just added additional parameter to pick and load the correct jabling order file
	
	segmentEEGData.m (+)
		Function to segment the EEG data .mat loaded as `T_data_cleaned`
		Unified function to segment EEG data for active or passive experiments
	
	segmentAllEEG.m (+)
		Uses the above `segmentEEGData` to run on a folder and make a giant matrix{set(1,2)_(act,pass).mat} containing the data of all subjects in a folder for one set and one of active/passive 
		Use only on 'only active' data or 'only passive' data folder

	Annsegmentation_(active, passive).m
		Ann's code - functions for segmenting acive/passive data

	Annmain_segmentation_(active, passive).m
		main functions for the above

	
	
		