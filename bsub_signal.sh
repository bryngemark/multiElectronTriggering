#!bin/bash

# this script takes up to 4 positional arguments. run as (all args optional)
# $  . bsub.sh [n_electrons] [ldmx config] [mass point] [nFiles to run] [pre-existing file list name]
#
# for first tests, make sure to not run the actual bsub command (for batch jobs), instead execute the part of the command starting with "singularity run ..."



# electron multiplicity. used for looking up files and passing nSimulated to the ldmx reco job
if [ -z $1 ]   #defaults to 1 
then 
    mult=1  
else
    mult=$1
fi
 

if [ -z $2 ]  #defaults to the one we typically want to use, 
then
    configToRun="runTriggerSums.py"
else  #but can specify a different config using arg 2 
    configToRun="$2" 
fi

echo "Running bsub script with $configToRun"

if [ -z $3 ]  #defaults to the one we typically want to use, 
then
    massPoint="0.001"
else  #but can specify a different config using arg 2 
    massPoint="$3"
fi

echo "Using signal input files for mass point $massPoint"


wallTime=20
version="pro_v3.0.0"
inputVersion="pro_edge"
process="signal"
#dPath="/nfs/slac/g/ldmx/data/mc20/v12/4.0GeV/${inputVersion}-${mult}e"
dPath="/nfs/slac/g/ldmx/data/validation/v12/4gev_${mult}e_${process}/${inputVersion}/Ap${massPoint}GeV"
#outDir="${HOME}/4gev_triggering_${inputVersion}/${version}/${process}_${mult}e"
outDir="/nfs/slac/g/ldmx/data/validation/v12/4gev_triggering_${inputVersion}/${version}/${process}_${mult}e/Ap${massPoint}GeV"

echo "outDir is $outDir"
#make sure the right pass name is set
inputPassName="rereco"
if [ $mult -ge 2 ]
then
    inputPassName="overlay"
fi 
# harmonize whitespace use
sed -ie 's,inputPassName = ,inputPassName=,g' ${configToRun}
sed -ie 's,inputPassName =,inputPassName=,g' ${configToRun}
sed -ie 's,inputPassName= ,inputPassName=,g' ${configToRun}
# here i'm just brute-force replacing all pass names i can think of; could do this more elegantly by reading in the actual line
sed -ie 's,inputPassName="sim",inputPassName="'$inputPassName'",g' ${configToRun}
sed -ie 's,inputPassName="signal",inputPassName="'$inputPassName'",g' ${configToRun}
sed -ie 's,inputPassName="overlay",inputPassName="'$inputPassName'",g' ${configToRun}
sed -ie 's,inputPassName="rereco",inputPassName="'$inputPassName'",g' ${configToRun}

#print the result 
grep "inputPassName" ${configToRun}


if [ -z $5 ]  #use arg 4 to specify an already existing file list, mostly for testing. NOTE arg 4 
then       # if none, the contents of dPath will be listed in one. 
    files=fList${mult}
    ls $dPath/*.root > $files
else
x
    files=$5
fi

if [ -z $4 ]  #max number of files (for testing). NOTE arg 3 (need $files defined before executing)
then
    echo "Running over all files in the dir"
    nFiles=$(cat $files | wc -l)  #count lines 
else
    nFiles=$4
    echo "Running over $nFiles files"
fi

echo "Running bsub script with file list $files"


singPath="/nfs/slac/g/ldmx/production/singularityImages"
singImage="ldmx-${version}-gLDMX.10.2.3_v0.4-r6.22.00-onnx1.3.0-xerces3.2.3-ubuntu18.04.sif"


# ------- all set, execute ------

if [ ! -d ${outDir} ]
then
    echo "Creating output directory ${outDir}"
    mkdir -p ${outDir}
fi

# submit 
let startNb=0  #this could be become a command line arg 
let nb=$startNb+1
while [ $nb -le $((nFiles + startNb)) ]  ; do
    file=$(head -n $nb $files | tail -n 1) #get the nb:th file                                                                                                              
    outfile=${file##*/}  #remove path 
    # uncomment this and move "singularity ..." up to right after walltime arg, to submit to batch 
    echo "command is ${configToRun} $file $mult $outfile $outDir"
    bsub -R "select[centos7]" -W ${wallTime} singularity run -B ${dPath}:${dPath} -B ${outDir}:${outDir} --home ${PWD} ${singPath}/${singImage} . ${configToRun} $file $mult $outfile $outDir
    # singularity run -B ${dPath}:${dPath} -B ${outDir}:${outDir} --home ${PWD} ${singPath}/${singImage} . ${configToRun} $file $mult $outfile $outDir
    ((nb++))
done


echo "Done."
