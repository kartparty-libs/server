using Google.Protobuf;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 玩家系统基类
/// </summary>
public class BasePlayerSystem : IPlayerSystem
{
    /// <summary>
    /// 拥有系统的玩家
    /// </summary>
    protected Player m_pPlayer;

    /// <summary>
    /// 拥有系统的玩家
    /// </summary>
    protected PlayerSystemManager m_pPlayerSystemManager;

    /// <summary>
    /// 存盘脏位
    /// </summary>
    protected ConcurrentDictionary<string, object> m_pSaveCaches = new ConcurrentDictionary<string, object>();

    /// <summary>
    /// 是否需要同步客户端
    /// </summary>
    protected bool m_bIsNeedSendClient = false;

    public BasePlayerSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager)
    {
        m_pPlayer = i_pPlayer;
        m_pPlayerSystemManager = i_pPlayerSystemManager;
    }

    public virtual string GetSqlTableName() => "";
    public virtual DataTable GetSystemSqlDataTable()
    {
        if (GetSqlTableName() == "")
        {
            return null;
        }
        DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eGameServer, GetSqlTableName(), "roleid", m_pPlayer.GetRoleId());
        if (data != null && data.Rows.Count == 0)
        {
            InsertSystemData();
            data = Launch.DBServer.SelectData(ServerTypeEnum.eGameServer, GetSqlTableName(), "roleid", m_pPlayer.GetRoleId());
        }
        return data;
    }

    public virtual void Initializer(bool i_bIsNewPlayer)
    {
        if (i_bIsNewPlayer)
        {
            InsertSystemData();
        }
    }

    public virtual void DayRefresh()
    {
    }

    public virtual void SaveData()
    {
        if (m_pSaveCaches.Count > 0 && GetSqlTableName() != "")
        {
            Dictionary<string, object> saveCaches;
            lock (this)
            {
                saveCaches = m_pSaveCaches.ToDictionary();
                m_pSaveCaches.Clear();
            }

            Launch.DBServer.UpdateData(ServerTypeEnum.eGameServer, GetSqlTableName(), saveCaches, "roleid", m_pPlayer.GetRoleId());
            saveCaches.Clear();
        }
    }

    public virtual void Update(int i_nMillisecondDelay)
    {
    }

    public virtual void Delete()
    {
    }

    public virtual void OnHandle(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
    }

    public virtual IMessage GetResMsgBody()
    {
        return null;
    }

    public virtual void OnChangeData()
    {
        m_bIsNeedSendClient = true;
    }

    public virtual void OnNewSeason(int i_nSeasonId)
    {
    }

    public bool IsChangeData()
    {
        return m_bIsNeedSendClient;
    }

    public void AddSaveCache(string i_sKey, object i_pValue)
    {
        m_bIsNeedSendClient = true;
        m_pSaveCaches.AddOrUpdate(i_sKey, i_pValue, (key, value) =>{ return i_pValue; });
    }

    /// <summary>
    /// 插入新系统数据
    /// </summary>
    protected void InsertSystemData()
    {
        if (GetSqlTableName() != "")
        {
            Dictionary<string, object> columnValues = new Dictionary<string, object>();
            columnValues.Add("roleid", m_pPlayer.GetRoleId());
            Launch.DBServer.InsertData(ServerTypeEnum.eGameServer, GetSqlTableName(), columnValues);
        }
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取玩家
    /// </summary>
    /// <returns></returns>
    public Player GetPlayer()
    {
        return m_pPlayer;
    }

    /// <summary>
    /// 获取指定系统
    /// </summary>
    /// <typeparam name="T0"></typeparam>
    /// <returns></returns>
    public T0 GetSystem<T0>() where T0 : BasePlayerSystem
    {
        return m_pPlayerSystemManager.GetSystem<T0>();
    }
}