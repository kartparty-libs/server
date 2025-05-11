--[[
	--游戏服配置
--]]
ServerInfo = 
{
	--游戏服信息
	self_ip				= "127.0.0.1",

	serverid			= 123,
	clientport			= 9885,
	fightserverport		= 1111,

	--跨服信息
	bridge_lan_ip		= "49.232.165.74";
	bridge_port			= 9998;

	--中心服信息
	commercial_ip		= "49.232.165.74",
	commercial_port		= 9999,
	commercial_wdport 	= 9997, 

	--数据库信息
	gamedb_host			= "49.232.165.74",
	gamedb_port			= 3306,
	gamedb_user			= "root",
	gamedb_pwd			= "Shj_2022",
	gamedb_name			= "gamedb_kart",

	-- log库
	district_log_host 		= "49.232.165.74",
	district_log_port 		= 3306,
	district_log_user 		= "root",
	district_log_pwd  		= "Shj_2022",
	district_log_name 		= "gamedb_kart_log",

	--其他配置
	ThreadNum			= 1,
	IsNotDataReport 	= true,
	bridge_group		= {},
	GM 					= true,
	Platform 			= "wan",
	PlayerLoginTime		= {{12,0,0},{24,0,0}}, -- 玩家可登录时间段{小时，分，秒}
	BufferRankTime		= {{18,0},{24,0}}, -- 排行榜刷新时间{小时，分}
	ExecuteRobotTime	= {{16,0},{22,0}}, -- 执行机器人时间{小时，分}
}