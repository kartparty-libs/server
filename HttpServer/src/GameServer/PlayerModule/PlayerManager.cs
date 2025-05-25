using Proto;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 玩家管理器
/// </summary>
public class PlayerManager : BaseManager<PlayerManager>
{
    /// <summary>
    /// 玩家Id基数
    /// </summary>
    public static int ServerRoleIdBaseValue = 10000000;

    /// <summary>
    /// 玩家id自增
    /// </summary>
    private static long m_nRoleIndex = 0;

    /// <summary>
    /// 创建中账号列表
    /// </summary>
    private ConcurrentDictionary<string, string> m_tCreateNewPlayers = new ConcurrentDictionary<string, string>();

    /// <summary>
    /// 玩家集合，基于Account
    /// </summary>
    private ConcurrentDictionary<string, Player> m_tPlayersByAccount = new ConcurrentDictionary<string, Player>();

    /// <summary>
    /// 玩家集合，基于Role
    /// </summary>
    private ConcurrentDictionary<long, Player> m_tPlayersByRoleId = new ConcurrentDictionary<long, Player>();

    /// <summary>
    /// 刷新间隔时间/ms
    /// </summary>
    private const int m_nUpdateInterval = 1000;

    /// <summary>
    /// 当前刷新间隔时间/ms
    /// </summary>
    private int m_nCurrentUpdateInterval = m_nUpdateInterval;

    /// <summary>
    /// 定时删除玩家时间
    /// </summary>
    private const int m_nDeletePlayerTime = 43200000;

    /// <summary>
    /// 定时删除玩家最大数量
    /// </summary>
    private const int m_nDeletePlayerMaxNum = 100;

    /// <summary>
    /// 定时保存玩家时间
    /// </summary>
    private const int m_nSaveDataTime = 5000;

    /// <summary>
    /// 定时保存玩家最大数量
    /// </summary>
    private const int m_nSaveDataMaxNum = 100;

    /// <summary>
    /// 定时保存列表
    /// </summary>
    private Queue<Player> m_tSaveDataQueue = new Queue<Player>();

    public PlayerManager()
    {
    }

    public override void Initializer(DataRow i_pGlobalInfo, bool i_bIsFirstOpenServer)
    {
        base.Initializer(i_pGlobalInfo, i_bIsFirstOpenServer);
        m_nRoleIndex = Convert.ToInt32(i_pGlobalInfo["roleindex"]);
    }

    public override void Update(int i_nMillisecondDelay)
    {
        base.Update(i_nMillisecondDelay);
        //Debug.Instance.Log($"PlayerManager Update i_nMillisecondDelay = {i_nMillisecondDelay}");

        foreach (var item in m_tPlayersByAccount)
        {
            item.Value.Update(i_nMillisecondDelay);
        }

        m_nCurrentUpdateInterval -= i_nMillisecondDelay;
        if (m_nCurrentUpdateInterval <= 0)
        {
            Dictionary<string, Player> tempPlayersByAccount = m_tPlayersByAccount.ToDictionary();
            if (tempPlayersByAccount.Count > 0)
            {
                // 准备删除玩家列表
                HashSet<Player> readyDeleteHashSet = new HashSet<Player>(m_nDeletePlayerMaxNum);
                foreach (var item in tempPlayersByAccount)
                {
                    long currTimestampMilliseconds = UtilityMethod.GetUnixTimeMilliseconds();
                    Player player = item.Value;
                    if (readyDeleteHashSet.Count < m_nDeletePlayerMaxNum && !player.IsReadyDelete() && (currTimestampMilliseconds - player.GetLastHandleTime()) >= m_nDeletePlayerTime)
                    {
                        player.SetReadyDelete(true);
                        readyDeleteHashSet.Add(player);
                    }
                    else if ((currTimestampMilliseconds - player.GetLastSaveDataTime()) >= m_nSaveDataTime)
                    {
                        if (!m_tSaveDataQueue.Contains(player))
                        {
                            m_tSaveDataQueue.Enqueue(player);
                        }
                    }
                }

                // 处理准备删除玩家
                if (readyDeleteHashSet.Count > 0)
                {
                    foreach (Player player in readyDeleteHashSet)
                    {
                        long currTimestampMilliseconds = UtilityMethod.GetUnixTimeMilliseconds();
                        if ((currTimestampMilliseconds - player.GetLastHandleTime()) >= m_nDeletePlayerTime)
                        {
                            m_tPlayersByAccount.TryRemove(player.GetAccount(), out Player __player1);
                            m_tPlayersByRoleId.TryRemove(player.GetRoleId(), out Player __player2);
                            player.Delete();
                        }
                    }
                }
                readyDeleteHashSet.Clear();
            }
            m_nCurrentUpdateInterval += m_nUpdateInterval;
        }

        // 处理保存数据玩家
        int count = m_nSaveDataMaxNum;
        while (m_tSaveDataQueue.Count > 0 && count > 0)
        {
            Player player = m_tSaveDataQueue.Dequeue();
            player.SaveData();
            count--;
        }
    }

