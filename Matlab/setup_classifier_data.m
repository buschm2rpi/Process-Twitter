% script for setting up the data for the weak-strong classifier experiments

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Put this header stuff in the processALL.m wrapper script
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% clear all
%
% % absolute paths of file locations
% datafile='/local/home/student/mbusch/Twitter/AllParents/hashtags.adopt.time.coded';
% topicsfile='/local/home/student/mbusch/Twitter/HT_to_INDEX_conversion/hashtag.topics';
% 
% % paths and file names to save as. be descriptive of the data.
% dataname='test';
% saveDIR=['/local/home/student/mbusch/Matlab/Data/Latency/',dataname,'/'];
% % specify option for data matrix construction
% datatype='log_normalized';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make new save directory if it doesn't already exist
if exist(saveDIR,'dir')~=7
    mkdir(saveDIR);
end

% construct sparse data matrices
[d_iu,d_binary]=make_data_matrices(datafile,datatype);

% construct sparse topic matrix
topics=load(topicsfile);
topics=topics(1:size(d_binary,1));
d_topics=make_d_topics(d_binary,topics);

% save data
save([saveDIR,'DATA'],'d_iu','d_binary','d_topics','topics','-v7.3')