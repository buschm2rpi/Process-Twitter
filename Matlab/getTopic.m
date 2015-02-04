function [topic,TOPIC_code]=getTopic(TAG_NAME);

% Purpose: to convert a hashtag name to its topic name. uses environment
% variables
% 
% Input:
%     TAG_NAME = tag name as string
%     
% Output:
%     topic = top name (as string) of given TAG_NAME

fid=fopen(getenv('HT_MAP'));
HT_MAP=textscan(fid,'%s');
fclose(fid);
tag_line=find(strcmp(HT_MAP{1},TAG_NAME));

fid=fopen(getenv('TOPICSFILE'));
HT_coded=textscan(fid,'%s');
fclose(fid);
TOPIC_code=str2num(HT_coded{1}{tag_line(1)});

fid=fopen(getenv('TOPICS_CODE'));
TOPIC_data=textscan(fid,'%s%s%d');
fclose(fid);
TOPIC_list=TOPIC_data{2};

topic=TOPIC_list{TOPIC_code};