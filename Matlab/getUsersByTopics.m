function users=getUsersByTopics(d_binary,user_list,topics,HTtopics,minTags)

% Input:
%     d_binary = sparse indicator matrix of the data
%     topics = vector of topic values, index corresponds with hashtag id
%     HTtopics = vector whose elements are the topic numbers to consider
%     minTags = minimum total number of tags present in specified topics
%     
% Output:
%     users = list of users in user_list who satisfy the minTags requirement

tags_list=[];
for t=1:length(HTtopics);
    tags_list=union(tags_list,find(topics==HTtopics(t)));
end

users = user_list(find(sum(d_binary(tags_list,user_list))>=minTags));