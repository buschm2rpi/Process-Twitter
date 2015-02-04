% Plot script

% clear all
clf

% gather data
% % % ROOTDIR=getenv('ROOTDIR'); % /local/home/student/mbusch/Matlab/Data/
% % % DATASET=getenv('DATASET'); % SNAP
% % % dataname=getenv('DATANAME'); % log_latency
% % % WEAK_CLASSIFIER=getenv('WEAK_CLASSIFIER');
% % % STRONG_CLASSIFIER=getenv('STRONG_CLASSIFIER');

CHOICE='strong';%{'strong','train','valid'}

DATASET='SNAP';
HTSET='all'; % choose 'manual' or 'All'
ROOTDIR=['/local/home/student/mbusch/data_tgenome/',DATASET,'/data/',HTSET];

dir_list=lsdir(ROOTDIR);
weak_list=cell({'LDA';'NB'});
strong_list=cell({'VOTE';'NB'});

weak_list=cell({'LDA'})
strong_list=cell({'NB'})

% use conf_valid to initialize the conf dimensions, since it
% always exists and has the same size as everything else
filename=[ROOTDIR,'/',dir_list{1},'/',weak_list{1},'_',strong_list{1},'_compile.mat'];
if exist(filename)~=0
    load(filename);
    [rows,cols]=size(conf_valid);
    err_rate=zeros(rows-1,length(dir_list));
else
    error('Check to make sure all files are ready for plotting.');
end

% find error rates
fig_count=10;
metric_err_rate=zeros(length(dir_list),length(weak_list)*length(strong_list));
for w=1:length(weak_list)
    WEAK_CLASSIFIER=weak_list{w};
    for s=1:length(strong_list)
        STRONG_CLASSIFIER=strong_list{s};
        for i=1:length(dir_list)
            DATANAME=dir_list{i};
            filename=[ROOTDIR,'/',DATANAME,'/',WEAK_CLASSIFIER,'_',STRONG_CLASSIFIER,'_compile.mat'];
            load(filename);
            
            if strcmp(CHOICE,'strong')==1
                eval(['conf=','conf_',lower(STRONG_CLASSIFIER),';']);
            elseif strcmp(CHOICE,'train')==1
                conf_temp=zeros(rows,cols);
                for j=1:100
                    if exist(['conf_train_T',int2str(j)])==1
                        eval(['conf_temp=','conf_temp+conf_train_T',int2str(j),';']);
                    end
                end
                eval(['conf=','conf_temp;']);
            elseif strcmp(CHOICE,'valid')==1
                eval(['conf=','conf_valid;']);
            else
                error('choose a correct data type to display.');
            end
            
            err_rate_temp=conf(:,cols)./max(ones(rows,1),sum(conf,2));
            err_rate(:,i)=err_rate_temp(1:rows-1);
            
            metric_err_rate(i,2*(w-1)+s)=sum(conf(:,cols))/sum(sum(conf,2));
            
        end
        
        %%% Plot and Plot Settings %%%
        
        FONTSIZE=14;
        
        % Position figure
        fig_count=fig_count+1;
        hFig = figure(fig_count);
        %set(hFig, 'Position', [1 1 520 400])
        set(hFig, 'Position', [1 1 600 400])
        
        % Plot bar graph and set position
        bar(1:length(dir_list),err_rate')
        set(gca, 'Position', [0.13 0.258 0.776 0.667])
        
        % Set tick labels to be data names, rotate, and turn off latex interpreter
        dir_list_temp=prettynames(dir_list);
        set(gca,'XTickLabel',dir_list_temp,'FontSize',FONTSIZE)
        th=rotateticklabel(gca,45);
        set(th,'Interpreter','none','FontName','Serif','FontSize',FONTSIZE);
        
        % Set remaining labels and legends
        if strcmp(CHOICE,'strong')==1
            TITLE=[DATASET,' data summary. Weak = ',WEAK_CLASSIFIER,', Strong = ',STRONG_CLASSIFIER];
        elseif strcmp(CHOICE,'train')==1
            TITLE=[DATASET,' training data summary. Weak = ',WEAK_CLASSIFIER];
        elseif strcmp(CHOICE,'valid')==1
            TITLE=[DATASET,' validation data summary. Weak = ',WEAK_CLASSIFIER];
        else
            error('choose a correct data type to display.');
        end
        title(TITLE,'FontSize',FONTSIZE);
        ylabel('Error rate','FontSize',FONTSIZE)
        
        if strcmp(HTSET,'manual')
            legend('Sports','Celebs','Tech','Location','NorthEastOutside')
        elseif strcmp(HTSET,'all')
            legend('BU','CELE','POLI','SCTECH','SPO','Location','NorthEastOutside')
        else
            error('HTSET environmental variable is not defined correctly.');
        end
        
    end
end