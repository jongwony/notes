---
layout: post
title: Hadoop Fully Distributed Setup
tags: ['hadoop','install']
---

## Note

- Hadoop 2.7.3 버전입니다.
- 기본적인 데이터 저장 방식만 고려하여 *yarn* 설정을 하지 않았습니다.
- [우분투 16.04](//releases.ubuntu.com/16.04/) 이미지를 사용하였습니다.
- 기본적으로 싱글 노드에서 테스트하는 Standalone이나 Pseudo-Distributed의 매뉴얼은 [이곳](//hadoop.apache.org/docs/r2.7.3/hadoop-project-dist/hadoop-common/SingleCluster.html)에서 그대로 따라 진행하시면 어렵지 않게 설치가 가능합니다.
- 하둡 자바 호환 버전이 [이곳](//wiki.apache.org/hadoop/HadoopJavaVersions)에 나타나 있지만 1.8 버전으로 진행해도 기본적인 부분은 동작이 잘 되었기 때문에 1.8 버전으로 설치하였습니다.

## HDFS Architecture

하둡의 파일 시스템인 HDFS는 일반적으로 하나의 NameNode와 다수의 DataNode가 master/slave 구조로 이루어진 구조입니다.

![hdfs_arch](/image/hadoop/hdfsarchitecture.gif)

내부적으로 DataNode는 큰 파일을 안정적으로 저장하기 위해 블록 구조로 이루어져 있습니다. 이 블록은 복제되며 기본적으로 64MB로 설정됩니다.

기본적으로 이 정도만 알고 있어도 스스로 네트워크를 구축하는 데 문제가 없습니다.
자세한 아키텍쳐는 [하둡 아키텍처 가이드](//hadoop.apache.org/docs/r1.2.1/hdfs_design.html)를 참조하시기 바랍니다.

## Prototype Modeling

하둡은 대용량 데이터를 처리하기 위해 물리적인 저장 공간인 랙(rack) 내부에 여러 데이터 노드가 있으며 다른 랙에 있는 노드 간의 통신은 스위치를 거쳐야 합니다.

아키텍처에 따라 간단하게 노트북에서 가상화로 가능한 네트워크 토폴로지를 구성해 보도록 하겠습니다.

![test](/image/hadoop/testtopology.png)

저는 가상화 도구로 *Hyper-V*를 사용했으며 다른 가상화 도구를 사용하더라도 차이는 없습니다.

## OS, Network Setup

Windows의 경우 기본적으로 네트워크 공유가 비활성화 되어 있습니다.
다음 설정이 되어 있어야 합니다.

![share](/image/hadoop/sharenetwork.png)

이 작업을 통해 내부 스위치를 통해 외부로 인터넷 접속이 가능합니다.

Hyper-V에서 내부 스위치를 생성한 다음 서브넷 마스크를 고려하여 다음과 같이 설정합니다.

![internal_switch](/image/hadoop/internalswitch.png)

이제 OS를 설치합니다. [우분투 16.04](//releases.ubuntu.com/16.04/) 이미지를 사용하였습니다. 저의 경우 파티션은 자동으로 나누었으며 `hadoop` 유저 생성과 ssh 및 기본 패키지 매니저만 같이 설치하였습니다.

설치가 완료되었으면 호스트를 설정합니다.

```
namenode
```
###### /etc/hostname


```
127.0.0.1       localhost
192.168.137.11  namenode
192.168.137.12  datanode1
192.168.137.13  datanode2
...
```
###### /etc/hosts

```
audo eth0
iface eth0 inet static
    address 192.168.137.11
    ...
    gateway 192.168.137.1
    dns-nameservers 192.168.137.1
```
###### /etc/network/interfaces

재부팅 후 네트워크 공유 설정이 잘 되었는지 ping을 통해 확인해 봅니다.

NameNode 네트워크 설정이 끝났습니다. 이제 putty로 내부 인스턴스로 접근이 가능하며
동시에 내부 네트워크에서 `apt` 패키지 설치가 가능하게 됩니다.

## Hadoop Prerequisites

하둡을 설치하기 전에 먼저 자바 최신 버전을 설치합니다.
다른 버전 설치는 다음 두 링크를 참조하시기 바랍니다.

- [http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u21-b07-oth-JPR](//www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u21-b07-oth-JPR)
- [https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04](//www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04)

```
sudo apt update
sudo apt install default-jdk
```

현재 Java 1.8 버전이 `/usr/lib/jvm` 경로에 설치됩니다.

```
echo "export JAVA_HOME=/usr/lib/jvm/default-java" >> ~/.profile
source ~/.profile
```
###### JAVA_HOME 환경변수 설정

[미러 주소](//apache.mirror.cdnetworks.com/hadoop/common/)에서 하둡을 다운로드 합니다. 2.7.3 버전을 다운로드 하였습니다.

```
wget http://mirror.apache-kr.org/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz

tar -xzf hadoop-2.7.3.tar.gz
```

글로벌로 하둡 환경변수를 추가하였습니다.

```
export HADOOP_PREFIX=/home/hadoop/hadoop-2.7.3
export HADOOP_HOME=$HADOOP_PREFIX
export HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop
```
###### /etc/profile.d/hadoop-prefix.sh

```
sudo source /etc/profile
```

여기까지 설치했으면 이제 가상 인스턴스를 여러개로 복사하여 host IP 주소만 바꾼 DataNode를 만들기만 하면 됩니다.

## ssh Connection

내부 네트워크로 노드 간의 통신을 위해 ssh를 설정합니다.

토폴로지로 구상한 대로라면 NameNode의 비밀키를 통해 각 DataNode의 공개키로 접근하면 됩니다. `scp` 명령을 통해 공개키를 전송합니다.

<div class='def'>
이제부터 NameNode와 DataNode 설정에 혼란을 방지하기 위해 코드에 해당 노드의 캡션을 추가하였습니다.
</div>

```
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
scp ~/.ssh/id_rsa.pub hadoop@datanode1:/home/hadoop/.ssh/id_rsa.pub
scp ~/.ssh/id_rsa.pub hadoop@datanode2:/home/hadoop/.ssh/id_rsa.pub
```
###### namenode

```
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
```
###### datanode1, datanode2

```
ssh datanode1
ssh datanode2
```
###### namenode: ssh establish

이제 비밀번호 없이 ssh를 통해 namenode에서 datanode로 접속이 가능하게 됩니다.

## Configuration

하둡은 자동으로 설정해준 네트워크 토폴로지를 인식하지 못합니다.

**모든 노드**에 파일시스템 주소를 지정하여 IPC를 통해 통신하도록 지정합니다.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
        <property>
                <name>fs.default.name</name>
                <value>hdfs://namenode:9000</value>
        </property>
</configuration>
```
###### everynode(rack): $HADOOP_PREFIX/etc/hadoop/core-site.xml

데몬을 실행할 때의 환경 변수를 지정합니다. 여기서는 가상머신의 RAM이 1GB밖에 안되기 때문에 기본값이 1000으로 지정된 하둡 힙 사이즈를 그대로 쓰면 JVM에서 오류가 발생할 수 있습니다. 기본적인 변수에 대한 자세한 내용은 [공식 문서](//hadoop.apache.org/docs/r2.7.3/hadoop-project-dist/hadoop-common/ClusterSetup.html)를 참조하시기 바랍니다.

```sh
export JAVA_HOME=/usr/lib/jvm/default-java
export HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop
export HADOOP_HEAPSIZE=512
```
###### namenode: $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
        <property>
                <name>dfs.replication</name>
                <value>2</value>
        </property>
        <property>
                <name>dfs.name.dir</name>
                <value>/home/hadoop/hadoop-2.7.3/hdfs/name</value>
        </property>
        <property>
                <name>dfs.namenode.secondary.http-address</name>
                <value>192.168.137.11:50090</value>
        </property>
        <property>
                <name>dfs.permissions</name>
                <value>false</value>
        </property>
</configuration>
```
###### namenode: $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

DataNode가 2개이므로 블록을 2개로 복제하도록 하고 secondary namenode가 기본적으로 `0.0.0.0` 주소로 지정되기 때문에 변경해 주었습니다.

각 DataNode에도 마찬가지로 데이터 경로만 지정해 주면 됩니다.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
        <property>
                <name>dfs.permissions</name>
                <value>false</value>
        </property>
                <property>
                <name>dfs.datanode.data.dir</name>
                <value>/home/hadoop/hadoop-2.7.3/hdfs/data</value>
        </property>
</configuration>
```

마지막으로 slave 호스트를 지정해 줍니다.

```
datanode1
datanode2
```
###### $HADOOP_PREFIX/etc/hadoop/slaves

## Testing

이제 NameNode에서 하둡을 차근차근 오류 없이 구동이 되면 성공입니다.
먼저 파일 시스템을 포맷합니다.

```
$HADOOP_PREFIX/bin/hdfs namenode -format <cluster_name>
```

NameNode 데몬을 구동합니다.

```
$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
```

그 후 NameNode에서 DataNode 데몬을 구동합니다.

```
$HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
```

여기서 뜨는 로그를 확인하셔서 오류메시지 없이 다음과 같은 로그가 나오면 제대로 구동이 된 것입니다.

![log](/image/hadoop/namenodelog.png)

앞의 데몬 구동 명령과 중복되는 부분이 있지만 secondary namenode까지 완전히 구동하는 스크립트는 `start-dfs.sh` 파일입니다.

```
$HADOOP_PREFIX/sbin/start-dfs.sh
```

구동이 되면 [공식 문서](//hadoop.apache.org/docs/r2.7.3/hadoop-project-dist/hadoop-common/SingleCluster.html)의 *Pseudo-Distributed Operation*에서 MapReduce 작업을 테스트하는 과정을 따라가봅니다.

```
bin/hdfs dfs -mkdir /user
bin/hdfs dfs -mkdir /user/jongwon
bin/hdfs dfs -put etc/hadoop /user/jongwon
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.3.jar grep /user/jongwon/hadoop /user/hadoop/output 'dfs[a-z.]+'
bin/hdfs dfs -ls /user/hadoop/output
bin/hdfs dfs -cat /user/hadoop/output/part-r-00000
```

![result](/image/hadoop/result.png)

보시다시피 `dfs[a-z.]+` 정규표현식을 `grep`하는 테스트도 정상적으로 동작함을 알 수 있습니다.

## Trouble Shooting

<div class='warn'>
-put 옵션만 동작하지 않습니다 could only be replicated to 0 nodes, instead of 1.
</div

보통 데몬 구동 중 잘못 포맷을 하거나 해서 발생하는 DataNode 문제입니다. 포맷 뿐 아니라 `/tmp/hadoop-user` 디렉터리를 제거하면 정상적으로 동작합니다. 

-[http://stackoverflow.com/questions/27147096/hadoop-put-command-throws-could-only-be-replicated-to-0-nodes-instead-of-1](//stackoverflow.com/questions/27147096/hadoop-put-command-throws-could-only-be-replicated-to-0-nodes-instead-of-1)

- [http://stackoverflow.com/questions/11889261/datanode-process-not-running-in-hadoop](//stackoverflow.com/questions/11889261/datanode-process-not-running-in-hadoop)

<div class='warn'>
Error: Could not create the Java Virtual Machine.<br>
Error: A fatal exception has occurred. Program will exit.
</div>

HEAPSIZE를 잘못 설정하였거나 명령어를 잘못 입력했을 때 발생합니다.

<div class='warn'>
WARN hdfs.DFSClient: Caught exception
java.lang.InterruptedException
</div>

이는 버그이며 무시 할 수 있습니다.

- [https://issues.apache.org/jira/browse/HDFS-10429](//issues.apache.org/jira/browse/HDFS-10429)