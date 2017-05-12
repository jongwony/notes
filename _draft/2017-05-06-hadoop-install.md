---
layout: post
title: Hadoop 설치
tags: ['hadoop','install']
---

http://releases.ubuntu.com/16.04/

sudo apt update
sudo apt search jdk
sudo apt install default-jdk

wget http://mirror.apache-kr.org/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz

tar -xzf hadoop-2.7.3.tar.gz

echo "export JAVA_HOME=/usr/lib/jvm/default-java" >> ~/.profile
source ~/.profile

https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html

java6

http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u21-b07-oth-JPR

https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04


web addr

http://blog.cloudera.com/blog/2009/08/hadoop-default-ports-quick-reference/
https://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml

bin/hdfs dfs -help ls

```
bin/hdfs dfs -ls /user/jongwon
```

-put 옵션이 동작하지 않습니다 could only be replicated to 0 nodes, instead of 1.

데이터 노드 문제입니다. 포멧 뿐 아니라 /tmp/hadoop-user 디렉터리를 제거하면 정상적으로 동작합니다.

http://stackoverflow.com/questions/27147096/hadoop-put-command-throws-could-only-be-replicated-to-0-nodes-instead-of-1

http://stackoverflow.com/questions/11889261/datanode-process-not-running-in-hadoop


Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.

https://wiki.apache.org/hadoop/HadoopJavaVersions