% weak-strong classifier script

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Put this header stuff in the processALL.m wrapper script
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % be sure that both make_d_topics.m and make_data_matrices.m have already been run
% clear all
% 
% % define the root directory for all of the data related to this script
% % dataname is taken from the 'dataname' variable of setup_classifier_data.m
% dataname='test'; 
% ROOTDIR=['/local/home/student/mbusch/Matlab/Data/Latency/',dataname,'/'];
% EDGE_LIST='/local/home/student/mbusch/Matlab/Data/Matfiles/Network.mat';
% 
% % set how this file should be used
% WEAK_CLASSIFIER='LDA'; % 'LDA' or 'NB'
% STRONG_CLASSIFIER='VOTE'; % 'VOTE' or 'NB'
% GET_SUBGRAPHS=0;
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% No need to change anything below this line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setup the environment
addpath /local/home/student/mbusch/Matlab/Functions/
load([ROOTDIR,'DATA.mat'],'d_iu','d_binary','d_topics','topics');
SUBROOTDIR=[ROOTDIR,WEAK_CLASSIFIER,'/'];
if exist(SUBROOTDIR,'dir')~=7
    mkdir(SUBROOTDIR);
end

% Don't delete files if only obtaining subgraphs
if strcmp(GET_SUBGRAPHS,'SUBGRAPHS')~=1
    delete([SUBROOTDIR,STRONG_CLASSIFIER,'*']); % delete old files
end

% start!
d_topics_all=d_topics;
[r,c]=size(d_binary);
STD=1/sqrt(2*pi); % put this here to save computation time

% initialize tag_list and user_list 
[e1,e2,s]=find(d_binary);
all_tag_list=unique(e1);
all_user_list=unique(e2);

% initialize other important vectors and variables
topic_set=unique(topics);
topic_set_bin=union(topic_set,max(topic_set)+1); % augment the topic set to include a 'topic' for the '~topics' set
final_vote=zeros(max(topic_set_bin),length(all_tag_list));
conf_valid=zeros(max(topic_set_bin));
count=0;

