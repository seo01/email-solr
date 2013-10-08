#shebang

#TODO: make these overwritable
DATA_DIR=../collection1/data
SOLR_DIR=../../lucene-solr/solr

URL_DIR=$DATA_DIR/urls
POST_JAR=$SOLR_DIR/example/exampledocs/post.jar

mkdir -p $URL_DIR

ALL_URLS=$URL_DIR/all_urls.txt
UNIQ_URLS=$URL_DIR/uniq_urls.txt

#get urls

#TODO: Handle pagination
#TODO: Sed out "=\n"
#TODO: Add an optional date parameter that allows incremental querying

#start=10
curl "http://localhost:8983/solr/collection1/select?q=messageId%3A*&fl=content&wt=json" | jq ".response.docs | map(.content)" | egrep -o "https?://[a-zA-Z0-9./?&=~_]+" >> $ALL_URLS

cat $ALL_URLS | sort -u > $UNIQ_URLS

for $url in `cat $UNIQ_URLS`
do
  java -Ddata=web -jar $POST_JAR $url
done

#TODO: crawl thumbnails for thumbnail files that don't already exist
