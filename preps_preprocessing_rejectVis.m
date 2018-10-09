%% Trial rejection with ft_rejectvisual

%% setup
clear all
dbstop if error
clc

if ~exist('root_dir',     'var'), root_dir     = '/project/3012026.13/processed/';  end
if ~exist('save_dir',     'var'), save_dir     = '/project/3012026.13/processed/rejectedTrials';  end

if ~exist (save_dir, 'dir'), mkdir(save_dir); end

% Datasets = {'sub-004','sub-005','sub-006','sub-007','sub-008','sub-009',...
%     'sub-010','sub-011','sub-012','sub-013','sub-014','sub-016',...
%     'sub-017','sub-018','sub-019','sub-020','sub-022','sub-023',...
%     'sub-024','sub-025','sub-026','sub-027','sub-028','sub-029','sub-031'...
%     'sub-032','sub-033','sub-034','sub-035','sub-036','sub-037','sub-038'}; %'sub-015','sub-021',

Datasets = {'sub-015','sub-021'};

for iSubject = 1:length(Datasets)
    
    subj         = Datasets{iSubject};
    
    if ~exist (fullfile(save_dir, [subj,'_rejectedTrials.mat']))
        %% load data and reject trials with too high variance
        
        disp(sprintf('\nloading subject %ss data\n',subj(6:end)));
        load (fullfile(root_dir, [subj,'_dataclean.mat']))
        
        cfg =[];
        cfg.method = 'summary';
        rejected_trls = ft_rejectvisual(cfg,dataclean);
        
        % compare trial info of dataclean with rejected_trls to determine which
        % trials were rejected
        
        rejected_logical    = not(ismember(dataclean.trialinfo(:,1), rejected_trls.trialinfo(:,1)));
        rejected_index      = find(rejected_logical);
        
        save(fullfile(save_dir, [subj,'_rejectedTrials']),'rejected_logical', 'rejected_index')
    end
end