tstart=tic;
for t_s=1:length(topic_set)
    user_set=topic_set(t_s);
    
    % generate user list and tag list for topic of interest
    user_list=getUsersByTopics(d_binary,all_user_list,topics,user_set,3);
    user_list=getUsersByTopics(d_binary,user_list,topics,setdiff(topic_set,user_set),2);
    tag_list=find(sum(d_binary(:,user_list)')>0);
    tag_runs=intersect(tag_list,find(topics==user_set));
    
    % re-initialize d_topics for binary classification
    [e1,e2,s]=find(d_topics_all);
    s(s~=user_set)=max(topic_set_bin);               %binary yes or no if tag is in topic
    d_topics=sparse(e1,e2,s);       %rewrite d_topics matrix for specific case
    
    % initialize prior distribution for binary classification
    PC=zeros(1,2);                  %rewrite prior distribution
    PC(1)=length(tag_runs)/length(tag_list);
    PC(2)=1-PC(1);           %needs to match # of elements, not # ids of sets
    
% % %     % Get subgraphs for user_list, Petko's code already does this
% % %     subgraph=0; % initialize, just to be safe
% % %     if strcmp(GET_SUBGRAPHS,'SUBGRAPHS')==1
% % %         load(EDGE_LIST,'edges_from_to');
% % %         subgraph=filterbylist(edges_from_to,user_list,1);
% % %         subgraph=filterbylist(subgraph,user_list,2);
% % %         singletons=setdiff(user_list,union(subgraph(:,1),subgraph(:,2)));
% % %         subgraph=[subgraph;-ones(length(singletons),1) singletons];
% % %         SUBGRAPHDIR=[ROOTDIR,'Subgraphs/'];
% % %         if exist(SUBGRAPHDIR,'dir')~=7
% % %             mkdir(SUBGRAPHDIR);
% % %         end
% % %         name=[SUBGRAPHDIR,WEAK_CLASSIFIER,'_graph_T',int2str(user_set)];
% % %         dlmwrite(name, subgraph,'precision','%10.0f');
% % %         continue;
% % %     end        
    
    TAG_NUMS=length(tag_runs); % run through each tag in tag_list
    topic_bayes=zeros(TAG_NUMS,1);
    
    for run=1:TAG_NUMS
        
        tag=tag_runs(run); % use each tag in tag_list
        
        % obtain training and validation sparse indicator matrices
        [d_train,d_validate]=getTrainValidate(d_binary,tag_list,user_list,tag);
        
        % obtain list of users who use the validation hashtag
        [e1,e2,s]=find(d_validate(tag,:));
        users=unique(e2);
        
        % initialize variables that store user specific data
        %prob_LC=1e-4*ones(length(users),max(topic_set_bin));
        prob_LC=zeros(length(users),max(topic_set_bin)); % for weak classifier
        weak_vote=zeros(length(users),max(topic_set_bin)); % for strong classifier
        conf_train=zeros(max(topic_set_bin));
        users_correct=zeros(length(users),1);
        
        for u=1:length(users)
            user=users(u);
            
            % obtain the training and validation hashtags
            [train_tags,e2,s]=find(d_train(:,user));
            [validation_tags,e2,s]=find(d_validate(:,user));
            
            % obtain the training data and their associated topics
            train_set=full(d_iu(train_tags,user));
            train_topics=full(d_topics(train_tags,user));
            
            % obtain the validation data and their associated topics
            validation_set=full(d_iu(validation_tags,user));
            validation_topics=full(d_topics(validation_tags,user));
            
            if strcmp(WEAK_CLASSIFIER,'NB')
                
                % all same values in topic will cause problems
                t_set=unique(train_topics);
                flag_nb=0;
                for t_num=1:length(t_set)
                    idxs=find(train_topics==t_set(t_num));
                    if var(train_set(idxs))==0
                        class_train=-1*ones(length(train_set),1);
                        class_validate=-1*ones(length(validation_set),1);
                        flag_nb=1;
                        break;
                        
                        % shouldn't be making stuff up
                        %avg_t=mean(train_set(train_topics==t_set(t_num)));
                        %train_set(idxs)=avg_t+1e-6.*randn(length(idxs),1);
                    end
                end
                
                % assign prob_LC
                if flag_nb==0
                    % do the naive bayes
                    nb=NaiveBayes.fit(train_set,train_topics,'Prior',PC);
                    class_train=predict(nb,train_set);
                    [post,class_validate]=posterior(nb,validation_set);
                    % post(post<1e-6)=1e-6;
                    prob_LC(u,[user_set max(topic_set_bin)])=post;
                else
                    prob_LC(u,[user_set max(topic_set_bin)])=1e-6;
                end
                
                % assign weak_vote... problem if max prob_LC is .0001
                vote=find(prob_LC(u,:)==max(prob_LC(u,:)));
                if length(vote)>1
                    weak_vote(u,max(topic_set_bin))=1;
                else
                    weak_vote(u,vote)=1;
                end
                
            elseif strcmp(WEAK_CLASSIFIER,'LDA')
                
                % compute class_train and class_validate
                flag_inconclusive=0;
                if length(unique(train_set))>length(unique(train_topics))
                    class_train=classify(train_set,train_set,train_topics);
                    class_validate=classify(validation_set,train_set,train_topics);
                elseif length(unique(train_set))==length(unique(train_topics))
                    class_train=train_topics;
                    for i=1:length(validation_set)
                        diffs=abs(train_set-validation_set(i));
                        T_choices=train_topics(find(diffs==min(diffs))); % find topic with closest values
                        num_Ts=hist(T_choices,1:max(topic_set_bin));
                        T_most=find(max(num_Ts)==num_Ts); % find topic with most closest values
                        if length(T_most)==1
                            class_validate(i)=T_most;
                        else
                            flag_inconclusive=1; % inconclusive
                        end
                    end
                else
                    % user not trainable or classifiable
                    flag_inconclusive=1; % inconclusive
                end
                
                % skip to next user if results are inconclusive
                %fprintf('flag_inconclusive = %d\n',flag_inconclusive);
                if flag_inconclusive==1
                    class_train=-1*ones(length(train_topics),1);
                    class_validate=-1*ones(length(validation_set),1);
                    prob_LC(u,[user_set max(topic_set_bin)])=1e-6;
                    weak_vote(u,max(topic_set_bin))=0;
                    continue;
                end
                
                % fill in prob_LC matrix
                if strcmp(STRONG_CLASSIFIER,'VOTE') % this 'if' is for efficiency
                    prob_LC(u,class_validate)=1;
                    weak_vote(u,class_validate)=1;
                elseif strcmp(STRONG_CLASSIFIER,'NB')
                    % Conditional Probability per user, assume gaussian marginal
                    % distributions. mean centered on the correctly labeled topic, and
                    % variance of all trained to that topic.
                    index_mean=find(class_train==class_validate); % training indices that match the validation topic
                    for t=1:max(topic_set_bin)
                        index_topic=intersect(find(train_topics==t),find(class_train==t));
                        if isempty(index_topic)
                            prob_LC(u,t)=.0001; % bad classifier, so ignore and move on
                        else % fit a normal distiribution using empirical statistics, and use to evaluate posterior probability
                            avg=mean(train_set(index_topic));
                            stdev=max(STD,std(train_set(class_train==t)));
                            prob_LC(u,t)=max(.0001,STD/stdev*exp(-0.5*(validation_set-avg)^2/stdev^2));
                        end
                    end
                    weak_vote(u,class_validate)=1;
                end
                
            else
                disp('Need to choose a weak classifier.');
                return;
            end
            
            % Generate training confusion matrix, row=actual, column=trained,
            % averaged over trained topics per actual topics.
            conf_user=zeros(max(topic_set_bin));
            for t=1:max(topic_set_bin)
                for class=1:max(topic_set_bin)
                    conf_user(t,class)=sum(class_train(train_topics==t)==class);
                end
            end
            conf_train=conf_train+conf_user;
            
            if class_validate>0
                conf_valid(validation_topics,class_validate)=conf_valid(validation_topics,class_validate)+1;
                
                % keep track of whether or not user was correct. check against
                % network
                users_correct(u)=(class_validate==validation_topics);
            else
                users_correct(u)=-1; % inconclusive
            end
            
% % %             if mod(u,10)==0
% % %                 fprintf('Tset = %d, Run = %d, ITER = %d/%d, TIME=%f\n',user_set,run,u,length(users),toc(tstart));
% % %             end
        end
        fprintf('Tset = %d, Run = %d, ITER = %d/%d, TIME=%f\n',user_set,run,u,length(users),toc(tstart));
        
        PRIOR=zeros(1,max(topic_set_bin));
        PRIOR(user_set)=PC(1);
        PRIOR(max(topic_set_bin))=PC(2);
        if strcmp(STRONG_CLASSIFIER,'NB')
        
%             PRIOR=zeros(1,max(topic_set_bin));
%             PRIOR(user_set)=PC(1);
%             PRIOR(max(topic_set_bin))=PC(2);
            loglikelihoods=sum(log(prob_LC),1)+log(PRIOR);
            topic_bayes=find(loglikelihoods==max(loglikelihoods([user_set max(topic_set_bin)])));
            
            % if not classifyable, then say the hashtag was misclassified
            if length(topic_bayes)>1
                topic_bayes=max(topic_set_bin);
            end
        
        elseif strcmp(STRONG_CLASSIFIER,'VOTE')
            
% % %             
% % %             [max_posts,topic_votes]=max(weak_vote,[],2);
% % %             true_topic=validation_topics;
% % %             num_votes=hist(topic_votes,1:max(topic_set_bin)); 
            count=count+1;
            true_topic=validation_topics;
            total=sum(weak_vote,1);
            [maxs,winning_vote]=max(find(total==max(total))); % misclassify in the case of a tie
            final_vote(true_topic,count)=maxs; % row index corresponds with true topic
            
        else
            disp('Need to choose a strong classifier.');
            return;
        end

        name=[SUBROOTDIR,STRONG_CLASSIFIER,'_T',int2str(user_set),'_',int2str(run)];
        save(name,'tag_list','tag','user_list','users','users_correct',...
            'conf_train','conf_valid','topic_bayes','prob_LC','weak_vote',...
            'final_vote','PRIOR');
              
    end
end