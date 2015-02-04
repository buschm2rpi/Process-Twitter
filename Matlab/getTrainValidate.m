function [d_train,d_validate]=getTrainValidate(d_binary,tag_list,user_list,v_tags)

% Input:
%     d_binary = sparse indicator matrix of the data
%     tag_list = list of hashtag indices that are to be studied
%     user_list = list of user ids that are to be studied
%     v_tags = tags contained in tag_list that are to removed for validation
%     
% Output:
%     d_train = sparse indicator matrix of the training data
%     d_validate = sparse indicator matrix of the validation data

[r,c]=size(d_binary);

% make topic unique matrices so that indices don't get messed up
d_train=sparse(r,c);
d_train(tag_list,user_list)=d_binary(tag_list,user_list);
d_validate=sparse(r,c);
% d_train(:,user_list)=d_iu(:,user_list);

% move hashtag from training set to validation set
% tag=tag_list(randi(length(tag_list),1,1)); % choose only one tag to remove
d_validate(v_tags,:)=d_train(v_tags,:);
d_train(v_tags,:)=0;