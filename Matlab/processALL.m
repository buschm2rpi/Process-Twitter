% wrapper function that executes all of the scripts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert data to Matlab matrices and store in its own respective folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all

% absolute paths of file locations
datafile=getenv('DATAFILE');
topicsfile=getenv('TOPICSFILE');

% paths and file names to save as. be descriptive of the data.
dataname=getenv('DATANAME');
saveDIR=getenv('ROOTDIR');
datatype=dataname; % redundant, change this

% skip running this script if the matrices already exist
if exist([saveDIR,'DATA.mat'],'file')~=2
    
    % run the script
    fprintf('Converting %s data to Matlab readable format...\n',dataname);
    run ./setup_classifier_data.m
    fprintf('Completed converting data to Matlab format.\n');
    
else
    fprintf('Converted %s data already exists.\n',dataname);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run the classifier experiments
% 
% Note: make sure that make_data_matrices.m is configured correctly.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all

% define variables
dataname=getenv('DATANAME');
ROOTDIR=getenv('ROOTDIR');
EDGE_LIST=getenv('EDGE_LIST');
WEAK_CLASSIFIER=getenv('WEAK_CLASSIFIER');
STRONG_CLASSIFIER=getenv('STRONG_CLASSIFIER');
GET_SUBGRAPHS=getenv('SUBGRAPHS'); % unused in (commented out of) the classifier_script.m

% skip this step if only the subgraphs need to be compiled
if ~(strcmp(GET_SUBGRAPHS,'SUBGRAPHS')==1 && isempty(dir([ROOTDIR,WEAK_CLASSIFIER,'/',STRONG_CLASSIFIER,'*.mat']))==0)
    
    % tailor output messages
    if strcmp(GET_SUBGRAPHS,'SUBGRAPHS')==1
        fprintf('Creating subgraphs of %s data with weak classifier: %s...\n',...
            dataname,WEAK_CLASSIFIER);
    else
        fprintf('Creating %s data with weak classifier: %s, and strong classifier: %s...\n',...
            dataname,WEAK_CLASSIFIER,STRONG_CLASSIFIER);
    end
    
    % run the script
    run ./classifier_script.m
    fprintf('Classification task complete. Output located in %s\n',[ROOTDIR,WEAK_CLASSIFIER]);
elseif strcmp(GET_SUBGRAPHS,'SUBGRAPHS')==1
    fprintf('%s data already classified, and only subgraphs need to be compiled.\n', dataname);
else
    fprintf('Skipping classification script of %s data.\n', dataname);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compile the output of the classifier experiments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all

% define variables
dataname=getenv('DATANAME');
ROOTDIR=getenv('ROOTDIR');
EDGE_LIST=getenv('EDGE_LIST');
WEAK_CLASSIFIER=getenv('WEAK_CLASSIFIER');
STRONG_CLASSIFIER=getenv('STRONG_CLASSIFIER');
SUBGRAPHS=getenv('SUBGRAPHS');

% import the hashtag map
% HT_MAP=importdata(getenv('HT_MAP'));
fid=fopen(getenv('HT_MAP'));
HT_MAP=textscan(fid,'%s');
fclose(fid);

% run the script
fprintf('Compiling %s data with weak classifier: %s, and strong classifier: %s...\n',...
    dataname,WEAK_CLASSIFIER,STRONG_CLASSIFIER);
run ./classifier_data_compile.m
fprintf('Data compile complete. Output located in %s\n',[ROOTDIR,WEAK_CLASSIFIER]);