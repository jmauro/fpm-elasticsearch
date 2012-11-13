class Elasticsearch < FPM::Cookery::Recipe
  description 'Open Source, Distributed, RESTful Search Engine'
  name        'elasticsearch'
  version     '0.19.11'
  revision    '1'
  homepage    'http://www.elasticsearch.org/'
  source      "https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-#{version}.tar.gz"
  sha256      '214096db24e90b429e667b0ec23c9f97426bdf2f46d1105dcbf3334468984b1c'
  arch        'all'
  section     'database'

  java = [
    'openjdk-7-jdk', 'openjdk-7-jre', 'openjdk-7-jre-headless',
    'openjdk-6-jdk', 'openjdk-6-jre', 'openjdk-6-jre-headless'
  ]

  depends java.join(' | ')

  config_files '/etc/elasticsearch/elasticsearch.yml',
    '/etc/elasticsearch/logging.yml',
    '/etc/security/limits.d/elasticsearch.conf',
    '/etc/init.d/elasticsearch',
    '/etc/default/elasticsearch'

  post_install   'post-install'
  pre_uninstall  'pre-install'
  post_uninstall 'post-uninstall'

  def share (path = nil)
	  opt/path
  end

  def bin (path =  nil)
	  share/bin/path
  end

  def build
    rm_f Dir['bin/*.bat']
    mv 'bin/plugin', 'bin/elasticsearch-plugin'

    inline_replace %w{bin/elasticsearch bin/elasticsearch-plugin} do |s|
      s.gsub! %{ES_HOME=`dirname "$SCRIPT"`/..}, 'ES_HOME=/opt/elasticsearch/'
    end

    inline_replace 'bin/elasticsearch.in.sh' do |s|
      s << "\n"
      s << "ES_JAVA_OPTS=\"-Des.config=/etc/elasticsearch/elasticsearch.yml\"\n"
    end

    inline_replace 'config/elasticsearch.yml' do |s|
      s.gsub! "# path.conf: /path/to/conf\n", "path.conf: /etc/elasticsearch\n"
      s.gsub! "# path.logs: /path/to/logs\n", "path.logs: /var/log/elasticsearch\n"
      s.gsub! "# path.data: /path/to/data\n", "path.data: /var/lib/elasticsearch\n"
    end
  end

  def install
    etc('elasticsearch').install Dir['config/*']
    etc('init.d').install_p workdir('elasticsearch.init'), 'elasticsearch'
    etc('default').install_p workdir('elasticsearch.default'), 'elasticsearch'
    etc('security/limits.d').install_p workdir('elasticsearch.limits'), 'elasticsearch.conf'
    var('lib/elasticsearch').mkpath
    var('log/elasticsearch').mkpath
    # --[ Elasticsearch HOME ]--
    bin.install Dir['bin/elasticsearch{,-plugin}']
    share('elasticsearch').install Dir['{bin/elasticsearch.in.sh,lib,plugins,*.*}']
  end
end
