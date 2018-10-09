function [trl] = mapmem_mytrialfun(cfg)
% This function splits up the data into trials based on trigger
% information. The triggers in the concentric grating experiment are the
% following:
%   xp.TRIG_ONSET_BLINK = 1;
%   xp.TRIG_ONSET_BASELINE = 2;
%   xp.TRIG_ONSET_GRATING = 3;
%   xp.TRIG_SHIFT = 4;
%   xp.TRIG_RESPONSE = 5;
% For analysis, grating onset is the zero time-point. The prestimulus
% baseline (trigger=2) will also be included in the trial window.
% The delay between trigger and stimulus is 15(-16) frames. To correct for
% this, select 15 frames after the trigger as the begin sample of an
% event. (event starts 15 frames after trigger).


cfg.trialdef.eventtype  = {'UPPT001'}; % define trials based on Bitsi triggers.
cfg.trialdef.eventtyperesp = {'UPPT002'};

hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset, 'type', {'UPPT001', 'UPPT002'});
%lag = 15; % in samples

% restructure events to make search easier (make a list of sample and value
% for all events)
for iEvent = 1:length(event)
    trigSample(iEvent,1) = event(iEvent).sample;
    trigValue(iEvent,1) = event(iEvent).value;
end

% log = cfg.logfile.log;

trl=[];
offset = 0;
iTrial=1;
for ii = 1:length(event)
    
    isBitsiEvent = ismember(event(ii).type, cfg.trialdef.eventtype);
    if isBitsiEvent
        isStoryEvent =  ismember(event(ii).value, cfg.trialdef.eventvalue(cfg.trialdef.eventvalue<200));   % check if event is a story clip
        
        if ii < length(event)
            isItiTrigger = ismember(event(ii+1).value, 255); %check if the next trigger is 255 (endtrigger)
        end
        
        
        if  isStoryEvent % if it's a story event
            
            if ~isItiTrigger % if the next trigger is not the endtrigger(255)
                j = ii;                                   % find the endtrigger
                x = event(j).value == 255;
                while x<1
                    j = j + 1;
                    x = event(j).value == 255;
                end
            end
            
            % first, get the first 3 rows for ft_definetrial (onset [sample index], end, offset [0])
            begsample = event(ii).sample;
            
            if isItiTrigger
                endsample = event(ii+1).sample;
            else
                endsample = event(j).sample;
            end
            
            % add relevant info for analysis:
            % trial number
            % story
            % video
            % pre/post
            % linked/unlinked
            
            trigger = event(ii).value;
            triggerStr = num2str(trigger);
            
            if trigger<100
                story = str2num(triggerStr(1));
                videoTrigger = str2num(triggerStr(2:end));
            elseif trigger > 99
                story = str2num(triggerStr(1:2));
                videoTrigger = str2num(triggerStr(3:end));
            end
            
            if videoTrigger < 4
                phase = 1;
                video = videoTrigger;
            elseif videoTrigger == 4
                phase = 3;
                video = videoTrigger;
            elseif videoTrigger > 4
                phase = 2;
                video = videoTrigger - 4;
            end
            
            if video == 1 | video == 2
                link = 1;
            elseif video == 3
                link = 0;
            end
            
            trl(end+1,:) = [begsample endsample offset iTrial videoTrigger video story phase link];
            
            
            iTrial=iTrial+1;
        end
    end
end

%% get rid of the first 40 trials for subject 4 (scanned the training session by accident)
if cfg.subj == 'sub-004'
    trl = trl(43:end,:)
end
end

