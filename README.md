# MC production for ttAlp #

Two steps:

## 1. Greate gridpacks: ##

First get the genproduction repo from https://github.com/cms-sw/genproductions.
More instructions given here: https://twiki.cern.ch/twiki/bin/view/CMS/QuickGuideMadGraph5aMCatNLO#Create_the_gridpacks_for_each_pr

```
git clone https://github.com/cms-sw/genproductions.git
cp -r gridpacks_cards/ttALP genproductions/bin/MadGraph5_aMCatNLO/cards/.
```

For some reason the model Phi_simp is not found altough it is listed on the cms generators webpage. So instead, download the model Phi_simp.tar.gz from the webpage:

https://cms-project-generators.web.cern.ch/cms-project-generators/

and add it to the directory `gridpacks_cards/ttALP genproductions/bin/MadGraph5_aMCatNLO`.

Generate gripacks for ttALP as:
```
cd gridpacks_cards/ttALP genproductions/bin/MadGraph5_aMCatNLO
./gridpack_generation.sh ttALP cards/ttALP
```

## 2. Gridpacks to MiniAOD ##

All steps of the MiniAOD production in `GridpackToMiniAOD/Hadronizers`.

### Running GridpacksToMiniAOD: ###

#### Requirements: ####

A gridpack is needed to run, which should be in the drectory specified for `output_dir` in `GridpackToMiniAOD/run_GridpackToMiniAOD.sh` (see Settings below). The name of the gridpack should be on the form: `tta_mAlp-${mass}GeV-ctau-${ctau}mm.tar.xz` (see Settings below).

#### Inputs: ####

1. Process-id = part in output name ($(PROCESS) for condor submission)
2. Mass [GeV]
3. Number of events to run (per job)
4. Lifetime (ctau) [mm], for default lifetimes set ctau to 0
5. save_all_steps: flag to save all root-files in each step. If `1` all intermediate root files will also be saved in the output directory. If `0` only RECO and MiniAOD root-files are saved.

#### Settings ####

Several paths are set in `GridpackToMiniAOD/run_GridpackToMiniAOD.sh`, all are given under PATHS in the file:

* `production_dir` = local path to GridpackToMiniAOD directory (needed for condor submission)
* `home_dir` = should be set to your home directory, needed when running on condor for root libraries that are loaded
* `gripack_name` should be given in the form `tta_mAlp-${mass}GeV.tar.xz`, example: `tta_mAlp-0p35GeV.tar.xz`
* `gridpack_path` = path to gridpack
* `output_dir` = path to where output MiniAODs are stored

Output MiniAOD name will be stores in the form: 
* `tta_mAlp-${mass}GeV_ctau-{ctau}mm_nEvents-{events}.root` for set ctau (ctau!=0)
* `tta_mAlp-${mass}GeV_nEvents-{events}.root` for default ctau (ctau=0)

Example: `tta_mAlp-0p35GeV_ctau-1e3mm_nEvents-10000.root`

#### Locally: ####

replace all {value} with your actual value.

```
cd GridpackToMiniAOD
./run_GridpackToMiniAOD.sh {process id} {mass} {number of events} {ctau} {save_all_steps}
```

Example:
```
./run_GridpackToMiniAOD.sh 0 0.35 10000 1e3 0
```

#### Condor submission: ####

Set input values in `run_GridpackToMiniAOD.sub` and run

```
cd GridpackToMiniAOD
mkdir log error output
condor_submit run_GridpackToMiniAOD.sub
```

For a larger amount of events in each run, it will take a while so make sure to check the job flavour, now default is "workday" = 3 days.

#### Setting ALP decay and lifetime: ####

The ALP decay channels and width are set when producing the gridpacks in ttAlp_param_card.dat, but it's also set for pythia in Step 1 in `GridpackToMiniAOD/Hadronizers/run_GEN_ttalp_noCopy.py`. Here the decay channel is now set to only ALP to muon-antimuon pair 100%. 

The lifetime is set by the decay width, such that `run_GEN_ttalp_noCopy.py` takes ctau [mm] as input, use it to calculate the decay width and sets the decay width which directly also updates pythias value of tau0 [mm/c].

The functionality of setting default ctau might not be working, this needs to be checked!
