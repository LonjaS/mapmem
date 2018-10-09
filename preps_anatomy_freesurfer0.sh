#!/bin/sh

export FREESURFER_HOME=/opt/freesurfer/5.3
export SUBJECTS_DIR=$1

source $FREESURFER_HOME/SetUpFreeSurfer.sh

mkdir $SUBJECTS_DIR/mri

cd $SUBJECTS_DIR
cp -f $1/$3_mni_resliced.mgz $SUBJECTS_DIR/mri
cp -f $1/$3_skullstrip.mgz $SUBJECTS_DIR/mri

cd $SUBJECTS_DIR/mri
mri_convert -c -oc 0 0 0 $1/mri/$3_mni_resliced.mgz orig.mgz
mri_convert -c -oc 0 0 0 $1/mri/$3_skullstrip.mgz brainmask.mgz

recon-all -talairach 
#recon-all -nuintensitycor -subjid $2
#recon-all -normalization -subjid $2

# part of autorecon2
#recon-all -gcareg -subjid $2
#recon-all -canorm -subjid $3
#recon-all -careg -subjid $3
#recon-all -careginv -subjid $3
#recon-all -calabel -subjid $3
#recon-all -normalization2 -subjid $3
#recon-all -maskbfs -subjid $3
#recon-all -segmentation -subjid $3