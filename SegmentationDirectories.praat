# SegmentationDirectories.praat

# Version history:

# Author: Patrick Reidy
# Date: July 03, 2013
# Comment:  Added example SegmentationDirectories.praat, which must be edited to 
# match the local filesystem from which Segmentation.praat is run.

# Author: Mary Beckman
# Date: October 30, 2013
# Comment: Inserted comments from the version that Tristan Mahr had made for local
# use on the Waisman Center server, and then expanded on these comments so that 
# Jamie Byrne, Hannele Nicholson, and Rose Crooks can see how the process can be
# structured so that there is no copying of files into the segmenter's working directory.

# Directories that will not be affected by the process of segmentation.

# The directory from where audio files are read.
audio_dir$ = "L:/DataAnalysis/RealWordRep/TimePoint1/Recordings"

# The directory from where word list tables are read.
wordList_dir$ = "L:/DataAnalysis/RealWordRep/TimePoint1/WordLists"

# Directories that will changed by the process of segmentation.

# The directory to where anonymized audio log files are written.
audioAnon_dir$ = "L:/DataAnalysis/RealWordRep/TimePoint1/Recordings/Anonymized"

# The directory to where the ...SegmentationLog.txt file is written when a segmenter first  
# starts segmenting a file and from where the segmentation log is read on subsequent 
# segmentation sessions for a file in process.
segmentLog_dir$ = "L:/Segmenting/Segmenters/BS/Logs"

# The directory to where the ...segm.TextGrid file is written for when a segmenter first  
# starts segmenting a file and from where the segmentation textgrid file is read on  
# subsequent segmentation sessions for a file in process .
textGrid_dir$ = "L:/Segmenting/Segmenters/BS/Segmentation"

