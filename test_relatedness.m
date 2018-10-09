%% analysis of relatedness judgments, MAPMEM

%% setup
clear all
dbstop if error

cd('/project/3012026.13/logfiles/MEG');

%% dataset info
datasetNames = {'sub004','sub005','sub006','sub007',...
    'sub008','sub009','sub010','sub011','sub012','sub013','sub014','sub015','sub016',...
    'sub017','sub018','sub019','sub020','sub023',...
    'sub024','sub025','sub026','sub027','sub028',...
    'sub029','sub031','sub032','sub033',...
    'sub034','sub035','sub036','sub037','sub038'}; %'sub021','sub022',

nDatasets = length(datasetNames);

linked = 1;
unlinked = 0;
pre = 1;
post = 3;

relatedness = struct;
for subject =  1:nDatasets
    %% load logfile
    delimiterIn = '\t';
    headerlinesIn = 1;
    data = importdata(sprintf('%06s_Relatedness_answers.txt1', datasetNames{subject}),delimiterIn,headerlinesIn);
    
    %determine columns
    story   = 1;
    phase   = 2;
    video   = 3;
    link    = 4;
    rating  = 6;
    
    [responsesRelatedness{subject}, count{subject}] = deal(cell(12,1));
    for t = 1:12                                                                                           % t: 12 stories
        [responsesRelatedness{subject}{t}, count{subject}{t}] = deal(cell(2,1));
        for q = 1:2                                                                                        % q: 2 phases
            [responsesRelatedness{subject}{t}{q}, count{subject}{t}{q}] = deal(cell(2,1));
            for r = 1:2                                                                                    % r: linked vs unlinked
                responsesRelatedness{subject}{t}{q}{r} = zeros(4,1);
                count{subject}{t}{q}{r} = 1;
            end
        end
    end
    
    for k = 1:size(data.data,1)
        if data.data(k, link) == 1              % if linkeddata.data,story
            iLink = 2;                          % linked = 2
        elseif data.data(k, link) == 0
            iLink = 1;                          % unlinked = 1
        end
        if data.data(k, phase) == 1
            iPhase = 1;
        elseif data.data(k, phase) == 3
            iPhase = 2;
        end
        responsesRelatedness{subject}{data.data(k,story)}{iPhase}{iLink}(count{subject}{data.data(k,story)}{iPhase}{iLink}) = data.data(k, rating);
        count{subject}{data.data(k,story)}{iPhase}{iLink} = count{subject}{data.data(k,story)}{iPhase}{iLink}+1;
    end
    
    %bars = [preUnlinked postUnlinked preLinked postLinked];
    
    for iStory = 1:12
        relatedness(subject).preUnlinked(iStory)   = sum(responsesRelatedness{subject}{iStory}{1}{1})/sum(responsesRelatedness{subject}{iStory}{1}{1}>0);
        relatedness(subject).postUnlinked(iStory)  = sum(responsesRelatedness{subject}{iStory}{2}{1})/sum(responsesRelatedness{subject}{iStory}{2}{1}>0);
        relatedness(subject).preLinked(iStory)     = sum(responsesRelatedness{subject}{iStory}{1}{2})/sum(responsesRelatedness{subject}{iStory}{1}{2}>0);
        relatedness(subject).postLinked(iStory)  = sum(responsesRelatedness{subject}{iStory}{2}{2})/sum(responsesRelatedness{subject}{iStory}{2}{2}>0);
    end
    
end

% for iSubject = 1:nDatasets
% datasetNames(iSubject)
%  relatedness(iSubject).preUnlinked(:)
% end

%% plot

preUnlinked = [relatedness.preUnlinked]';
postUnlinked = [relatedness.postUnlinked]';
preLinked = [relatedness.preLinked]';
postLinked = [relatedness.postLinked]';

dataBars = [preUnlinked, postUnlinked, preLinked, postLinked];

% plot the bars

figure
hold on
title('Relatedness Judgement');
bar(mean(dataBars,1));
sem = [std(dataBars)/sqrt(length(dataBars(:,1)))];
h1=errorbar(mean(dataBars,1),sem);
hc = get(h1, 'Children');
%                             set(hc(1), 'Marker', 'none', 'LineStyle', 'none')   % remove lines for data from errorbar
%                             set(hc(2), 'color', [0 0 0], 'LineWidth', 3)        % set error bars to black and make them thick
%                             errorbar_tick(h1, 0);                               % remove error bar end markers
xlabel('phase');
% ylabel('R');
set(gca,'XTick',[1 2 3 4], 'Fontsize',12, 'Fontname', 'Arial')
set(gca,'XTickLabel',{'unlinked pre', 'unlinked post', 'linked pre', 'linked post'}, 'Fontsize',12, 'Fontname', 'Arial')

% finishing touches
set(gca, 'box', 'off')                                                                                  % remove bounding box
set(gca, 'LineWidth', 3)

% ylim ([0.15,0.53])

% add indicvidual participants' data
dataBarsScatter = [dataBars(:,1), dataBars(:,2); dataBars(:,3), dataBars(:,4)]
x = [ones(length(dataBars),1), ones(length(dataBars),1)*2; ones(length(dataBars),1)*3, ones(length(dataBars),1)*4];
currColor = 'red';
for iRow = 1:length(dataBars)*2
    plot(x(iRow,:), dataBarsScatter(iRow,:),...
        '-o',...
        'Color', currColor,...
        'MarkerEdgeColor',currColor,...
        'MarkerFaceColor',currColor,...
        'MarkerSize',5);
end

outputDir = '/project/3012026.13/logfiles/MEG';
figureFn = fullfile(outputDir, 'judgementRatings');
print(figureFn,'-dpng')