% compile Bayes_vote results
% this script runs after classifier_script.m

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Put this header stuff in the processALL.m wrapper script
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% clear all
% 
% % define the root directory for all of the data related to this script
% % dataname is taken from the 'dataname' variable of setup_classifier_data.m
% dataname='test'; 
% ROOTDIR=['/local/home/student/mbusch/Matlab/Data/Latency/',dataname,'/'];
% 
% % set how this file should be used
% WEAK_CLASSIFIER='LDA'; % 'LDA' or 'NB'
% STRONG_CLASSIFIER='NB'; % 'VOTE' or 'NB'
% SUBGRAPHS=0;
% 
% % hashtag to index conversion
% HT_MAP=importdata('/local/home/student/mbusch/Twitter/HT_to_INDEX_conversion/tagGroupsUnique-Fixed.txt');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% No need to change anything below this line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Notes:
% conf_train is on a per hashtag basis
% conf_valid is on an over all basis

load([ROOTDIR,'DATA.mat'],'topics')
SUBROOTDIR=[ROOTDIR,WEAK_CLASSIFIER,'/'];

% delete old subgraph data
if strcmp(SUBGRAPHS,'SUBGRAPHS')==1
    delete([ROOTDIR,'Subgraphs/','users_',WEAK_CLASSIFIER,'_tag_*']);
end

RUNS=90; % hashtags

TOPIC_SET=unique(topics);
topic_set_bin=union(TOPIC_SET,max(TOPIC_SET)+1); % augment the topic set to include a 'topic' for the '~topics' set

conf_train_all=zeros(max(topic_set_bin)); % total confusion matrix count, per topic validation set
conf_nb=zeros(max(topic_set_bin));

for topicset=1:max(TOPIC_SET)
    run=1;
    
    name=[SUBROOTDIR,STRONG_CLASSIFIER,'_T',int2str(topicset),'_',int2str(run),'.mat'];
    if exist(name,'file')==0
        %disp([name,' does not exist']);
        continue;
    end
    
    var_name_train=['conf_train_T',int2str(topicset)];
    eval([var_name_train,'=zeros(',int2str(max(topic_set_bin)),');'])
    for run=1:RUNS
        
        % load data: 'tag','users','train_error_rate','validate_error_rate','final_vote'
        name=[SUBROOTDIR,STRONG_CLASSIFIER,'_T',int2str(topicset),'_',int2str(run),'.mat'];
        if exist(name,'file')==0
            %disp([name,' does not exist']);
            break;
        end
        load(name);
        
        % Sum all of the conf_train matrices
        eval([var_name_train,'=conf_train+',var_name_train,';'])
        
        if strcmp(STRONG_CLASSIFIER,'NB')
            % final bayes confusion matrix
            conf_nb(topics(tag),topic_bayes)=conf_nb(topics(tag),topic_bayes)+1;
        end
        
        if strcmp(SUBGRAPHS,'SUBGRAPHS')==1;
            
            SUBGRAPHDIR=[ROOTDIR,'Subgraphs/'];% write user_list per tag
            PRIORSDIR=[ROOTDIR,'Priors/'];% write PRIOR distributions per tag
            if exist(SUBGRAPHDIR,'dir')~=7
                mkdir(SUBGRAPHDIR);
            end
            if exist(PRIORSDIR,'dir')~=7
                mkdir(PRIORSDIR);
            end
            unames=[SUBGRAPHDIR,'users_',WEAK_CLASSIFIER,'_tag_',HT_MAP{1}{tag}]; % int2str(tag)
            priors=[PRIORSDIR,'priors_',WEAK_CLASSIFIER,'_tag_',HT_MAP{1}{tag}]; % int2str(tag)
            
            % keep track of weak classifier decisions
            users_choices=users_correct; % binary decision
            users_choices(users_choices==1)=prob_LC(users_choices==1,topicset);
            users_choices(users_choices==0)=prob_LC(users_choices==0,max(topic_set_bin));
            
            % write output to text file
            dlmwrite(unames,[users' users_correct users_choices prob_LC(:,topicset) prob_LC(:,max(topic_set_bin))],'precision','%10.4f');
            dlmwrite(priors,PRIOR);
        end
        
    end
    
    % Total the conf_train matrices
    eval(['conf_train_all=',var_name_train,'+conf_train_all;']);
    
end

% final vote confusion matrix
[rows,cols]=size(final_vote);
conf_vote=zeros(max(topic_set_bin));
for coln=1:cols
    if nnz(final_vote(:,coln))==0
        break;
    end
    [topic,e2,vote_for]=find(sparse(final_vote(:,coln)));
    conf_vote(topic,vote_for)=conf_vote(topic,vote_for)+1;
end

% save the data
savename=[ROOTDIR,WEAK_CLASSIFIER,'_',STRONG_CLASSIFIER,'_compile'];
save(savename,'conf_valid',['conf_',lower(STRONG_CLASSIFIER)]);
for i=1:max(TOPIC_SET)
    if exist(['conf_train_T',int2str(i)])==1
        save(savename,['conf_train_T',int2str(i)],'-APPEND');
    end
end

