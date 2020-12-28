# Simple RBAC Demo without LDAP
Minimal Confluent Server configuration to experiment with MDS/RBAC.  Tested with CP 5.5.1.

## Initialization
1. Generate MDS token keypair and `login.properties` file to `/tmp`
```sh
./init.sh
```
2. Start Zookeeper (default `zookeeper.properties` included)
```sh
./zookeeper-server-start zookeeper.properties
```
3. Start Confluent Server
```sh
./kafka-server-start server.properties
```

## Bind MDS role
1. From `/tmp` check `login.properties` was created with one user `mds` and password `mds1`:
```
mds:mds1
```
2. Login to Confluent Server
```sh
$ confluent login --url http://localhost:8090
Enter your Confluent credentials:
Username: mds
Password: ****
Logged in as "mds".
```
3. Describe the cluster
```sh
$ confluent cluster describe --url http://localhost:8090
Confluent Resource Name: 1234567890ABCDEFGHIJKL
Scope:
      Type      |           ID
+---------------+------------------------+
  kafka-cluster | 1234567890ABCDEFGHIJKL
```
4. Get the cluster ID from the previous command and export it to `$KAFKA_CLUSTER_ID`
```sh
export KAFKA_CLUSTER_ID=1234567890ABCDEFGHIJKL
```
5. Bind the `UserAdmin` role to the `mds` user
```sh
confluent iam rolebinding create --kafka-cluster-id $KAFKA_CLUSTER_ID --principal 'User:mds' --role UserAdmin
```
6. List the role
```sh
confluent iam rolebinding list --kafka-cluster-id $KAFKA_CLUSTER_ID --principal 'User:mds'
```
7. Remove `User:mds` from `super.users` in `server.properties`
8. Restart Kafka

## Bind client roles
1. (Login to Confluent Server)
2. Add the following roles to allow `User:weikang` minimum permission to read/write to topic `test`
```sh
confluent iam rolebinding create --kafka-cluster-id $KAFKA_CLUSTER_ID --principal 'User:weikang' --role DeveloperRead --resource 'Topic:test'
confluent iam rolebinding create --kafka-cluster-id $KAFKA_CLUSTER_ID --principal 'User:weikang' --role DeveloperRead --resource 'Group:console-consumer-' --prefix
confluent iam rolebinding create --kafka-cluster-id $KAFKA_CLUSTER_ID --principal 'User:weikang' --role DeveloperWrite --resource 'Topic:test'
```
3. List the roles
```sh
confluent iam rolebinding list --kafka-cluster-kd $KAFKA_CLUSTER_ID --principal 'User:weikang'
```

## Create topics
1. Create topic `test` (as `User:kafka`, a super user)
```sh
kafka-topics --bootstrap-server localhost:9094 --command-config client_kafka.properties --create --topic test --partitions 1 --replication-factor 1
```
2. Create topic `test-noauth`
```sh
afka-topics --bootstrap-server localhost:9094 --command-config client_kafka.properties --create --topic test-noauth --partitions 1 --replication-factor 1
```

## Produce and Consume topic
1. Produce to the `test` topic as `User:weikang`, connecting to the `EXTERNAL` listener
```sh
$ kafka-console-producer --bootstrap-server localhost:9093 --producer.config client_weikang.properties --topic test
>123
>abc
>789
^C
```
2. Consume from the `test` topic as `User:weikang`
```sh
$ kafka-console-consumer --bootstrap-server localhost:9093 --consumer.config client_weikang.properties --topic test --from-beginning
123
abc
789
^C
```
3. Try to produce to or consume from topic `test-noauth` as the same user, should receive no authorization:
```
org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [test-noauth]
```

## Additional things to try
* Remove the user `mds:mds1` from `login.properties` and restart Kafka.  Are you still able to do `confluent login`? Are you still able to produce/consume as `User:weikang`?
* Add a `PLAINTEXT` listener and attempt to produce/consume.  What additional roles are needed? (Hint: `User:ANONYMOUS`)
* Add/uncomment the `TOKEN` listener to experiment with connecting CP components.  Once this listener is up, try to authenticate with `client_token.properties` when connecting to the `TOKEN` listener.
* Regenerate the MDS keypair but specify 1024-bit RSA length instead of 2048 (see `init.sh`).  Does Kafka/MDS still start?  What happens with `confluent login`?
