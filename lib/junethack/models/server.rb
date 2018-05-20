require 'dm-migrations'
require 'dm-migrations/migration_runner'

require 'open-uri'

class Server
    include DataMapper::Resource

    has n, :games
    has n, :accounts
    has n, :users, :through => :accounts

    property :id,                Serial
    property :name,              String, :length => 255
    property :url,               String, :length => 255
    property :xlogurl,           String, :length => 255
    property :xloglastmodified,  String, :default => "Sat Jan 01 00:00:00 UTC 2000"
    property :variant,           String
    property :xlogcurrentoffset, Integer
    property :configfileurl,     String, :length => 255

    # open the rc file for the user and return true if the regexp is found
    def verify_user(user, regexp)
        open(configfileurl.gsub("random_user_initial", CGI::escape(user[0]))
                          .gsub("random_user", CGI::escape(user))) do |f|
            f.each do |line|
              return true if line.strip.match regexp
            end
        end
        return false;
    end

    def display_name
        hostname+" ("+variant+")"
    end

    def hostname
      @host ||= URI(url).host
    end

    def dumplog_link(game)
      case hostname
      when "nethack.alt.org"
        case game.version
        when "3.6"
          return "https://alt.org/nethack/userdata/#{game.name[0..0]}/#{game.name}/dumplog/#{game.starttime}.nh343.txt"
        end
      when "grunthack.org"
        return "http://grunthack.org/userdata/#{game.name[0..0]}/#{game.name}/dumplog/#{game.starttime}.gh020.txt"
      when "nethack.dank.ninja", "ascension.run"
        case game.version
        when "3.4.3"
            return "https://ascension.run/userdata/#{game.name}/nethack/dumplog/#{game.starttime}"
        when "dnh"
            return "https://ascension.run/userdata/#{game.name}/dnethack/dumplog/#{game.starttime}"
        when "nh4k"
            return "https://ascension.run/userdata/#{game.name}/nhfourk/dumplog/#{game.dumplog.tr("_",":")}"
        when "nh4"
            return "https://ascension.run/userdata/#{game.name}/nethack4/dumplog/#{game.dumplog.tr("_",":")}"
        when "shc"
            return "https://ascension.run/userdata/#{game.name}/sporkhack/dumplog/#{game.starttime}"
        when "NH-1.3d"
            return "https://ascension.run/userdata/#{game.name}/oldhack/dumplog/#{game.starttime}"
        when "slth"
            return "https://ascension.run/userdata/#{game.name}/slashthem/dumplog/#{game.starttime}"
        when "gho"
            return "https://ascension.run/userdata/#{game.name}/grunthack/dumplog/#{game.starttime}"
        when "unh"
          return "https://ascension.run/userdata/#{game.name}/unnethack/dumplog/#{game.starttime}.html"
        when "fiq"
            return "https://ascension.run/userdata/#{game.name}/fiqhack/dumplog/#{game.dumplog.tr("_",":")}"
        when "dyn"
            return "https://ascension.run/userdata/#{game.name}/dynahack/dumplog/#{game.dumplog}"
        end
      when "nethack4.org"
        return "http://nethack4.org/dumps/#{game.dumplog.tr("_",":")}"
      when "hardfought.org"
        player = "#{game.name[0..0]}/#{game.name}"
        case game.version
        when "dyn"
            "https://www.hardfought.org/userdata/#{player}/dynahack/dumplog/#{game.dumplog}"
        when "gho"
            "https://www.hardfought.org/userdata/#{player}/gh/dumplog/#{game.starttime}.gh.txt"
        when "3.6"
            "https://www.hardfought.org/userdata/#{player}/nhdev/dumplog/#{game.starttime}.nhdev.txt"
        when "unh"
            "https://www.hardfought.org/userdata/#{player}/un531/dumplog/#{game.starttime}.un531.txt.html"
        when "fiq"
            "https://www.hardfought.org/userdata/#{player}/fiqhack/dumplog/#{game.dumplog.tr("_",":")}"
        when "nh4k"
            "https://www.hardfought.org/userdata/#{player}/nhfourk/dumps/#{game.dumplog.tr("_",":")}"
        when "nh4"
            "https://www.hardfought.org/userdata/#{player}/nethack4/dumplog/#{game.dumplog.tr("_",":")}"
        when "dnh"
            "https://www.hardfought.org/userdata/#{player}/dnethack/dumplog/#{game.starttime}.dnh.txt"
        when "3.4.3"
            "https://www.hardfought.org/userdata/#{player}/nh343/dumplog/#{game.starttime}.nh343.txt"
        end
      when "em.slashem.me"
        case game.version
        when "3.6"
          endtime = DateTime.strptime(game.endtime.to_s,"%s").strftime("%Y%m%d%H%M%S")
          "https://em.slashem.me/userdata/#{game.name}/nethack/dumplog/#{endtime}.txt"
        #when "slex"
        #  "https://em.slashem.me/userdata/#{game.name}/slex/dumplog/#{endtime}.txt"
        when "gho"
          "https://em.slashem.me/userdata/#{game.name}/grunthack/dumplog/#{game.starttime}.txt"
        when "sho"
          "https://em.slashem.me/userdata/#{game.name}/sporkhack/dumplog/#{game.starttime}.txt"
        end
      else
        return nil
      end
    end
