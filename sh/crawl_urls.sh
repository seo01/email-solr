#!/bin/sh

#TODO: make these overwritable
DATA_DIR=../collection1/data
SOLR_DIR=../../lucene-solr/solr
WEBKIT2PNG=../../webkit2png/webkit2png

URL_ROOT=$SOLR_DIR/example/solr-webapp/webapp

URL_DIR=$DATA_DIR/urls
POST_JAR=$SOLR_DIR/example/exampledocs/post.jar

mkdir -p $URL_DIR

ALL_URLS=$URL_DIR/all_urls.txt
UNIQ_URLS=$URL_DIR/uniq_urls.txt
MORE_URLS=$URL_DIR/more_urls.txt

THUMBNAIL_ROOT=$URL_DIR/thumbnails/
mkdir -p $THUMBNAIL_ROOT 

COPY_TO_THUMBS=$URL_ROOT/img/thumbnails/

urlencode() {
    local l=${#1}
    for (( i = 0 ; i < l ; i++ )); do
        local c=${1:i:1}
        case "$c" in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            ' ') printf + ;;
            *) printf '%%%X' "'$c"
        esac
    done
}

#get urls

#TODO: Handle pagination
#TODO: Sed out "=\n"
#TODO: Add an optional date parameter that allows incremental querying

#start=10
#rows=1000
curl "http://localhost:8983/solr/collection1/select?q=messageId%3A*&fl=content&wt=json&rows=10000" | jq ".response.docs | map(.content)" | egrep -o "https?://[a-zA-Z0-9./?&=~_%-]+" > $ALL_URLS

cat $ALL_URLS | gsort -u -R > $UNIQ_URLS

for url in `cat $UNIQ_URLS`
do
  
  #TODO: check it is not already indexed
  ENCODED=`urlencode $url`
  NUM_FOUND=`curl --stderr /dev/null "http://localhost:8983/solr/collection1/select?q=id%3A%22{$ENCODED}%22&fl=id&wt=json" | jq .response.numFound`

  if [ "x1" = "x$NUM_FOUND" ]
  then
  	echo "Already indexed"
  else 
	  curl --stderr /dev/null -I $url | head -n1 | egrep "(2|3)0[0-9]"
	  if [ "x$?" = "x0" ]
	  then
		  domain=`echo $url | egrep -o "//[^/?]+" | egrep -o "[^/?]+"`
		  gtimeout 20 java -Ddata=web -Dparams=literal.domain=$domain -jar $POST_JAR $url
	   else
	     echo "Return code not 20X or 30X"
	   fi
  fi
done

curl "http://localhost:8983/solr/collection1/select?q=domain%3A*&fl=id&wt=json&rows=10000" | jq -r ".response.docs | map(.id)" | egrep -o '[^", ]+' | grep "http" > $MORE_URLS

cat $ALL_URLS $MORE_URLS | gsort -u -R > $UNIQ_URLS

for url in `cat $UNIQ_URLS`
do
  ENCODED=`urlencode $url`
  DEST_FILE={$THUMBNAIL_ROOT}/{$ENCODED}-clipped.png
  if [ -a $DEST_FILE ]
  then
    echo "File already exists"
  else
    curl --stderr /dev/null -I $url | head -n1 | egrep "(2|3)0[0-9]"
	if [ "x$?" = "x0" ]
	then
      gtimeout 30 $WEBKIT2PNG -D $THUMBNAIL_ROOT -o $ENCODED -C $url
    else
	  echo "Return code not 20X or 30X"
	fi
  fi
done

cp -r $THUMBNAIL_ROOT $COPY_TO_THUMBS
