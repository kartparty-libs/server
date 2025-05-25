using Proto;
using System.Numerics;

/// <summary>
/// 玩家类
/// </summary>
public partial class Player
{
    /// <summary>
    /// 存盘脏位
    /// </summary>
    protected Dictionary<string, object> m_pSaveCaches = new Dictionary<string, object>();

    /// <summary>
    /// 账号
    /// </summary>
    private string m_sAccount = "";

    /// <summary>
    /// 玩家Id
    /// </summary>
    private long m_nRoleId;

    /// <summary>
    /// 名字
    /// </summary>
    private string m_sName = "";

    /// <summary>
    /// 邮箱
    /// </summary>
    private string m_sEMail = "";

    /// <summary>
    /// 邀请码
    /// </summary>
    private string m_sKartKey = "";

    /// <summary>
    /// 创建时间
    /// </summary>
    private long m_nCreateTime;

    /// <summary>
    /// 累计登录
    /// </summary>
    private int m_nLoginNum;

    /// <summary>
    /// 最后操作时间戳
    /// </summary>
    private long m_nLastHandleTime;

    /// <summary>
    /// 最后保存时间戳
    /// </summary>
    private long m_nLastSaveDataTime;

    /// <summary>
    /// 今日凌晨时间戳
    /// </summary>
    private long m_nZeroTime;

    /// <summary>
    /// 准备删除
    /// </summary>
    private bool m_bReadyDelete = false;

    /// <summary>
    /// 玩家系统管理器
    /// </summary>
    private PlayerSystemManager m_pPlayerSystemManager;

    /// <summary>
    /// 玩家数据缓存
    /// </summary>
    private Dictionary<string, object> m_pTempPlayerData = new Dictionary<string, object>();

    public Player()
    {
        m_pPlayerSystemManager = new PlayerSystemManager(this);
    }

    public void Initializer(PlayerData i_pPlayerData, bool i_bIsNewPlayer)
    {
        m_sAccount = i_pPlayerData.account;
        m_nRoleId = i_pPlayerData.roleId;
        m_sName = i_pPlayerData.roleName;
        m_nCreateTime = i_pPlayerData.createtime;
        m_nLoginNum = i_pPlayerData.loginnum;
        m_nLastHandleTime = i_pPlayerData.lasthandletime;
        m_nZeroTime = i_pPlayerData.zerotime;
        m_sEMail = i_pPlayerData.email;
        m_sKartKey = i_pPlayerData.kartkey;

        m_pPlayerSystemManager.Initializer(i_bIsNewPlayer);
        if (i_bIsNewPlayer)
        {
            UpdateLastHandleTime();
            UpdateLastSaveDataTime();
        }
    }

    public void DayRefresh()
    {
        AddLoginNum();
        m_pPlayerSystemManager.DayRefresh();
    }

    public void SaveData()
    {
        if (m_pSaveCaches.Count > 0)
        {
            Launch.DBServer.UpdateData(ServerTypeEnum.eGameServer, SqlTableName.role, m_pSaveCaches, "roleid", m_nRoleId);
            m_pSaveCaches.Clear();
        }

        m_pPlayerSystemManager.SaveData();

        UpdateLastSaveDataTime();
        //Debug.Instance.Log($"Player SaveData m_sAccount = {m_sAccount}");
    }

    public void Update(int i_nMillisecondDelay)
    {
        m_pPlayerSystemManager.Update(i_nMillisecondDelay);
    }

