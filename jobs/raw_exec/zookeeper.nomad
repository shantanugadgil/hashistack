job "zookeeper_cluster" {
  datacenters = ["dc1"]
  #type = "service"
  type = "system"

  constraint {
    attribute = node.class
    value     = "zookeeper"
  }

  group "zkgroup" {
    count = 1

    #update {
    #  auto_revert = true
    #}

    restart {
      #attempts = 3
      delay = "30s"
    }

    task "zktask" {
      driver = "raw_exec"
      #shutdown_delay = "10s"
      #kill_timeout = "10s"

      artifact {
        #source      =  "https://www-us.apache.org/dist/zookeeper/zookeeper-3.5.5/apache-zookeeper-3.5.5-bin.tar.gz"
        #source      =  "http://192.168.0.54:8080/www/apache-zookeeper-3.5.5-bin.tar.gz"
        source      = "http://10.20.13.80:8080/www/apache-zookeeper-3.5.5-bin.tar.gz"
        destination = "local/"
      }

      template {
        data = <<EOF
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html"/>
<xsl:template match="configuration">
<html>
<body>
<table border="1">
<tr>
 <td>name</td>
 <td>value</td>
 <td>description</td>
</tr>
<xsl:for-each select="property">
<tr>
  <td><a name="{name}"><xsl:value-of select="name"/></a></td>
  <td><xsl:value-of select="value"/></td>
  <td><xsl:value-of select="description"/></td>
</tr>
</xsl:for-each>
</table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
EOF

        destination = "local/config/configuration.xsl"
      }

      template {
        data = <<EOF
# Copyright 2012 The Apache Software Foundation
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Define some default values that can be overridden by system properties
zookeeper.root.logger=INFO, CONSOLE

zookeeper.console.threshold=INFO

zookeeper.log.dir=.
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.log.maxfilesize=256MB
zookeeper.log.maxbackupindex=20

zookeeper.tracelog.dir=${zookeeper.log.dir}
zookeeper.tracelog.file=zookeeper_trace.log

log4j.rootLogger=${zookeeper.root.logger}

#
# console
# Add "console" to rootlogger above if you want to use this
#
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

#
# Add ROLLINGFILE to rootLogger to get log file output
#
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}
log4j.appender.ROLLINGFILE.MaxFileSize=${zookeeper.log.maxfilesize}
log4j.appender.ROLLINGFILE.MaxBackupIndex=${zookeeper.log.maxbackupindex}
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

#
# Add TRACEFILE to rootLogger to get log file output
#    Log TRACE level and above messages to a log file
#
log4j.appender.TRACEFILE=org.apache.log4j.FileAppender
log4j.appender.TRACEFILE.Threshold=TRACE
log4j.appender.TRACEFILE.File=${zookeeper.tracelog.dir}/${zookeeper.tracelog.file}

log4j.appender.TRACEFILE.layout=org.apache.log4j.PatternLayout
### Notice we are including log4j's NDC here (%x)
log4j.appender.TRACEFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L][%x] - %m%n
EOF

        destination = "local/config/log4j.properties"
      }

      template {
        data        = <<EOH
{{with node}}{{index .Node.Meta "zkid"}}{{end}}
EOH
        destination = "local/myid"
      }

      template {
        data = <<EOH
tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=60
initLimit=10
syncLimit=5
4lw.commands.whitelist=*
{{range $i, $node := nodes}}{{if index .Meta "node_class" | regexMatch "^zookeeper$"}}server.{{index .Meta "zkid"}}={{.Address}}:2888:3888
{{end}}{{end}}
EOH

        destination = "local/config/zoo.cfg"
      }

      template {
        data = <<EOH
#!/bin/bash

set -u
set -x

sleep 10
sync
env | sort
hostname
ifconfig eth1
cat local/config/zoo.cfg

mkdir -p /var/lib/zookeeper
cp -fv local/myid /var/lib/zookeeper/myid

cat /var/lib/zookeeper/myid

./local/apache-zookeeper-3.5.5-bin/bin/zkServer.sh --config ./local/config start-foreground
EOH

        destination = "local/zkrun.bash"
      }

      resources {
        cpu    = 500
        memory = 500

        network {
          port "zookeeper" {
            static = 2181
          }
        }
      }

      config {
        command = "/bin/bash"
        args    = ["local/zkrun.bash"]
      }

      service {
        name = "zookeeper"
        port = "zookeeper"

        check {
          name     = "zookeeper"
          type     = "tcp"
          interval = "60s"
          timeout  = "10s"
          port     = "zookeeper"
        }
      }
    }
  }
}
