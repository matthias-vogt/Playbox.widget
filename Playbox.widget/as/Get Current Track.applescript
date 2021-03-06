global artistName, songName, albumName, songRating, songDuration, currentPosition, musicapp, apiKey, songMetaFile
property blackStar : "★"
property whiteStar : "☆"
set metaToGrab to {"artistName", "songName", "albumName", "songDuration", "currentPosition", "coverURL"}

set apiKey to "2e8c49b69df3c1cf31aaa36b3ba1d166"
try
	set mypath to POSIX path of (path to me)
	set AppleScript's text item delimiters to "/"
	set mypath to (mypath's text items 1 thru -2 as string) & "/"
	set AppleScript's text item delimiters to ""
on error e
	logEvent(e)
	return
end try

set songMetaFile to (mypath & "songMeta.plist" as string)

if isMusicPlaying() is true then
	getSongMeta()
	
	writeSongMeta({"currentPosition" & "##" & currentPosition})
	
	if didSongChange() is true then
		writeSongMeta({¬
			"artistName" & "##" & artistName, ¬
			"songName" & "##" & songName, ¬
			"songDuration" & "##" & songDuration ¬
			})
		if didCoverChange() is true then
			set savedCoverURL to my readSongMeta({"coverURL"})
			set currentCoverURL to coverURLGrab()
			if savedCoverURL is not currentCoverURL then writeSongMeta({"coverURL" & "##" & currentCoverURL})
		end if
		writeSongMeta({"albumName" & "##" & albumName})
	end if
	
	spitOutput(metaToGrab) as string
else
	return
end if

------------------------------------------------
---------------SUBROUTINES GALORE---------------
------------------------------------------------

on isMusicPlaying()
	set apps to {"iTunes", "Spotify"}
	set answer to false
	repeat with anApp in apps
		tell application "System Events" to set isRunning to (name of processes) contains anApp
		if isRunning is true then
			try
				using terms from application "iTunes"
					tell application anApp
						if player state is playing then
							set musicapp to (anApp as string)
							set answer to true
						end if
					end tell
				end using terms from
			on error e
				my logEvent(e)
			end try
		end if
	end repeat
	return answer
end isMusicPlaying

on getSongMeta()
	try
		set musicapp to a reference to application musicapp
		using terms from application "iTunes"
			try
				tell musicapp
					set {artistName, songName, albumName, songDuration} to {artist, name, album, duration} of current track
					set currentPosition to my formatNum(player position as string)
					set songDuration to my formatNum(songDuration as string)
				end tell
			on error e
				my logEvent(e)
			end try
		end using terms from
	on error e
		my logEvent(e)
	end try
	
	(*
	try
		if musicapp is "iTunes" then
			tell application "iTunes"
				set {artistName, songName, albumName, rawRating, songDuration} to {artist, name, album, rating, duration} of current track
				set currentPosition to player position
			end tell
		else if musicapp is "Spotify" then
			set theApp to a reference to application "Spotify"
			using terms from application "iTunes"
				try
					tell application theApp
						set {artistName, songName, albumName, rawRating, songDuration} to {artist, name, album, popularity, duration} of current track
						set currentPosition to my roundDown(player position as string)
					end tell
				end try
			end using terms from
		end if
		--set songRating to convertRating(rawRating)
	on error e
		my logEvent(e)
	end try
	*)
end getSongMeta

on didSongChange()
	set answer to false
	try
		set currentSongMeta to artistName & songName
		set savedSongMeta to (readSongMeta({"artistName"}) & readSongMeta({"songName"}) as string)
		if currentSongMeta is not savedSongMeta then set answer to true
	on error e
		my logEvent(e)
	end try
	return answer
end didSongChange


on didCoverChange()
	set answer to false
	try
		set currentSongMeta to artistName & albumName
		set savedSongMeta to (readSongMeta({"artistName"}) & readSongMeta({"albumName"}) as string)
		if currentSongMeta is not savedSongMeta then set answer to true
		if readSongMeta({"coverURL"}) is "NA" then set answer to true
	on error e
		my logEvent(e)
	end try
	return answer
end didCoverChange

on coverURLGrab()
	set coverDownloaded to false
	set rawXML to ""
	set currentCoverURL to "NA"
	repeat 5 times
		try
			set rawXML to (do shell script "curl 'http://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=" & quoted form of (my encodeText(artistName, true, false, 1)) & "&album=" & quoted form of (my encodeText(albumName, true, false, 1)) & "&api_key=" & apiKey & "'")
			delay 1
		on error e
			my logEvent(e & return & rawXML)
		end try
		if rawXML is not "" then
			try
				set AppleScript's text item delimiters to "extralarge\">"
				set processingXML to text item 2 of rawXML
				set AppleScript's text item delimiters to "</image>"
				set currentCoverURL to text item 1 of processingXML
				set AppleScript's text item delimiters to ""
				if currentCoverURL is "" then
					my logEvent("Cover art unavailable." & return & rawXML)
					set currentCoverURL to "NA"
					set coverDownloaded to true
				end if
			on error e
				my logEvent(e & return & rawXML)
			end try
			set coverDownloaded to true
		end if
		if coverDownloaded is true then exit repeat
	end repeat
	return currentCoverURL
end coverURLGrab

on readSongMeta(keyNames)
	set valueList to {}
	tell application "System Events" to tell property list file songMetaFile to tell contents
		repeat with keyName in keyNames
			try
				set keyValue to value of property list item keyName
			on error e
				my logEvent("Reading song metadata" & space & e)
				my writeSongMeta({keyName & "##" & "NA"})
				set keyValue to value of property list item keyName
			end try
			
			copy keyValue to the end of valueList
		end repeat
	end tell
	return valueList
end readSongMeta

on writeSongMeta(keys)
	tell application "System Events"
		if my checkFile(songMetaFile) is false then
			-- create an empty property list dictionary item
			set the parent_dictionary to make new property list item with properties {kind:record}
			-- create new property list file using the empty dictionary list item as contents
			set this_plistfile to ¬
				make new property list file with properties {contents:parent_dictionary, name:songMetaFile}
		end if
		try
			repeat with aKey in keys
				set AppleScript's text item delimiters to "##"
				set keyName to text item 1 of aKey
				set keyValue to text item 2 of aKey
				set AppleScript's text item delimiters to ""
				make new property list item at end of property list items of contents of property list file songMetaFile ¬
					with properties {kind:string, name:keyName, value:keyValue}
			end repeat
		on error e
			my logEvent(e)
		end try
	end tell
end writeSongMeta

on spitOutput(metaToGrab)
	set valuesList to {}
	repeat with metaPiece in metaToGrab
		set valuesList to valuesList & readSongMeta({metaPiece}) & " ~ "
	end repeat
	return items 1 thru -2 of valuesList
end spitOutput

(*
on roundDown(aNumber)
	set delimiters to {",", "."}
	repeat with aDelimiter in delimiters
		if aNumber contains aDelimiter then
			set AppleScript's text item delimiters to aDelimiter
			--set outNumber to text item 1 of aNumber & "000"
			set outNumber to text items of aNumber
			set AppleScript's text item delimiters to ""
		else
			set outNumber to aNumber
		end if
	end repeat
	return outNumber
end roundDown
*)

on formatNum(aNumber)
	set delimiters to {",", "."}
	repeat with aDelimiter in delimiters
		if aNumber does not contain aDelimiter then
			set outNumber to comma_delimit(aNumber)
		else
			set outNumber to aNumber
		end if
	end repeat
	return outNumber
end formatNum

on comma_delimit(this_number)
	set this_number to this_number as string
	if this_number contains "E" then set this_number to number_to_string(this_number)
	set the num_length to the length of this_number
	set the this_number to (the reverse of every character of this_number) as string
	set the new_num to ""
	repeat with i from 1 to the num_length
		if i is the num_length or (i mod 3) is not 0 then
			set the new_num to (character i of this_number & the new_num) as string
		else
			set the new_num to ("." & character i of this_number & the new_num) as string
		end if
	end repeat
	return the new_num
end comma_delimit

on number_to_string(this_number)
	set this_number to this_number as string
	if this_number contains "E+" then
		set x to the offset of "." in this_number
		set y to the offset of "+" in this_number
		set z to the offset of "E" in this_number
		set the decimal_adjust to characters (y - (length of this_number)) thru ¬
			-1 of this_number as string as number
		if x is not 0 then
			set the first_part to characters 1 thru (x - 1) of this_number as string
		else
			set the first_part to ""
		end if
		set the second_part to characters (x + 1) thru (z - 1) of this_number as string
		set the converted_number to the first_part
		repeat with i from 1 to the decimal_adjust
			try
				set the converted_number to ¬
					the converted_number & character i of the second_part
			on error
				set the converted_number to the converted_number & "0"
			end try
		end repeat
		return the converted_number
	else
		return this_number
	end if
end number_to_string

on encodeText(this_text, encode_URL_A, encode_URL_B, method)
	--http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789"
	set the URL_A_chars to "$+!'/?;&@=#%><{}[]\"~`^\\|*"
	set the URL_B_chars to ".-_:"
	set the acceptable_characters to the standard_characters
	if encode_URL_A is false then set the acceptable_characters to the acceptable_characters & the URL_A_chars
	if encode_URL_B is false then set the acceptable_characters to the acceptable_characters & the URL_B_chars
	set the encoded_text to ""
	repeat with this_char in this_text
		if this_char is in the acceptable_characters then
			set the encoded_text to (the encoded_text & this_char)
		else
			set the encoded_text to (the encoded_text & encode_char(this_char, method)) as string
		end if
	end repeat
	return the encoded_text
end encodeText

on encode_char(this_char, method)
	set the ASCII_num to (the ASCII number this_char)
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set x to item ((ASCII_num div 16) + 1) of the hex_list
	set y to item ((ASCII_num mod 16) + 1) of the hex_list
	if method is 1 then
		return ("%" & x & y) as string
	else if method is 2 then
		return "_" as string
	end if
end encode_char

on checkFile(myfile)
	try
		POSIX file myfile as alias
		return true
	on error
		return false
	end try
end checkFile

on logEvent(e)
	do shell script "echo '" & (current date) & space & e & "' >> ~/Library/Logs/Playbox-Widget.log"
end logEvent