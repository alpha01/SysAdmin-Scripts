#!/bin/bash

sudo mount -t nfs -o resvport,vers=3,locallocks mini01:/backup /Volumes/Macintosh\ HD/Users/tony/nas/

hdiutil attach /Users/tony/nas/macbook_air/timemachine.sparsebundle 

sudo tmutil setdestination /Volumes/TimeMachine
