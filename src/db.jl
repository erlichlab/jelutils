
function dbConnection()
    conf = ConfParse(joinpath(homedir(),".dbconf"))
    parse_conf!(conf)
    user     = retrieve(conf, "client", "user")
    password = retrieve(conf, "client", "passwd");
    host     = retrieve(conf, "client", "host")
    conn = DBInterface.connect(MySQL.Connection, host, user, password, reconnect=true)
end