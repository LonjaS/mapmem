%% setup
clear all
dbstop if error
clc

%% Specify variables
% if ~exist('subject',         'var'), subject         = 'sub-016';  end
if ~exist('do_dicom2ctf', 'var'), do_dicom2ctf = true;  end
if ~exist('do_freesurfer','var'), do_freesurfer = true;  end
if ~exist('do_groupjobs','var'), do_groupjobs = false;  end
if ~exist('root_dir',     'var'), root_dir     = '/project/3012026.13/processed/';  end
if ~exist('save_dir',     'var'), save_dir     = '/project/3012026.13/processed/time-freq';  end

if ~exist (save_dir, 'dir'), mkdir(save_dir); end


% subjects = strsplit(sprintf('sub-%.3d ', [4:38]));
% subjects = subjects(~cellfun(@isempty, subjects));
subjects = {'sub-004'}%,'sub-008','sub-014'};

for iSubject = 1:numel(subjects)
    
    subj = subjects{iSubject};
    
    %% load data, remove bad trials and demean & detrend
    
    load (fullfile(root_dir, [subj,'_dataclean.mat']));
    
    % remove bad trials
    load (fullfile(root_dir,'rejectedTrials', [subj,'_rejectedTrials.mat'])); 
    
    cfg                     = [];
    cfg.trials              = not(rejected_logical);
    
    data                    = ft_selectdata(cfg, dataclean);
    
    % detrend and demean the data
    cfg                     = [];
    cfg.demean              = 'yes';
    cfg.detrend             = 'yes';
    
    data_demeaned           = ft_preprocessing(cfg, data);
    
    %% compute planar gradient

    cfg                     = [];
    cfg.method              = 'distance';
    cfg.feedback            = 'no';
    neighbours              = ft_prepare_neighbours(cfg, data);

    
    cfg                     = [];
    cfg.headmodel           = fullfile('/project/3012026.13/', subj, 'preproc', [subj, '_headmodel' '.mat']);
    cfg.neighbours          = neighbours;
    data_demeaned           = ft_megplanar(cfg, data_demeaned);
    data                    = ft_megplanar(cfg, data);

    %% select data
    
    linked_logical          = data.trialinfo(:,end) == 1;
    post_logical            = data.trialinfo(:,5) == 2;
    pre_logical             = data.trialinfo(:,5) == 1;
    unlinked_logical        = not(linked_logical);
    
    linked_post             = logical(linked_logical.*post_logical);
    unlinked_post           = logical(unlinked_logical.*post_logical);
    
    % quick sanity check
    if sum(linked_logical + unlinked_logical)/(504-sum(rejected_logical)) ~= 1
        error ('check the trial definitions (maybe wrong number of trials)');
    end
    
    cfg                          = [];
    cfg.trials                   = linked_post;
    data_linked_post_demeaned    = ft_selectdata(cfg, data_demeaned);
    data_linked_post             = ft_selectdata(cfg, data);
    
    cfg                          = [];
    cfg.trials                   = unlinked_post;
    data_unlinked_post_demeaned  = ft_selectdata(cfg, data_demeaned);
    data_unlinked_post           = ft_selectdata(cfg, data);
        
    %% time-frequency analysis
    
    cfg                         = [];
    cfg.output                  = 'pow';
    cfg.channel                 = 'MEG';
    cfg.method                  = 'mtmconvol';
    cfg.taper                   = 'hanning';
    cfg.foi                     = 2:2:30;                         % analysis 2 to 30 Hz in steps of 2 Hz % 1:1:30
    cfg.t_ftimwin               = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec % 1.0 sec
    cfg.toi                     = 0:0.05:2;                  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
    
    TFRhann_linked_demeaned     = ft_freqanalysis(cfg, data_linked_post_demeaned);
    TFRhann_unlinked_demeaned   = ft_freqanalysis(cfg, data_unlinked_post_demeaned);
    
    TFRhann_linked              = ft_freqanalysis(cfg, data_linked_post);
    TFRhann_unlinked            = ft_freqanalysis(cfg, data_unlinked_post);
    
    
    %% visualize the single subject results
    
    cfg = [];
    cfg.baseline     = [-1 0];
    cfg.baselinetype = 'absolute';
    cfg.zlim         = [-3e-27 3e-27];
    cfg.showlabels   = 'yes';
    cfg.layout       = 'CTF275_helmet.mat';
    figure
    ft_multiplotTFR(cfg, TFRhann_linked);

    
end


