# MC production for ttAlp #

Two steps:

## 1. Greate gridpacks: ##

First get the genproduction repo from https://github.com/cms-sw/genproductions.
More instructions given here: https://twiki.cern.ch/twiki/bin/view/CMS/QuickGuideMadGraph5aMCatNLO#Create_the_gridpacks_for_each_pr

```
git clone https://github.com/cms-sw/genproductions.git
cp -r gridpacks_cards/ttALP genproductions/bin/MadGraph5_aMCatNLO/cards/.
cd gridpacks_cards/ttALP genproductions/bin/MadGraph5_aMCatNLO
./gridpack_generation.sh ttALP cards/ttALP
```

## 2. Gridpacks to MiniAOD ##

All steps of the MiniAOD production in GridpackToMiniAOD/Hadronizers.

### Running GridpacksToMiniAOD: ###

#### Requirements: ####

A gridpack is needed to run, which should be in the drectory specified for `output_dir` in `GridpackToMiniAOD/run_GridpackToMiniAOD.sh` (see Settings below). The name of the gridpack should be on the form: `tta_mAlp-${mass}GeV.tar.xz` (see Settings below).

#### Inputs: ####

1. Procedd-id = part in output name ($(PROCESS) for condor submission)
2. Mass [GeV]
3. Number of events to run (per job)
4. Lifetime (ctau) [mm], __if default lifetime is wanted set this input as -1__

#### Settings ####

Several paths are set in `GridpackToMiniAOD/run_GridpackToMiniAOD.sh`, all are given under PATHS in the file:

* `production_dir` = local path to GridpackToMiniAOD directory (needed for condor submission)
* `gripack_name` should be given in the form `tta_mAlp-${mass}GeV.tar.xz`, example: `tta_mAlp-0p35GeV.tar.xz`
* `gridpack_path` = path to gridpack
* `output_dir` = path to where output MiniAODs are stored

Output MiniAOD name will be stores in the form: 
* `tta_mAlp-${mass}GeV_ctau-{ctau}mm_nEvents-{events}.root` for set ctau (ctau!=-1)
* `tta_mAlp-${mass}GeV_nEvents-{events}.root` for default ctau (ctau=-1)

Example: `tta_mAlp-0p35GeV_ctau-1e3mm_nEvents-10000.root`

Other settings in `GridpackToMiniAOD/run_GridpackToMiniAOD.sh`:

* `save_allsteps` set to false by default. If `true` all intermediate root files will also be saved in the output directory.

#### Locally: ####

replace all {value} with your actual value.

```
cd GridpackToMiniAOD
./run_GridpackToMiniAOD.sh {process id} {mass} {number of events} {ctau}
```

Example:
```
./run_GridpackToMiniAOD.sh 0 0.35 10000 1e3
```

#### Condor submission: ####

Set input values in `run_GridpackToMiniAOD.sub` and run

```
cd GridpackToMiniAOD
condor_submit run_GridpackToMiniAOD.sub
```

#### Setting ALP decay and lifetime: ####

Note this is still WORK-IN-PROGRESS.

The ALP decay and lifetime is set by pythia in Step 1 in `GridpackToMiniAOD/Hadronizers/run_GEN_ttalp_noCopy.py`. Here the decay channel is now set to only ALP to muon-antimuon pair 100%. 

The lifetime is set by the decay width, such that `run_GEN_ttalp_noCopy.py` takes ctau [mm] as input, use it to calculate the decay width and sets the decay width which directly also updates pythias value of tau0 [mm/c].

TODO: double check conversion of ctau to gamma to tau0.
