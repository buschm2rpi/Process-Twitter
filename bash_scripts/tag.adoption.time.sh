#!/bin/bash

export NAME="topics";
export BASE=$(pwd)/../data;

# TODO(Razvan,Petko) need to change this to keep all mentions of tags within a topic
# The rest of the script should be updated as well

<<comment_keep_first_mention
date
zcat $BASE/*.tar.gz | gawk -F "\t" '
{
  c++
  if(c%100000 == 0)
    print c > "/dev/stderr"
  gsub(/[\-\:]/," ",$1); 
  ts = mktime($1); 
  gsub(" ","",$2); # for some reason there were spaces next to the user names
  gsub("#","  #",$3);
  n = split($3, htgs, "[ ]+");
  for(i=1;i<=n;i++) {
    if (htgs[i]=="") continue;
    key=$2 "\t" htgs[i]; 
    if (!(key in first)) first[key] = ts;
    else if(first[key]>ts) first[key] = ts;
  }
}
END {
  for (k in first) {
    print k "\t" first[k];
  }
}
' > user_tag_fts
comment_keep_first_mention

#keep all mentions, format: 
<<comment_keep_all_mentions
date
zcat $BASE/*.tar.gz | gawk -F "\t" '
{
  c++
  if(c%100000 == 0)
    print "user_tag_all " c > "/dev/stderr"

  gsub(/[\-\:]/," ",$1); 
  ts = mktime($1); 
  gsub(" ","",$2); # for some reason there were spaces next to the user names
  gsub("#","  #",$3);
  n = split($3, htgs, "[ ]+");
  for(i=1;i<=n;i++) {
    if (htgs[i]=="") continue;
    key=$2 "\t" htgs[i]; 
    if (!(key in first)){
      first[key] = ts;
      all[key] = ts;
    }
    else {
      if (!(key in first)) first[key] = ts;
      all[key] = all[key] " " ts;
    }
  }
}
END {
  for (k in first) {
    print k "\t" first[k] "\t" all[k];
  }
}
' > user_tag_all
comment_keep_all_mentions

<<comment_all

date
echo "Select the tag group related tag mentions"
# First select the tag group
gawk -F "\t" -v gfn=tagGroups.txt '
BEGIN{
  # build a hashtag to topic map
  while((getline line < gfn)!=0){
    n=split(line,lines," ");
    for (i=2;i<=n;i++){
      if(lines[i]!~/ +/ && lines[i]!="" ){
        tags["#" lines[i]]=lines[1];

      }
    }
  }
  close(gfn);
} 

(tolower($2) in tags){
  gsub(" ","",$1); 
  if (!($1 in u)) print $1;
  u[$1]="";
} ' user_tag_all | sort | uniq > $NAME.users

date
echo "Get ids to filter follower graph"
# Get ids to filter follower graph ## ??? only half of the users found
gawk -F " " -v fn=$NAME.users '
BEGIN{ 
  #mark names we are interested in 
  while((getline line < fn)!=0) 
    u[line]=""
  close(fn);
}

($2 in u){  
  #print id,name for previously marked names
  print $1 "\t" $2
}' $BASE1/numeric2screen > $NAME.users.id


date
echo "Get followees"
# Get followees
cat $BASE1/twitter_rv | gawk -F " " -v fn=$NAME.users.id '
BEGIN{ 
  #mark ids we are interested in 
  while((getline line < fn)!=0){ 
    split(line,lines,"\t");
    u[lines[1]]=""
  }
}
{
  c++
  if(c%1000000 == 0)
    print ".followee.follower.ids " c > "/dev/stderr"
  # print edge between previously marked ids
  if (($2 in u) && ($1 in u)) print $1 "\t" $2; 
}
' > $NAME.followee.follower.ids
comment_all
date
echo "Computing adoption intervals" 


gawk -F "\t" -v fn=$NAME.users.id -v sfn=$NAME.followee.follower.ids -v gfn=tagGroups.txt '
BEGIN{
  # build a hashtag to topic map and a topic to hashtag one
  while((getline line < gfn)!=0){
    n=split(line,lines," ");
    for (i=2;i<=n;i++){
      if(lines[i]!~/ +/ && lines[i]!=""){
        tags["#" lines[i]]=lines[1];
        if (!(lines[1] in topic)) topic[lines[1]] = "#" lines[i];
        else topic[lines[1]] = topic[lines[1]] " #" lines[i];
        
      }
    }
  }
  close(gfn);

  # build a name to id map
  while((getline line < fn)!=0){ 
    split(line,lines,"\t");
    u[lines[2]]=lines[1];
  }
  close(fn);
 
  #build a id to ids of followees map
  while((getline line < sfn)!=0) {
    split(line,lines,"\t");
    followees[lines[2]] = followees[lines[2]] " " lines[1];
  }
  close(sfn);
}

#store all timestamps for relevant id, hashtag pairs
(tolower($2) in tags && $1 in u){
  tft[u[$1] " " tolower($2)]=$4;
  first[u[$1] " " tolower($2)]=$3;
}

END {
  for (ut in tft) {
    c++
    if(c%100000 == 0)
      print "user.adoption " c > "/dev/stderr"

    split(ut,uts," ");
    usr = uts[1];
    count = -1;
    tag = uts[2];
    parents = followees[usr];
    n = split(parents, pars, " ");
    exposure=-1;
    infparent=-1;
    usage = first[ut] #first usage of the hashtag
    # get the first parent that mentioned the tag and the time he mentioned it at
    for(i=1; i<=n; i++) {
      pt = pars[i] " " tag;
      if (pt in first) {
        if ((exposure == -1 || first[pt] < exposure) && first[pt] < usage) {
          exposure = first[pt];
          infparent = pars[i];
        }
      }
    }
    if(exposure != -1) {
      count = 0;
      split(topic[tags[tag]],allTags," ");
      times = "";
      for (ctg in allTags) {
        cur = usr " " allTags[ctg];        
        if(cur != ut && cur in tft)
          times = times " " tft[cur]
      }
      # print exposure " " usage " " times > "/dev/stderr"
      split(times,alltimes," ");


      for (ctime in alltimes) {
        
        if(alltimes[ctime] > exposure && alltimes[ctime] < usage) {
          count++;
        }
      }
    }
    print usr "\t" tag "\t" infparent "\t" count "\t" exposure "\t" usage;
  }
}
' user_tag_all > $NAME.adopt.time

