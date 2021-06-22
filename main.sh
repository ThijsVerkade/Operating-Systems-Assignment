#!/bin/bash
TRASH=~/trash

# Initialize alias
alias rm=Main

mkdir -p  ~/trash
touch ~/trash/logger.txt

Main(){
  CheckVariable
  TAR=${@: -1 | xargs }
  if [ $# -eq 1 ] && [ "$STATE" != "ERROR" ] ; then
    if [ "$STATE"  == "DIR" ]; then
      echo "Please use an -r when removing a directory"
    else
      Delete
    fi
  elif [ $# -eq 2 ]; then
    if [ $1 == "-u" ]; then
      UnDelete
    elif [ $1 == "-r" ] && [ "$STATE"  != "ERROR" ]; then
      Delete
    fi
  elif [ $# -eq 3 ]  && [ "$STATE"  != "ERROR" ] ; then
    if [ $1 == "-p" ]; then
      PASS=$2
      DeletePassword
    fi
  elif [ $# -eq 4 ] && [ "$STATE"  != "ERROR" ] ; then
    if [ $1 == "-r" ] && [ $2 == "-p" ]; then
      PASS=$3
      DeletePassword
    fi
  else
    GetHelper
  fi
}

# TODO:
# will delete myfile.dat by zipping and moving it to the trash directory
Delete(){
  Confirmation
  if [ $CONF == "1" ]; then
    PW="false"
    NAME="$TRASH/$TAR.zip"
    if [ $STATE == "FILE" ]; then
      zip -r $NAME $TAR
      SetLogger
      \rm -rf $TAR
    elif [ $STATE == "DIR" ]; then
      zip -r $NAME $TAR/*
      SetLogger
      \rm -rf $TAR
    fi
  fi
}

# TODO:
# will undelete myfile.dat
# will prompt :  The file is password protected. Please enter the password
# undeletes Pics and its subdirectories
# deletes Pics directory and its subdirectories
# undeletes  Pics  and  its  subdirectories.
# The  user  will  receive  the  message:  The file is password protected. Please enter the password
UnDelete(){
  GetDeleted
  if [ "$result" != "" ]; then
    for i in $(echo $result | sed "s/|/ /g")
    do
      if [[ "$i" == *"destination="* ]]; then
        destination="$i"
      fi
      if [[ "$i" == *"new="* ]]; then
        new="$i"
      fi
      if [[ "$i" == *"file="* ]]; then
        file="$(echo $i | sed 's/.*=//')"
      fi
    done
    if [ -f "$file" ];then
      ConfirmationReplace
    else
      UnZip
    fi
    \rm -rf $(echo $new | sed 's/.*=//')
  else
    echo "ERROR: File/Directory not found"
  fi
}

UnZip(){
  unzip $(echo $new | sed 's/.*=//')
}

# TODO:
# The rm  command  provides  the  possibility  of  retrieving  the  deleted  files  to  the  current directory
# will return "" when no results
# IMPORTANT REMOVE FILE WHEN ALREADY FOUND
GetDeleted(){
  find="file"
  result=""
  
  if [ -f "$TAR" ];then
    while IFS= read -r line; do
      for i in $(echo $line | sed "s/ | / /g")
      do
        if [ $i == "$find=$TAR" ]; then
          result=$line
          echo result
        fi
      done
    done < ~/trash/logger.txt
  fi
}

# TODO:
# will  delete  sampleFile  by  password  protected  zipping  the  file  and  moving  it  to trash directory
DeletePassword(){
  Confirmation
  read -p "Do you want to set a Password to encrypt your files? (Y/N)" answerEncrypt
  if [ "$answerEncrypt" == "Y" ] || [ "$answerEncrypt" == "y" ];then
    if [ $CONF == "1" ]; then
      read -s -p "Please set a password to encrypt your files: " passwordEncrypt
      PW="true"
      NAME="$TRASH/$TAR.zip"
      if [ $STATE == "FILE" ]; then
        read -s -p "Please enter you password: " PWD2
        if [ $PWD2 = $passwordEncrypt ]; then
          zip -P $PASS -r $NAME $TAR
          SetLogger
          unlink $TAR
        else
          echo PWD is niet juist!
        fi
      elif [ $STATE == "DIR" ]; then
        read -s -p "Please enter you password: " PWD
        if [ $PWD = $passwordEncrypt ]; then
          #echo ik kom erin!
          zip -P $PASS -r $NAME $TAR #/*
          SetLogger
          \rm -rf $TAR
        else
          echo PWD is niet juist!
        fi
      fi
    fi
  elif [ "$answerEncrypt" == "N" ] || [ "$answerEncrypt" == "n" ]; then
    if [ $CONF == "1" ]; then      
      PW="true"
      NAME="$TRASH/$TAR.zip"
      if [ $STATE == "FILE" ]; then              
          zip -P $PASS -r $NAME $TAR
          SetLogger
          unlink $TAR       
      elif [ $STATE == "DIR" ]; then
          #echo ik kom erin!
          zip -P $PASS -r $NAME $TAR #/*
          SetLogger
          \rm -rf $TAR       
      fi
    fi
  else
    echo "Choose (Y/N)"
  fi
}

SetLogger(){
  path=$(realpath $TAR)
  des=$(echo $path | sed "s/$TAR//")
  echo "new=$NAME | old=$path | file=$TAR | pw=$PW | destination=$des | state=$STATE" >> ~/trash/logger.txt
}

Confirmation(){
  read -p "Are u sure u want to delete this file? (Y/N) " del
  if [ "$del" == "Y" ] || [ "$del" == "y" ]; then
    CONF="1"
  elif [ "$del" == "N" ] || [ "$del" == "n" ]; then
    CONF="0"
  else
    echo "Choose (Y/N)"
    Confirmation
  fi
}
ConfirmationReplace(){
  read -p "Are u sure u want to replace this file/directory? (Y/N) " del
  if [ "$del" == "Y" ] || [ "$del" == "y" ]; then
    DEL="1"
    \rm -rf $file
    UnZip
  elif [ "$del" == "N" ] || [ "$del" == "n" ]; then
    DEL="0"
  else
    echo "Choose (Y/N)"
    ConfirmationReplace
  fi
}

GetHelper(){
  echo "rm myfile.dat "
  echo " # will delete myfile.dat by zipping and moving it to the trash directory"
  echo "rm –u myfile.dat "
  echo " # will undelete myfile.dat"
  echo "rm –p MyPass1 sampleFile "
  echo " # will  delete  sampleFile  by  password  protected  zipping  the  file  and  moving  it  to trash directory"
  echo "rm –u sampleFile "
  echo " # will prompt :  The file is password protected. Please enter the password"
  echo "rm –r Pics "
  echo " # deletes Pics directory and its subdirectories"
  echo "rm –u Pics "
  echo " # undeletes Pics and its subdirectories"
  echo "rm –r –p secretKey2 Pics "
  echo " # deletes  Pics  directory  and  its  subdirectories  by  password  protected  zipping them"
  echo "rm –u Pics "
  echo " # undeletes  Pics  and  its  subdirectories.  The  user  will  receive  the  message:  The file is password protected. Please enter the password"
}

CheckVariable(){
  if [[ -d $TAR ]]; then
    STATE="DIR"
  elif [[ -f $TAR ]]; then
    STATE="FILE"
  else
    STATE="ERROR"
  fi
}
