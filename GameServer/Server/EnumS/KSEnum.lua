-- KS上Player状态类型
local KSPlayerStateEnum = {
    eConnect = 1, -- 链接上
    eLogin = 2, -- 登陆中
    eWaitNew = 3, -- 等待创建角色
    eLoadData = 4, -- 读取role数据
    eInGame = 5, -- 在游戏中
    eWaitReconnect = 9, -- 等待重连
    eDestroy = 10, -- 销毁
    eReadDBData = 11 -- 从数据库读数据中
}
RegistEnum("KSPlayerStateEnum", KSPlayerStateEnum)

-- KS上Player bekick 原因
local PlayerBeKickReasonEnum = {
    eBanPlay = 1, -- 封号踢人
    eRepeatLogin = 2, -- 重复登录踢人
    eGMKick = 3, -- GM踢人
    eServerShutdown = 4, -- 服务器关闭
    eLoginFailed = 5, -- 登陆失败
    eLoginServerError = 6, -- 登录服务器错误
    eServerHeavyLoad = 7, -- 服务器高负载
    eRename = 8, -- 改名成功后踢人
    eLockMac = 9, -- 禁止mac
    eGSError = 50, -- GS报错踢人
    eKSHandleCLMsgError = 51, -- KS处理客户端消息错误
    eKSDayRefreshError = 52, -- KS每日刷新错误
    eKSUpdateError = 53, -- KSupdate错误
    eToBridgeServer = 54, -- 离开本服去跨服
    eLeaveBridgeServer = 55, -- 离开跨服回本服
    eNoPlayerData = 56, -- 没有player数据
    eNoToken = 57, -- 没有跨服token
    eInsertPlayerError = 58, -- 数据库新建player错误
    eTooManyPlayer = 59, -- 创建角色过多
    eSelectPlayerError = 60, -- 数据库查询player错误
    ePlayerInBridge = 61, -- 角色在跨服服务器里
    eKSHandleGSMsgError = 62, -- KS处理GS消息错误
    eNormalServerKick = 63, -- 普通服申请把在跨服的账号踢掉
    eLoadDBDataError = 64 -- 在DB线程查询playsystem错误
}
RegistEnum("PlayerBeKickReasonEnum", PlayerBeKickReasonEnum)

-- 地图类型
local MapTypeEnum = {
    eCommon			= 1,	-- 公共场景/主地图
    eCompetition    = 2,    -- 比赛场景
    eDodgems        = 3,    -- 碰碰车场景
}
RegistEnum("MapTypeEnum", MapTypeEnum)

-- 进入地图类型
local EnterMapType = {
	eNormal = 0,	-- 正常进入
};
RegistEnum("EnterMapType", EnterMapType)

-- 进入地图失败原因
local EnterMapError = {
	eSuccess	= 0,			-- 成功
	eNoPlayer	= 99,			-- 没有玩家
};
RegistEnum("EnterMapError", EnterMapError)

-- 地图对象类型
local MapObjectTypeEnum = {
	ePlayer		= 1, -- 玩家
	eAI			= 2, -- AI
}
RegistEnum("MapObjectTypeEnum", MapObjectTypeEnum)

-- 任务类型
local TaskTypeEnum = {
	eDailyTask		= 1, -- 每日任务
	eOneTask		= 2, -- 一次性任务
}
RegistEnum("TaskTypeEnum", TaskTypeEnum)

-- 任务事件
local TaskEventEnum = {
	eAccomplishGame		= 1, -- 完成比赛
	eChampionship		= 2, -- 获得冠军
	eOnlineTime		    = 3, -- 在线时长
	eLogin		        = 4, -- 累计登陆
	eInvite		        = 5, -- 累计邀请
	ePlayMap		    = 6, -- 体验赛场
}
RegistEnum("TaskEventEnum", TaskEventEnum)

-- 排行榜类型
local RankTypeEnum = {
    eScoreRank   = 1,  -- 积分榜
}
RegistEnum("RankTypeEnum", RankTypeEnum)

-- 排行榜玩家数据Idx
local RankRoleDataIdxEnum = {
    eRoleId   = 1,  -- 玩家Id
    eName     = 2,  -- 玩家名字
    eHead     = 3,  -- 玩家头像
    eScore    = 4,  -- 玩家积分
    eEmail    = 5,  -- 玩家邮箱
    eKartKey  = 6,  -- 玩家激活码
}
RegistEnum("RankRoleDataIdxEnum", RankRoleDataIdxEnum)