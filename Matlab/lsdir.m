function dir_list=lsdir(directory)

% Input:
%     directory = directory to check the contents of
%     
% Output:
%     dir_list = cell array that is a list of sub-directories of input directory

% make temporary list of directories
list_dir=dir(directory);
dir_list_temp=cell(length(list_dir)-2,1);
count=0;
for i=3:length(list_dir)
    if list_dir(i).isdir==1
        count=count+1;
        dir_list_temp{count}=list_dir(i).name;
    end
end

% make final list of directories from temporary list of directories by
% removing the empty cell elements
dir_list=cell(count,1);
for i=1:count
    dir_list{i}=dir_list_temp{i};
end