    public void Delete()
    {
        SaveData();

        m_pPlayerSystemManager.Delete();
        //Debug.Instance.Log($"Player Delete m_sAccount = {m_sAccount}");
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取玩家RoleId
    /// </summary>
    /// <returns></returns>
    public long GetRoleId() => m_nRoleId;

    /// <summary>
    /// 获取账号
    /// </summary>
    /// <returns></returns>
    public string GetAccount() => m_sAccount;

    /// <summary>
    /// 获取名字
    /// </summary>
    /// <returns></returns>
    public string GetName() => m_sName;

    /// <summary>
    /// 设置名字
    /// </summary>
    /// <param name="i_sName"></param>
    public bool SetName(string i_sName)
    {
        if (!UtilityMethod.VerifyConventionByName(i_sName))
        {
            return false;
        }

        m_sName = i_sName;
        AddSaveCaches("rolename", m_sName);
        return true;
    }

    /// <summary>
    /// 获取邮箱
    /// </summary>
    /// <returns></returns>
    public string GetEMail() => m_sEMail;

    /// <summary>
    /// 获取邀请码
    /// </summary>
    /// <returns></returns>
    public string GetKartKey() => m_sKartKey;

    /// <summary>
    /// 获取累计登录
    /// </summary>
    /// <returns></returns>
    public int GetLoginNum() => m_nLoginNum;

    /// <summary>
    /// 添加累计登录
    /// </summary>
    public void AddLoginNum()
    {
        m_nLoginNum++;
        AddSaveCaches("loginnum", m_nLoginNum);
    }

    /// <summary>
    /// 获取最后操作时间戳
    /// </summary>
    /// <returns></returns>
    public long GetLastHandleTime() => m_nLastHandleTime;

    /// <summary>
    /// 刷新最后操作时间戳
    /// </summary>
    public void UpdateLastHandleTime()
    {
        m_nLastHandleTime = UtilityMethod.GetUnixTimeMilliseconds();
        AddSaveCaches("lasthandletime", m_nLastHandleTime);
    }

    /// <summary>
    /// 获取最后保存时间戳
    /// </summary>
    /// <returns></returns>
    public long GetLastSaveDataTime() => m_nLastSaveDataTime;

    /// <summary>
    /// 刷新最后保存时间戳
    /// </summary>
    public void UpdateLastSaveDataTime()
    {
        m_nLastSaveDataTime = UtilityMethod.GetUnixTimeMilliseconds();
    }

    /// <summary>
    /// 获取今日凌晨时间戳
    /// </summary>
    /// <returns></returns>
    public long GetZeroTimee() => m_nZeroTime;

    /// <summary>
    /// 刷新今日凌晨时间戳
    /// </summary>
    public void UpdateZeroTime()
    {
        m_nZeroTime = UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing();
        AddSaveCaches("zerotime", m_nZeroTime);
    }

    /// <summary>
    /// 是否准备删除
    /// </summary>
    /// <returns></returns>
    public bool IsReadyDelete() => m_bReadyDelete;

    /// <summary>
    /// 设置准备删除
    /// </summary>
    /// <param name="i_bReadyDelete"></param>
    public void SetReadyDelete(bool i_bReadyDelete) => m_bReadyDelete = i_bReadyDelete;

    /// <summary>
    /// 获取指定系统
    /// </summary>
    /// <typeparam name="T0"></typeparam>
    /// <returns></returns>
    public T0 GetSystem<T0>() where T0 : BasePlayerSystem
    {
        return m_pPlayerSystemManager.GetSystem<T0>();
    }

    /// <summary>
    /// 获取指定系统
    /// </summary>
    /// <returns></returns>
    public BasePlayerSystem GetSystem(Type type)
    {
        return m_pPlayerSystemManager.GetSystem(type);
    }

    /// <summary>
    /// 获取玩家系统管理器
    /// </summary>
    /// <returns></returns>
    public PlayerSystemManager GetPlayerSystemManager()
    {
        return m_pPlayerSystemManager;
    }

    /// <summary>
    /// 添加存盘脏位
    /// </summary>
    /// <param name="i_sKey"></param>
    /// <param name="i_pValue"></param>
    public void AddSaveCaches(string i_sKey, object i_pValue)
    {
        if (!m_pSaveCaches.ContainsKey(i_sKey))
        {
            m_pSaveCaches.Add(i_sKey, i_pValue);
        }
        else
        {
            m_pSaveCaches[i_sKey] = i_pValue;
        }
    }

    /// <summary>
    /// 获取玩家反应数据集合
    /// </summary>
    /// <returns></returns>
    public virtual ResMsgBodyPlayerData GetResMsgBody()
    {
        ResMsgBodyPlayerData resMsgBodyPlayerData = new ResMsgBodyPlayerData()
        {
            Account = m_sAccount,
            RoleId = m_nRoleId,
            Hash = m_sAccount,
            Name = m_sName,
            RankPostUrl = ServerConfig.GetCtoSURL(ServerTypeEnum.eRankServer),
            LoginNum = m_nLoginNum,
            InviteCount = GetSystem<InviteSystem>().GetInviteCount(),
        };
        return resMsgBodyPlayerData;
    }

    /// <summary>
    /// 操作通知
    /// </summary>
    public void OnHandle()
    {
        if (m_nZeroTime < UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing())
        {
            UpdateZeroTime();
            DayRefresh();
        }

        long CurrTime = UtilityMethod.GetUnixTimeMilliseconds();
        long LastHandleTime = m_nLastHandleTime;
        int Intervaltime = (int)(CurrTime - LastHandleTime);
        UpdateLastHandleTime();

        m_pPlayerSystemManager.OnHandle(CurrTime, LastHandleTime, Intervaltime);
    }
}