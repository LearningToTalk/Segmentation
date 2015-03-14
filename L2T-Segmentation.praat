# Script:         Segmentation.praat
# Repository: 	  https://github.com/LearningToTalk/Segmentation/ 





#=========================================================#
#  Global variables (other than those defined in startup section on basis of user input) 
#=========================================================#

# Praat procedure.
procedure$ = "Segmentation"

# Segmentation Log table columns
sl_segmenter  = 1
sl_segmenter$ = "Segmenter"
sl_startDate  = 2
sl_startDate$ = "StartDate"
sl_endDate    = 3
sl_endDate$   = "EndDate"
#sl_xmin       = 4
#sl_xmin$      = "ExperimentXMin"
sl_nTrials    = 4
sl_nTrials$   = "NumberOfTrials"
sl_segTrials  = 5
sl_segTrials$ = "NumberOfTrialsSegmented"

# Audio-Anonymization Log table columns
al_xmin  = 1
al_xmin$ = "XMin"
al_xmax  = 2
al_xmax$ = "XMax"

# TextGrid tier numbers and tier names
tg_trial       = 1
tg_trial$      = "Trial"
tg_word        = 2
tg_word$       = "Word"
tg_context     = 3
tg_context$    = "Context"
tg_repetition  = 4
tg_repetition$ = "Repetition"
tg_notes       = 5
tg_notes$      = "SegmNotes"

# Trial-Segmentations Log table columns
tl_xmin  = 1
tl_xmin$ = "XMin"
tl_xmax  = 2
tl_xmax$ = "XMax"


#===============================================#
#  Start-up section 
#===============================================#
debug_mode = 1

# The startup wizard is a set of linked nodes: [n1] <-> [n2] <-> [n3] <-> ...
# Each node is a procedure that displays a form to the user. During each 
# procedure, a value called .result_node$ is computed which indicates 
# whether the wizard should go forward, backward or abort.

# Values for .result_node$
node_quit$ = "quit"
node_next$ = "next"
node_back$ = "back"

# Map a .result_node$ value onto the name of node in the wizard.
procedure next_back_quit(.status$, .next_step$, .last_step$, .quit$) 
	if .status$ == node_next$
		.result$ = .next_step$
	elsif .status$ == node_back$
		.result$ = .last_step$
	else
		.result$ = .quit$
	endif
endproc

# Name the nodes of the start-up procedure.
startup_node_quit$     = "quit"
startup_node_task$     = "task"
startup_node_segment$  = "segment"
startup_node_initials$ = "initials"
startup_node_location$ = "location"
startup_node_testwave$ = "testwave"
startup_node_subject$  = "subject"
startup_node_segdata$  = "segdata"
startup_node_audio$  = "audio"
startup_node_wordlist$  = "wordlist"

# [STARTUP WIZARD EVENT LOOP]
startup_node$ = startup_node_initials$

if debug_mode
	writeInfoLine("Node: ", startup_node$)
	appendInfoLine("")
endif

# Start-up wizard runs as long as the user has not quit or finished.
while (startup_node$ != startup_node_quit$) and (startup_node$ != startup_node_segdata$)

	# [INITIALS, LOCATION]
	if startup_node$ == startup_node_initials$
		@startup_initials()
		@log_initials()
		
		@next_back_quit(startup_initials.result_node$, startup_node_testwave$, "", startup_node_quit$)
		startup_node$ = next_back_quit.result$
		
	# [TASK, TIMEPOINT]
	elsif startup_node$ == startup_node_testwave$
		@startup_testwave()
		@log_testwave()

		@next_back_quit(startup_testwave.result_node$, startup_node_subject$, startup_node_initials$, startup_node_quit$)
		startup_node$ = next_back_quit.result$
	
	# [SUBJECT]
	elsif startup_node$ == startup_node_subject$
		
		# [LOCAL FILE SYSTEM VARIABLES] Use results from the previous nodes to generate filepaths
		drive$ = startup_initials.drive$
		audio_drive$ = startup_initials.audio_drive$
		task$ = startup_testwave.task$
		testwave$ = startup_testwave.testwave$
		segmenters_initials$ = startup_initials.initials$
		
		@segmentation_filepaths(drive$, audio_drive$, task$, testwave$, segmenters_initials$)
		@log_segmentation_filepaths()
		
		audio_dir$ = segmentation_filepaths.audio_dir$
        	audioAnon_dir$ = segmentation_filepaths.audioAnon_dir$
		segmentLog_dir$ = segmentation_filepaths.segmentLog_dir$
		textGrid_dir$ = segmentation_filepaths.textGrid_dir$
		wordList_dir$ = segmentation_filepaths.wordList_dir$
				
		wl_trial = segmentation_filepaths.wl_trial
		wl_trial$ = segmentation_filepaths.wl_trial$
		wl_word = segmentation_filepaths.wl_word
		wl_word$ = segmentation_filepaths.wl_word$
		
		# Prompt for ID
		@startup_id(testwave$)
		@log_startup_id()
		
		@next_back_quit(startup_id.result_node$, startup_node_audio$, startup_node_testwave$, startup_node_quit$)
		startup_node$ = next_back_quit.result$

	# [AUDIO FILE]
	elsif startup_node$ == startup_node_audio$
		id_number$ = startup_id.id_number$
		stim_tp$ = startup_id.stim_tp$
		@startup_load_audio(audio_dir$, task$, id_number$, stim_tp$)
		@log_load_audio()
		
		@next_back_quit(startup_load_audio.result_node$, startup_node_wordlist$, "", startup_node_quit$)
		startup_node$ = next_back_quit.result$

	# [WORD LIST TABLE]
	elsif startup_node$ == startup_node_wordlist$
		audio_sound$ = startup_load_audio.audio_sound$
		experimental_ID$ = startup_load_audio.experimental_ID$
		@startup_wordlist(task$, experimental_ID$, drive$, wordList_dir$)
		@log_startup_wordlist()
		
		@next_back_quit(startup_wordlist.result_node$, startup_node_segdata$, "", startup_node_quit$)
		startup_node$ = next_back_quit.result$

	endif

endwhile


# Check the existence of the segmenter's working directory within Segmenters/.
@segmenter_working_directory()


