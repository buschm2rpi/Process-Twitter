function [d_iu,d_binary]=make_data_matrices(filename,option)

% Input:
%       filename = name of data file with all relevant values, string value
%
%       option =
%           'latency' for latency data
%           'time' for absolute time response delay data
%           'log_latency' for log normalized latency data
%           'number_of_usages'
%           'number_of_parents'
%           'fraction_of_parents'
%
% Output:
%       d_iu = sparse matrix where data exists at element (hashta_id,user_id)
%       d_binary = sparse indicator matrix of d_iu, has value of '1' where
%       nonzero element of d_iu exists.
%
% Note: we assume that hashtags.adopt.time.coded has the following format:
%       (# given by column)
%
% 1: userid
% 2: tagid (according to the ordering in tagfn)
% 3: time user first posted the ht
% 4: time user's earliest parent posted the ht
% 5: number of messages (in the same topic) since first parent tweeted ht
% 6: time since first first parent posted the ht
% 7: number of usages
% 8: number of parents who adopted before me
% 9: fraction of parents who adopted before me
%
% 7,8,9 are the new types of signals (maybe we should normalize 7 for classification)

RawData=load(filename);

% only keep data associated with non-trivial latency values
RawData=RawData(find(RawData(:,5)>=0),:);

% make d_binary
d_binary=sparse(RawData(:,2),RawData(:,1),ones(length(RawData(:,5)),1));
[e1,e2,s]=find(d_binary);
d_binary=sparse(e1,e2,ones(length(s),1)); % gets rid of repeat values

% make sure that user-hashtag pairs are unique
if length(s)~=length(RawData(:,1))
    warning('Original data potentially has repeat values.');
end

% make d_iu
[rows,columns]=size(d_binary);
if strcmp(option,'latency')
    s=RawData(:,5)+1;
    d_iu=sparse(RawData(:,2),RawData(:,1),s);
elseif strcmp(option,'log_latency')
    latency=RawData(:,5)+1;
    d_latency=sparse(RawData(:,2),RawData(:,1),latency);
    d_avg=sum(d_latency,2)./sum(d_binary,2);
    d_log=sparse(rows,columns);
    for r=1:rows
        [e1,e2,vals]=find(d_latency(r,:));
        d_log(r,e2)=log(vals/d_avg(r));
    end
    d_iu=d_log;
elseif strcmp(option,'time')
    d_iu=sparse(RawData(:,2),RawData(:,1),RawData(:,6));
elseif strcmp(option,'number_of_usages')
    d_iu=sparse(RawData(:,2),RawData(:,1),RawData(:,7));
elseif strcmp(option,'number_of_parents')
    d_iu=sparse(RawData(:,2),RawData(:,1),RawData(:,8));
elseif strcmp(option,'fraction_of_parents')
    d_iu=sparse(RawData(:,2),RawData(:,1),RawData(:,9));
elseif strcmp(option,'time_of_tweet')
    d_iu=sparse(RawData(:,2),RawData(:,1),RawData(:,3));
elseif strcmp(option,'LAT')
    [d_latency,d_binary]=make_data_matrices(filename,'latency')
    [rows,cols]=size(d_binary);
    [h,u,value]=find(d_latency); % deconstruct data matrix
    LAT=1./(value); % calculate LAT values from latency data
    d_iu=sparse(h,u,LAT,rows,cols); % reconstruct data matrix
elseif strcmp(option,'LOG_LAT')
    [d_LAT,d_binary]=make_data_matrices(filename,'LAT')
    d_LATTT=d_LAT';
    d_avg=sum(d_LAT,2)./sum(d_binary,2);
    d_log=sparse(cols,rows);
    for c=1:rows
        [e1,e2,vals]=find(d_LATTT(:,c));
        d_log(e1,c)=log(vals/d_avg(c));
    end
    d_iu=d_log';
else
    error('Need to choose a valid data type.');
end