    public override void Delete()
    {
        base.Delete();
        Dictionary<string, Player> tempPlayersByAccount = m_tPlayersByAccount.ToDictionary();
        m_tPlayersByAccount.Clear();
        m_tPlayersByRoleId.Clear();
        if (tempPlayersByAccount.Count > 0)
        {
            foreach (var item in tempPlayersByAccount)
            {
                item.Value.SaveData();
            }
        }
        tempPlayersByAccount.Clear();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取玩家列表数量
    /// </summary>
    /// <returns></returns>
    public int GetPlayerListCount()
    {
        return m_tPlayersByAccount.Count;
    }

    /// <summary>
    /// 获取玩家实例，基于账号
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <returns></returns>
    public Player GetPlayerByAccount(string i_sAccount)
    {
        if (i_sAccount == null) return null;
        m_tPlayersByAccount.TryGetValue(i_sAccount, out Player player);
        return player;
    }

    /// <summary>
    /// 获取玩家实例，基于RoleId
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <returns></returns>
    public Player GetPlayerByRoleId(long i_nRoleId)
    {
        if (i_nRoleId == default) return null;
        m_tPlayersByRoleId.TryGetValue(i_nRoleId, out Player player);
        return player;
    }

    /// <summary>
    /// 获取玩家实例，基于账号，强制上线
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <returns></returns>
    public Player GetPlayerByAccountForce(string i_sAccount)
    {
        Player player = PlayerManager.Instance.GetPlayerByAccount(i_sAccount);
        if (player == null)
        {
            PlayerCallData playerReturnData = PlayerManager.Instance.LoginPlayer(i_sAccount);
            player = playerReturnData.player;
        }
        return player;
    }

    /// <summary>
    /// 获取新角色Id
    /// </summary>
    /// <returns></returns>
    public long GetNewRoleId()
    {
        long roleid = 0;
        lock (this)
        {
            m_nRoleIndex = m_nRoleIndex + 1;
            roleid = m_nRoleIndex + ServerConfig.ServerId * ServerRoleIdBaseValue;
        }
        Launch.DBServer.UpdateData(ServerTypeEnum.eGameServer, SqlTableName.globalinfo, new Dictionary<string, object>() { { "roleindex", m_nRoleIndex } }, "serverid", ServerConfig.ServerId);
        return roleid;
    }

    /// <summary>
    /// 创建玩家
    /// </summary>
    /// <param name="i_pPlayerData"></param>
    /// <param name="i_bIsNewPlayer"></param>
    /// <returns></returns>
    public Player CreatePlayer(PlayerData i_pPlayerData, bool i_bIsNewPlayer = false)
    {
        Player player = new Player();

        if (i_bIsNewPlayer)
        {
            Dictionary<string, object> columnValues = new Dictionary<string, object>();
            columnValues.Add("roleid", i_pPlayerData.roleId);
            columnValues.Add("account", i_pPlayerData.account);
            columnValues.Add("rolename", i_pPlayerData.roleName);
            columnValues.Add("createtime", i_pPlayerData.createtime);
            columnValues.Add("loginnum", i_pPlayerData.loginnum);
            columnValues.Add("lasthandletime", i_pPlayerData.lasthandletime);
            columnValues.Add("zerotime", i_pPlayerData.zerotime);
            columnValues.Add("email", i_pPlayerData.email);
            columnValues.Add("platformenum", i_pPlayerData.platformenum);
            columnValues.Add("platforminfo", i_pPlayerData.platforminfo);
            columnValues.Add("kartkey", i_pPlayerData.kartkey);
            Launch.DBServer.InsertData(ServerTypeEnum.eGameServer, SqlTableName.role, columnValues);
        }

        player.Initializer(i_pPlayerData, i_bIsNewPlayer);

        m_tPlayersByAccount.TryAdd(player.GetAccount(), player);
        m_tPlayersByRoleId.TryAdd(player.GetRoleId(), player);
        return player;
    }

    /// <summary>
    /// 创建新玩家
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <param name="i_sName"></param>
    /// <param name="i_ePlatformEnum"></param>
    /// <param name="i_sPlatformInfo"></param>
    /// <param name="i_sInviteAccount"></param>
    /// <returns></returns>
    public PlayerCallData CreateNewPlayer(string i_sAccount, string i_sName, PlatformEnum i_ePlatformEnum, string i_sPlatformInfo, string i_sInviteAccount)
    {
        //Debug.Instance.Log($"PlayerManager CreateNewPlayer1 {Thread.CurrentThread.ManagedThreadId} -> i_sAccount={i_sAccount} i_sName={i_sName}");
        PlayerCallData playerReturnData = new PlayerCallData();
        if (i_sAccount == null)
        {
            playerReturnData.responseCodeEnum = ResponseCodeEnum.MsgParamError;
            return playerReturnData;
        }

        if (!m_tCreateNewPlayers.TryAdd(i_sAccount, i_sName))
        {
            playerReturnData.responseCodeEnum = ResponseCodeEnum.ServerBusy;
            return playerReturnData;
        }

        // 验证名字
        if (!UtilityMethod.VerifyConventionByName(i_sName))
        {
            i_sName = i_sAccount;
            //playerReturnData.responseCodeEnum = ResponseCodeEnum.InvalidName;
            //m_tCreateNewPlayers.TryRemove(i_sAccount, out i_sName);
            //return playerReturnData;
        }

        playerReturnData.player = this.GetPlayerByAccount(i_sAccount);

        if (playerReturnData.player != null)
        {
            playerReturnData.responseCodeEnum = ResponseCodeEnum.AccountDuplication;
            m_tCreateNewPlayers.TryRemove(i_sAccount, out i_sName);
            return playerReturnData;
        }

        DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eGameServer, SqlTableName.role, "account", i_sAccount);
        if (data == null)
        {
            playerReturnData.responseCodeEnum = ResponseCodeEnum.ServerBusy;
            m_tCreateNewPlayers.TryRemove(i_sAccount, out i_sName);
            return playerReturnData;
        }
        else if (data.Rows.Count > 0)
        {
            playerReturnData.responseCodeEnum = ResponseCodeEnum.AccountDuplication;
            m_tCreateNewPlayers.TryRemove(i_sAccount, out i_sName);
            return playerReturnData;
        }

        long currTime = UtilityMethod.GetUnixTimeMilliseconds();
        PlayerData playerData = new PlayerData();
        playerData.roleId = GetNewRoleId();
        playerData.account = i_sAccount;
        playerData.roleName = i_sName;
        playerData.createtime = currTime;
        playerData.loginnum = 1;
        playerData.lasthandletime = currTime;
        playerData.zerotime = UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing();
        playerData.platformenum = i_ePlatformEnum;
        playerData.platforminfo = i_sPlatformInfo;

        playerReturnData.player = this.CreatePlayer(playerData, true);
        playerReturnData.responseCodeEnum = ResponseCodeEnum.Succeed;

        Debug.Instance.Log($"PlayerManager CreateNewPlayer {Thread.CurrentThread.ManagedThreadId} -> account={playerData.account} roleid={playerData.roleId} InviteAccount={i_sInviteAccount}", LogType.system);
        m_tCreateNewPlayers.TryRemove(i_sAccount, out i_sName);

        if (i_sInviteAccount != default)
        {
            playerReturnData.player?.GetSystem<InviteSystem>().SetOwnerInvitePlayerInfo(i_sInviteAccount);
        }
        return playerReturnData;
    }