end

DataMapper::MigrationRunner.migration( 1, :create_servers ) do
  up do
    [
      [:nao_nh36, 'NetHack 3.6.1', 'https://alt.org/nethack/xlogfile.nh361dev'],
    ].each {|server|
      url = 'https://nethack.alt.org/'
      configfileurl = 'https://alt.org/nethack/userdata/random_user/random_user.nh361rc'
      Server.create name: server[0], variant: server[1], url: url, xlogurl: server[2], configfileurl: configfileurl
    }

    Server.create name: 'nh4', variant: 'NetHack4 4.3.0',
      url: 'http://nethack4.org/', xlogurl: 'http://nethack4.org/xlogfile.txt', configfileurl: 'http://nethack4.org/junethack-rc/random_user.rc'

    [
      [:esm_nh36, 'NetHack 3.6.1',           'https://em.slashem.me/xlogfiles/nethack'],
      [:esm_slex, "Slash'EM Extended 2.2.2", 'https://em.slashem.me/xlogfiles/slex'],
      [:esm_gho,  'GruntHack 0.2.1',         'https://em.slashem.me/xlogfiles/grunthack'],
      [:esm_shc,  'SporkHack 0.6.3',         'https://em.slashem.me/xlogfiles/sporkhack'],
    ].each {|server|
      url = 'https://em.slashem.me/'
      configfileurl = 'https://em.slashem.me/userdata/random_user/nethack/random_user.nh360rc'

      Server.create name: server[0], variant: server[1], url: url, xlogurl: server[2], configfileurl: configfileurl
    }

    [
      [:asc_nao,  'NetHack 3.4.3-nao',     'https://ascension.run/xlogfiles/nethack'],
      [:asc_unh,  'UnNetHack 5.3.1',       'https://ascension.run/xlogfiles/unnethack'],
      [:asc_dnh,  'dNetHack 3.15.1',       'https://ascension.run/xlogfiles/dnethack'],
      [:asc_dyn,  'DynaHack 0.6.0',        'https://ascension.run/xlogfiles/dynahack'],
      [:asc_nh4k, 'NetHack Fourk 4.3.0.4', 'https://ascension.run/xlogfiles/nhfourk'],
      [:asc_fiq,  'FIQHack 4.3.0',         'https://ascension.run/xlogfiles/fiqhack'],
      [:asc_nh4,  'NetHack4 4.3.0',        'https://ascension.run/xlogfiles/nethack4'],
    ].each {|server|
      url = 'https://ascension.run/'
      configfileurl = 'https://ascension.run/userdata/random_user/nethack/nethackrc'

      Server.create name: server[0], variant: server[1], url: url, xlogurl: server[2], configfileurl: configfileurl
    }

    [
      [:hdf_nao,  'NetHack 3.4.3-nao',       'https://www.hardfought.org/xlogfiles/nh343/xlogfile'],
      [:hdf_nh36, 'NetHack 3.6.1',           'https://www.hardfought.org/xlogfiles/nhdev/xlogfile'],
      [:hdf_shc,  'SporkHack 0.6.5',         'https://www.hardfought.org/xlogfiles/sporkhack/xlogfile'],
      [:hdf_gho,  'GruntHack 0.2.3',         'https://www.hardfought.org/xlogfiles/gh/xlogfile'],
      [:hdf_unh,  'UnNetHack 5.3.1',         'https://www.hardfought.org/xlogfiles/un531/xlogfile'],
      [:hdf_dnh,  'dNetHack 3.15.1',         'https://www.hardfought.org/xlogfiles/dnethack/xlogfile'],
      [:hdf_nh4,  'NetHack4 4.3.0',          'https://www.hardfought.org/xlogfiles/nethack4/xlogfile'],
      [:hdf_nh4k, 'NetHack Fourk 4.3.0.4',   'https://www.hardfought.org/xlogfiles/4k/xlogfile'],
      [:hdf_fiq,  'FIQHack 4.3.1',           'https://www.hardfought.org/xlogfiles/fh/xlogfile'],
      [:hdf_dyn,  'DynaHack 0.6.0',          'https://www.hardfought.org/xlogfiles/dynahack/xlogfile'],
      [:hdf_slex, "Slash'EM Extended 2.2.2", 'https://www.hardfought.org/xlogfiles/slex/xlogfile'],
      [:hdf_xnh,  'xNetHack 0.2.0',          'https://www.hardfought.org/xlogfiles/xnethack/xlogfile'],
      [:hdf_spl,  'SpliceHack 0.2.1',        'https://www.hardfought.org/xlogfiles/splicehack/xlogfile'],
    ].each {|server|
      url = 'https://hardfought.org/'
      configfileurl = 'https://hardfought.org/userdata/random_user_initial/random_user/nh343/random_user.nh343rc'
      Server.create name: server[0], variant: server[1], url: url, xlogurl: server[2], configfileurl: configfileurl
    }

  end

  down do
    Server.destroy
  end
end
