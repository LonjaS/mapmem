%% preprocess pipeline for mapmemMEG
% lonsch, July 2018

%% setup
clear all
dbstop if error
clc

Datasets = {'sub-004','sub-005','sub-006','sub-007','sub-008','sub-009',...
   'sub-010','sub-011','sub-012','sub-013','sub-014','sub-015','sub-016',...
   'sub-017','sub-018','sub-019','sub-020','sub-021','sub-022','sub-023',...
   'sub-024','sub-025','sub-026','sub-027','sub-028','sub-029','sub-031'...
   'sub-032','sub-033','sub-034','sub-035','sub-036','sub-037','sub-038'};

for iSubject = 1:length(Datasets)
    
    %% Specify variables
    
    subj         = Datasets{iSubject};  
    trigger      = [11:17,21:27,31:37,41:47,51:57,61:67,71:77,81:87,91:97,101:107,111:117,121:127,201:206,253,254,255];   %[140,240,40,31:39,110:119,120:129,210:219,220:229]
    trigger_last = [];  %[119,129,219,229];  
    root_dir     = '/project/3012026.13/';  
    
    outputDir = fullfile(root_dir, 'processed');

    if ~exist (fullfile(outputDir, [subj,'_dataclean.mat'])) %only proceed if no cleaned data available
        %% epoch data from raw files
        file                    = dir(fullfile(root_dir,'raw',subj,'ses-meg01/meg'));
        
        cfg                     = [];
        cfg.dataset             = strcat(root_dir,'raw/',subj,'/ses-meg01/meg/',file(3).name);
        %cfg.logfile             = strcat(root_dir,'raw/',subj,'/ses-meg01/beh/',subj, '_log.txt');
        cfg.trialdef.prestim    = 1;
        cfg.trialdef.poststim   = 2.5;
        % cfg.trialdef.eventtype  = 'UPPT001';
        cfg.trialdef.eventvalue = trigger;
        cfg.trialfun            = 'mapmem_mytrialfun'; %'ft_trialfun_preps';
        cfg.subj                = subj;
        new_cfg                 = ft_definetrial(cfg);
        
        % check sampling rate!!
        % check onsets in logfile
        % check range of values for ITIs
        
        new_cfg.channel         = {'MEG','UADC005','UADC006'};
        new_cfg.continuous      = 'yes';
        % new_cfg.lpfilter        = 'yes';
        % new_cfg.lpfreq          = 40;
        % new_cfg.lpfilttype      = 'firws';
        new_cfg.dftfilter       = 'yes'
        new_cfg.dftfreq         = 50;
        new_cfg.hpfilter        = 'yes';
        new_cfg.hpfreq          = 1;
        new_cfg.hpfilttype      = 'firws';
        new_cfg.usefftfilt      = 'yes';
        new_cfg.padding         = 10;
        data                    = ft_preprocessing(new_cfg);
        
        
        %% compute ICA on data to remove ECG/EOG artifacts
        %downsampling data to 300 Hz for ICA analysis
        
        cfg                 = [];
        cfg.channel         = 'MEG';
        cfg.resamplefs      = 300;
        cfg.detrend         = 'no';
        data_resamp         = ft_resampledata(cfg, data);
        
        
        % ICA analysis (limit to 100 iterations)
        cfg                 = [];
        cfg.channel         = 'MEG';
        cfg.method          = 'runica';
        cfg.runica.maxsteps = 100;
        compds              = ft_componentanalysis(cfg, data_resamp);
        
        % perform same ICA on original data (not downsampled)
        cfg                 = [];
        cfgcomp.channel     = 'MEG';
        cfg.unmixing        = compds.unmixing;
        cfg.topolabel       = compds.topolabel;
        comp                = ft_componentanalysis(cfg,data);
        
        
        %% Correlate ICs to EOGh, EOGv and ECG and store which components to remove
        
        EEG = cell2mat(data.trial);
        EEG = EEG(ismember(data.label, {'UADC005', 'UADC006'}), :); %or 'EEG059'
        
        % Correlate ICs to EEG and print the ICs that have highest correlations
        % r = corr(cell2mat(comp.trial)', EEG');
        % [~, j] = sort(abs(r));
        % [r(j((end-3):end, 1), 1), r(j((end-3):end, 2), 2), r(j((end-3):end, 3), 3), j((end-3):end, :)]
        
        
        %% STEP 3.2
        % inspect ICA component and marks those related to ECG/EOG artifacts as bad
        cfg           = [];
        cfg.component = [1:30];       % specify the component(s) that should be plotted
        cfg.layout    = 'CTF275.lay'; % specify the layout file that should be used for plotting
        cfg.comment   = 'no';
        ft_topoplotIC(cfg, compds)
        
        fh            = figure();
        cfg           = [];
        %cfg.channel   = unique(j((end-2):end, :));
        cfg.compscale = 'local';
        cfg.viewmode  = 'component';
        cfg.layout    = 'CTF275.lay'; % specify the layout file that should be used for plotting
        ft_databrowser(cfg, compds)
        
        waitfor(fh) % wait until we have closed the window for entring bad components
        %% STEP 3.2
        % save bad ICA components
        
        badcomp='tmp';
        promptUser=true;
        while promptUser
            prompt=inputdlg('List of ICA components to remove','Output File',1,{'tmp'});
            if isempty(prompt)
                disp('Cancel experiment ...');
                return;
            else
                badcomp= str2num(prompt{1});
            end
            
            if badcomp
                promptUser = false;
            end
        end
        %% STEP 3.3
        % remove components related to ECG and EOG artifacts and backproject the data
        cfg                 = [];
        cfg.channel         = 'MEG';
        cfg.component       = badcomp; % to be removed component(s)
        dataclean                = ft_rejectcomponent(cfg, comp, data);
        
        cfg                 = [];
        cfg.resamplefs      = 300;
        cfg.detrend         = 'yes';  % not good for evoked data
        cfg.demean          = 'no';
        cfg.trials          = 'all';
        dataclean                = ft_resampledata(cfg, dataclean);
        
        cfg = [];
        cfg.channel = 'MEG';
        ft_databrowser(cfg,data)
        ft_databrowser(cfg,dataclean)
        
        
        % Remove non-MEG channels, because ft_rejectcomponent adds those again
        cfg                 = [];
        cfg.channel         = 'MEG';
        cfg.detrend         = 'no';
        cfg.demean          = 'no';
        %cfg.baselinewindow  = [-inf 0];
        dataclean            = ft_preprocessing(cfg, dataclean);
        
        
        %% save data
        
        if ~exist(outputDir,'dir')
            mkdir (outputDir)
        end
        
        save(fullfile(outputDir, [subj,'_dataclean']),'dataclean','compds','badcomp','-v7.3')
    end

end