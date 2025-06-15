/// <summary>
/// 服务器类型
/// </summary>
public enum ServerTypeEnum
{
    /// <summary>
    /// 登录服
    /// </summary>
    eLoginServer = 0,
    /// <summary>
    /// 游戏服
    /// </summary>
    eGameServer = 1,
    /// <summary>
    /// 挖矿服
    /// </summary>
    eMiningServer = 2,
    /// <summary>
    /// 排行服
    /// </summary>
    eRankServer = 3,
    /// <summary>
    /// 战斗服
    /// </summary>
    eBattleServer = 4,
}

/// <summary>
/// 服务器环境枚举
/// </summary>
public enum EnvironmentEnum
{
    /// <summary>
    /// 开发环境
    /// </summary>
    development = 0,
    /// <summary>
    /// 测试环境
    /// </summary>
    test = 1,
    /// <summary>
    /// 生产环境
    /// </summary>
    production = 2,

    // tg服 2测
    tg_central = 100,
    tg_gs1 = 101,
    tg_gs2 = 102,

    // tg服  2测新
    tg_central_new = 200,
    tg_gs1_new = 201,
    tg_gs2_new = 202,

    // tg战斗服
    tg_bs1 = 301,
    tg_bs2 = 302,
    tg_bs3 = 303,

    // tg测试服
    tg_test = 400,

    // tg服 3测
    tg_central_3 = 500,
    tg_gs1_3 = 501,
    tg_gs2_3 = 502,
}

/// <summary>
/// 战斗服分组
/// </summary>
public enum BattleServerGroupEnum
{
    /// <summary>
    /// 私有战斗服分组
    /// </summary>
    ePrivate = 0,
    /// <summary>
    /// 公共战斗服分组1
    /// </summary>
    eCommon1 = 1,
    /// <summary>
    /// 公共战斗服分组2
    /// </summary>
    eCommon2 = 2,
    /// <summary>
    /// 公共战斗服分组3
    /// </summary>
    eCommon3 = 3,
}

/// <summary>
/// 数据库表名
/// </summary>
public static class SqlTableName
{
    public const string globalinfo = nameof(globalinfo);
    public const string orderinfo = nameof(orderinfo);
    public const string gameorderinfo = nameof(gameorderinfo);
    public const string mininginfo = nameof(mininginfo);
    public const string twitterinfo = nameof(twitterinfo);
    public const string aeonorderinfo = nameof(aeonorderinfo);

    public const string role = nameof(role);
    public const string role_baseinfo = nameof(role_baseinfo);
    public const string role_taskinfo = nameof(role_taskinfo);
    public const string role_treasurechestinfo = nameof(role_treasurechestinfo);
    public const string role_carcultivateinfo = nameof(role_carcultivateinfo);
    public const string role_luckyboxinfo = nameof(role_luckyboxinfo);
    public const string role_mininginfo = nameof(role_mininginfo);
    public const string role_shopinfo = nameof(role_shopinfo);
    public const string role_mapinfo = nameof(role_mapinfo);
    public const string role_inviteinfo = nameof(role_inviteinfo);
    public const string role_energyinfo = nameof(role_energyinfo);
    public const string role_luckyturntableinfo = nameof(role_luckyturntableinfo);
    public const string role_iteminfo = nameof(role_iteminfo);
    public const string role_seasoninfo = nameof(role_seasoninfo);
    
    public const string mining_serverinfo = nameof(mining_serverinfo);
    public const string mining_giftcodeinfo = nameof(mining_giftcodeinfo);
    public const string mining_receivetokeninfo = nameof(mining_receivetokeninfo);
    
    public const string rank_goldearnings = nameof(rank_goldearnings);
    public const string rank_luckyvalue = nameof(rank_luckyvalue);
    public const string rank_miningtokenscore = nameof(rank_miningtokenscore);
    public const string rank_seasonleaguexp = nameof(rank_seasonleaguexp);
    public const string rank_seasonmedal = nameof(rank_seasonmedal);
    public const string rank_seasonmedallast = nameof(rank_seasonmedallast);

    public const string login_roleinfo = nameof(login_roleinfo);
    public const string login_walletinfo = nameof(login_walletinfo);
    public const string login_tgbotinfo = nameof(login_tgbotinfo);
    public const string login_rebateinfo = nameof(login_rebateinfo);
}

/// <summary>
/// 数据库操作类型
/// </summary>
public enum SqlHandleEnum
{
    eInsert,
    eUpdate,
    eDelete,
}

/// <summary>
/// 任务类型
/// </summary>
public enum TaskTypeEnum
{
    /// <summary>
    /// 每日任务
    /// </summary>
    eDailyTask = 1,
    /// <summary>
    /// 一次性任务
    /// </summary>
    eOneTask = 2,
}

