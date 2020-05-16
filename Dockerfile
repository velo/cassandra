#
# Copyright 2012-2019 The Feign Authors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

# generate cassandra artifacts
FROM frekele/ant as artifacts

WORKDIR /workdir

COPY / /workdir

RUN ant artifacts -Dno-javadoc=true -Dant.gen-doc.skip=true

# build native image
FROM oracle/graalvm-ce as builder

RUN gu install native-image

WORKDIR /workdir

COPY --from=artifacts /workdir/build/dist/ /workdir

RUN ls -lha

RUN native-image --verbose \
    --no-fallback \
    -H:+ReportExceptionStackTraces \
    -H:EnableURLProtocols=https \
    --report-unsupported-elements-at-runtime \
    --allow-incomplete-classpath \
    --initialize-at-build-time \
    -cp classes:lib/* \
    org.apache.cassandra.service.CassandraDaemon



# test the native image
FROM ubuntu

COPY --from=builder /opt/graalvm-ce-19.0.0/jre/lib/amd64/libsunec.so /
COPY --from=builder /workdir/feign.graalvm.github.githubexample /githubexample

RUN /githubexample



# create docker image with native
FROM ubuntu

COPY --from=builder /opt/graalvm-ce-19.0.0/jre/lib/amd64/libsunec.so /
COPY --from=builder /workdir/feign.graalvm.github.githubexample /githubexample

CMD /githubexample
