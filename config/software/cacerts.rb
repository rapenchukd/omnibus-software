#
# Copyright 2012-2014 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name 'cacerts'
default_version '2014.04.22'

# This locally cached version of the cacert.pem has the BloombergRootCA.pem
# concatenated to the end of it.
version '2014.04.22' do
  source url: 'https://raw.githubusercontent.com/bagder/ca-bundle/5a391619cb2490d3304a91c71e2fa338a0557f81/ca-bundle.crt'
end

s3_path = 'https://s3.iny1.bcpc.bloomberg.com/webops/certs'
source url: "#{s3_path}/BloombergLPGithHubEnterprise.cert", md5: 'bc0966bee2d30ad6ac60500251978b0b'
source url: "#{s3_path}/BloombergLPCorpClass1RootCA.cert", md5: '7e5638d0a9ebe556cc3651d810f41d97'
source url: "#{s3_path}/BloombergLPCorpClass1SubCA.cert", md5: '86febcb519eb38c50d5e97ee77d1520d'
source url: "#{s3_path}/SystemSecurityRootCA.cert", md5: 'f02814f57fc3aeba68f28a4547736f48'

relative_path "cacerts-#{version}"

build do
  block do
    FileUtils.mkdir_p(File.expand_path("embedded/ssl/certs", install_dir))

    # Apply the corporate root certificates required for various MITM SSL
    # issues that plague us here in a big Enterprise.
    cacert_file = File.expand_path("cacert-#{version}.pem", Omnibus.config.cache_dir)
    IO.open(cacert_file, 'w') do |file|
      Dir.glob(File.join(Omnibus.config.cache_dir, '*.cert')).each do |cert|
        file.puts IO.readlines(cert)
        file.flush
      end
    end

    # There is a bug in omnibus-ruby that may or may not have been
    # fixed. Since the source url does not point to an archive,
    # omnibus-ruby tries to copy cacert.pem into the project working
    # directory. However, it fails and copies to
    # '/var/cache/omnibus/src/cacerts-2012.12.19\' instead There is
    # supposed to be a fix in omnibus-ruby, but under further testing,
    # it was unsure if the fix worked. Rather than trying to fix this
    # now, we're filing a bug and copying the cacert.pem directly from
    # the cache instead.
    FileUtils.cp(cacert_file,
      File.expand_path("embedded/ssl/certs/cacert.pem", install_dir))
  end

  unless platform == 'windows'
    command "ln -sf #{install_dir}/embedded/ssl/certs/cacert.pem #{install_dir}/embedded/ssl/cert.pem"
  end
end