/// <summary>
/// 任务事件
/// </summary>
public enum TaskEventEnum
{
    /// <summary>
    /// 完成比赛
    /// </summary>
    eAccomplishGame = 1,
    /// <summary>
    /// 获得冠军
    /// </summary>
    eChampionship = 2,
    /// <summary>
    /// 在线时长
    /// </summary>
    eOnlineTime = 3,
    /// <summary>
    /// 累计登陆
    /// </summary>
    eLogin = 4,
    /// <summary>
    /// 累计邀请
    /// </summary>
    eInvite = 5,
    /// <summary>
    /// 体验赛场
    /// </summary>
    ePlayMap = 6,
    /// <summary>
    /// 完成指定类型任务
    /// </summary>
    eAccomplishTaskByType = 7,
    /// <summary>
    /// 完成指定事件任务
    /// </summary>
    eAccomplishTaskByEvent = 8,
    /// <summary>
    /// 登录钱包
    /// </summary>
    eTaskEvent101 = 101,
    /// <summary>
    /// 登录游戏
    /// </summary>
    eTaskEvent102 = 102,
    /// <summary>
    /// 购买任意商城礼包
    /// </summary>
    eTaskEvent103 = 103,
    /// <summary>
    /// 分享
    /// </summary>
    eTaskEvent104 = 104,
    /// <summary>
    /// 访问XX平台kart party频道
    /// </summary>
    eTaskEvent105 = 105,
    /// <summary>
    /// 参与幸运宝箱玩法
    /// </summary>
    eTaskEvent106 = 106,
    /// <summary>
    /// 关注ceo
    /// </summary>
    eTaskEvent107 = 107,
    /// <summary>
    /// 关注kp
    /// </summary>
    eTaskEvent108 = 108,
    /// <summary>
    /// 加入游戏群
    /// </summary>
    eTaskEvent109 = 109,
    /// <summary>
    /// 成为XX平台会员
    /// </summary>
    eTaskEvent110 = 110,
    /// <summary>
    /// 累计登录钱包
    /// </summary>
    eTaskEvent111 = 111,
    /// <summary>
    /// 累计充值金额
    /// </summary>
    eTaskEvent112 = 112,
    /// <summary>
    /// 累计邀请人数
    /// </summary>
    eTaskEvent113 = 113,
    /// <summary>
    /// 累计邀请高级会员人数
    /// </summary>
    eTaskEvent114 = 114,
    /// <summary>
    /// 升级卡丁车一次
    /// </summary>
    eTaskEvent115 = 115,
    /// <summary>
    /// 获得幸运宝箱奖励
    /// </summary>
    eTaskEvent116 = 116,
    /// <summary>
    /// 点赞官推帖子
    /// </summary>
    eTaskEvent117 = 117,
    /// <summary>
    /// 可直接完成的任务
    /// </summary>
    eTaskEvent118 = 118,
    /// <summary>
    /// 访问DC频道并关注
    /// </summary>
    eTaskEvent119 = 119,
    /// <summary>
    /// 获得质押奖励
    /// </summary>
    eTaskEvent120 = 120,
    /// <summary>
    /// okx钱包绑定
    /// </summary>
    eTaskEvent121 = 121,
    /// <summary>
    /// 完成地图冠军次数
    /// </summary>
    eTaskEvent122 = 122,
    /// <summary>
    /// 参与匹配玩法
    /// </summary>
    eTaskEvent123 = 123,
    /// <summary>
    /// 车辆达成品质
    /// </summary>
    eTaskEvent124 = 124,
    /// <summary>
    /// 升级任意卡丁车部件
    /// </summary>
    eTaskEvent125 = 125,
    /// <summary>
    /// 转盘七日任务 消耗金币
    /// </summary>
    eTaskEvent201 = 201,
    /// <summary>
    /// 转盘七日任务 参加质押
    /// </summary>
    eTaskEvent202 = 202,
    /// <summary>
    /// 转盘七日任务 参加幸运宝箱
    /// </summary>
    eTaskEvent203 = 203,
    /// <summary>
    /// 转盘七日任务 消耗钻石
    /// </summary>
    eTaskEvent204 = 204,
    /// <summary>
    /// 转盘七日任务 消耗体力
    /// </summary>
    eTaskEvent205 = 205,
    /// <summary>
    /// 转盘七日任务 车辆升级至x级
    /// </summary>
    eTaskEvent206 = 206,
    /// <summary>
    /// 转盘七日任务 参加车辆质押
    /// </summary>
    eTaskEvent207 = 207,
    /// <summary>
    /// 转盘七日任务 每日签到
    /// </summary>
    eTaskEvent208 = 208,
    /// <summary>
    /// 转盘七日任务 完成一次所有每日任务
    /// </summary>
    eTaskEvent209 = 209,
}

/// <summary>
/// 任务条件判定类型
/// </summary>
public enum TaskConditionTypeEnum
{
    /// <summary>
    /// 等于
    /// </summary>
    eEqual,
    /// <summary>
    /// 小于
    /// </summary>
    eLessThan,
    /// <summary>
    /// 小于等于
    /// </summary>
    eLessEqual,
    /// <summary>
    /// 大于
    /// </summary>
    eGreaterThan,
    /// <summary>
    /// 大于等于
    /// </summary>
    eGreaterEqual,
}

