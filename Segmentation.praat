# Author:       Patrick Reidy             <reidy@ling.ohio-state.edu>
# Affiliations: Learning to Talk          <learningtotalk.org>
#               The Ohio State University <linguistics.osu.edu>



#====================#
#  Global variables  #
#====================#

# Directory names for navigating the local filesystem.
# The following 'include' call creates the following global variables:
#   audio_dir$      (where original .wav files are saved)
#   audioAnon_dir$  (where Audio-Anonymization Logs are saved)
#   segmentLog_dir$ (where Segmentation Logs are saved)
#   textGrid_dir$   (where Segmentation .TextGrid files are saved)
#   wordList_dir$   (where Word List tables are saved)
include SegmentationDirectories.praat

# Task
task$ = "RealWordRepetition: Segmentation"

# Word List table columns
wl_trial  = 1
wl_trial$ = "TrialNumber"
wl_abbr   = 2
wl_abbr$  = "Abbreviation"
wl_word   = 3
wl_word$  = "Word"
wl_wdbet  = 4
wl_wdbet$ = "WorldBet"
wl_cons   = 5
wl_cons$  = "TargetC"
wl_vowel  = 6
wl_vowel$ = "TargetV"
wl_frame  = 7
wl_frame$ = "Frame"
wl_type   = 8
wl_type$  = "TrialType"
wl_audio  = 9
wl_audio$ = "AudioPrompt"
wl_image  = 10
wl_image$ = "PicturePrompt"
wl_xmin   = 11
wl_xmin$  = "PictureOnset"
wl_xmax   = 12
wl_xmax$  = "ITIOnset"

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





#====================================================================#
#  Start-up procedure                                                #
#====================================================================#

# Name the nodes of the start-up procedure.
startup_node_quit$     = "quit"
startup_node_segment$  = "segment"
startup_node_github$   = "github"
startup_node_initials$ = "initials"
startup_node_subject$  = "subject"
startup_node_segdata$  = "segdata"


# The start-up procedure begins by checking that the segmenter fetched
# the latest version of the segmentation script from GitHub before
# beginning the current segmentation session.
# That is, the "start node" of the start-up procedure is the node
# 'startup_node_github$'
startup_node$ = startup_node_github$


