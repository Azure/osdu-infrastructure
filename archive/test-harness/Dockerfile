#  Copyright © Microsoft Corporation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

ARG base_image

FROM $base_image

ARG build_directory
RUN echo "INFO: copying $build_directory"
# Copy the recently modified terraform templates
ADD $build_directory *.go ./
RUN find ./ -type f -iname "*.sh" -exec chmod +x {} \;

RUN echo "INFO: copying test-harness"
ADD test-harness/ ./test-harness

# Run a fresh clean/format/test run
CMD ["go", "run", "magefile.go"]