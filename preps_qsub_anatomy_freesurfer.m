function preps_qsub_anatomy_freesurfer(subject,scriptname)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here


% Fressurfer script2
shell_script      = strcat('/project/3012026.13/scripts/preps_anatomy_',scriptname,'.sh');
mri_dir           = fullfile('/project/3012026.13/anatomy', subject) ;% '/project/3012026.13/anatomy' 

% streams_anatomy_freesurfer2.sh
command = [shell_script, ' ', mri_dir, ' ', 'preproc', ' ', subject];

system(command);

end