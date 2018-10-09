%% Copyright 2016 Kristijan Armeni
%% MRI PREPROCESSING, HEADMODEL, SOURCEMODEL

%% setup
clear all
dbstop if error
clc

%% Specify variables
% if ~exist('subject',         'var'), subject         = 'sub-016';  end
if ~exist('do_dicom2ctf', 'var'), do_dicom2ctf = false;  end
if ~exist('do_freesurfer','var'), do_freesurfer = false;  end
if ~exist('do_groupjobs','var'), do_groupjobs = true;  end
if ~exist('root_dir',     'var'), root_dir     = '/project/3012026.13/raw/';  end
if ~exist('save_dir',     'var'), save_dir     = '/project/3012026.13/anatomy/';  end

if ~exist (save_dir, 'dir'), mkdir(save_dir); end


 subjects = strsplit(sprintf('sub-%.3d ', [4:38]));
% subjects = subjects(~cellfun(@isempty, subjects));
%subjects = {'sub-007','sub-008','sub-014'};

for iSubject = 1:numel(subjects)
    
    subject = subjects{iSubject};
    if ~exist (fullfile(save_dir,subject), 'dir'), mkdir(fullfile(save_dir,subject)); end
    
    if do_dicom2ctf
        % converting dicoms to mgz format
        if ~exist(fullfile(save_dir,subject,sprintf('%.7s_mri.mgz', subject)), 'file')
            preps_anatomy_dicom2mgz(root_dir,save_dir,subject);
        end
        
        % reslicing to freesufer-friendly 256x256x256
        if ~exist(fullfile(save_dir,subject,sprintf('%.7s_mni_resliced.mgz', subject)), 'file')
            preps_anatomy_mgz2mni(save_dir,subject);
        end
        
        if ~exist(fullfile(save_dir,subject,sprintf('%.7s_transform_vox2ctf.mat', subject)), 'file')
            preps_anatomy_mgz2ctf(save_dir,subject);
        end
        
        % Skullstriping
        if ~exist(fullfile(save_dir,subject,sprintf('%.7s_skullstrip.mgz', subject)), 'file')
            preps_anatomy_skullstrip(save_dir,subject);
        end
        
    end
end
if do_freesurfer
    
    for i = 1:numel(subjects)
        
        % first, all files have to be moved to '../preproc'
        preprocDir = fullfile(save_dir,subject,'preproc');
        if ~exist (preprocDir, 'dir')
        mkdir(fullfile(save_dir,subject,'preproc'));
        end
        
        if ~exist (fullfile(preprocDir,sprintf('%s_mni_resliced.mgz', subject)), 'file') && exist (fullfile(save_dir,subject,sprintf('%s_mni_resliced.mgz', subject)), 'file')
        movefile (fullfile(save_dir,subject, sprintf('%s*',subject)), preprocDir)
        end
        
        subject = subjects{i}%sprintf('sub-%0.3d',i);
        
        qsubfeval('preps_qsub_anatomy_freesurfer', subject,'freesurfer1',...
            'memreq', 1024^3 * 6,...
            'timreq', 720*60,...
            'batchid', 'preps_freesurfer1');
    end
    
    %% Check-up and white matter segmentation cleaning if needed
    
    preps_anatomy_volumetricQC(save_dir,subject)
    
    preps_anatomy_wmclean(save_dir,subject)
    
    
    for k = 1:numel(subjects)
        
        subject = sprintf('sub-%0.3d',k);
        
        qsubfeval('preps_qsub_anatomy_freesurfer', subject,'freesurfer2',...
            'memreq', 1024^3 * 7,...
            'timreq', 720*60,...
            'batchid', sprintf('preps_freesurfer2_%s',subject));
        
    end
    %% Post-processing Freesurfer script: workbench HCP tool
    
    for k = 1:numel(subjects)
        
        subject = sprintf('sub-%0.3d',k);
        qsubfeval('preps_qsub_anatomy_freesurfer', subject,'postfreesurferscript',...
            'memreq', 1024^3 * 6,...
            'timreq', 480*60);
        
    end
    
end

%%
if do_groupjobs
    
%     %%  Sourcemodel
%     
%     for h = 1:numel(subjects)
%         
%         subject = subjects{h};
%         preps_anatomy_sourcemodel2d(save_dir, subject);
%         
%     end
    
    %% Headmodel
    
    for i = 1:numel(subjects)
        
        subject = subjects{i};
        qsubfeval('preps_anatomy_headmodel', save_dir, subject, ...
            'memreq', 1024^3 * 5,...
            'timreq', 20*60);
        
    end
    
    
    %%  Coregistration check
    
    for i = 1:numel(subjects)
        
        subject = subjects{i};
        preps_anatomy_coregistration_qc(save_dir,subject);
        
    end
end

%% check headmodel & sensors
rawfiledir      = fullfile('/project/3011210.01/raw/',subject,'ses-meg01/meg');
d               = dir(rawfiledir);
rawfile         = d(3).name;
headmodel_file  = fullfile(save_dir, subject, [subject, '_headmodel' '.mat']);

load(headmodel_file)

headmodel = ft_convert_units(headmodel,'cm');
sens      = ft_read_sens(fullfile(rawfiledir,rawfile),'senstype','meg');

figure
ft_plot_sens(sens, 'style', '*b');

hold on
ft_plot_vol(headmodel);