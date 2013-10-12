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
  #TODO: crawl headers and check there isn't a 40X err
  #TODO: check it is not already indexed
  domain=`echo $url | egrep -o "//[^/?]+" | egrep -o "[^/?]+"`
  java -Ddata=web -Dparams=literal.domain=$domain -jar $POST_JAR $url
done

#TODO: crawl thumbnails for thumbnail files that don't already exist
THUMBNAIL_ROOT=$URL_ROOT/img/thumbnails/
mkdir -p $THUMBNAIL_ROOT

for url in `cat $UNIQ_URLS`
do
  ENCODED=`urlencode $url`
  $WEBKIT2PNG -D $THUMBNAIL_ROOT -o $ENCODED -C $url
done
