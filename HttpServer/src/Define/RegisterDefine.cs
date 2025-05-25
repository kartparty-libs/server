
using Proto;

/// <summary>
/// 注册定义
/// </summary>
public class RegisterDefine
{
    /// <summary>
    /// 管理器注册
    /// </summary>
    public static Dictionary<ServerTypeEnum, HashSet<IBaseManager>> ManagerRegister = new Dictionary<ServerTypeEnum, HashSet<IBaseManager>>()
    {
        [ServerTypeEnum.eLoginServer] = new HashSet<IBaseManager>()
        {
            CommonLoginManager.Instance ,
            WalletManager.Instance ,
            RebateManager.Instance ,
        },
        [ServerTypeEnum.eGameServer] = new HashSet<IBaseManager>()
        {
            PlayerManager.Instance ,
            OrderManager_Ton.Instance ,
            OrderManager_Aeon.Instance ,
            //MiningManager.Instance ,
            RankManager.Instance ,
            CryptoCnyManager.Instance,
            TwitterManager.Instance,
            BattleServerManager.Instance ,
            SeasonManager.Instance ,
        },
        [ServerTypeEnum.eMiningServer] = new HashSet<IBaseManager>()
        {
            //CommonMiningManager.Instance ,
            GiftCodeManager.Instance,
            ReceiveTokenManager.Instance,
        },
        [ServerTypeEnum.eRankServer] = new HashSet<IBaseManager>()
        {
            CommonRankManager.Instance ,
        },
        [ServerTypeEnum.eBattleServer] = new HashSet<IBaseManager>()
        {
            WebSocketMessageManager.Instance ,
            BattlePlayerManager.Instance ,
            RoomManager.Instance ,
        },
    };

    /// <summary>
    /// Http路由注册
    /// </summary>
    public static HashSet<string> HttpRoutingRegister = new HashSet<string>()
    {
        $"/kp_game/tg_gs{ServerConfig.ServerId}/proto",
        $"/kp_game/tg_gs{ServerConfig.ServerId}/json",
        "/kp_game/tg_zyserver/proto",
        "/kp_game/tg_zyserver/json",
        "/kp_game/tg_paihangserver/proto",
        "/kp_game/tg_paihangserver/json",
        "/kp_game/tg_loginserver/proto",
        "/kp_game/tg_loginserver/json",

        $"/kp_game_test/tg_gs{ServerConfig.ServerId}/proto",
        $"/kp_game_test/tg_gs{ServerConfig.ServerId}/json",
        "/kp_game_test/tg_zyserver/proto",
        "/kp_game_test/tg_zyserver/json",
        "/kp_game_test/tg_paihangserver/proto",
        "/kp_game_test/tg_paihangserver/json",
        "/kp_game_test/tg_loginserver/proto",
        "/kp_game_test/tg_loginserver/json",

        $"/kp_game/battleserver_{ServerConfig.ServerId}/proto",
        $"/kp_game/battleserver_{ServerConfig.ServerId}/json",

        $"/kp_game_test/battleserver_{ServerConfig.ServerId}/proto",
        $"/kp_game_test/battleserver_{ServerConfig.ServerId}/json",
    };

    /// <summary>
    /// 协议注册
    /// </summary>
    public static Dictionary<ServerTypeEnum, Action> ProtocolRegister = new Dictionary<ServerTypeEnum, Action>()
    {
        [ServerTypeEnum.eLoginServer] = () => { RegisterProtocol.RegisterLoginServer(); },
        [ServerTypeEnum.eGameServer] = () => { RegisterProtocol.RegisterGameServer(); },
        [ServerTypeEnum.eMiningServer] = () => { RegisterProtocol.RegisterMiningServer(); },
        [ServerTypeEnum.eRankServer] = () => { RegisterProtocol.RegisterRankServer(); },
        [ServerTypeEnum.eBattleServer] = () => { RegisterProtocol.RegisterBattleServer(); },
    };

    /// <summary>
    /// 排行榜注册
    /// </summary>
    public static Dictionary<RankTypeEnum, Func<IRank>> RankRegister = new Dictionary<RankTypeEnum, Func<IRank>>()
    {
        //[RankTypeEnum.MiningTokenScore] = () => { return new Rank(RankTypeEnum.MiningTokenScore, SqlTableName.rank_miningtokenscore, 1); },
        //[RankTypeEnum.GoldEarnings] = () => { return new Rank(RankTypeEnum.GoldEarnings, SqlTableName.rank_goldearnings, 1); },
        //[RankTypeEnum.LuckyValue] = () => { return new Rank(RankTypeEnum.LuckyValue, SqlTableName.rank_luckyvalue, 1); },
        [RankTypeEnum.SeasonLeagueXp] = () => { return new Rank(RankTypeEnum.SeasonLeagueXp, SqlTableName.rank_seasonleaguexp, 1, true); },
        [RankTypeEnum.SeasonMedal] = () => { return new SeasonMedalRank(RankTypeEnum.SeasonMedal, SqlTableName.rank_seasonmedal, 3, true); },
        [RankTypeEnum.SeasonMedalLast] = () => { return new Rank(RankTypeEnum.SeasonMedalLast, SqlTableName.rank_seasonmedallast, 3, true); },
    };

    /// <summary>
    /// 房间注册
    /// </summary>
    public static Dictionary<RoomTypeEnum, CreateRoomDelegate> RoomRegister = new Dictionary<RoomTypeEnum, CreateRoomDelegate>()
    {
        [RoomTypeEnum.eMatchRoom] = (i_nInstId, i_nRoomCfgId, i_sRoomCode) => { return new MatchRoom(i_nInstId, i_nRoomCfgId, i_sRoomCode); },
        [RoomTypeEnum.eLeagueRoom] = (i_nInstId, i_nRoomCfgId, i_sRoomCode) => { return new LeagueRoom(i_nInstId, i_nRoomCfgId, i_sRoomCode); },
    };
    public delegate BaseRoom CreateRoomDelegate(long i_nInstId, int i_nRoomCfgId, string i_sRoomCode = "");

    /// <summary>
    /// 段位对应战斗服务器注册
    /// </summary>
    public static Dictionary<RankTierTypeEnum, BattleServerGroupEnum> RankTierToBattleServer = new Dictionary<RankTierTypeEnum, BattleServerGroupEnum>()
    {
        [RankTierTypeEnum.RankTierBronze] = BattleServerGroupEnum.eCommon1,
        [RankTierTypeEnum.RankTierSilver] = BattleServerGroupEnum.eCommon1,
        [RankTierTypeEnum.RankTierGold] = BattleServerGroupEnum.eCommon2,
        [RankTierTypeEnum.RankTierDiamond] = BattleServerGroupEnum.eCommon2,
        [RankTierTypeEnum.RankTierMaster] = BattleServerGroupEnum.eCommon3,
        [RankTierTypeEnum.RankTierChallenger] = BattleServerGroupEnum.eCommon3,
    };
}