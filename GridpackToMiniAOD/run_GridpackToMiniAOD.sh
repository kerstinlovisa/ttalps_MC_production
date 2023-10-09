#!/bin/bash

#source /osg/osg3.2/osg-wn-client/setup.sh
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
export CMSSW_GIT_REFERENCE=/cvmfs/cms.cern.ch/cmssw.git

## INPUTS ##
# 1: process ID 
# 2: mass 
# 3: tot events 
# 4: ctau - for default ctau set ctau=-1 as input
process_id=$1
mass=$2
mass_str=`echo "$mass" | tr . p`
n_events=$3
ctau=$4


## PATHS ##

## NAF
# path to GridpackToMiniAOD
# production_dir=/afs/desy.de/user/l/lrygaard/TTALP/ttalps_MC_production/GridpackToMiniAOD
# gridpack_path=/nfs/dust/cms/user/lrygaard/ttalps_cms/gridpacks/ttALP_slc7_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz
# output_dir=/nfs/dust/cms/user/lrygaard/ttalps_cms/LHEtoNanoAOD_output

## LXPLUS
# path to GridpackToMiniAOD
production_dir=/afs/cern.ch/user/l/lrygaard/TTALPs/ttalps_MC_production/GridpackToMiniAOD
# gridpack names given as example:
# tta_mAlp-0p35GeV.tar.xz
gripack_name=tta_mAlp-${mass_str}GeV.tar.xz
gridpack_path=/eos/user/l/lrygaard/TTALP/gridpacks/$gripack_name
output_dir=/eos/user/l/lrygaard/TTALP/signal_MiniAODs

# condor directory or local tmp directory
condordir=`echo $_CONDOR_SCRATCH_DIR`
if [ -z "$condordir" ]
then
  condordir=$production_dir/tmp
  mkdir $condordir
fi

## NAMING ##
# signal naming as exmple: 
# tta_mAlp-0p35GeV_ctau-1e3mm_nEvents-10000_part-0
file_collection=tta_mAlp-${mass_str}GeV
if [ "$ctau" != -1 ]
then
  file_collection=${file_collection}_ctau-${ctau}mm
fi
file_collection=${file_collection}_nEvents-$n_events
file_name=${file_collection}_part-$process_id

## OTHER SETTINGS ##
save_allsteps=false

## Print all settings ##
echo processId: $process_id, mass: $mass_str, events: $n_events, condordir: $condordir
echo Directory for GridpackToMiniAOD production: $production_dir
echo Input gridpack: $gridpack_path
echo Output files stored in: $output_dir/$file_collection

## GEN STEP ##
cmsrel CMSSW_10_6_30_patch1
cd CMSSW_10_6_30_patch1/src
eval `scramv1 runtime -sh`
cd $condordir

echo 1_run_GEN
cp $production_dir/Hadronizers/run_GEN_ttalp_noCopy.py $condordir
cd $condordir
# inputs:  gridpack_path, file_name, condordir,  events/job,  mass,  ctau
cmsRun run_GEN_ttalp_noCopy.py $(($process_id+0)) $gridpack_path $file_name $condordir $n_events $mass $ctau
if [ "$save_allsteps" = true ] 
then
  cp ${file_name}_GENSIM_${1}.root $output_dir/$file_collection/.
fi

## SIM STEP ##
cmsrel CMSSW_10_6_19_patch3
cd CMSSW_10_6_19_patch3/src
eval `scramv1 runtime -sh`

echo 2_run_SIM
cp $production_dir/Hadronizers/run_SIM_noCopy.py $condordir
cd $condordir
cmsRun run_SIM_noCopy.py $(($process_id+0)) $file_name $condordir
if [ "$save_allsteps" = true ] 
then
  cp ${file_name}_SIM_${1}.root $output_dir/$file_collection/.
fi

## DIGIPremix STEP ##
cmsrel CMSSW_10_6_17_patch1
cd CMSSW_10_6_17_patch1/src
eval `scramv1 runtime -sh`

echo 3_run_DIGIPremix
cp $production_dir/Hadronizers/run_DIGIPremix_noCopy.py $condordir
cd $condordir
cmsRun run_DIGIPremix_noCopy.py $(($process_id+0)) $file_name $condordir
if [ "$save_allsteps" = true ] 
then
  cp ${file_name}_DIGIPremix_${1}.root $output_dir/$file_collection/.
fi

## HLT STEP ##
cmsrel CMSSW_10_2_16_UL
cd CMSSW_10_2_16_UL/src
eval `scramv1 runtime -sh`

echo 4_run_HLT
cp $production_dir/Hadronizers/run_HLT_noCopy.py $condordir
cd $condordir
cmsRun run_HLT_noCopy.py $(($process_id+0)) $file_name $condordir
if [ "$save_allsteps" = true ] 
then
  cp ${file_name}_HLT_${1}.root $output_dir/$file_collection/.
fi

## RECO STEP ##
cd CMSSW_10_6_17_patch1/src
eval `scramv1 runtime -sh`

echo 5_run_RECO
cp $production_dir/Hadronizers/run_RECO_noCopy.py $condordir
cd $condordir
cmsRun run_RECO_noCopy.py $(($process_id+0)) $file_name $condordir
if [ "$save_allsteps" = true ] 
then
  cp ${file_name}_RECO_${1}.root $output_dir/$file_collection/.
fi

## MiniAOD STEP ##
cmsrel CMSSW_10_6_20
cd CMSSW_10_6_20/src
eval `scramv1 runtime -sh`

echo 6_run_MiniAOD
cp $production_dir/Hadronizers/run_MiniAOD_noCopy.py $condordir
cd $condordir
mkdir -p $output_dir/$file_collection
cmsRun run_MiniAOD_noCopy.py $(($process_id+0)) $output_dir $file_collection $file_name $condordir

# CLEANING UP ##
# removing local tmp diretory
if [ "$condordir" == $production_dir/tmp ]
then
  rm -r $condordir
fi
