#!/bin/bash

export NAME="topics";
export BASE=$(pwd)/../data;


# TODO(Razvan,Petko) need to change this to keep all mentions of tags within a topic
# The rest of the script should be updated as well

<<comment_keep_only_first_mention
date
zcat $BASE/*.txt.gz | gawk -F "\t" '
{
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
comment_keep_only_first_mention


date
echo "Select the tag group related tag mentions"
# First select the tag group
gawk -F "\t" -v gfn=tagGroups.txt '
BEGIN{
  # build a hashtag to topic map
  while((getline line < gfn)!=0){
    n=split(line,lines,"\t");
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
} ' user_tag_fts | sort | uniq > $NAME.users

date
echo "Get ids to filter follower graph"
# Get ids to filter follower graph ## ??? only half of the users found
gawk -F " " -v fn=$NAME.users '
BEGIN{
  while((getline line < fn)!=0) 
    u[line]=""
  close(fn);
}
 
($2 in u){
  print $1 "\t" $2
}' $BASE/numeric2screen > $NAME.users.id


date
echo "Get followees"
# Get followees
cat $BASE/twitter_rv | gawk -F " " -v fn=$NAME.users.id '
BEGIN{
  while((getline line < fn)!=0){ 
    split(line,lines,"\t");
    u[lines[1]]=""
  }
}
{
  if (($2 in u) && ($1 in u)) print $1 "\t" $2;
}
' > $NAME.followee.follower.ids

date
echo "Computing adoption intervals" 

gawk -F "\t" -v fn=$NAME.users.id -v sfn=$NAME.followee.follower.ids -v gfn=tagGroups.txt '
BEGIN{
  # build a hashtag to topic map
  while((getline line < gfn)!=0){
    n=split(line,lines,"\t");
    for (i=2;i<=n;i++){
      if(lines[i]!~/ +/ && lines[i]!=""){
        tags["#" lines[i]]=lines[1];
      }
    }
  }
  close(gfn);
  while((getline line < fn)!=0){ 
    split(line,lines,"\t");
    u[lines[2]]=lines[1];
  }
  close(fn);
 
  while((getline line < sfn)!=0) {
    split(line,lines,"\t");
    followees[lines[2]] = followees[lines[2]] " " lines[1];
  }
  close(sfn);
}

(tolower($2) in tags && $1 in u){
  tft[u[$1] " " $2]=$3;
}

END {
  for (ut in tft) {
    split(ut,uts," ");
    usr = uts[1];
    tag = uts[2];
    parents = followees[usr];
    n = split(parents, pars, " ");
    interval=-1;
    infparent=-1;
    # get the first parent that mentioned the tag and the time lag
    for(i=1; i<=n; i++) {
      pt = pars[i] " " tag;
      if (pt in tft) {
        if (tft[pt] < tft[ut]) {
          if (interval < tft[ut] - tft[pt]) {
            interval = tft[ut] - tft[pt];
            infparent = pars[i];
          }
        }
      }
    }
    print usr "\t" tag "\t" infparent "\t" interval;
  }
}
' user_tag_fts > $NAME.user.adoption