/// <summary>
/// 宝箱品质枚举
/// </summary>
public enum TreasureChestQualityEnum
{
    /// <summary>
    /// 宝箱品质C
    /// </summary>
    eTreasureChestQualityC = 0,
    /// <summary>
    /// 宝箱品质B
    /// </summary>
    eTreasureChestQualityB = 1,
    /// <summary>
    /// 宝箱品质A
    /// </summary>
    eTreasureChestQualityA = 2,
    /// <summary>
    /// 宝箱品质S
    /// </summary>
    eTreasureChestQualityS = 3,
    /// <summary>
    /// 宝箱品质SS
    /// </summary>
    eTreasureChestQualitySS = 4,
}

/// <summary>
/// 订单类型枚举
/// </summary>
public enum OrderTypeEnum
{
    /// <summary>
    /// 宝箱订单
    /// </summary>
    eTreasure = 0,
    /// <summary>
    /// 商店订单
    /// </summary>
    eShow = 1,
}

/// <summary>
/// 订单状态枚举
/// </summary>
public enum OrderStateEnum
{
    /// <summary>
    /// 待验证发票信息
    /// </summary>
    eWaitVerifiedResponse = 0,
    /// <summary>
    /// 待验证交易详情
    /// </summary>
    eWaitVerifiedDetail = 1,
    /// <summary>
    /// 验证通过
    /// </summary>
    ePassVerified = 2,
    /// <summary>
    /// 验证失败
    /// </summary>
    eFailedVerified = 3,
}

/// <summary>
/// 订单验证失败原因枚举
/// </summary>
public enum OrderFailedVerifiedCauseEnum
{
    eNone = 0,
    /// <summary>
    /// 验证订单status为“0x0”
    /// </summary>
    eFailedVerified1 = 1,
    /// <summary>
    /// 订单Hash与发票信息响应的"transactionHash"对不上
    /// </summary>
    eFailedVerified2 = 2,
    /// <summary>
    /// 订单钱包Hash与发票信息响应中转"to"钱包Hash对不上
    /// </summary>
    eFailedVerified3 = 3,
    /// <summary>
    /// 订单Hash与交易详情响应的"hash"对不上
    /// </summary>
    eFailedVerified4 = 4,
    /// <summary>
    /// 订单钱包Hash与交易详情响应中转"to"钱包Hash对不上
    /// </summary>
    eFailedVerified5 = 5,
}

/// <summary>
/// 挖矿类型
/// </summary>
public static class MiningType
{
    /// <summary>
    /// 赛车挖矿
    /// </summary>
    public const int Car = 1;
    /// <summary>
    /// 钻石挖矿
    /// </summary>
    public const int Diamond = 2;
}

/// <summary>
/// 商城物品类型
/// </summary>
public enum ShopItemTypeEnum
{
    /// <summary>
    /// 首次双倍礼包
    /// </summary>
    eNormalGift = 1,
    /// <summary>
    /// 每日特惠礼包
    /// </summary>
    ePreferenceGift = 2,
    /// <summary>
    /// 超值礼包
    /// </summary>
    eDeserveGift = 3,
    /// <summary>
    /// 每日免费礼包
    /// </summary>
    eDailyFreeGift = 4,
    /// <summary>
    /// 兑换码礼包
    /// </summary>
    eGiftCodeFreeGift = 5,
}

/// <summary>
/// 礼包类型
/// </summary>
public enum GiftTypeEnum
{
    eShop = 1,
}

/// <summary>
/// 领取商品途径
/// </summary>
public enum ReceiveShopItemWay
{
    eGM = 0,
    eBuy = 1,
    eGiftCode = 3,
    eOrder = 4,
}

/// <summary>
/// 游戏订单状态枚举
/// </summary>
public enum GameOrderStateEnum
{
    eNone = 0,
    /// <summary>
    /// 待验证
    /// </summary>
    eWaitVerified = 1,
    /// <summary>
    /// 预先通过
    /// </summary>
    ePreVerified = 2,
    /// <summary>
    /// 验证通过
    /// </summary>
    ePassVerified = 3,
    /// <summary>
    /// 验证失败
    /// </summary>
    eFailedVerified = 4,
}

/// <summary>
/// 战斗服玩家状态枚举
/// </summary>
public enum BattlePlayerStateEnum
{
    /// <summary>
    /// 在线
    /// </summary>
    eOnLine = 0,
    /// <summary>
    /// 离线
    /// </summary>
    eOffLine = 1,
    /// <summary>
    /// 匹配中
    /// </summary>
    eInMatch = 2,
    /// <summary>
    /// 战斗中
    /// </summary>
    eInBattle = 3,
}

/// <summary>
/// 房间类型枚举
/// </summary>
public enum RoomTypeEnum
{
    /// <summary>
    /// 匹配比赛房间
    /// </summary>
    eMatchRoom = 0,
    /// <summary>
    /// 排位联赛房间
    /// </summary>
    eLeagueRoom = 1,
}

public enum MapTypeServer
{
    eMapNone = 0,
    // 公共地图
    eCommonMap = 1,
    // pve地图
    ePveMap = 2,
    // 排位联赛地图
    ePvpRankingMap = 3,
}