# The start-up procedure runs so long as the user has not quit or
# finished and continued to the segmentation procedure.
while (startup_node$ != startup_node_quit$) and (startup_node$ != startup_node_segment$)
  # [NODE]
  # Remind the segmenter to use the most recent version of the script.
  if startup_node$ == startup_node_github$
    beginPause ("'task$'")
      comment ("Did you fetch the latest version of this script from GitHub before you began segmenting?")
    button = endPause ("No, I need to fetch the script from GitHub", "Yes, I'm using the current version", 2, 1)
    # Use the 'button' variable to determine which node to transition to next.
    if button == 1
      # If the segmenter is not using the most recent version of the 
      # segmentation script (ie. button = 1), direct them to GitHub 
      # (possibly by way of the Segmentation Handbook).
      beginPause ("'task$'")
        comment ("Once you have fetched the latest version of the segmentation script from GitHub, restart Praat and run the script in a new Praat session.")
        comment ("You can consult the Segmentation Handbook for instructions on how to fetch from GitHub.")
      endPause ("Close this Segmentation session", 1, 1)
      # And then transition to the 'startup_node_quit$' node.
      startup_node$ = startup_node_quit$
    else
      # If the segmenter is using the most recent version of the 
      # segmentation script (ie. button = 2), then transititon to
      # the 'startup_node_initials$' node for them to enter their
      # initials.
      startup_node$ = startup_node_initials$
    endif
  
  # [NODE]
  # Prompt the segmenter to enter their initials.
  elsif startup_node$ == startup_node_initials$
    beginPause ("'task$'")
      comment ("Please enter your initials in the field below.")
      word    ("Your initials", "")
    button = endPause ("Back", "Quit", "Continue", 3, 1)
    segmenters_initials$ = your_initials$
    # Use the 'button' variable to determine which node to transition to next.
    if button == 1
      # If the segmenter has a crisis of conscience from having lied
      # about fetching the segmentation script from GitHub, and they
      # wish to return to the previous step of the start-up procedure 
      # (button = 1), then transition to the 'startup_node_github$' node.
      startup_node$ = startup_node_github$
    elsif button == 2
      # If the segmenter must quit this segmentation session prematurely
      # (button = 2), transition to the 'startup_node_quit$' node.
      startup_node$ = startup_node_quit$
    else
      # If the segmenter has entered their initials and wishes to
      # continue to the next step of the start-up procedure (button = 3),
      # transition to the 'startup_node_experiment$' node so that they
      # can choose the experimental ID of the subject whose audio
      # recording they would like to segment.
      startup_node$ = startup_node_subject$
    endif
  
  # [NODE]
  # Prompt the segmenter to choose the subject's experimental ID.
  elsif startup_node$ == startup_node_subject$
    # Create a Strings object from the list of .wav files in the
    # audio directory.  If the segmentation script is currently being
    # run on a Macintosh or UNIX platform, then it is also necessary
    # to append a list of all the .WAV files in the audio directory.
    Create Strings as file list... wavFiles 'audio_dir$'/*.wav
    if (macintosh or unix)
      Create Strings as file list... files2 'audio_dir$'/*.WAV
      select Strings wavFiles
      plus Strings files2
      Append
      select Strings wavFiles
      plus Strings files2
      Remove
      select Strings appended
      Rename... wavFiles
    endif
    # The list of all the .wav (and .WAV) files in the audio directory
    # has been created.  Now sort it alpha-numerically.
    select Strings wavFiles
    Sort
    # Open a dialog box and prompt the user to select the subject's
    # experimental ID from a drop-down menu.  
    beginPause ("'task$'")
      comment ("Choose the subject's experimental ID from the menu below.")
      # Create the drop-down menu by looping through the Strings
      # object 'wavFiles'.
      # Making a selection from this optionMenu creates the string
      # variable 'experimental_ID$'.
      select Strings wavFiles
      n_wav_files = Get number of strings
      optionMenu ("Experimental ID", 1)
      for n_file to n_wav_files
        select Strings wavFiles
        # Get the n-th filename from the Strings object 'wavFiles'.
        wav_filename$ = Get string... n_file
        # 'wav_filename$' has the form "RealWordRep_::SubjectID::.(wav|WAV)".
        # The extractWord$ function returns all characters to the right of the
        # first occurrence of '_', which in this case is the only occurrence
        # of '_'.
        exp_id$ = extractWord$(wav_filename$, "_")
        # The file extension (.wav or .WAV) is removed by calling the
        # left$ function with a second argument equal to four characters
        # less than the length of 'exp_id$'.
        exp_id$ = left$(exp_id$, length(exp_id$) - 4)
        # From the experimental ID, parse the subject ID, the ###X
        # code at the beginning of the experimental ID.
        subject_id$ = left$(exp_id$, 4)
        # Use the 'subject_id$' variable to determine whether the
        # 'exp_id$' should be displayed as a possible choice to 
        # segment.  Some subjects don't have associated word list
        # tables, and so should not be available for segmentation
        # with this script.
        # These are subjects: 002L, 004L, 005L, 007L & 026L
        if (subject_id$ != "002L") and (subject_id$ != "004L") and (subject_id$ != "005L") and (subject_id$ != "007L") and (subject_id$ != "026L")
          option ("'exp_id$'")
        endif
      endfor
      # Once the optionMenu has been constructed, remove the Strings 
      # object 'wavFiles' from the Praat object list,
      select Strings wavFiles
      Remove
    button = endPause ("Back", "Quit", "Continue", 3, 1)
    # Use the 'button' variable to determine which node to transition to next.
    if button == 1
      # If the segmenter wishes to go to the previous step in the
      # start-up procedure (button = 1), then transition to the
      # 'startup_node_initials$' node.
      startup_node$ = startup_node_initials$
    elsif button == 2
      # If the segmenter wishes to quit this segmentation session
      # prematurely (button = 2), then transition to the
      # 'startup_node_quit$' node.
      startup_node$ = startup_node_quit$
    else
      # If the segmenter wishes to continue to the next step in the
      # start-up procedure (ie. loading the data files necessary to
      # segment an audio recording) (button = 3), then transition to
      # the 'startup_node_segdata$' node.
      startup_node$ = startup_node_segdata$
    endif

  # [NODE]
  # Respectively load or create all of the data objects that are
  # necessary to segment an audio file.
  # These data objects include:
  #   1. A word list table
  #   2. An audio file
  #   3. A segmentation log
  #   4. An audio-anonymization log
  #   5. A TextGrid
  elsif startup_node$ == startup_node_segdata$
    # [WORD LIST TABLE]
    # Make string variables for the word list table's basename,
    # filename, and filepath on the local filesystem, using the
    # 'subject's experimental ID, which was chosen during the previous
    # step in the start-up procedure (see the code block for the
    # 'startup_node_subject$' node above) and the 'wordList_dir$' 
    # variable that is imported from the '...Directories.praat' file.
    wordList_basename$ = "RealWordRep_'experimental_ID$'_WordList"
    wordList_filename$ = "'wordList_basename$'.txt"
    wordList_filepath$ = "'wordList_dir$'/'wordList_filename$'"
    wordList_table$    = "'experimental_ID$'_WordList"
    # Determine whether a Word List table exists on the local file
    # system.
    wordList_exists = fileReadable(wordList_filepath$)
    if (wordList_exists)
      # Read the word list table from the local filesystem, and then
      # rename it according to the 'wordList_table$' variable.
      Read Table from tab-separated file... 'wordList_filepath$'
      select Table 'wordList_basename$'
      Rename... 'wordList_table$'
      # Determine the number of trials (both Familiarization and Test
      # trials) in this experimental session.
      select Table 'wordList_table$'
      n_trials = Get number of rows
      # [AUDIO FILE]
      # Determine which .wav (or .WAV) file in the 'audio_dir$'
      # directory corresponds to the experimental ID of the subject
      # presently being segmented.
      Create Strings as file list... wavFile 'audio_dir$'/*'experimental_ID$'.wav
      if (macintosh or unix)
        Create Strings as file list... wavFile2 'audio_dir$'/*'experimental_ID$'.WAV
        select Strings wavFile
        plus Strings wavFile2
        Append
        select Strings wavFile
        plus Strings wavFile2
        Remove
        select Strings appended
        Rename... wavFile
      endif
      # The resulting Strings object 'wavFile' should list a single
      # .wav (or .WAV) filename that corresponds to the correct
      # audio file for this subject.
      # Check whether the Strings object 'wavFile' includes at least
      # one filename.
      select Strings wavFile
      n_wavs = Get number of strings
      if (n_wavs > 0)
        # If the Strings object 'wavFile' has at least one filename,
        # use the filename in this Strings object to make string
        # variables for the filename, basename, and filepath of the
        # audio file on the local filesystem.
        select Strings wavFile
        audio_filename$ = Get string... 1
        audio_basename$ = left$(audio_filename$, length(audio_filename$) - 4)
        audio_filepath$ = "'audio_dir$'/'audio_filename$'"
        audio_sound$    = "'experimental_ID$'_Audio"
        # Remove the Strings object from the Praat object list.
        select Strings wavFile
        Remove
        # Read in the audio file, and rename it to the value of the
        # 'audio_sound$' string variable.
        Read from file... 'audio_filepath$'
        select Sound 'audio_basename$'
        Rename... 'audio_sound$'
        # [SEGMENTATION LOG]
        # Make string variables for the segmentation log's basename,
        # filename, and filepath on the local filesystem, using the
        # 'subject's experimental ID, which was chosen during the previous
        # step in the start-up procedure (see the code block for the
        # 'startup_node_subject$' node above) and the 'segmentLog_dir$' 
        # variable that is imported from the '...Directories.praat' file.
        segmentLog_basename$ = "RealWordRep_'experimental_ID$'_'segmenters_initials$'segmentLog"
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
          # the current segmentation session is a continuation of a
          # previous session for the same subject, and so there should
          # also be  an anonymized-audio log file, and a segmentation
          # TextGrid that can be read from the local filesystem.
          # [AUDIO-ANONYMIZATION LOG]
          # Make string variables for the audio-anonymization log's
          # basename, filename, and filepath on the local filesystem.
          audioLog_basename$ = "RealWordRep_'experimental_ID$'_AudioLog"
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
            # [SEGMENTATION TEXTGRID]
            # Make string variables for the segmentation TextGrid's
            # basename, filename, and filepath on the local filesystem.
            textGrid_basename$ = "RealWordRep_'experimental_ID$'_'segmenters_initials$'segm"
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
              beginPause ("'task$'")
                comment ("You seem to be continuing a segmentation session for subject 'experimental_ID$'."
                comment ("But there doesn't seem to be a segmentation TextGrid for this subject on the local filesystem.")
                comment ("Check that the following directory exists on the local filesystem:")
                comment ("'textGrid_dir$'")
                comment ("Also check that this directory contains a file named RealWordRep_'experimental_ID$'_'segmenters_initials$'segm.TextGrid"
                comment ("You may have to edit the textGrid_dir$ variable in the ...Directories.praat file before restarting this segmentation session.")
              endPause ("Quit segmenting & check filesystem", 1, 1)
              # Transition to the 'startup_node_quit$' node.
              startup_node$ = startup_node_quit$
            endif
          else
            # If the audio-anonymization log doesn't exist on the local
            # filesystem, first display an error message to the segmenter,
            # and then quit this segmentation session.
            beginPause ("'task$'")
              comment ("You seem to be continuing a segmentation session for subject 'experimental_ID$'."
              comment ("But there doesn't seem to be an audio-anonymization log for this subject on the local filesystem.")
              comment ("Check that the following directory exists on the local filesystem:")
              comment ("'audioAnon_dir$'")
              comment ("Also check that this directory contains a file named RealWordRep_'experimental_ID$'_AudioLog.txt."
              comment ("You may have to edit the audioAnon_dir$ variable in the ...Directories.praat file before restarting this segmentation session.")
            endPause ("Quit segmenting & check filesystem", 1, 1)
            # Transition to the 'startup_node_quit$' node.
            startup_node$ = startup_node_quit$
          endif
        else
          # If a segmentation log doesn't exist on the local file system,
          # then this is the segmenter has not made any progress on
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
          audioLog_basename$ = "RealWordRep_'experimental_ID$'_AudioLog"
          audioLog_filename$ = "'audioLog_basename$'.txt"
          audioLog_filepath$ = "'audioAnon_dir$'/'audioLog_filename$'"
          audioLog_table$    = "'experimental_ID$'_AudioLog"
          # Create the audio-anonymization log as a Praat Table with
          # 0 rows.
          Create Table with column names... 'audioLog_table$' 0 'al_xmin$' 'al_xmax$'
          # [SEGMENTATION TEXTGRID]
          # Make string variables for the segmentation TextGrid's
          # basename, filename, and filepath on the local filesystem.
          textGrid_basename$ = "RealWordRep_'experimental_ID$'_'segmenters_initials$'segm"
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
      else
        # If the Strings object 'wavFile' has no filenames on it,
        # then the script was unable to find a candidate .wav file.
        # Display an error message to the segmenter and then
        # quit this segmentation session.
        beginPause ("'task$'")
          comment ("There doesn't seem to be an audio file for subject 'experimental_ID$' on the local filesystem.")
          comment ("Check that the following directory exists on the local filesystem:")
          comment ("'audio_dir$'")
          comment ("Also check that this directory contains a wave file whose basename is RealWordRep_'experimental_ID$'.")
          comment ("You may have to edit the audio_dir$ variable in the ...Directories.praat file before restarting this segmentation session.")
        endPause ("Quit segmenting & check filesystem", 1, 1)
        # Transition to the 'startup_node_quit$' node.
        startup_node$ = startup_node_quit$
      endif
    else
      # If there is no Word List table on the local filesystem,
      # first display an error message to the segmenter and then
      # quit this segmentation session.
      beginPause ("'task$'")
        comment ("There doesn't seem to be a word list table for this subject on the local filesystem.")
        comment ("Check that the following directory exists on the local filesystem:")
        comment ("'wordList_dir$'")
        comment ("Also check that this directory contains a word list table whose filename is RealWordRep_'experimental_ID$'_WordList.txt.")
        comment ("You may have to edit the wordList_dir$ variable in the ...Directories.praat file before restarting this segmentation session.")
      endPause ("Quit segmenting & check filesystem", 1, 1)
      # Transition to the 'startup_node_quit$' node.
      startup_node$ = startup_node_quit$
    endif  
  endif
endwhile
#=============================#
#  End of start-up procedure  #
#=============================#





#====================================================================#
#  Segmentation procedure                                            #
#====================================================================#

# The Segmentation procedure is run only if the Start-Up procedure
# finished on the 'startup_node_segment$' node.
# Check whether the Start-Up procedure finished on the 
# 'startup_node_segment$' node.
if (startup_node$ == startup_node_segment$)
  # Initialize a 'trial' variable, which denotes the current row of
  # the Word List table, by getting the number of trials already
  # segmented.
  select Table 'segmentLog_table$'
  n_trials_segmented = Get value... 1 'sl_segTrials$'
  trial = 'n_trials_segmented' + 1
  
  # Initialize a variable for the Trial Number of the current trial.
  # Note that the Trial Number differs from the 'trial' variable
  # in that the 'trial' variable denotes the row of the word list
  # table, while the Trial Number is an alphanumeric code that denotes
  # whether the trial was Familiarization or Test, and then the
  # ordinal number within each of the trial types---eg. Fam2 or Test4.
  select Table 'wordList_table$'
  trial_number$ = Get value... 'trial' 'wl_trial$'
  
  # Initialize a variable for the Target Word of the current trial.
  select Table 'wordList_table$'
  trial_word$ = Get value... 'trial' 'wl_word$'
  
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
      # If the current and next trials ahve the same Target WOrd,
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
      # Target Word, then the current trial is a part of a multi-trial
      # STS.
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
  
  # Initialize a Praat Table object that records the xmin and xmax
  # of each segmentation for the current trial.
  if trial_word$ == "teddy bear"
    trial_segmentations_table$ = "Trial_'trial_number$'_teddy_bear"
  else 
    trial_segmentations_table$ = "Trial_'trial_number$'_'trial_word$'"
  endif
  Create Table with column names... 'trial_segmentations_table$' 0 'tl_xmin$' 'tl_xmax$'
  
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
  
  # Open an Editor window.
  select TextGrid 'textGrid_object$'
  plus Sound 'audio_sound$'
  Edit
  
  # Set the view range of the Editor window to the initial values
  # of 'segment_window_xmin' and 'segment_window_xmax'
  editor TextGrid 'textGrid_object$'
    Zoom... 'segment_window_xmin' 'segment_window_xmax'
  endeditor
  
  # Initialize a switch that keeps the segmentation menu open so long
  # as the segmenter has neither finished nor quit segmenting.
  segmentation_window_open = 1
  
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
    # segmenting a given trial, then they do not have he option to
    # 'Quit segmenting'.  Conversely, if they have not segmented
    # a presentation/production for a given trial, then they do not
    # have the option to 'Finish current trial'
    # The determination of whether the segmenter has the option 
    # to 'Finish current trial' or 'Quit segmenting' is made by
    # looking at whether the Table 'trial_segmentations_table$' has
    # had any rows added to it or not.
    select Table 'trial_segmentations_table$'
    n_segmentations = Get number of rows
    beginPause ("'task$'")
      # Display the Trial Number and the Target Word of the current
      # trial.
      comment ("Current trial: 'trial_number$'")
      comment ("Target word: 'trial_word$'")
      # If the current trial is a part of an STS, display a warning
      # message to the segmenter.
      if (trial_in_STS)
        comment ("ATTENTION! The current trial is a part of a multi-trial sequence in which the same target word was elicited.")
        comment ("You may have to listen to the preceding and following portions of the audio recording to ensure that you are segmenting the correct trial.")
      endif
      # Display a brief explanation of each button option.
      comment ("To segment an interval of the audio recording, first highlight it in the Editor window, and then click 'Segment selection'.")
      comment ("To mute an interval of the audio recording, first highlight it in the Editor window, and then click 'Mute selection'.")
      if (n_segmentations)
        # If the current trial has already been segmented at least
        # once, then give the segmenter the option to 'Finish current trial'.
        comment ("If you are finished segmenting the current trial, click 'Finish current trial'.")
        action = endPause ("", "Segment selection", "Mute selection", "Finish current trial", 2, 1)
      else
        # If the current trial has not yet been segmented even once,
        # then give the segmenter the option to 'Quit segmenting'.
        comment ("If you would like to quit segmenting at this time, click 'Quit segmenting'.")
        action = endPause ("", "Segment selection", "Mute selection", "Quit segmenting", 2, 1)
      endif
      # Determine what options are made available to the segmenter
      # according to the action that they selected from the top-level
      # menu.
      
      # [TOP-LEVEL ACTION]
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
            beginPause ("'task$'")
              # Display the Trial Number and the Target Word of the current
              # trial.
              comment ("Current trial: 'trial_number$'")
              comment ("Target word: 'trial_word$'")
              # Prompt the segmenter to choose the Context label for the
              # current trial
              comment ("If you would like to segment the current selection, select the appropriate Context label from the menu below and optionally enter a note in the field below.")
              comment ("Then, click 'Segment selection'.")
              optionMenu ("Context", 2)
                option ("NonResponse")
                option ("Response")
                option ("UnpromptedResponse")
                option ("VoicePromptResponse")
              sentence ("Note", "")
              comment ("If you would like to change the boundaries of the selection before adding a Context label, do so in the Editor window, and then click 'Update boundaries'.")
            segment_action = endPause ("", "Segment selection", "Update boundaries", "Back", 2, 1)
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
              # tier, of the interval whose boundaries were just
              # added.
              segment_selection_xmid = ('segment_selection_xmin' + 'segment_selection_xmax') / 2
              select TextGrid 'textGrid_object$'
              context_interval = Get interval at time... 'tg_context' 'segment_selection_xmid'
              # Fifth, add the Context label to the correct interval
              # on the Context tier.
              context_label$ = "'context$''context_suffix$'"
              select TextGrid 'textGrid_object$'
              Set interval text... 'tg_context' 'context_interval' 'context_label$'
              # Sixth, add the Note label to the SegmNotes tier.
              if note$ != ""
                select TextGrid 'textGrid_object$'
                Insert point... 'tg_notes' 'segment_selection_xmid' 'note$'
              endif
              # Seventh, save the TextGrid object to a text file
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
            beginPause ("'task$'")
              comment ("You have only selected a point in the Editor window, but you must select an interval in order to add a segmentation.")
              comment ("To segment an interval of the audio recording, first highlight it in the Editor window, and then click 'Segment selection'.")
            segment_action = endPause ("", "Segment selection", "Back", 2, 1)
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
        
      # [TOP-LEVEL ACTION]
      # [MUTE SELECTION]
      elsif action == 3
        # If the segmenter chooses to 'Mute selection'...
        # Clear the action-selection variable that controls how the
        # script behaves within this block of code.
        mute_action = 0
        # Send the segmenter into a while-loop within which they 
        # have the option to do one of the following actions:
        #   1. Confirm the boundaries of the selection to be muted
        #   2. Update the boundaries of the selection to be muted
        #   3. Go back to the top-level selection menu
        in_mute_selection_loop = 1
        while (in_mute_selection_loop)
          # Get the xmin and xmax boundaries of the selection to be
          # muted.
          editor TextGrid 'textGrid_object$'
            mute_selection_xmin = Get start of selection
            mute_selection_xmax = Get end of selection
            mute_selection_dur  = Get selection length
          endeditor
          # The selection can only be muted if it is an interval,
          # ie. has nonzero duration.
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
            # Check that the xmin of the zoom window for the 
            # to-be-muted selection is not less than the xmin of 
            # the audio.
            if (mute_selection_zoom_xmin < audio_xmin)
              mute_selection_zoom_xmin = audio_xmin
            endif
            # Check that the xmax of the zoom window for the
            # to-be-muted selection is not greater than the xmax
            # of the audio.
            if (mute_selection_zoom_xmax > audio_xmax)
              mute_selection_zoom_xmax = audio_xmax
            endif
             # Zoom and play in the Editor window.
            editor TextGrid 'textGrid_object$'
              Zoom... mute_selection_zoom_xmin mute_selection_zoom_xmax
              Play... mute_selection_xmin mute_selection_xmax
            endeditor
            # Prompt the segmenter to confirm the selection to be
            # muted.
            beginPause ("'task$'")
              comment ("If this is the interval of the recording that you would like to mute, click 'Mute selection'.")
              comment ("Otherwise, adjust the boundaries of the selection in the Editor window, and then click 'Update boundaries'.")
            mute_action = endPause ("", "Mute selection", "Update boundaries", "Back", 2, 1)
            # Use the 'mute_action' variable to determine what happens
            # next.
            if mute_action == 2
              # If the segmenter chooses to 'Mute selection'...
              # First, add the xmin and xmax of the mute-selection
              # to the Audio-Anonymization Log table.
              select Table 'audioLog_table$'
              Append row
              n_anonymizations = Get number of rows
              Set numeric value... 'n_anonymizations' 'al_xmin$' 'mute_selection_xmin'
              Set numeric value... 'n_anonymizations' 'al_xmax$' 'mute_selection_xmax'
              # Second, mute the mute-selection in the audio Sound
              # object.
              select Sound 'audio_sound$'
              Set part to zero... 'mute_selection_xmin' 'mute_selection_xmax' at nearest zero crossing
              # Third, save the audio-anonymization log.
              select Table 'audioLog_table$'
              Save as tab-separated file... 'audioLog_filepath$'
              # Fourth, update the Segmentation Log table and save
              # it as a tab-separated file on the local filesystem.
              current_time$ = replace$(date$(), " ", "_", 0)
              select Table 'segmentLog_table$'
              Set string value... 1 'sl_endDate$' 'current_time$'
              Save as tab-separated file... 'segmentLog_filepath$'
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
            beginPause ("'task$'")
              comment ("You're trying to mute a single point in the audio recording, rather than an interval.")
              comment ("To mute an interval of the audio recording, first highlight it in the Editor window, and then click 'Mute selection'.")
            mute_action = endPause ("", "Mute selection", "Back", 2, 1)
            if mute_action == 2
              # If the segmenter chooses to 'Mute selection', then
              # stay in the 'mute selection' while-loop.
              in_mute_selection_loop = 1
            elsif mute_action == 3
              # If the segmenter chooses to go 'Back' to the top-level
              # selection menu, then break out of the 'mute selection'
              # while-loop.
              in_mute_selection_loop = 0
            endif
          endif
        endwhile
        
      # [TOP-LEVEL ACTION]
      # [FINISH CURRENT TRIAL or QUIT SEGMENTING]
      elsif action == 4
        # Check whether this trial has been segmented.
        if (n_segmentations)
          # [TOP-LEVEL ACTION]
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
            # A) Get the xmin and xmax of the repetition from the
            #    Trial Segmentations table
            select Table 'trial_segmentations_table$'
            repetition_xmin = Get value... 'repetition_number' 'tl_xmin$'
            repetition_xmax = Get value... 'repetition_number' 'tl_xmax$'
            repetition_xmid = ('repetition_xmin' + 'repetition_xmax') / 2
            # B) Add the boundaries to the Repetition tier.
            select TextGrid 'textGrid_object$'
            Insert boundary... 'tg_repetition' 'repetition_xmin'
            Insert boundary... 'tg_repetition' 'repetition_xmax'
            # C) Determine the interval number on the Repetition tier.
            select TextGrid 'textGrid_object$'
            repetition_interval = Get interval at time... 'tg_repetition' 'repetition_xmid'
            # D) Add the Repetition Number to the correct interval
            #    on the Repetition tier of the TextGrid
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
          beginPause ("'task$'")
            # Display the Trial Number and the Target Word of the current
            # trial.
            comment ("Current trial: 'trial_number$'")
            comment ("Target word: 'trial_word$'")
            # Tell the segmenter to do their job.
            comment ("If any modifications need to be made to the segmentations, make them manually in the Editor window.")
            comment ("Once you are ready to confirm the segmentations for this trial, click 'Next trial'.")
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
            # B) Get the current Trial Number and Target Word of the
            #    new trial.
            select Table 'wordList_table$'
            trial_number$ = Get value... 'trial' 'wl_trial$'
            trial_word$   = Get value... 'trial' 'wl_word$'
            # C) Initialize a Praat Table object that records the 
            #    xmin and xmax of each segmentation for the current 
            #    trial.
            if trial_word$ == "teddy bear"
              trial_segmentations_table$ = "Trial_'trial_number$'_teddy_bear"
            else
              trial_segmentations_table$ = "Trial_'trial_number$'_'trial_word$'"
            endif
            Create Table with column names... 'trial_segmentations_table$' 0 'tl_xmin$' 'tl_xmax$'
            # D) Determine whether the current trial is a part of a
            #    multi-trial STS, and if so its position in the STS.
            # D1) First, check whether the current trial continues
            #     an STS that includes the previous trial.
            previous_trial = 'trial' - 1
            select Table 'wordList_table$'
            previous_trial_word$ = Get value... 'previous_trial' 'wl_word$'
            if (trial_word$ == previous_trial_word$)
              trial_in_STS = 1
              position_in_STS = 'position_in_STS' + 1
            else
              # D2) If the current Target Word doesn't match the previous
              #     Target Word, then check the next Target Word.
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
            # E) Use the 'position_in_STS' variable to determine the
            #    suffix of the current trial's Context labels.
            if (position_in_STS == 1)
              context_suffix$ = ""
            else
              context_suffix$ = "_ConsecTarget'position_in_STS'"
            endif
            # F) Set the xmin and xmax of the Editor window, in reference
            #    to the xmax value of the previously segmented and
            #    confirmed trial.
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
            # G) Finally, send the segmenter back to the top-level
            #    selection menu
            segmentation_window_open = 1
          else
            # If the trial that was just segmented and confirmed is
            # the last trial on the Word List table...
            # Prompt the segmenter to listen to the remaining portion
            # of the audio file and anonymize any portions that
            # need it.
            anonymize_action = 0
            in_anonymizing_audio_end_loop = 1
            while (in_anonymizing_audio_end_loop)
              beginPause ("'task$'")
                comment ("You've finished segmenting all the trials in this audio recording.")
                comment ("Please listen to the remaining portion of the audio file and mute any subject-identifying information.")
                comment ("To mute an interval of the audio recording, first highlight it in the Editor window, and then click 'Mute selection'.")
                comment ("If you've reached the end of the audio recording, click 'I've finished'.")
              anonymize_action = endPause ("", "Mute selection", "I've finished", 2, 1)
              # Use the segmenter's button selection to determine
              # what to do next.
              if anonymize_action == 2
                # If the segmenter chooses to 'Mute selection'...
                mute_selection = 0
                in_mute_selection_loop = 1
                while (in_mute_selection_loop)
                  # Get the xmin and xmax boundaries of the selection to be
                  # muted.
                  editor TextGrid 'textGrid_object$'
                    mute_selection_xmin = Get start of selection
                    mute_selection_xmax = Get end of selection
                    mute_selection_dur  = Get selection length
                  endeditor
                  # The selection can only be muted if it is an interval,
                  # ie. has nonzero duration.
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
                    # Check that the xmin of the zoom window for the 
                    # to-be-muted selection is not less than the xmin of 
                    # the audio.
                    if (mute_selection_zoom_xmin < audio_xmin)
                      mute_selection_zoom_xmin = audio_xmin
                    endif
                    # Check that the xmax of the zoom window for the
                    # to-be-muted selection is not greater than the xmax
                    # of the audio.
                    if (mute_selection_zoom_xmax > audio_xmax)
                      mute_selection_zoom_xmax = audio_xmax
                    endif
                     # Zoom and play in the Editor window.
                    editor TextGrid 'textGrid_object$'
                      Zoom... mute_selection_zoom_xmin mute_selection_zoom_xmax
                      Play... mute_selection_xmin mute_selection_xmax
                    endeditor
                    # Prompt the segmenter to confirm the selection to be
                    # muted.
                    beginPause ("'task$'")
                      comment ("If this is the interval of the recording that you would like to mute, click 'Mute selection'.")
                      comment ("Otherwise, adjust the boundaries of the selection in the Editor window, and then click 'Update boundaries'.")
                    mute_action = endPause ("", "Mute selection", "Update boundaries", "Back", 2, 1)
                    # Use the 'mute_action' variable to determine what happens
                    # next.
                    if mute_action == 2
                      # If the segmenter chooses to 'Mute selection'...
                      # First, add the xmin and xmax of the mute-selection
                      # to the Audio-Anonymization Log table.
                      select Table 'audioLog_table$'
                      Append row
                      n_anonymizations = Get number of rows
                      Set numeric value... 'n_anonymizations' 'al_xmin$' 'mute_selection_xmin'
                      Set numeric value... 'n_anonymizations' 'al_xmax$' 'mute_selection_xmax'
                      # Second, mute the mute-selection in the audio Sound
                      # object.
                      select Sound 'audio_sound$'
                      Set part to zero... 'mute_selection_xmin' 'mute_selection_xmax' at nearest zero crossing
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
                    beginPause ("'task$'")
                      comment ("You're trying to mute a single point in the audio recording, rather than an interval.")
                      comment ("To mute an interval of the audio recording, first highlight it in the Editor window, and then click 'Mute selection'.")
                    mute_action = endPause ("", "Mute selection", "Back", 2, 1)
                    if mute_action == 2
                      # If the segmenter chooses to 'Mute selection', then
                      # stay in the 'mute selection' while-loop.
                      in_mute_selection_loop = 1
                    elsif mute_action == 3
                      # If the segmenter chooses to go 'Back' to the top-level
                      # selection menu, then break out of the 'mute selection'
                      # while-loop.
                      in_mute_selection_loop = 0
                    endif
                  endif
                endwhile
              elsif anonymize_action == 3
                # If the segmenter has 'Finished'...
                beginPause ("'task$'")
                  comment ("You've finished everything for subject 'experimental_ID$'! Thank you for your hard work.")
                  comment ("To finalize all of your work, click 'Save and clear Praat objects'.")
                endPause ("Save and clear Praat objects", "Back", 1, 1)
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
                # Remove the Word List table from the Praat objects
                # list.
                select Table 'wordList_table$'
                Remove
                # Remove the audio Sound from the Praat objects list.
                select Sound 'audio_sound$'
                Remove
                # Break out of the in_anonymizing_audio_end_loop
                in_anonymizing_audio_end_loop = 0
              endif
            endwhile
            # Break out of the segmentation_window_open loop
            segmentation_window_open = 0
          endif
        else
          # [TOP-LEVEL ACTION]
          # [QUIT SEGMENTING]
          # If the segmenter chooses to 'Quit segmenting'
          quit_action = 0
          beginPause ("'task$'")
            comment ("Thank you for your hard work during this segmentation session!")
            comment ("If you're sure that you would like to quit, click 'Save and clear Praat objects'.")
            comment ("If you accidently clicked 'Quit segmenting', click 'Back' to return to segmenting subject 'experimental_ID$'.")
          quit_action = endPause("", "Save and clear Praat objects", "Back", 2, 1)
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
            # Remove the Word List table from the Praat objects
            # list.
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


