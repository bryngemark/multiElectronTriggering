#!/bin/python

import os
import sys
import json

from LDMX.Framework import ldmxcfg

# set a 'pass name'; avoid sim or reco(n) as they are apparently overused
inputPassName="overlay"
passName = "triggerSums"
p=ldmxcfg.Process(passName)

#import all processors

# Ecal hardwired/geometry stuff
import LDMX.Ecal.EcalGeometry
import LDMX.Ecal.ecal_hardcoded_conditions

# Hcal hardwired/geometry stuff
import LDMX.Hcal.HcalGeometry
import LDMX.Hcal.hcal_hardcoded_conditions


from LDMX.Recon.electronCounter import ElectronCounter
from LDMX.Recon.simpleTrigger import TriggerProcessor



#pull in command line options
infile= sys.argv[1]        # input file name
nEle=int(sys.argv[2])      # simulated beam electrons
outputNameString= str(sys.argv[3]) #sample identifier
outDir= str(sys.argv[4])    #sample identifier

outname=outDir+"/triggerSumsLayer0_"+outputNameString #+".root"
print("Outname is"+outname)


#if use a file list 
#with open(fileList) as inputFiles :
#     p.inputFiles = [ line.strip('\n') for line in inputFiles.readlines() ]
p.inputFiles = [ infile ] 
     
print( p.inputFiles )

#
# Configure the sequence in which user actions should be called.
#

eCount = ElectronCounter( nEle, "ElectronCounter")
eCount.input_pass_name = inputPassName
eCount.use_simulated_electron_number = True

p.sequence=[ eCount ]

layers = [20, 22, 24, 26, 28, 30, 32, 34]
tList=[]
for iLayer in range(len(layers)) : 
#     print("at layer iterator  "+str(iLayer)+" and layer nb "+str(layers[iLayer]))
     tp = TriggerProcessor("TriggerSumsLayer"+str(layers[iLayer]))
     tp.input_pass = inputPassName
     tp.start_layer = 0
     tp.end_layer = layers[iLayer]
     tp.trigger_collection = "TriggerSums"+str(layers[iLayer])+"Layers"
     tList.append(tp)
#     p.sequence.extend( [tp] )
p.sequence.extend( tList ) #=[ ecalVeto ] #TrigScintClusterProducer.tagger(), TrigScintClusterProducer.up(), TrigScintClusterProducer.down(), trigScintTrack ]# ecalVeto ]

print( tList[0].trigger_collection )

p.keep = ["drop .*SimParticles", "drop .*SimHits", "drop .*Hcal.*", "keep .*Trig.*", "drop .*TriggerPad.*SimHits", "drop .*trigScintDigis", "drop HcalVeto", "keep .*Ecal.*", "drop .*ScoringPlaneHits.*"]

# p.maxEvents = 100

p.outputFiles=[ outname ]


p.termLogLevel = 1  # default is 2 (WARNING); but then logFrequency is ignored. level 1 = INFO.
#print this many events to stdout (independent on number of events, edge case: round-off effects when not divisible. so can go up by a factor 2 or so)
logEvents=20 
if p.maxEvents < logEvents :
     logEvents = p.maxEvents
p.logFrequency = int( p.maxEvents/logEvents )

json.dumps(p.parameterDump(), indent=2)

with open('parameterDump.json', 'w') as outfile:
     json.dump(p.parameterDump(),  outfile, indent=4)


     
