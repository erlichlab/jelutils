
function dbConnection(section="client")
    conf = ConfParse(joinpath(homedir(),".dbconf"))
    parse_conf!(conf)
    user     = retrieve(conf, section, "user")
    password = retrieve(conf, section, "passwd");
    host     = retrieve(conf, section, "host")
    conn = DBInterface.connect(MySQL.Connection, host, user, password, reconnect=true)
end