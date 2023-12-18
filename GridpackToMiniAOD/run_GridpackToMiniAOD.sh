#!/bin/bash

#source /osg/osg3.2/osg-wn-client/setup.sh
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
export CMSSW_GIT_REFERENCE=/cvmfs/cms.cern.ch/cmssw.git

#######    INPUTS    #######   
# 1: process ID 
# 2: mass 
# 3: tot events 
# 4: ctau - for default ctau set ctau=0 as input
# 5: save_all_steps - to save all intermediate root files from all steps, 0 = false, 1 = true 
process_id=$1
mass=$2
mass_str=`echo "$mass" | tr . p`
n_events=$3
ctau=$4
save_all_steps=$5

#######    PATHS    #######   

# path to GridpackToMiniAOD
production_dir=/afs/cern.ch/user/l/lrygaard/TTALPs/ttalps_MC_production/GridpackToMiniAOD
home_dir=/afs/cern.ch/user/l/lrygaard
# gridpack names in format tta_mAlp-{mass}GeV_ctau-{ctau}mm.tar.xz
# example: tta_mAlp-0p35GeV_ctau-1e5mm.tar.xz
gripack_name=tta_mAlp-${mass_str}GeV_ctau-${ctau}mm.tar.xz
gridpack_path=/eos/user/l/lrygaard/TTALP/gridpacks/$gripack_name
output_dir=/eos/user/l/lrygaard/TTALP/signal_MiniAODs

# condor directory or local tmp directory
condordir=`echo $_CONDOR_SCRATCH_DIR`
if [ -z "$condordir" ]
then
  rand_nr=$((1 + $RANDOM % 1000))
  condordir=$production_dir/tmp_$rand_nr
  mkdir $condordir
fi

#######    NAMING    #######   
# signal naming in format tta_mAlp-{mass}GeV_ctau-{ctau}mm_nEvents-{nevents}_part-{process}
# example: tta_mAlp-0p35GeV_ctau-1e3mm_nEvents-10000_part-0
file_collection=tta_mAlp-${mass_str}GeV
if [ "$ctau" != 0 ]
then
  file_collection=${file_collection}_ctau-${ctau}mm
fi
file_collection=${file_collection}_nEvents-$n_events
file_name=${file_collection}_part-$process_id


#######    Print all settings    #######   
echo processId: $process_id, mass: $mass_str, events: $n_events, condordir: $condordir
echo Directory for GridpackToMiniAOD production: $production_dir
echo Input gridpack: $gridpack_path
echo Output files stored in: $output_dir/$file_collection
if [ "$save_all_steps" = 1 ] 
then
  mkdir $output_dir/$file_collection/all_steps
  echo Saving all intermediate root files in: $output_dir/$file_collection/all_steps
else
  echo Not saving all intermediate root files, to save all intermediate steps change save_all_steps to 1
fi

######    GEN STEP    #######   
cd $condordir
cmsrel CMSSW_10_6_30_patch1
cd $condordir/CMSSW_10_6_30_patch1/src
eval `scramv1 runtime -sh`
export HOME=$home_dir

echo 1_run_GEN
cp $production_dir/Hadronizers/run_GEN_ttalp_noCopy.py $condordir
cd $condordir
# inputs:  gridpack_path, file_name, condordir,  events/job,  mass,  ctau
cmsRun $condordir/run_GEN_ttalp_noCopy.py $gridpack_path $file_name $condordir $n_events $mass $ctau
if [ "$save_all_steps" = 1 ] 
then
  cp ${file_name}_GENSIM.root $output_dir/$file_collection/all_steps/.
fi

#######    SIM STEP    #######   
cmsrel CMSSW_10_6_19_patch3
cd $condordir/CMSSW_10_6_19_patch3/src
eval `scramv1 runtime -sh`
export HOME=$home_dir

echo 2_run_SIM
cp $production_dir/Hadronizers/run_SIM_noCopy.py $condordir
cd $condordir
cmsRun $condordir/run_SIM_noCopy.py $file_name $condordir
if [ "$save_all_steps" = 1 ] 
then
  cp ${file_name}_SIM.root $output_dir/$file_collection/all_steps/.
fi

#######    DIGIPremix STEP    #######   
cmsrel CMSSW_10_6_17_patch1
cd $condordir/CMSSW_10_6_17_patch1/src
eval `scramv1 runtime -sh`
export HOME=$home_dir

echo 3_run_DIGIPremix
cp $production_dir/Hadronizers/run_DIGIPremix_noCopy.py $condordir
cd $condordir
cmsRun $condordir/run_DIGIPremix_noCopy.py $file_name $condordir
if [ "$save_all_steps" = 1 ] 
then
  cp ${file_name}_DIGIPremix.root $output_dir/$file_collection/all_steps/.
fi

#######    HLT STEP    #######   
cmsrel CMSSW_10_2_16_UL
cd $condordir/CMSSW_10_2_16_UL/src
eval `scramv1 runtime -sh`
export HOME=$home_dir

echo 4_run_HLT
cp $production_dir/Hadronizers/run_HLT_noCopy.py $condordir
cd $condordir
cmsRun $condordir/run_HLT_noCopy.py $file_name $condordir
if [ "$save_all_steps" = 1 ] 
then
  cp ${file_name}_HLT.root $output_dir/$file_collection/all_steps/.
fi

#######    RECO STEP    #######   
cd $condordir/CMSSW_10_6_17_patch1/src
eval `scramv1 runtime -sh`
export HOME=$home_dir

echo 5_run_RECO
cp $production_dir/Hadronizers/run_RECO_noCopy.py $condordir
cd $condordir
mkdir -p $output_dir/$file_collection/RECO
cmsRun $condordir/run_RECO_noCopy.py $output_dir $file_collection $file_name $condordir
if [ "$save_all_steps" = 1 ] 
then
  cp ${file_name}_RECO.root $output_dir/$file_collection/all_steps/.
fi

#######    MiniAOD STEP    #######   
cd $condordir
cmsrel CMSSW_10_6_20
cd $condordir/CMSSW_10_6_20/src
eval `scramv1 runtime -sh`
export HOME=$home_dir

echo 6_run_MiniAOD
cp $production_dir/Hadronizers/run_MiniAOD_noCopy.py $condordir
cd $condordir
mkdir -p $output_dir/$file_collection/MiniAOD
cmsRun $condordir/run_MiniAOD_noCopy.py $output_dir $file_collection $file_name $condordir

#######    CLEANING UP    #######
# removing local tmp diretory
if [ "$condordir" == $production_dir/tmp ]
then
  rm -r $condordir
fi
