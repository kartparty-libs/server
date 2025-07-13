using Proto;
using System;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 公共登入管理器
/// </summary>
public class CommonLoginManager : BaseManager<CommonLoginManager>
{
    /// <summary>
    /// 服务器数据集合
    /// </summary>
    private ConcurrentDictionary<int, ServerData> m_pServerDatas = new ConcurrentDictionary<int, ServerData>();

    /// <summary>
    /// 玩家登入数据集合
    /// </summary>
    private ConcurrentDictionary<string, PlayerLoginData> m_pLoginPlayerDatas = new ConcurrentDictionary<string, PlayerLoginData>();

    /// <summary>
    /// 简易会话集合（有时间做统一的会话管理器）
    /// </summary>
    private ConcurrentDictionary<string, string> m_pSessions = new ConcurrentDictionary<string, string>();

    public override void Initializer(DataRow i_pGlobalInfo, bool i_bIsFirstOpenServer)
    {
        base.Initializer(i_pGlobalInfo, i_bIsFirstOpenServer);

        InitServerData();

        DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eLoginServer, SqlTableName.login_roleinfo);
        if (data != null && data.Rows.Count > 0)
        {
            for (int i = 0; i < data.Rows.Count; i++)
            {
                DataRow dataRow = data.Rows[i];
                PlayerLoginData playerLoginData = new PlayerLoginData();
                playerLoginData.account = Convert.ToString(dataRow["account"]);
                playerLoginData.serverId = Convert.ToInt32(dataRow["serverid"]);
                playerLoginData.ip = Convert.ToString(dataRow["ip"]);
                m_pLoginPlayerDatas.TryAdd(playerLoginData.account, playerLoginData);
                if ( m_pServerDatas.TryGetValue(playerLoginData.serverId, out ServerData serverData))
                {
                    serverData.playerCount++;
                }
            }
        }
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 初始化服务器数据
    /// </summary>
    public void InitServerData()
    {
        int[] serverList = ServerConfig.GetToIntArray("server_list", ServerTypeEnum.eLoginServer);
        foreach (int serverId in serverList)
        {
            if (!m_pServerDatas.ContainsKey(serverId))
            {
                ServerData serverData = new ServerData();
                serverData.serverId = serverId;
                serverData.url = ServerConfig.GetCtoGSURL(serverId);
                m_pServerDatas.TryAdd(serverId, serverData);
                Debug.Instance.LogInfo($"CommonLoginManager InitServerData -> serverId = {serverId}");
            }
        }
    }

    /// <summary>
    /// 获取服务器数据
    /// </summary>
    /// <param name="i_nServerId"></param>
    /// <returns></returns>
    public ServerData GetServerData(int i_nServerId)
    {
        m_pServerDatas.TryGetValue(i_nServerId, out ServerData serverData);
        return serverData;
    }

    /// <summary>
    /// 获取玩家服务器id
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <returns></returns>
    public int GetPlayerServerId(string i_sAccount)
    {
        if (m_pLoginPlayerDatas.TryGetValue(i_sAccount, out PlayerLoginData __loginPlayerData))
        {
            return __loginPlayerData.serverId;
        }
        return -1;
    }

    /// <summary>
    /// 服务器负载均衡SLB
    /// </summary>
    /// <returns></returns>
    private ServerData ServerLoadBalancing()
    {
        ServerData bestServer = null;
        int minPlayerCount = int.MaxValue;
        Dictionary<int, ServerData> serverDatas = m_pServerDatas.ToDictionary();
        foreach (var item in serverDatas)
        {
            if (item.Value.playerCount < minPlayerCount)
            {
                minPlayerCount = item.Value.playerCount;
                bestServer = item.Value;
            }
        }
        return bestServer;
    }

    /// <summary>
    /// 获取玩家登入数据
    /// </summary>
    /// <param name="i_sAccount"></param>
    /// <param name="i_sIp"></param>
    public PlayerLoginData GetPlayerLoginData(string i_sAccount, string i_sIp)
    {
        if (i_sAccount == "")
        {
            return null;
        }

        if (!m_pSessions.TryAdd(i_sAccount, i_sIp))
        {
            return null;
        }

        if (m_pLoginPlayerDatas.TryGetValue(i_sAccount, out PlayerLoginData __loginPlayerData))
        {
            m_pSessions.TryRemove(i_sAccount, out i_sIp);
            return __loginPlayerData;
        }

        ServerData serverData = ServerLoadBalancing();
        if (serverData == null)
        {
            m_pSessions.TryRemove(i_sAccount, out i_sIp);
            return null;
        }

        lock (this)
        {
            serverData.playerCount++;
        }

        PlayerLoginData loginPlayerData = new PlayerLoginData();
        loginPlayerData.account = i_sAccount;
        loginPlayerData.ip = i_sIp;
        loginPlayerData.serverId = serverData.serverId;
        m_pLoginPlayerDatas.TryAdd(i_sAccount, loginPlayerData);

        Dictionary<string, object> columnValues = new Dictionary<string, object>();
        columnValues.Add("account", loginPlayerData.account);
        columnValues.Add("serverid", loginPlayerData.serverId);
        columnValues.Add("ip", loginPlayerData.ip);
        Launch.DBServer.InsertData(ServerTypeEnum.eLoginServer, SqlTableName.login_roleinfo, columnValues);

        m_pSessions.TryRemove(i_sAccount, out i_sIp);

        DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eLoginServer, SqlTableName.login_tgbotinfo, "account", i_sAccount);
        if (data != null || data.Rows.Count > 0)
        {
            Launch.DBServer.UpdateData(ServerTypeEnum.eLoginServer, SqlTableName.login_tgbotinfo, new Dictionary<string, object>()
            {
                ["iscreateplayer"] = 1,
            }, "account", i_sAccount);
        }

        return loginPlayerData;
    }
}

/// <summary>
/// 登入服玩家数据
/// </summary>
public class PlayerLoginData
{
    /// <summary>
    /// 账号
    /// </summary>
    public string account;
    /// <summary>
    /// 服务器Id
    /// </summary>
    public int serverId;
    /// <summary>
    /// 首次登入Ip
    /// </summary>
    public string ip;
}

/// <summary>
/// 服务器数据
/// </summary>
public class ServerData
{
    /// <summary>
    /// 服务器Id
    /// </summary>
    public int serverId;
    /// <summary>
    /// 服务器URL
    /// </summary>
    public string url;
    /// <summary>
    /// 服务器状态
    /// </summary>
    ServerStateEnum serverStateEnum = ServerStateEnum.eIdle;
    /// <summary>
    /// 服务器总注册人数
    /// </summary>
    public int playerCount = 0;
}

/// <summary>
/// 服务器状态枚举
/// </summary>
enum ServerStateEnum
{
    /// <summary>
    /// 服务器空闲
    /// </summary>
    eIdle = 0,
    /// <summary>
    /// 负载较低
    /// </summary>
    eLow = 1,
    /// <summary>
    /// 负载中等
    /// </summary>
    eMedium = 2,
    /// <summary>
    /// 负载较高
    /// </summary>
    eHigh = 3,
    /// <summary>
    /// 人数火爆，已超载
    /// </summary>
    eOverLoaded = 4,
}