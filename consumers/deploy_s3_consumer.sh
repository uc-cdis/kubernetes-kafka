#!/bin/bash
echo "S3 access key for pushing to S3:"
read access_key 

echo "S3 secret key for pushing to S3:"
read secret_key

export S3_ACCESS_KEY=$access_key S3_SECRET_KEY=$secret_key 

if [[ ! -z $access_key && ! -z $secret_key ]]; then
    envsubst <10secrets.yml | kubectl apply -f -
else
    echo "Secrets not provided, skip configuring"
fi

echo "current environment:"
read environment

echo "topic to subscribe:"
read topic

echo "number of partitions(default to 1):"
read partitions

echo "number of replications(default to 1):"
read replications 

if [[ ! -z $topic ]]; then
    echo "Creating topic"
    kubectl exec kafka-0 -- ./bin/kafka-topics.sh --zookeeper zookeeper:2181 --topic $topic --create --partitions ${partitions:-1} --replication-factor ${replications:-1}
    echo "Creating consumer group"
    kubectl exec kafka-0 -- ./bin/kafka-console-consumer.sh --zookeeper zookeeper:2181 --topic $topic --consumer-property group.id=${topic}_to_S3 &
    last_pid=$!
    sleep 1
    kill -9 $last_pid >/dev/null 2>&1
    export TOPIC=$topic
    export ENVIRONMENT=$environment
    envsubst <00configmap.yml | kubectl apply -f -
else
    echo "Topic not provided"
    exit 1
fi



kubectl apply -f 20s3consumer.yml