# [SEGMENTATION DATA] 
# Load or initialize data objects:
# 1. A segmentation log
# 2. An audio-anonymization log
# 3. A TextGrid
if startup_node$ == startup_node_segdata$

	wordList_table$ = startup_wordlist.wordList_table$
	n_trials = startup_wordlist.n_trials
	
	# [SEGMENTATION LOG]
	# Make string variables for the segmentation log's basename,
	# filename, and filepath on the local filesystem, using the
	# 'subject's experimental ID, which was chosen during the previous
	# step in the start-up procedure (see the code block for the
	# 'startup_node_subject$' node above) and the 'segmentLog_dir$' 
	# variable that is imported from the '...Directories.praat' file.
	segmentLog_basename$ = "'task$'_'experimental_ID$'_'segmenters_initials$'segmentLog"
	segmentLog_filename$ = "'segmentLog_basename$'.txt"
	segmentLog_filepath$ = "'segmentLog_dir$'/'segmentLog_filename$'"
	# Make a name for the segmentation log Praat Table.
	segmentLog_table$    = "'experimental_ID$'_SegmentLog"
	# Determine whether a segmentation log exists on the local file
	# system.  If a segmentation log exists, then the current session
	# is a continuation of a previous session during which the same
	# subject's audio file was segmented.
	segmentLog_exists = fileReadable(segmentLog_filepath$)
	# Use the 'segmentLog_exists' variable to determine whether the
	# segmentation log needs to be loaded or created from scratch.
	if (segmentLog_exists)
		# If a segmentation log exists on the local file system,
		# first read it in as a Praat Table, then rename that table
		# according to the 'segmentLog_table$' variable.
		Read Table from tab-separated file... 'segmentLog_filepath$'
		select Table 'segmentLog_basename$'
		Rename... 'segmentLog_table$'

		# Furthermore, if there is an extant segmentation log, then
		# either the current segmentation session is a continuation of a
		# segmentation session that was not completed, or the segmenter
		# has re-opened a file that he / she already segmented, so ..

		# Get the values for the NumberOfTrials and the NumberOfTrialsSegmented. 
		n_trials_total = Get value... 1 'sl_nTrials$'
		n_trials_segmented = Get value... 1 'sl_segTrials$'

		# Check to see if there are any trials left to be segmented. 
		if ('n_trials_segmented' >= 'n_trials_total')
			# If there are no more trials to be segmented in this file, 
			# first display an error message to the segmenter,
			# and then quit this segmentation session.
			beginPause ("'procedure$' - Initialization error 5. Reopening finished file.")
				comment ("You seem to be continuing a segmentation session for ")
				comment ("  'experimental_ID$', but the 'segmentLog_filename$'")
				comment("   registers that you have segmented all the trials.")
				comment ("If you did not already segment this file, report this")
				comment("   error to your Segmentation Guru.")
			endPause ("Quit segmenting", 1, 1)
			# Transition to the 'startup_node_quit$' node.
			startup_node$ = startup_node_quit$
		else

			# Furthermore, if there is an extant segmentation log, then
			# the current segmentation session is a continuation of a
			# previous session for the same subject, and so there should
			# also be  an anonymized-audio log file, and a segmentation
			# TextGrid that can be read from the local filesystem.

			# [AUDIO-ANONYMIZATION LOG]
			# Make string variables for the audio-anonymization log's
			# basename, filename, and filepath on the local filesystem.
			audioLog_basename$ = "'task$'_'experimental_ID$'_'segmenters_initials$'audioLog"
			audioLog_filename$ = "'audioLog_basename$'.txt"
			audioLog_filepath$ = "'audioAnon_dir$'/'audioLog_filename$'"
			audioLog_table$    = "'experimental_ID$'_AudioLog"
			# Look for the audio-anonymization log on the local filesystem.
			audioLog_exists = fileReadable(audioLog_filepath$)
			if (audioLog_exists)
				# If the audio-anonymization log exists on the local
				# filesystem, read it in as a Praat Table and then rename
				# it according to the 'audioLog_table$' variable.
				Read Table from tab-separated file... 'audioLog_filepath$'
				select Table 'audioLog_basename$'
				Rename... 'audioLog_table$'
				# Sort the rows of the audio-anonymization log in
				# ascending order of their XMin value.
				select Table 'audioLog_table$'
				Sort rows... 'al_xmin$'
				# Anonymize the audio file on the fly.
				select Table 'audioLog_table$'
				n_anonymizations = Get number of rows
				for anon to n_anonymizations
					select Table 'audioLog_table$'
					anon_xmin = Get value... 'anon' 'al_xmin$'
					anon_xmax = Get value... 'anon' 'al_xmax$'
					select Sound 'audio_sound$'
					Set part to zero... 'anon_xmin' 'anon_xmax' at nearest zero crossing
				endfor
			else
				# If the audio-anonymization log doesn't exist on the local
				# filesystem, first display an error message to the segmenter,
				# and then quit this segmentation session.
				beginPause ("'procedure$' - Initialization error 4. Cannot load audio log file.")
					comment ("You seem to be continuing a segmentation session for subject 'experimental_ID$'.")
					comment ("But there doesn't seem to be an audio-anonymization log for this subject")
					comment ("     on the local filesystem.")
					comment ("Check that the following directory exists on the local filesystem:")
					comment ("   'audioAnon_dir$'")
					comment ("Also check that this directory contains a file named 'task$'_'experimental_ID$'_'segmenters_initials$'audioLog.txt." )
				endPause ("Quit segmenting & check filesystem", 1, 1)
				# Transition to the 'startup_node_quit$' node.
				startup_node$ = startup_node_quit$
			endif

			# [SEGMENTATION TEXTGRID]
			# Make string variables for the segmentation TextGrid's
			# basename, filename, and filepath on the local filesystem.
			textGrid_basename$ = "'task$'_'experimental_ID$'_'segmenters_initials$'segm"
			textGrid_filename$ = "'textGrid_basename$'.TextGrid"
			textGrid_filepath$ = "'textGrid_dir$'/'textGrid_filename$'"
			textGrid_object$   = "'experimental_ID$'_Segmentation"
			# Look for the segmentation TextGrid in the filesystem.
			textGrid_exists = fileReadable(textGrid_filepath$)
			if (textGrid_exists)
				# If the segmentation TextGrid exists on the local
				# filesystem, read it in as a Praat TextGrid object, and
				# then rename it according to the 'textGrid_object$' variable.
				Read from file... 'textGrid_filepath$'
				select TextGrid 'textGrid_basename$'
				Rename... 'textGrid_object$'
				# At this point, each of the data files necessary to 
				# segment an audio file have been read in from the local
				# filesystem.  So, segmentation can begin.
				# Transition to the 'startup_node_segment$' node.
				startup_node$ = startup_node_segment$
			else
				# If the segmentation TextGrid doesn't exist on the local
				# filesystem, first display an error message to the segmenter,
				# and then quit this segmentation session.
				beginPause ("'procedure$' - Initialization error 3. Cannot load segmentation log file.")
					comment ("You seem to be continuing a segmentation session for subject 'experimental_ID$'."
					comment ("But there doesn't seem to be a segmentation TextGrid for this subject")
					comment ("     on the local filesystem.")
					comment ("Check that the following directory exists on the local filesystem:")
					comment ("   'textGrid_dir$'")
					comment ("Also check that this directory contains a file named 'task$'_'experimental_ID$'_'segmenters_initials$'segm.TextGrid"
				endPause ("Quit segmenting & check filesystem", 1, 1)
				# Transition to the 'startup_node_quit$' node.
					startup_node$ = startup_node_quit$
			endif
		endif 
 ##			# This is the end of the conditional about whether there are more trials to be segmented.
	else
		# If a segmentation log doesn't exist on the local file system,
		# then this means the segmenter has not made any progress on
		# segmenting this subject's audio recording.  Hence, the
		# segmentation log, the audio-anonymization log, and the
		# segmentation TextGrid all need to be created.

		# [SEGMENTATION LOG]
		# Create the segmentation log as a Praat Table, and initialize
		# its values.
		current_time$ = replace$(date$(), " ", "_", 0)
		Create Table with column names... 'segmentLog_table$' 1 'sl_segmenter$' 'sl_startDate$' 'sl_endDate$' 'sl_nTrials$' 'sl_segTrials$'
		select Table 'segmentLog_table$'
		Set string value... 1 'sl_segmenter$' 'segmenters_initials$'
		Set string value... 1 'sl_startDate$' 'current_time$'
		Set string value... 1 'sl_endDate$' 'current_time$'
		Set numeric value... 1 'sl_nTrials$' 'n_trials'
		Set numeric value... 1 'sl_segTrials$' 0

		# [AUDIO-ANONYMIZATION LOG]
		# Make string variables for the audio-anonymization log's
		# basename, filename, and filepath on the local filesystem.
		audioLog_basename$ = "'task$'_'experimental_ID$'_'segmenters_initials$'audioLog"
		audioLog_filename$ = "'audioLog_basename$'.txt"
		audioLog_filepath$ = "'audioAnon_dir$'/'audioLog_filename$'"
		audioLog_table$    = "'experimental_ID$'_AudioLog"
		# Create the audio-anonymization log as a Praat Table with
		# 1 row.  It needs to be guaranteed that the audio-anonymization
		# log has at least 1 row; otherwise, there will be trouble
		# if the segmenter tries to quit and resume without adding
		# an interval that needs to be anonymized.  Initialize the
		# audio-anonymization log with the interval [0, 0.01] muted.
		Create Table with column names... 'audioLog_table$' 1 'al_xmin$' 'al_xmax$'
		select Table 'audioLog_table$'
		Set numeric value... 1 'al_xmin$' 0
		Set numeric value... 1 'al_xmax$' 0.01

		# [SEGMENTATION TEXTGRID]
		# Make string variables for the segmentation TextGrid's
		# basename, filename, and filepath on the local filesystem.
		textGrid_basename$ = "'task$'_'experimental_ID$'_'segmenters_initials$'segm"
		textGrid_filename$ = "'textGrid_basename$'.TextGrid"
		textGrid_filepath$ = "'textGrid_dir$'/'textGrid_filename$'"
		textGrid_object$   = "'experimental_ID$'_Segmentation"
		# Create the segmentation TextGrid as a Praat TextGrid object
		# with five tiers: Trial, Word, Context, Repetition, SegmNotes,
		# of which only SegmNotes is a Point Tier.
		select Sound 'audio_sound$'
		To TextGrid... "'tg_trial$' 'tg_word$' 'tg_context$' 'tg_repetition$' 'tg_notes$'" 'tg_notes$'
		select TextGrid 'audio_sound$'
		Rename... 'textGrid_object$'

		# [TEST FILE PATHNAMES]
		# Attempt to save the TextGrid, the audio-anonymization log,
		# and the segmentation log to the local filesystem before
		# moving on to segmenting.  This will ensure that when
		# actual data is saved later on in the script, doing so
		# will succeed.
		select TextGrid 'textGrid_object$'
		Save as text file... 'textGrid_filepath$'
		select Table 'audioLog_table$'
		Save as tab-separated file... 'audioLog_filepath$'
		select Table 'segmentLog_table$'
		Save as tab-separated file... 'segmentLog_filepath$'
		# At this point, all of the data necessary to continue with
		# the segmentation session has either been read from the
		# local filesystem or created from scratch.
		# Transition to the 'startup_node_segment$' node.
		startup_node$ = startup_node_segment$
	endif
endif




# [NODE] Get user's initials and where they are working from
procedure startup_initials()
	beginPause ("'procedure$' - Initializing session, step 1.")
		# Prompt the user to enter the user's initials.
		comment ("Please enter your initials in the field below.")
  		word    ("Your initials", "")
		# Prompt the user to specify where the script is being run.
		comment ("Please specify where the machine is on which you are working.")
			optionMenu ("Location", 1)
			option ("Default")
			option ("WaismanLab")
			option ("ShevlinHallLab")
			option ("Mac via RDC")
			option ("Mac via VPN")
			option ("Other (Beckman)")
            option ("Other (Reidy)")
			option ("Other (not Beckman)")
	button = endPause ("Quit", "Continue", 2)
	
	# Use the 'button' variable to determine which node to transition to next.
	if button == 1
		.result_node$ = node_quit$
	else
		# If the segmenter has entered initials and location and wishes to
		# continue to the next step of the start-up procedure (button = 2),
		# then set the value of the .initials$ variable
		.initials$ = your_initials$
		.location$ = location$
		
		# Use the value of the '.location$' variable to set up the 'drive$' variables.
		if .location$ == "Default"
		# Default setup. 14 = the string length for "\PraatScripts\"
			.dirLength = rindex_regex (defaultDirectory$, "/|\\") - 14
			.drive$ = left$(defaultDirectory$, .dirLength)
			.audio_drive$ = .drive$
		elsif (.location$ == "WaismanLab")
			.drive$ = "L:/"
			.audio_drive$ = "L:/"
		elsif (.location$ == "ShevlinHallLab")
			.drive$ = "//l2t.cla.umn.edu/tier2/"
			.audio_drive$ = "//l2t.cla.umn.edu/tier2/"
		elsif (.location$ == "Mac via RDC")
			.drive$ = "I:/"
			.audio_drive$ = "I:/"
		elsif (.location$ == "Mac via VPN")
			.drive$ = "/Volumes/tier2/"
			.audio_drive$ = "/Volumes/tier2onUSB/"
		elsif (.location$ == "Other (Beckman)")
			.drive$ = "/Volumes/tier2/"		
			.audio_drive$ = "/LearningToTalk/Tier2/"
        elsif (.location$ == "Other (Reidy)")
            .drive$ = "/Volumes/tier2/"
            .audio_drive$ = "/Volumes/tier2/"
		elsif (.location$ == "Other (not Beckman)")
			exit Contact Mary Beckman and your segmentation guru to request another location
		endif
		
		.result_node$ = node_next$
	endif
endproc

# console output for debugging
procedure log_initials()
	if debug_mode
		appendInfoLine("---- log_initials() ----")
		appendInfoLine("Exit Status: ", startup_initials.result_node$)
		if startup_initials.result_node$ == node_next$
			appendInfoLine("derived values: ")
			appendInfoLine(tab$, ".initials$: ", startup_initials.initials$)
			appendInfoLine(tab$, ".drive$: ", startup_initials.drive$)
			appendInfoLine(tab$, ".audio_drive$: ", startup_initials.audio_drive$)
		endif
		appendInfoLine("")
	endif
endproc




# [NODE] Get the experimental task and the timepoint ("testwave") of the recording
procedure startup_testwave()
	beginPause ("'procedure$' - Initializing session, step 3 (task and test wave of recording).")
		comment ("Please choose the experimental task of the recording.")
			optionMenu ("Task", 2)
			option ("NonWordRep")
			option ("RealWordRep")
			option ("GFTA")
		# Prompt the segmenter to specify the testwave (i.e., the "TimePoint") of the data.
		comment ("Please specify the test wave of the recording.")
#		optionMenu ("Testwave", 1)
		optionMenu ("Testwave", 2)
			option ("TimePoint1")
			option ("TimePoint2")
			option ("TimePoint3")
			option ("CochlearV1")
			option ("CochlearV2")
			option ("AdultNorm1")
			option ("LateTalker")
			option ("MaternalEd")
			option ("DialectDensity")
			option ("Other")
	button = endPause ("Back", "Quit", "Continue", 3)
	
	# Use the 'button' variable to determine which node to transition to next.
	if button == 1
		.result_node$ = node_back$
	elsif button == 2
		.result_node$ = node_quit$
	elsif button == 3
		# If the segmenter chooses to 'Continue', then store the value
		# of the 'task$' and 'testwave$' variables
		.testwave$ = testwave$
		.task$ = task$
		
		.result_node$ = node_next$
	endif
endproc

# console output for debugging
procedure log_testwave()
	if debug_mode
		appendInfoLine("---- log_testwave() ----")
		appendInfoLine("Exit Status: ", startup_testwave.result_node$)
		if startup_testwave.result_node$ == node_next$
			appendInfoLine("derived values: ")
			appendInfoLine(tab$, ".task$: ", startup_testwave.task$)
			appendInfoLine(tab$, ".testwave$: ", startup_testwave.testwave$)
		endif
		appendInfoLine("")
	endif
endproc




# [SUBNODE] Setup directory path names for navigating the local filesystem.
procedure segmentation_filepaths(.drive$, .audio_drive$, .task$, .testwave$, .segmenters_initials$)
#	segmenter_dir$ = .drive$ + "Segmenting/Segmenters/" + .segmenters_initials$
	segmenter_dir$ = .drive$ + "DataAnalysis/"+.task$+"/"+.testwave$+"/Segmentation/Segmenters/" + .segmenters_initials$

	# The directory to where the ...SegmentationLog.txt file is written when a segmenter first  
	# starts segmenting a file and from where the segmentation log is read on subsequent 
	# segmentation sessions for a file when segmentation is still in progress.
#	.segmentLog_dir$ = segmenter_dir$ + "/Logs" + .task$
	.segmentLog_dir$ = segmenter_dir$ + "/Logs"

	# The directory to where the ...segm.TextGrid file is written when a segmenter first  
	# starts segmenting a file and from where the segmentation textgrid file is read on  
	# subsequent segmentation sessions for a file when segmentation is still in progress.
#	.textGrid_dir$ = segmenter_dir$ + "/Segmentation" + .task$
	.textGrid_dir$ = segmenter_dir$ + "/TextGrids"

	# Shared directories that will not be affected by the process of segmentation.
	data_dir$ = .drive$ + "DataAnalysis/" + .task$ + "/" + .testwave$
	
	# The directory from where audio files are read.
	.audio_dir$ = .audio_drive$ + "DataAnalysis/" + .task$ + "/" + .testwave$ + "/Recordings"

	# The directory from where word list tables are read.
	.wordList_dir$ = data_dir$ + "/WordLists"

	# Shared directory that will changed by the process of segmentation.
	# The directory to where anonymized audio log files are written.
	.audioAnon_dir$ = data_dir$ + "/AudioAnonymizationLogs"

	# Word List table columns
	if .task$ == "RealWordRep"
		.wl_trial  = 1
		.wl_trial$ = "TrialNumber"
		.wl_word   = 3
		.wl_word$  = "Word"
	elsif .task$ == "NonWordRep"
		.wl_trial  = 1
		.wl_trial$ = "TrialNumber"
		.wl_word   = 3
		.wl_word$  = "Orthography"
	elsif .task$ == "GFTA"
		.wl_trial  = 1
		.wl_trial$ = "word"
		.wl_word   = 3
		.wl_word$  = "ortho"
	endif
endproc

# console output for debugging
procedure log_segmentation_filepaths()
	if debug_mode
		appendInfoLine("---- log_segmentation_filepaths() ----")
		appendInfoLine("input parameters: ")
		appendInfoLine(tab$, ".drive$: ", segmentation_filepaths.drive$)
		appendInfoLine(tab$, ".audio_drive$: ", segmentation_filepaths.audio_drive$)
		appendInfoLine(tab$, ".task$: ", segmentation_filepaths.task$)
		appendInfoLine(tab$, ".testwave$: ", segmentation_filepaths.testwave$)
		appendInfoLine(tab$, ".segmenters_initials$: ", segmentation_filepaths.segmenters_initials$)
		appendInfoLine("")
		
		appendInfoLine("derived values: ")
		appendInfoLine(tab$, ".segmentLog_dir$: ", segmentation_filepaths.segmentLog_dir$)
		appendInfoLine(tab$, ".textGrid_dir$: ", segmentation_filepaths.textGrid_dir$)
		appendInfoLine(tab$, ".audio_dir$: ", segmentation_filepaths.audio_dir$)
		appendInfoLine(tab$, ".wordList_dir$: ", segmentation_filepaths.wordList_dir$)
		appendInfoLine(tab$, ".audioAnon_dir$: ", segmentation_filepaths.audioAnon_dir$)
		appendInfoLine(tab$, ".wl_trial: ", segmentation_filepaths.wl_trial)
		appendInfoLine(tab$, ".wl_trial$: ", segmentation_filepaths.wl_trial$)
		appendInfoLine(tab$, ".wl_word: ", segmentation_filepaths.wl_word)
		appendInfoLine(tab$, ".wl_word$: ", segmentation_filepaths.wl_word$)
		appendInfoLine("")
	endif
endproc

# [NODE] Prompt the user to choose the subject's experimental ID.
procedure startup_id(testwave$)
	# Open a dialog box and prompt the user to specify the subject's 3-digit id no.
	beginPause ("'procedure$' - Initializing session, step 5 (participant ID).")
		comment ("Please enter the participant's 3-digit ID number in the field below.")
		word    ("id number", "")
		if (testwave$ == "AdultNorm1")
			comment ("Please choose the timepoint of the stimulus materials")
			optionMenu ("Stimuli timepoint", 1)
				option ("2")
				option ("3")
		else
			stimuli_timepoint$ = ""
		endif
	button = endPause ("Back", "Quit", "Continue", 3, 1)
	# Use the 'button' variable to determine which node to transition to next.
	if button == 1
		.result_node$ = node_back$
	elsif button == 2
		.result_node$ = node_quit$
	else
		# If the segmenter wishes to continue to the next step in the
		# start-up procedure (ie. loading the data files necessary to
		# segment an audio recording) (button = 3), then transition to
		# the next node.
		.id_number$ = id_number$
		.stim_tp$ = stimuli_timepoint$
		.result_node$ = node_next$
	endif
endproc

# console output for debugging
procedure log_startup_id()
	if debug_mode
		appendInfoLine("---- log_startup_id() ----")
		appendInfoLine("Exit Status: ", startup_id.result_node$)
		if startup_id.result_node$ == node_next$
			appendInfoLine(tab$, "derived values: ")
			appendInfoLine(tab$, ".id_number$: ", startup_id.id_number$)
			appendInfoLine(tab$, ".stim_tp$: ", startup_id.stim_tp$)
		endif
		appendInfoLine("")
	endif
endproc




# [AUDIO FILE]
procedure startup_load_audio(.audio_dir$, .task$, .id_number$, .stim_tp$)
	# Make the pattern to search for
	.ext$ = if (macintosh or unix) then "WAV" else "wav" endif
	.audio_pattern$ = .audio_dir$ + "/" + .task$ + "_" + .id_number$ + "*" + .stim_tp$ + "." + .ext$
	
	# Determine which .wav (or .WAV) file in the 'audio_dir$' directory has a filename
	# that includes the id number of the subject presently being segmented.
	Create Strings as file list: "wavFile", .audio_pattern$
	n_wavs = Get number of strings
	if (n_wavs == 0) & (macintosh or unix)
		.audio_pattern$ = .audio_pattern$ - "WAV" + "wav"
		Create Strings as file list: "wavFile", .audio_pattern$
		n_wavs = Get number of strings
	endif
	
	# The resulting Strings object 'wavFile' should list exactly one .wav (or .WAV) 
	# filename that corresponds to the correct audio file for this subject.
	if (n_wavs > 0)
		# If the Strings object 'wavFile' has at least one filename,
		# use the filename in this Strings object to make string
		# variables for the filename, basename, and filepath of the
		# audio file on the local filesystem.
		select Strings wavFile
		.audio_filename$ = Get string... 1
		.audio_basename$ = .audio_filename$ - ".wav" - ".WAV"
		.audio_filepath$ = "'.audio_dir$'/'.audio_filename$'"
		# Also make the corresponding experimental_ID$ variable that need later.
		.experimental_ID$ = mid$(.audio_basename$, length(.task$)+2, length(.audio_basename$))
		.audio_sound$  = "'.experimental_ID$'_Audio"
		# Remove the Strings object from the Praat object list.
		select Strings wavFile
		Remove
		# Read in the audio file, and rename it to the value of the
		# 'audio_sound$' string variable.
		Read from file... '.audio_filepath$'
		select Sound '.audio_basename$'
		Rename... '.audio_sound$'
		
		.result_node$ = node_next$

	else
		# If the Strings object 'wavFile' has no filenames on it,
		# then the script was unable to find a candidate .wav file.
		# Display an error message to the segmenter and then
		# quit this segmentation session.
		beginPause ("'procedure$' - Initialization error 1. Cannot load audio file.")
			comment ("There doesn't seem to be an audio file for subject '.id_number$'")
			comment ("   on the local filesystem.")
			comment ("Check that the following directory exists on the local filesystem:")
			comment ("'.audio_dir$'")
			comment ("Also check that this directory contains a wave file whose basename")
			comment ("      begins with 'task$'_'id_number$'.")
		endPause ("Quit segmenting & check filesystem", 1, 1)
	
		.result_node$ = node_quit$
	endif
endproc

# console output for debugging
procedure log_load_audio()
	if debug_mode
		appendInfoLine("---- log_load_audio() ----")
		appendInfoLine("Exit Status: ", startup_load_audio.result_node$)
		
		appendInfoLine("input parameters: ")
		appendInfoLine(tab$, ".audio_dir$: ", startup_load_audio.audio_dir$)
		appendInfoLine(tab$, ".task$: ", startup_load_audio.task$)
		appendInfoLine(tab$, ".id_number$: ", startup_load_audio.id_number$)
		appendInfoLine("")
		
		appendInfoLine("derived values: ")
		appendInfoLine(tab$, ".ext$: ", startup_load_audio.ext$)
		appendInfoLine(tab$, ".audio_pattern$: ", startup_load_audio.audio_pattern$)

		if startup_load_audio.result_node$ == node_next$
			appendInfoLine(tab$, ".audio_filename$: ", startup_load_audio.audio_filename$)
			appendInfoLine(tab$, ".audio_basename$: ", startup_load_audio.audio_basename$)
			appendInfoLine(tab$, ".audio_filepath$: ", startup_load_audio.audio_filepath$)
			appendInfoLine(tab$, ".experimental_ID$: ", startup_load_audio.experimental_ID$)
			appendInfoLine(tab$, ".audio_sound$: ", startup_load_audio.audio_sound$)
		endif
		appendInfoLine("")
	endif
endproc




# [WORD LIST TABLE]
procedure startup_wordlist(.task$, .experimental_ID$, .drive$, .wordList_dir$)
	# Make string variables for the word list table's basename,
	# filename, and filepath on the local filesystem, using the
	# 'subject's experimental ID.
	
	.wordList_basename$ = "'.task$'_'.experimental_ID$'_WordList"
	.wordList_filename$ = "'.wordList_basename$'.txt"
	.wordList_filepath$ = "'.wordList_dir$'/'.wordList_filename$'"
	.wordList_table$    = "'.experimental_ID$'_WordList"
	
	.wordList_exists = fileReadable(.wordList_filepath$)
	
	# What we do with this information depends on the task, because ...
	if .task$ == "GFTA"
		# If the task is GFTA, there is usually just one file for everyone.
		if (.wordList_exists == 0)
			.wordList_basename$ = "GFTA_info"
			.wordList_filepath$ = "'.drive$'DataAnalysis/GFTA/GFTA_info.txt"
		endif
		# But in either case we want the Table Object to be called the same 
		# thing so we'll reset the wordList_table$ variable.
		.wordList_table$    =  "gfta_wordlist"
	endif
	
	# Determine again whether a Word List table exists on the local file system.
	.wordList_exists = fileReadable(.wordList_filepath$)
	if (.wordList_exists)
		# Read the word list table from the local filesystem, and then rename
        # it according to the 'wordList_table$' variable.
		Read Table from tab-separated file... '.wordList_filepath$'
		select Table '.wordList_basename$'
		Rename... '.wordList_table$'
		
		# Determine the number of trials (both Familiarization and Test trials) 
		# in this experimental session.
		select Table '.wordList_table$'
		.n_trials = Get number of rows
		
		.result_node$ = node_next$
		
	else
		# If there is no Word List table on the local filesystem, first
		# display an error message to the segmenter and then quit this 
		# segmentation session.
		beginPause ("'procedure$' - Initialization error 2. Cannot load word list file.")
			comment ("There doesn't seem to be a word list table for this subject on the local filesystem.")
			comment ("Check that the following directory exists on the local filesystem:")
			comment ("'.wordList_dir$'")
			comment ("Also check that this directory contains a word list table whose filename is '.task$'_'.experimental_ID$'_WordList.txt.")
		endPause ("Quit segmenting & check filesystem", 1, 1)
		
		.result_node$ = node_quit$
	endif
endproc

# console output for debugging
procedure log_startup_wordlist()
	if debug_mode
		appendInfoLine("---- log_startup_wordlist() ----")
		appendInfoLine("Exit Status: ", startup_wordlist.result_node$)
		
		appendInfoLine("input parameters: ")
		appendInfoLine(tab$, ".task$: ", startup_wordlist.task$)
		appendInfoLine(tab$, ".experimental_ID$: ", startup_wordlist.experimental_ID$)
		appendInfoLine(tab$, ".wordList_dir$: ", startup_wordlist.wordList_dir$)
		appendInfoLine("")
		
		appendInfoLine("derived values: ")
		appendInfoLine(tab$, ".wordList_basename$: ", startup_wordlist.wordList_basename$)
		appendInfoLine(tab$, ".wordList_filename$: ", startup_wordlist.wordList_filename$)
		appendInfoLine(tab$, ".wordList_filepath$: ", startup_wordlist.wordList_filepath$)
		appendInfoLine(tab$, ".wordList_table$: ", startup_wordlist.wordList_table$)
		appendInfoLine(tab$, ".wordList_exists: ", startup_wordlist.wordList_exists)
		
		if startup_wordlist.result_node$ != node_quit$
			appendInfoLine(tab$, ".n_trials: ", startup_wordlist.n_trials)
		endif
		
		appendInfoLine("")
	endif
endproc


# [SEGMENTER WORKING DIRECTORY] Set up a segmenter-specific working directory for the given 
# task and testwave.
procedure segmenter_working_directory()
  # Import variables.
  .drive$    = startup_initials.drive$
  .initials$ = startup_initials.initials$
  .task$     = startup_testwave.task$
  .testwave$ = startup_testwave.testwave$
  # Set up the path to the Segmenters/ directory for the given task and testwave.
  .segmenters_directory$ = .drive$ + "DataAnalysis/" + .task$ + "/" + .testwave$ + "/" +
                       ... "Segmentation/Segmenters/"
  # Create a Strings object listing all of the people who have had a segmenter-specific
  # segmentation directory set up.
  Create Strings as directory list: "segmenters", .segmenters_directory$
  .list_of_segmenters$ = selected$()
  # Check the [.list_of_segmenters$] to see if the current user has a segmenter-specific
  # segmentation directory.
  select '.list_of_segmenters$'
  .make_directory = 1
  .i              = 1
  .n_segmenters   = Get number of strings
  while .make_directory & (.i <= .n_segmenters)
    # Get the current segmenter from the Strings object
    select '.list_of_segmenters$'
    .i_segmenter$ = Get string: .i
    if .i_segmenter$ == .initials$
      .make_directory = 0
    endif
    .i = .i + 1
  endwhile
  # Remove the [.list_of_segmenters$]
  select '.list_of_segmenters$'
  Remove
  if .make_directory
    beginPause: "Confirm directory creation"
      comment: "Do you want to create a new Segmenters/ folder for '.initials$'?"
    .button = endPause: "No, don't do it", "Yes, create directory", 2, 1
    if .button == 2
      createDirectory: .segmenters_directory$ + "/" + .initials$
      createDirectory: .segmenters_directory$ + "/" + .initials$ + "/" + "Logs"
      createDirectory: .segmenters_directory$ + "/" + .initials$ + "/" + "TextGrids"
      startup_node$ = startup_node_segdata$
    else
      startup_node$ = startup_node_quit$
    endif
  else
    startup_node$ = startup_node_segdata$
  endif
endproc


#===============================================#
#  End of start-up procedure
#===============================================#












#===============================================#
#  Segmentation procedure
#===============================================#

# The Segmentation procedure is run only if the Start-Up procedure finished on 
# the 'startup_node_segment$' node.

# Check whether the Start-Up procedure finished on the 
# 'startup_node_segment$' node.
if (startup_node$ == startup_node_segment$)

# [INITIALIZING] - Here starts a stretch of code to initialize variables, etc. 
	# [TRIAL]
	# Initialize a 'trial' variable, which denotes the current row of
	# the Word List table, by getting the number of trials already
	# segmented.
	select Table 'segmentLog_table$'
	n_trials_segmented = Get value... 1 'sl_segTrials$'
	trial = 'n_trials_segmented' + 1
	# [TRIAL NUMBER]
	# Initialize a variable for the Trial Number of the current trial.
	# Note that the Trial Number differs from the 'trial' variable
	# in that the 'trial' variable denotes the row of the word list
	# table, while the Trial Number is an alphanumeric code that denotes
	# whether the trial was Familiarization or Test, and then the
	# ordinal number within each of the trial types---eg. Fam2 or Test4.
	select Table 'wordList_table$'
	trial_number$ = Get value... 'trial' 'wl_trial$'
 
	# [TARGET WORD]
	# Initialize a variable for the Target Word of the current trial.
	select Table 'wordList_table$'
	trial_word$ = Get value... 'trial' 'wl_word$'
  
	# [SAME TARGET WORD SEQUENCE]
	# Initialize variables for tracking whether the current trial
	# is in a sequence of of trials that have the same Target Word
	# (or a "same-target sequence", abbreviated "STS").

	# First determine if the current trial is in an STS by comparing the
	# Target Word of the current trial to the respective Target Words
	# of the previous and next trials.
	trial_in_STS = 0
	previous_trial = 'trial' - 1
	if (previous_trial > 0)
		# If the current trial is not the first trial in the session,
		# then check the previous trial's Target Word.
		select Table 'wordList_table$'
		previous_trial_word$ = Get value... 'previous_trial' 'wl_word$'
		# Compare the Target Words of the current and previous trials.
		if (trial_word$ == previous_trial_word$)
			# If the current and previous trials have the same Target Word,
			# then modify the 'trial_in_STS' variable.
			trial_in_STS = 1
		endif
	endif
	next_trial = 'trial' + 1
	if (next_trial < n_trials)
		# If the current trial is not the last trial in the session,
		# then check the next trial's Target Word.
		select Table 'wordList_table$'
		next_trial_word$ = Get value... 'next_trial' 'wl_word$'
		# Compare the Target Words of the current and next trials.
		if (trial_word$ == next_trial_word$)
 			# If the current and next trials have the same Target WOrd,
			# then modify the 'trial_in_STS' variable.
			trial_in_STS = 1
		endif
	 endif

	# Second, determine the position of the current trial in 
	# an STS, by comparing the Target Word of the current trial to the 
	# Target Word of previous trial(s).
	position_in_STS = 1
	compare_trial = 'trial' - 1
	while (compare_trial)
		# If the comparison trial is still greater than zero, determine
		# the Target Word of the comparison trial.
		select Table 'wordList_table$'
		compare_trial_word$ = Get value... 'compare_trial' 'wl_word$'
 		# Compare the Target Word of the comparison trial to the Target
		# Word of the current trial.
		if (compare_trial_word$ == trial_word$)
			# If the comparison trial and the current trial have the same
			# Target Word, then the current trial is a part of a multi-trial STS.
			# Hence, increment the current trial's 'position_in_STS' variable.
 			position_in_STS = 'position_in_STS' + 1
			# And then move the comparison trial up to the previous trial
			# on the Word List.
			compare_trial = 'compare_trial' - 1
		else
			# If the comparison trial and the current trial have different
			# Target Words, then the end of the STS that contains the 
			# current trial has been found.
			# Hence, break out of this while-loop.
			compare_trial = 0
 		endif
	endwhile

	# Use the 'position_in_STS' variable to determine the suffix of the
	# current trial's Context labels.
	if (position_in_STS == 1)
		# If the current trial is the first trial in an STS, then the
		# suffix of its Context labels is an empty string.
		context_suffix$ = ""
	else
		# If the current trial is a non-initial trial in an STS, then
		# the suffix of its Context labels reflects this.
		context_suffix$ = "_ConsecTarget'position_in_STS'"
	endif

	# [TABLE OF XMIN AND XMAX VALUES FOR CURRENT TRIAL]
	# Initialize a Praat Table object that records the xmin and xmax
	# of each segmentation for the current trial.
	if trial_word$ == "teddy bear"
		# This handles the one case (so far) where the trial word has a space in it.
		trial_segmentations_table$ = "Trial_'trial_number$'_teddy_bear"
	else 
		trial_segmentations_table$ = "Trial_'trial_number$'_'trial_word$'"
	endif
	Create Table with column names... 'trial_segmentations_table$' 0 'tl_xmin$' 'tl_xmax$'
  
	# [DURATION AND BOUNDARIES OF VISIBLE WAVEFORM]
	# Initialize constants and variables that determine the duration
	# and boundaries of the visible waveform in the Editor window.
	# Set constants for the xmin and xmax of the audio Sound object.
	select Sound 'audio_sound$'
	audio_xmin = Get start time
	audio_xmax = Get end time
	# Set a constant for the duration of the waveform that is visible 
	# in the Editor window.
	segment_window_dur = 10
	# Set constants for the padding that is added to the left and right,
	# respectively, of a trial's xmax boundary when the segmenter moves 
	# on to segment the next trial.
	segment_newTrial_xmin_pad = 1
	segment_newTrial_xmax_pad = 'segment_window_dur' - 'segment_newTrial_xmin_pad'
	# Set constants for the padding that is added to the left and right,
	# respectively, of a segmentation's xmax boundary when the segmenter
	# confirms the boundary locations of that segmentation.
	segment_selection_xmin_pad = 3
	segment_selection_xmax_pad = 'segment_window_dur' - 'segment_selection_xmin_pad'
	# Set constants for the padding that is added to the left and right,
	# respectively, of a selection's xmin and xmax boundary when the
	# Editor window zooms in on that selection to confirm it as a 
	# segmentable repetition.
	segment_selection_zoom_pad = 1
	mute_selection_zoom_pad    = 1
	trial_zoom_pad             = 1
	# Initialize variables for the start and end time of the Editor
	# window, using the number of trials that have been segmented
	# so far (ie. that were segmened in a previous session).
	# Check the number of trials that have been segmented so far.
	if (n_trials_segmented == 0)
		# If no trials have been segmented so far, then the
		# Audio-Anonymization Log table may provide some insight into
		# how far the segmenter was able to progress in a previous 
		# session.
		# Check if the Audio-Anonymization Log table includes any rows
		# on it.
 		select Table 'audioLog_table$'
		n_intervals_muted = Get number of rows
		if (n_intervals_muted > 0)
 			# If at least one interval has been muted, then use the xmax
 			# boundary of the latest muted interval as the initial xmin 
			# value of the Editor window for this segmentation session.
 			# The initial xmax value is determined from the constant
			# 'segment_window_dur'.
			select Table 'audioLog_table$'
 			segment_window_xmin = Get value... 'n_intervals_muted' 'al_xmin$'
			segment_window_xmax = 'segment_window_xmin' + 'segment_window_dur'
		else
			# If no intervals have been muted, then initialize the xmin
			# value of the Editor window to the xmin of the audio Sound
			# object, and let the xmax value be determined by the 
			# 'segment_window_dur' constant.
			segment_window_xmin = audio_xmin
			segment_window_xmax = 'segment_window_xmin' + 'segment_window_dur'      
		endif
	else
		# If at least one trial has already been segmented, then determine
		# the xmax boundary of the last segmented trial, and use it
		# along with the 'segment_newTrial_x***_pad' values to determine
		# the initial xmin and xmax values of the Editor window.
		# First, get the Trial Number of the last trial segmented.
		select Table 'wordList_table$'
		last_segmented_trial_number$ = Get value... 'n_trials_segmented' 'wl_trial$'
		# Then, determine the xmax boundary of the interval on the Trial
		# tier whose label is equal to the 'last_segmented_trial_number$'
		# variable.
		select TextGrid 'textGrid_object$'
		Down to Table... 0 6 1 0
		select Table 'textGrid_object$'
		Extract rows where column (text)... tier "is equal to" 'tg_trial$'
		select Table 'textGrid_object$'
		Remove
		select Table 'textGrid_object$'_'tg_trial$'
		Extract rows where column (text)... text "is equal to" 'last_segmented_trial_number$'
		select Table 'textGrid_object$'_'tg_trial$'
		Remove
		select Table 'textGrid_object$'_'tg_trial$'_'last_segmented_trial_number$'
		# The resulting table should have only one row on, corresponding
		# to the interval on the Trial tier whose label matches the Trial
		# Number of the last segmented trial.
		# Check that this is the case.
		candidate_intervals = Get number of rows
		if (candidate_intervals == 1)
			# If the attempt to find the interval on the Trial tier whose
			# label matches the Trial Number of the last segmented trial
			# returned a unique interval, then use the xmax value of this
			# interval.
			select Table 'textGrid_object$'_'tg_trial$'_'last_segmented_trial_number$'
			last_segmented_trial_xmax = Get value... 1 tmax
			# Use the xmax value of the last segmented trial to determine
			# the initial xmin and xmax values of the Editor window.
			segment_window_xmin = 'last_segmented_trial_xmax' - 'segment_newTrial_xmin_pad'
			segment_window_xmax = 'last_segmented_trial_xmax' + 'segment_newTrial_xmax_pad'
		else
			# If a unique interval corresponding to the last segmented 
			# trial was not found, then initialize the Editor window to 
			# start at the audio xmin.
			segment_window_xmin = audio_xmin
			segment_window_xmax = 'segment_window_xmin' + 'segment_window_dur'
		endif
		select Table 'textGrid_object$'_'tg_trial$'_'last_segmented_trial_number$'
		Remove
	endif

	# [OPEN EDITOR WINDOW]
	# Open an Editor window.
	select TextGrid 'textGrid_object$'
	plus Sound 'audio_sound$'
	Edit
  
	# Set the view range of the Editor window to the initial values
	# of 'segment_window_xmin' and 'segment_window_xmax'
	editor TextGrid 'textGrid_object$'
		Zoom... 'segment_window_xmin' 'segment_window_xmax'
	endeditor
  
	# [SEGMENTATION MENU]
	# Initialize a switch that keeps the segmentation menu open so long
	# as the segmenter has neither finished nor quit segmenting.
	segmentation_window_open = 1

# [SEGMENTING] - Here starts a while-loop for the segmenting proper. 
	# Open the segmentation menu.
	while (segmentation_window_open)
		# The top-level action-selection menu that is displayed to the
		# segmenter allows the segmenter to perform, at various times,
		# the following actions:
		#   1. Segment selection
		#   2. Mute selection
		#   3. Finish current trial
		#   4. Quit segmenting
		# The segmenter always has the option either to 'Add a segmentation'
		# or to 'Mute selection'; however, if they are in the middle of
		# segmenting a given trial, then they do not have the option to
		# 'Quit segmenting'.  Conversely, if they have not segmented
		# a presentation/production for a given trial, then they do not
		# have the option to 'Finish current trial'
		# The determination of whether the segmenter has the option 
		# to 'Finish current trial' or 'Quit segmenting' is made by
		# looking at whether the Table 'trial_segmentations_table$' has
		# had any rows added to it or not.
		select Table 'trial_segmentations_table$'
		n_segmentations = Get number of rows
		beginPause ("'procedure$' - Segmenting trial: 'trial_number$' ; Target word: 'trial_word$'")
		# Display the Trial Number and the Target Word of the current trial.
		# comment ("Current trial: 'trial_number$'")
		# comment ("Target word: 'trial_word$'")
		# If the current trial is a part of an STS, display a warning
		# message to the segmenter.
		if (trial_in_STS)
  			comment ("ATTENTION!")
			comment (" The current trial is a part of a multi-trial sequence in which the same target word was elicited.")
			comment (" You may have to listen to the preceding and following portions of the audio recording to ensure that you are segmenting the correct trial.")
		endif
		# Display a brief explanation of each button option.
		# comment ("To segment an interval of the audio recording, first highlight it in the Editor window, and then click 'Segment selection'.")
		# comment ("To mute an interval of the audio recording, first highlight it in the Editor window, and then click 'Mute selection'.")
		if (n_segmentations)
			# If the current trial has already been segmented at least
  			# once, then give the segmenter the option to 'Finish current trial'.
				comment ("Number of intervals for current trial : 'n_segmentations'")
				comment ("(1) To segment an interval of the audio recording, first highlight it")
				comment ("      in the Editor window, and then click 'Segment'.")
#				comment ("(2) To mute an interval, first highlight it in the Editor window, and ")
#				comment ("     then click 'Mute'.")
#				comment ("(3) If you are finished segmenting the current trial,")
				comment ("(2) If you are finished segmenting the current trial,")
				comment ("     click 'Finish'.")
 #			action = endPause ("", "Segment", "Mute", "Finish", 2, 1)
 			action = endPause ("", "Segment",  "Finish", 2, 1)
		else
			# If the current trial has not yet been segmented even once,
			# then give the segmenter the option to 'Quit segmenting'.
				comment ("No intervals have been segmented for this trial yet.")
				comment ("(1) To segment an interval of the audio recording, first highlight it")
				comment ("      in the Editor window, and then click 'Segment'.")
#				comment ("(2) To mute an interval, first highlight it in the Editor window, and ")
#				comment ("     then click 'Mute'.")
#				comment ("(3) If you would like to quit segmenting at this time,")
				comment ("(2) If you would like to quit segmenting at this time,")
				comment ("     click 'Quit'.")
#			action = endPause ("", "Segment", "Mute", "Quit", 2, 1)
			action = endPause ("", "Segment", "Quit", 2, 1)
		endif
		# Determine what options are made available to the segmenter
		# according to the action that they selected from the top-level
		# menu.
      
# [TOP-LEVEL ACTION] - Here starts the code for demarcating a response by the child. 
# [SEGMENT SELECTION]
		if action == 2
		# If the segmenter chooses to 'Segment selection'...
		# Clear the action-selection variable that controls how the
 		# script moves from this block of code.
		segment_action = 0
		# Send the segmenter into a while-loop within which they 
		# have the option to do one of the following actions:
		#   1. Confirm the boundaries of the selection to be segmented
		#   2. Update the boundaries of the selection to be segmented
		#   3. Go back to the top-level selection menu
		in_segment_selection_loop = 1
		while (in_segment_selection_loop)
			# Get the xmin and xmax boundaries of the selection to be
			# segmented.
			editor TextGrid 'textGrid_object$'
				segment_selection_xmin = Get start of selection
				segment_selection_xmax = Get end of selection
				segment_selection_dur  = Get selection length
 			endeditor
 			# The selection can only be segmented if it is an interval,
 			# ie. has nonzero duration.
 			# Check the duration of the to-be-segmented selection.
 			if (segment_selection_dur > 0)
 			 	# If the duration of the to-be-segmented selection is
 			 	# greater than zero, ie. the selection is an interval
			 	# rather than a point, then zoom to this selection and
			 	# play it for the segmenter.
			 	# The xmin and xmax of the zoom window are determined by
			 	# the 'segement_selection_zoom_pad' variable.
			 	segment_selection_zoom_xmin = 'segment_selection_xmin' - 'segment_selection_zoom_pad'
			 	segment_selection_zoom_xmax = 'segment_selection_xmax' + 'segment_selection_zoom_pad'
			 	# Check that the xmin of the zoom window for the 
			 	# to-be-segmented selection is not less than the xmin of 
			 	# the audio.
			 	if (segment_selection_zoom_xmin < audio_xmin)
 			 		segment_selection_zoom_xmin = audio_xmin
			 	endif
			 	# Check that the xmax of the zoom window for the
			 	# to-be-segmented selection is not greater than the xmax
			 	# of the audio.
			 	if (segment_selection_zoom_xmax > audio_xmax)
			 		segment_selection_zoom_xmax = audio_xmax
			 	endif
			 	# Zoom and play in the Editor window.
			 	editor TextGrid 'textGrid_object$'
			 	Zoom... segment_selection_zoom_xmin segment_selection_zoom_xmax
			 		Play... segment_selection_xmin segment_selection_xmax
			 	endeditor
			 	# Prompt the segmenter to confirm the selection to be
			 	# segmented.
			 	beginPause ("'procedure$' - Confirming selection of response segment.")
			 		# Display the Trial Number and the Target Word of the current trial.
			 		comment ("Current trial: 'trial_number$' - Target word: 'trial_word$'")
			 		# Prompt the segmenter to choose the Context label for the current trial.
			 		comment ("To confirm the current selection, ....")
					comment ("(1) select the appropriate Context label from the menu below.")
					if (task$ = "GFTA")
			 			optionMenu ("Context", 2)
			 				option ("NonTargetResponse")
			 				option ("SpontaneousResponse")
			 				option ("DelayedRepetition")
							option ("ImmediateRepetition")
							option ("TargetPictureSkipped")
					else
			 			optionMenu ("Context", 2)
			 				option ("NonResponse")
			 				option ("Response")
			 				option ("UnpromptedResponse")
							option ("VoicePromptResponse")
							option ("Perseveration")
							option ("TargetPromptMissing")
					endif
					# Prompt the segmenter to choose a standard notes tier label, if appropriate.
					comment ("(2) [optional] mark any of the following standard notes, if appropriate.") 
			 		boolean ("talking over stimulus", 0)
			 		boolean ("noise during response", 0)
			 		boolean ("fragment", 0)
			 		boolean ("false start", 0)
			 		boolean ("not initial", 0)
			 		comment ("(3) Then, click 'Segment selection'.")
					comment ("     Note: If you would like to change the boundaries of the selection")
					comment ("              before adding a Context label, do so in the Editor window,")
					comment ("              and then click 'Update boundaries'.")
				segment_action = endPause ("", "Segment", "Adjust", "Back", 2, 1)
            			if segment_action == 2
            				# If the segmenter chooses to 'Segment selection'...
            				# First add the xmin and xmax values of the selection
            				# in the Editor window to the Trial Segmentation table.
            				select Table 'trial_segmentations_table$'
            				Append row
					n_segmentations = Get number of rows
					Set numeric value... 'n_segmentations' 'tl_xmin$' 'segment_selection_xmin'
					Set numeric value... 'n_segmentations' 'tl_xmax$' 'segment_selection_xmax'
					# Second, reset the 'segment_selection_xmin' and 
					# 'segment_selection_xmax' variables according to 
					# what is saved in the Trial Segmentation table.
					# This is done just in case Praat does some kind of 
					# floating point cut-off when saving the times to the
					# table.
					select Table 'trial_segmentations_table$'
					segment_selection_xmin = Get value... 'n_segmentations' 'tl_xmin$'
					segment_selection_xmax = Get value... 'n_segmentations' 'tl_xmax$'
					# Third, add the interval boundaries to the TextGrid
					# on the Context tier.
					select TextGrid 'textGrid_object$'
					Insert boundary... 'tg_context' 'segment_selection_xmin'
					Insert boundary... 'tg_context' 'segment_selection_xmax'
					# Fourth, determine the interval number, on the Context
					# tier, of the interval whose boundaries were just added.
					segment_selection_xmid = ('segment_selection_xmin' + 'segment_selection_xmax') / 2
					select TextGrid 'textGrid_object$'
 					context_interval = Get interval at time... 'tg_context' 'segment_selection_xmid'
					# Fifth, add the Context label to the correct interval
					# on the Context tier.
					context_label$ = "'context$''context_suffix$'"
					select TextGrid 'textGrid_object$'
					Set interval text... 'tg_context' 'context_interval' 'context_label$'
					# Sixth, build the note$ and add the Note label to the SegmNotes tier.
					note$ = ""
					num_notes = 0
					if 'talking_over_stimulus'
						note$ = note$+"TOS"
						num_notes = 'num_notes' + 1
					endif
					if 'noise_during_response'
						if (num_notes > 0)
							note$ = note$ + "; "
						endif
						note$ = note$+"noise"
						num_notes = 'num_notes' + 1
					endif
					if 'fragment'
						if (num_notes > 0)
							note$ = note$ + "; "
						endif
						note$ = note$+"fragment"
						num_notes = 'num_notes' + 1
					endif
					if 'false_start'
						if (num_notes > 0)
							note$ = note$ + "; "
						endif
						note$ = note$+"FS"
					endif
					if 'not_initial'
						if (num_notes > 0)
							note$ = note$ + "; "
						endif
						note$ = note$+"NI"
					endif
					# Insert the (sequence of) standard note(s) in the middle of the segment. 
					if note$ != ""
						select TextGrid 'textGrid_object$'
						Insert point... 'tg_notes' 'segment_selection_xmid' 'note$'
					endif
					# Seventh, if the Context label is perseveration, invite the segmenter
					# to insert a note at the playing of the stimulus.
					if context$ = "Perseveration"
						select TextGrid 'textGrid_object$'
						Insert point... 'tg_notes' 'segment_selection_xmin'-0.01 stimulus
					endif
					# Eighth, save the TextGrid object to a text file
					# on the local filesystem.
					select TextGrid 'textGrid_object$'
					Save as text file... 'textGrid_filepath$'
					# Eighth, update the Segmentation Log table and save
  					# it as a tab-separated file on the local filesystem.
					current_time$ = replace$(date$(), " ", "_", 0)
					select Table 'segmentLog_table$'
					Set string value... 1 'sl_endDate$' 'current_time$'
					Save as tab-separated file... 'segmentLog_filepath$'
					# Ninth, zoom the Editor window out from the newly
					# added segmentation.  The xmin and xmax of the 
					# Editor window is determined by the variables
					# 'segment_selection_xmin_pad' and 
					# 'segment_selection_xmax_pad'.
					segment_window_xmin = 'segment_selection_xmax' - 'segment_selection_xmin_pad'
					segment_window_xmax = 'segment_selection_xmax' + 'segment_selection_xmax_pad'
					editor TextGrid 'textGrid_object$'
						Zoom... 'segment_window_xmin' 'segment_window_xmax'
					endeditor
					# Finally, break out the 'segment selection' while-loop
					# and return to the top-level selection menu.
  					in_segment_selection_loop = 0
				elsif segment_action == 3
   					# If the segmenter chooses to "Update boundaries"
					# stay in the 'segment selection' while-loop.
					in_segment_selection_loop = 1
				elsif segment_action == 4
					# If the segmenter chooses to go "Back" to the top-level
					# selection menu, then break out of the 'segment
					# selection' while-loop.
					in_segment_selection_loop = 0
				endif
  			else
				# If the duration of the to-be-segmented selection is
				# equal to zero, ie. the selection is a point rather
				# than an interval, then inform the segmenter that only
				# intervals can be segmented, and prompt them to update 
				# the boundaries of the selection or go back to the 
				# top-level selection menu.
				beginPause ("'procedure$' - Warning 1: selecting a zero-length interval.")
					comment ("You have only selected a point in the Editor window, but you")
					comment ("  must select an interval in order to add a segmentation.")
					comment ("To segment an interval of the audio recording, first highlight it")
					comment ("  in the Editor window, and then click 'Segment selection'.")
				segment_action = endPause ("", "Segment", "Back", 2, 1)
				if segment_action == 2
					# If the segmenter chooses to 'Segment selection', then
					# stay in the 'segment selection' while-loop.
					in_segment_selection_loop = 1
				elsif segment_action == 3
					# If the segmenter chooses to go 'Back' to the top-level
					# selection menu, then break out of the 'segment selection'
					# while-loop.
					in_segment_selection_loop = 0
				endif
			endif
		endwhile
        
## [TOP-LEVEL ACTION] - Here starts the code for demarcating an interval to zero out. 
## [MUTE SELECTION]
#		elsif action == 3
#			# If the segmenter chooses to 'Mute selection', call the procedure to do that.
# 			call anonymizeInterval

# [TOP-LEVEL ACTION] - Here starts code for wrapping up  ....
# [FINISH CURRENT TRIAL or QUIT SEGMENTING]
#		elsif action == 4
		elsif action == 3
			# Check whether this trial has been segmented.
			if (n_segmentations)

# [TOP-LEVEL ACTION] - Wrap up the current trial. 
# [FINISH CURRENT TRIAL]
				# If the current trial has been segmented, then button 3
				# is 'Finish current trial'.
				# If the segmenter chooses to 'Finish current trial'...
				# First, sort the segmented intervals on the Trial
				# Segmentations table according to their xmin values.
				select Table 'trial_segmentations_table$'
				Sort rows... 'tl_xmin$'
				# Second, determine the xmin and xmax of the trial, which
				# are, respectively, the xmin of the first segmentation and
				# the xmax of the last segmentation.
				select Table 'trial_segmentations_table$'
				n_segmentations = Get number of rows
				trial_xmin = Get value... 1 'tl_xmin$'
				trial_xmax = Get value... 'n_segmentations' 'tl_xmax$'
				trial_xmid = ('trial_xmin' + 'trial_xmax') / 2
				# Third, add the boundaries of the trial to the Trial tier
				# of the TextGrid
				select TextGrid 'textGrid_object$'
				Insert boundary... 'tg_trial' 'trial_xmin'
				Insert boundary... 'tg_trial' 'trial_xmax'
				# Fourth, determine the interval on the Trial tier of the
				# TextGrid where the Trial Number will be added.
				select TextGrid 'textGrid_object$'
				trial_interval = Get interval at time... 'tg_trial' 'trial_xmid'
				# Fifth, add the Trial Number to the correct interval.
				select TextGrid 'textGrid_object$'
				Set interval text... 'tg_trial' 'trial_interval' 'trial_number$'
				# Sixth, add the boundaries of the trial to the Word tier
 				# of the TextGrid
				select TextGrid 'textGrid_object$'
				Insert boundary... 'tg_word' 'trial_xmin'
				Insert boundary... 'tg_word' 'trial_xmax'
				# Seventh, determine the interval on the Word tier of the
				# TextGrid where the Target Word will be added.
				select TextGrid 'textGrid_object$'
				word_interval = Get interval at time... 'tg_word' 'trial_xmid'
				# Eighth, add the Target Word to the correct interval on 
				# the Word tier of the TextGrid.
				select TextGrid 'textGrid_object$'
				Set interval text... 'tg_word' 'word_interval' 'trial_word$'
				# Ninth, loop through the rows of the Trial Segmentations
				# table, adding boundaries on the Repetition tier and a 
				# repetition number for each segmentation.
				for repetition_number to n_segmentations
					repetition_number$ = "'repetition_number'"
					# A)	Get the xmin and xmax of the repetition from the
					#	Trial Segmentations table
					select Table 'trial_segmentations_table$'
					repetition_xmin = Get value... 'repetition_number' 'tl_xmin$'
					repetition_xmax = Get value... 'repetition_number' 'tl_xmax$'
					repetition_xmid = ('repetition_xmin' + 'repetition_xmax') / 2
					# B)	Add the boundaries to the Repetition tier.
					select TextGrid 'textGrid_object$'
					Insert boundary... 'tg_repetition' 'repetition_xmin'
					Insert boundary... 'tg_repetition' 'repetition_xmax'
					# C) Determine the interval number on the Repetition tier.
					select TextGrid 'textGrid_object$'
					repetition_interval = Get interval at time... 'tg_repetition' 'repetition_xmid'
					# D)	Add the Repetition Number to the correct interval
					#	on the Repetition tier of the TextGrid
					select TextGrid 'textGrid_object$'
					Set interval text... 'tg_repetition' 'repetition_interval' 'repetition_number$'
				endfor
				# Tenth, zoom out so that the segmenter can view the entire
				# trial, and play the trial's duration from the audio file.
				trial_zoom_xmin = 'trial_xmin' - 'trial_zoom_pad'
				if (trial_zoom_xmin < audio_xmin)
					trial_zoom_xmin = audio_xmin
				endif
				trial_zoom_xmax = 'trial_xmax' + 'trial_zoom_pad'
				if (trial_zoom_xmax > audio_xmax)
					trial_zoom_xmax = audio_xmax
				endif
				editor TextGrid 'textGrid_object$'
					Zoom... 'trial_zoom_xmin' 'trial_zoom_xmax'
					Play... 'trial_xmin' 'trial_xmax'
				endeditor
				# Eleventh, prompt the user to confirm the segmentations
				# for the given trial.
				beginPause ("'procedure$' - Wrapping up the current trial.")
   					# Display the Trial Number and the Target Word of the current trial.
					comment ("Current trial: 'trial_number$' ; Target word: 'trial_word$'")
					# Tell the segmenter to do their job.
					comment ("If any modifications need to be made to the segmentations,")
					comment ("	make them manually in the Editor window.")
					comment ("Once you are ready to confirm the segmentations for this")
					comment ("	trial, click 'Next trial'.")
				endPause ("", "Next trial", 2, 1)
				# Twelfth, save the TextGrid object to a text file on
				# the local filesystem.
				select TextGrid 'textGrid_object$'
				Save as text file... 'textGrid_filepath$'
				# Thirteenth, remove the current Trial Segmentations table
				# from the Praat object list.
				select Table 'trial_segmentations_table$'
				Remove
				# Fourteenth, increment the 'n_trials_segmented' variable,
				# and log the update in the Segmentation Log table.
				n_trials_segmented = 'n_trials_segmented' + 1
				select Table 'segmentLog_table$'
				Set numeric value... 1 'sl_segTrials$' 'n_trials_segmented'
				# Fifteenth, update the Segmentation Log table and save
 				# it as a tab-separated file on the local filesystem.
				current_time$ = replace$(date$(), " ", "_", 0)
				select Table 'segmentLog_table$'
				Set string value... 1 'sl_endDate$' 'current_time$'
				# Sixteenth, save the progress that has been made so far.
				# I.e., save the Segmentation Log table to a tab-separated
				# file on the local filesystem.
				select Table 'segmentLog_table$'
				Save as tab-separated file... 'segmentLog_filepath$'
				# Seventeenth, check that the trial that was just segmented
 				# and confirmed isn't the last trial on the Word List table.
				if (trial < n_trials)
					# If there are still trials on the Word List table...
					# A) Increment the 'trial' variable to the next trial.
					trial = 'trial' + 1
					# B)	Get the current Trial Number and Target Word of the
					#	new trial.
					select Table 'wordList_table$'
					trial_number$ = Get value... 'trial' 'wl_trial$'
					trial_word$   = Get value... 'trial' 'wl_word$'
					# C)	Initialize a Praat Table object that records the xmin and 
					#	xmax of each segmentation for the current trial.
					if trial_word$ == "teddy bear"
						trial_segmentations_table$ = "Trial_'trial_number$'_teddy_bear"
					else
  						trial_segmentations_table$ = "Trial_'trial_number$'_'trial_word$'"
					endif
					Create Table with column names... 'trial_segmentations_table$' 0 'tl_xmin$' 'tl_xmax$'
					# D)	Determine whether the current trial is a part of a
					#	multi-trial STS, and if so its position in the STS.
 					#	D1)	First, check whether the current trial continues
					#		an STS that includes the previous trial.
					previous_trial = 'trial' - 1
					select Table 'wordList_table$'
					previous_trial_word$ = Get value... 'previous_trial' 'wl_word$'
					if (trial_word$ == previous_trial_word$)
						trial_in_STS = 1
						position_in_STS = 'position_in_STS' + 1
					else
					#	D2)	If the current Target Word doesn't match the previous
					#		Target Word, then check the next Target Word.
  						next_trial = 'trial' + 1
						if (next_trial < n_trials)
							select Table 'wordList_table$'
							next_trial_word$ = Get value... 'next_trial' 'wl_word$'
							if (trial_word$ == next_trial_word$)
								trial_in_STS = 1
							else
								trial_in_STS = 0
							endif
						else
							trial_in_STS = 0
						endif
						position_in_STS = 1
					endif
					# E)	Use the 'position_in_STS' variable to determine the
					# 	suffix of the current trial's Context labels.
					if (position_in_STS == 1)
						context_suffix$ = ""
					else
						context_suffix$ = "_ConsecTarget'position_in_STS'"
					endif
					# F)	Set the xmin and xmax of the Editor window, in reference
					# 	to the xmax value of the previously segmented and
					#	confirmed trial.
					segment_window_xmin = 'trial_xmax' - 'segment_newTrial_xmin_pad'
					if (segment_window_xmin < audio_xmin)
						segment_window_xmin = audio_xmin
					endif
					segment_window_xmax = 'trial_xmax' + 'segment_newTrial_xmax_pad'
					if (segment_window_xmax > audio_xmax)
						segment_window_xmax = audio_xmax
					endif
					editor TextGrid 'textGrid_object$'
						Zoom... 'segment_window_xmin' 'segment_window_xmax'
					endeditor
					# G)	Finally, send the segmenter back to the top-level
					#	selection menu
					segmentation_window_open = 1
				else
					# If the trial that was just segmented and confirmed is
					# the last trial on the Word List table...
### MEB: commenting out most of this part.
					# Prompt the segmenter to listen to the remaining portion
					# of the audio file and anonymize any portions that need it.
#					anonymize_action = 0
#					in_anonymizing_audio_end_loop = 1
#					while (in_anonymizing_audio_end_loop)
#						beginPause ("'procedure$' - Last trial has been segmented.")
#						comment ("You've finished segmenting all the trials in this audio recording.")
#						comment ("Please listen to the remaining portion of the audio file and")
#						comment ("	mute any subject-identifying information.")
#						comment ("To mute an interval of the audio recording, first highlight it" )
#						comment ("	in the Editor window, and then click 'Mute selection'.")
#						comment ("If you've reached the end of the audio recording, click 'I've finished'.")
#					anonymize_action = endPause ("", "Mute selection", "I've finished", 2, 1)
#					# Use the segmenter's button selection to determine
#					# what to do next.
#					if anonymize_action == 2  
#						# If the segmenter chooses to 'Mute selection', then call the
#						#  procedure that does that.  
#						call anonymizeInterval
#
#					elsif anonymize_action == 3
						# If the segmenter has 'Finished'...
						beginPause ("'procedure$' - Wrapping up this session.")
							comment ("You've finished everything for subject 'experimental_ID$'!")
							comment("	Thank you for your hard work.")
							comment ("To finalize all of your work, click 'Save and clear Praat objects'.")
						endPause ("Save and clear Praat objects", "Back", 1, 1)
						# Add the current time to the Segmentation Log table,
						# and then save it to the local filesystem.
						current_time$ = replace$(date$(), " ", "_", 0)
 						select Table 'segmentLog_table$'
						Set string value... 1 'sl_endDate$' 'current_time$'
						Save as tab-separated file... 'segmentLog_filepath$'
						# Save the Audio-Anonymization Log table to the local
						# filesystem.
#						select Table 'audioLog_table$'
#						Save as tab-separated file... 'audioLog_filepath$'
#						Remove
						# Save the TextGrid object to the local filesystem.
						select TextGrid 'textGrid_object$'
						Save as text file... 'textGrid_filepath$'
						Remove
						# Remove the Word List table from the Praat objects list.
						select Table 'wordList_table$'
						Remove
						# Remove the audio Sound from the Praat objects list.
						select Sound 'audio_sound$'
						Remove
                        # PFR: Also save the completed Segmentation Log table to 
                        #      /Segmentation/ToCheck  (next 7 lines)
                        toCheck_dir$ = replace_regex$: segmentLog_dir$,
                                                   ... "Segmenters.*Logs",
                                                   ... "ToCheck",
                                                   ... 1
                        toCheck_filepath$ = toCheck_dir$ + "/" + segmentLog_filename$
                        select Table 'segmentLog_table$'
                        Save as tab-separated file... 'toCheck_filepath$'
						Remove
                        Remove
						# Break out of the in_anonymizing_audio_end_loop
#						in_anonymizing_audio_end_loop = 0
#					endif
#				endwhile
#				# Break out of the segmentation_window_open loop
				segmentation_window_open = 0
			endif
		else

# [TOP-LEVEL ACTION]
# [QUIT SEGMENTING]
			# If the segmenter chooses to 'Quit segmenting'
			quit_action = 0
				beginPause ("'procedure$' - Confirm that you want to end this session.")
					comment ("Thank you for your hard work during this segmentation session!")
					comment ("If you're sure that you would like to quit, ")
					comment ("	click 'Save and clear'.")
					comment ("If you accidently clicked 'Quit segmenting',")
					comment ("	click 'Back' to return to segmenting subject 'experimental_ID$'.")
				quit_action = endPause("", "Save and clear", "Back", 2, 1)
				if quit_action == 2
					# Add the current time to the Segmentation Log table,
					# and then save it to the local filesystem.
					current_time$ = replace$(date$(), " ", "_", 0)
					select Table 'segmentLog_table$'
					Set string value... 1 'sl_endDate$' 'current_time$'
					Save as tab-separated file... 'segmentLog_filepath$'
					Remove
					# Save the Audio-Anonymization Log table to the local
					# filesystem.
					select Table 'audioLog_table$'
					Save as tab-separated file... 'audioLog_filepath$'
					Remove
					# Save the TextGrid object to the local filesystem.
					select TextGrid 'textGrid_object$'
					Save as text file... 'textGrid_filepath$'
					Remove
					# Remove the Word List table from the Praat objects list.
					select Table 'wordList_table$'
					Remove
					# Remove the audio Sound from the Praat objects list.
					select Sound 'audio_sound$'
					Remove
					# Remove the Trial Segmentations table.
					select Table 'trial_segmentations_table$'
					Remove
					# Break out of the segmentation_window_open loop.
					segmentation_window_open = 0
				elsif quit_action == 3
					# Stay in the segmentation_window_open loop.
					segmentation_window_open = 1
				endif
			endif
		endif
	endwhile
endif


#===============================================#
#  Procedure definitions                                                                                   #
#===============================================#

procedure anonymizeInterval
	# Clear the action-selection variable that controls how the script behaves 
	# within this block of code.
	mute_action = 0
	# Send the segmenter into a while-loop within which they have the 
	# option to do one of the following actions:
	#   1. Confirm the boundaries of the selection to be muted
	#   2. Update the boundaries of the selection to be muted
	#   3. Go back to the top-level selection menu
	in_mute_selection_loop = 1
	while (in_mute_selection_loop)
		# Get the xmin and xmax boundaries of the selection to be muted.
		editor TextGrid 'textGrid_object$'
			mute_selection_xmin = Get start of selection
			mute_selection_xmax = Get end of selection
			mute_selection_dur  = Get selection length
		endeditor
		# The selection can only be muted if it is an interval, - ie. has nonzero duration.
		# Check the duration of the to-be-muted selection.
		if (mute_selection_dur > 0)
			# If the duration of the to-be-muted selection is
			# greater than zero, ie. the selection is an interval
			# rather than a point, then zoom to this selection and
			# play it for the segmenter.
			# The xmin and xmax of the zoom window are determined by
			# the 'mute_selection_zoom_pad' variable.
			mute_selection_zoom_xmin = 'mute_selection_xmin' - 'mute_selection_zoom_pad'
			mute_selection_zoom_xmax = 'mute_selection_xmax' + 'mute_selection_zoom_pad'
			# Check that the xmin of the zoom window for the to-be-muted 
			# selection is not less than the xmin of the audio.
			if (mute_selection_zoom_xmin < audio_xmin)
				mute_selection_zoom_xmin = audio_xmin
			endif
			# Check that the xmax of the zoom window for the to-be-muted selection 
			# is not greater than the xmax of the audio.
			if (mute_selection_zoom_xmax > audio_xmax)
				mute_selection_zoom_xmax = audio_xmax
			endif
			# Zoom and play in the Editor window.
			editor TextGrid 'textGrid_object$'
				Zoom... mute_selection_zoom_xmin mute_selection_zoom_xmax
				Play... mute_selection_xmin mute_selection_xmax
			endeditor
			# Prompt the segmenter to confirm the selection to be muted.
			beginPause ("'procedure$' - Muting the selected interval.")
 				comment ("(1)	If this is the interval of the recording that you would")
				comment(" 	like to mute, click 'Mute'.")
				comment ("(2)	Otherwise, adjust the boundaries of the selection in")
				comment("	the Editor window, and then click 'Adjust'.")
			mute_action = endPause ("", "Mute", "Adjust", "Back", 2, 1)
			# Use the 'mute_action' variable to determine what happens next.
			if mute_action == 2
				# If the segmenter chooses to 'Mute selection'...
				# First, add the xmin and xmax of the mute-selection
				# to the Audio-Anonymization Log table.
   				select Table 'audioLog_table$'
				Append row
				n_anonymizations = Get number of rows
				Set numeric value... 'n_anonymizations' 'al_xmin$' 'mute_selection_xmin'
				Set numeric value... 'n_anonymizations' 'al_xmax$' 'mute_selection_xmax'
###### [ACTION ITEM]  This zeroing out is not saved and it does not affect the copy of the 
# 	feedback to Sound object that is being viewed and played in the Edit window, so it does 
#	not give the segmenter.  Could we replace it with one of the following actions?
# 		(1) Add a Muted tier for demarcating muted intervals
# 		(2) Add notes to the SegmNotes tier for start and end of the muted interval
				# Second, mute the mute-selection in the audio Sound object.
#				select Sound 'audio_sound$'
#				Set part to zero... 'mute_selection_xmin' 'mute_selection_xmax' at nearest zero crossing

				# Second, insert notes on the notes tier marking the start and end 
				# of the muted selection.
				select TextGrid 'textGrid_object$'
				Insert point... 'tg_notes' 'mute_selection_xmin' <mute_on>
				Insert point... 'tg_notes' 'mute_selection_xmax' <mute_off>

				# Third, save the audio-anonymization log.
				select Table 'audioLog_table$'
				Save as tab-separated file... 'audioLog_filepath$'
				# Finally, break out of the 'mute selection' loop.
				in_mute_selection_loop = 0
			elsif mute_action == 3
				# If the segmenter chooses to 'Update boundaries',
				# stay in the 'mute selection' while-loop.
				in_mute_selection_loop = 1
			elsif mute_action == 4
				# If the segmenter chooses to go 'Back' to the top-level
				# selection menu, then break from the 'mute selection'
				# while-loop.
				in_mute_selection_loop = 0
			endif
		else
			# If the duration of the to-be-muted selection is
			# equal to zero, ie. the selection is a point rather
			# than an interval, then inform the segmenter that only
			# intervals can be muted, and prompt them to update 
			# the boundaries of the selection or go back to the 
			# top-level selection menu.
			beginPause ("'procedure$' - Warning 2: trying to mute a single point.")
				comment ("You're trying to mute a single point in the audio recording,")
				comment ("	rather than an interval.")
				comment ("To mute an interval of the audio recording, first highlight it")
				comment ("	in the Editor window, and then click 'Mute selection'.")
			mute_action = endPause ("", "Mute selection", "Back", 2, 1)
			if mute_action == 2
				# If the segmenter chooses to 'Mute selection', then
				# stay in the 'mute selection' while-loop.
				in_mute_selection_loop = 1
			elsif mute_action == 3
				# If the segmenter chooses to go 'Back' to the top-level selection menu, 
				# then break out of the 'mute selection' while-loop.
   				in_mute_selection_loop = 0
   			endif
   		endif
   	endwhile
endproc