    /// <summary>
    /// 登入玩家
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <returns></returns>
    public PlayerCallData LoginPlayer(string i_sAccount)
    {
        PlayerCallData playerReturnData = new PlayerCallData();

        if (i_sAccount == null)
        {
            playerReturnData.responseCodeEnum = ResponseCodeEnum.MsgParamError;
            return playerReturnData;
        }

        playerReturnData.player = this.GetPlayerByAccount(i_sAccount);

        if (playerReturnData.player == null)
        {
            DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eGameServer, SqlTableName.role, "account", i_sAccount);
            if (data == null)
            {
                playerReturnData.responseCodeEnum = ResponseCodeEnum.ServerBusy;
                return playerReturnData;
            }
            else if (data.Rows.Count == 0)
            {
                playerReturnData.responseCodeEnum = ResponseCodeEnum.AccountNotRegistered;
                return playerReturnData;
            }
            else
            {
                DataRow dataRow = data.Rows[0];
                PlayerData playerData = new PlayerData();
                playerData.account = Convert.ToString(dataRow["account"]);
                playerData.roleId = Convert.ToInt64(dataRow["roleid"]);
                playerData.roleName = Convert.ToString(dataRow["rolename"]);
                playerData.createtime = Convert.ToInt64(dataRow["createtime"]);
                playerData.loginnum = Convert.ToInt32(dataRow["loginnum"]);
                playerData.lasthandletime = Convert.ToInt64(dataRow["lasthandletime"]);
                playerData.zerotime = Convert.ToInt64(dataRow["zerotime"]);
                playerData.email = Convert.ToString(dataRow["email"]);
                playerData.platformenum = (PlatformEnum)Convert.ToInt32(dataRow["platformenum"]);
                playerData.platforminfo = Convert.ToString(dataRow["platforminfo"]);
                playerData.kartkey = Convert.ToString(dataRow["kartkey"]);
                playerReturnData.player = this.CreatePlayer(playerData);
            }
        }

        playerReturnData.responseCodeEnum = ResponseCodeEnum.Succeed;
        playerReturnData.player?.OnHandle();
        return playerReturnData;
    }
}

/// <summary>
/// 玩家数据结构体
/// </summary>
public struct PlayerData()
{
    public string account;
    public long roleId;
    public string roleName;
    public long createtime;
    public int loginnum;
    public long lasthandletime;
    public long zerotime;
    public string email = "";
    public PlatformEnum platformenum;
    public string platforminfo = "";
    public string kartkey = "";
}

/// <summary>
/// 玩家返回数据
/// </summary>
public struct PlayerCallData()
{
    public ResponseCodeEnum responseCodeEnum;
    public object responseParam;
    public Player? player;
}