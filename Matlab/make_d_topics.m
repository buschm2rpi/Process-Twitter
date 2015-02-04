function d_topics=make_d_topics(d_binary,topics)

% Input:
%       d_binary = indicator matrix of d_iu data, sparse matrix
%       topics = column vector with coded topic number at index of
%       corresponding hashtag.
%
% Output:
%       d_topic = indicator matrix of d_iu data where the indicator value
%       is the value of that hashtag's topic, sparse matrix

[rows,columns]=size(d_binary);
d_topics=sparse(rows,columns);

topic_list=unique(topics);

for t=1:length(topic_list)
    temp=sparse(rows,columns);
    idx=find(topics==topic_list(t));
    temp(idx,:)=d_binary(idx,:);
    [te1,te2,ts]=find(temp);
    [e1,e2,s]=find(d_topics);
    d_topics=sparse([e1;te1],[e2;te2],[s;topic_list(t)*ones(length(ts),1)]);
end
    