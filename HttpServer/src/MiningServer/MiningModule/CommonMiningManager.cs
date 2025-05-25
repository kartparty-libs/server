using Proto;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 公共挖矿管理器
/// </summary>
public class CommonMiningManager : BaseManager<CommonMiningManager>
{
    /// <summary>
    /// 存盘脏位
    /// </summary>
    private ConcurrentDictionary<string, object> m_pSaveCaches = new ConcurrentDictionary<string, object>();
    private ConcurrentDictionary<int, Dictionary<string, object>> m_pMiningSaveCachesInsert = new ConcurrentDictionary<int, Dictionary<string, object>>();
    private ConcurrentDictionary<int, Dictionary<string, object>> m_pMiningSaveCachesUpdate = new ConcurrentDictionary<int, Dictionary<string, object>>();

    /// <summary>
    /// 今日凌晨时间
    /// </summary>
    public long ZeroTime { get; private set; }

    /// <summary>
    /// 刷新存储间隔时间/ms
    /// </summary>
    private const int m_nSaveDataUpdateInterval = 10000;

    /// <summary>
    /// 当前刷新存储间隔时间/ms
    /// </summary>
    private int m_nCurrentSaveDataUpdateInterval = m_nSaveDataUpdateInterval;

    /// <summary>
    /// 赛车挖矿池剩余token积分
    /// </summary>
    private long m_nCarTokenScorePoolValue = 0;

    /// <summary>
    /// 钻石挖矿池剩余token积分
    /// </summary>
    private long m_nDiamondTokenScorePoolValue = 0;

    /// <summary>
    /// 全服挖矿数据
    /// </summary>
    private ConcurrentDictionary<int, CommonMiningData> m_pServerMiningDatas = new ConcurrentDictionary<int, CommonMiningData>();

    public override void Initializer(DataRow i_pGlobalInfo, bool i_bIsFirstOpenServer)
    {
        base.Initializer(i_pGlobalInfo, i_bIsFirstOpenServer);
        if (i_bIsFirstOpenServer)
        {
            m_nCarTokenScorePoolValue = ConfigManager.Mining.Get(MiningType.Car).ScorePool;
            m_nDiamondTokenScorePoolValue = ConfigManager.Mining.Get(MiningType.Diamond).ScorePool;
            ZeroTime = UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing();
            OnChangeData();
            SaveData();
        }
        else
        {
            m_nCarTokenScorePoolValue = Convert.ToInt64(i_pGlobalInfo["cartokenscorepoolvalue"]);
            m_nDiamondTokenScorePoolValue = Convert.ToInt64(i_pGlobalInfo["diamondtokenscorepoolvalue"]);
            ZeroTime = Convert.ToInt64(i_pGlobalInfo["zerotime"]);
        }

        DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eMiningServer, SqlTableName.mining_serverinfo);
        if (data != null && data.Rows.Count > 0)
        {
            for (int i = 0; i < data.Rows.Count; i++)
            {
                DataRow dataRow = data.Rows[i];
                CommonMiningData miningData = new CommonMiningData();
                int serverId = Convert.ToInt32(dataRow["serverid"]);
                miningData.totalMiningCount = Convert.ToInt32(dataRow["totalminingcount"]);
                miningData.totalReceiveCount = Convert.ToInt32(dataRow["totalreceivecount"]);
                miningData.carTotalMiningCount = Convert.ToInt32(dataRow["cartotalminingcount"]);
                miningData.diamondTotalMiningCount = Convert.ToInt32(dataRow["diamondtotalminingcount"]);
                miningData.carTotalMiningValue = Convert.ToInt64(dataRow["cartotalminingvalue"]);
                miningData.diamondTotalMiningValue = Convert.ToInt64(dataRow["diamondtotalminingvalue"]);
                m_pServerMiningDatas.TryAdd(serverId, miningData);
            }
        }
    }

    public override void Update(int i_nMillisecondDelay)
    {
        base.Update(i_nMillisecondDelay);
        if (ZeroTime < UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing())
        {
            DayRefresh();
        }

        m_nCurrentSaveDataUpdateInterval -= i_nMillisecondDelay;
        if (m_nCurrentSaveDataUpdateInterval <= 0)
        {
            SaveData();
            m_nCurrentSaveDataUpdateInterval = m_nSaveDataUpdateInterval;
        }
    }

    public override void SaveData()
    {
        base.SaveData();
        Dictionary<string, object> saveCaches = m_pSaveCaches.ToDictionary();
        foreach (var item in saveCaches)
        {
            Launch.DBServer.UpdateData(ServerTypeEnum.eMiningServer, SqlTableName.globalinfo, new Dictionary<string, object>() { { item.Key, item.Value } }, "serverid", ServerConfig.ServerId);
        }

        if (m_pMiningSaveCachesInsert.Count > 0)
        {
            Dictionary<int, Dictionary<string, object>> saveCachesInsert = new Dictionary<int, Dictionary<string, object>>();
            lock (this)
            {
                saveCachesInsert = m_pMiningSaveCachesInsert.ToDictionary();
                m_pMiningSaveCachesInsert.Clear();
            }
            foreach (var item in saveCachesInsert)
            {
                Launch.DBServer.InsertData(ServerTypeEnum.eMiningServer, SqlTableName.mining_serverinfo, item.Value);
            }
        }

        if (m_pMiningSaveCachesUpdate.Count > 0)
        {
            Dictionary<int, Dictionary<string, object>> saveCachesUpdate = new Dictionary<int, Dictionary<string, object>>();
            lock (this)
            {
                saveCachesUpdate = m_pMiningSaveCachesUpdate.ToDictionary();
                m_pMiningSaveCachesUpdate.Clear();
            }
            foreach (var item in saveCachesUpdate)
            {
                Launch.DBServer.UpdateData(ServerTypeEnum.eMiningServer, SqlTableName.mining_serverinfo, item.Value, "serverid", item.Key);
            }
        }
    }

    public void DayRefresh()
    {
        m_nCarTokenScorePoolValue = ConfigManager.Mining.Get(MiningType.Car).ScorePool;
        m_nDiamondTokenScorePoolValue = ConfigManager.Mining.Get(MiningType.Diamond).ScorePool;
        ZeroTime = UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing();
        OnChangeData();
    }

    public void OnChangeData()
    {
        m_pSaveCaches.Clear();
        m_pSaveCaches.TryAdd("zerotime", ZeroTime);
        m_pSaveCaches.TryAdd("cartokenscorepoolvalue", m_nCarTokenScorePoolValue);
        m_pSaveCaches.TryAdd("diamondtokenscorepoolvalue", m_nDiamondTokenScorePoolValue);
    }

    public void OnMiningChangeData(SqlHandleEnum i_eSqlHandleEnum, int i_nServerId, Dictionary<string, object> i_pSaveMiningData)
    {
        if (i_eSqlHandleEnum == SqlHandleEnum.eInsert)
        {
            m_pMiningSaveCachesInsert.AddOrUpdate(i_nServerId, i_pSaveMiningData, (key, oldValue) => { return i_pSaveMiningData; });
        }
        else if (i_eSqlHandleEnum == SqlHandleEnum.eUpdate)
        {
            if (m_pMiningSaveCachesInsert.ContainsKey(i_nServerId))
            {
                m_pMiningSaveCachesInsert.AddOrUpdate(i_nServerId, i_pSaveMiningData, (key, oldValue) => { return i_pSaveMiningData; });
            }
            else
            {
                m_pMiningSaveCachesUpdate.AddOrUpdate(i_nServerId, i_pSaveMiningData, (key, oldValue) => { return i_pSaveMiningData; });
            }
        }
    }

    private Dictionary<string, object> GetSaveMiningData(int i_nServerId, CommonMiningData i_pMiningData)
    {
        Dictionary<string, object> saveData = new Dictionary<string, object>();
        saveData.Add("serverid", i_nServerId);
        saveData.Add("totalminingcount", i_pMiningData.totalMiningCount);
        saveData.Add("totalreceivecount", i_pMiningData.totalReceiveCount);
        saveData.Add("cartotalminingcount", i_pMiningData.carTotalMiningCount);
        saveData.Add("diamondtotalminingcount", i_pMiningData.diamondTotalMiningCount);
        saveData.Add("cartotalminingvalue", i_pMiningData.carTotalMiningValue);
        saveData.Add("diamondtotalminingvalue", i_pMiningData.diamondTotalMiningValue);
        return saveData;
    }
    // ---------------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取赛车挖矿池剩余token积分
    /// </summary>
    /// <returns></returns>
    public long GetCarTokenScorePoolValue()
    {
        return m_nCarTokenScorePoolValue;
    }

    /// <summary>
    /// 获取钻石挖矿池剩余token积分
    /// </summary>
    /// <returns></returns>
    public long GetDiamondTokenScorePoolValue()
    {
        return m_nDiamondTokenScorePoolValue;
    }

    /// <summary>
    /// 获取全服挖矿数据之和
    /// </summary>
    /// <returns></returns>
    public CommonMiningData GetAllServerTotalMiningData()
    {
        CommonMiningData miningData = new CommonMiningData();

        Dictionary<int, CommonMiningData> serverMiningDatas = m_pServerMiningDatas.ToDictionary();
        foreach (var item in serverMiningDatas)
        {
            miningData.totalMiningCount += item.Value.totalMiningCount;
            miningData.totalReceiveCount += item.Value.totalReceiveCount;
            miningData.carTotalMiningCount += item.Value.carTotalMiningCount;
            miningData.carTotalMiningValue += item.Value.carTotalMiningValue;
            miningData.diamondTotalMiningCount += item.Value.diamondTotalMiningCount;
            miningData.diamondTotalMiningValue += item.Value.diamondTotalMiningValue;
        }

        // 特殊设计
        //if (miningData.totalReceiveCount != 0 && miningData.carTotalMiningCount != 0 && miningData.diamondTotalMiningCount != 0)
        //{
        //    int extendCarCount = 0;
        //    int extendDiamondCount = 0;
        //    int extendTotalCount = 0;

        //    List<RobotCountData> robotRankCountMapping = KartKey_Table.RobotRankCountMapping.ToList();
        //    for (int i = robotRankCountMapping.Count - 1; i >= 0; --i)
        //    {
        //        RobotCountData robotCountData = robotRankCountMapping[i];
        //        if (miningData.totalReceiveCount >= robotCountData.rank - 1)
        //        {
        //            extendCarCount = robotCountData.extendCarCount;
        //            extendDiamondCount = robotCountData.extendDiamondCount;
        //            extendTotalCount = robotCountData.extendTotalCount;
        //            break;
        //        }
        //    }

        //    miningData.carTotalMiningValue = miningData.carTotalMiningValue + miningData.carTotalMiningValue / miningData.carTotalMiningCount * extendCarCount;
        //    miningData.diamondTotalMiningValue = miningData.diamondTotalMiningValue + miningData.diamondTotalMiningValue / miningData.diamondTotalMiningCount * extendDiamondCount;

        //    miningData.carTotalMiningCount += extendCarCount;
        //    miningData.diamondTotalMiningCount += extendDiamondCount;
        //    miningData.totalMiningCount += extendTotalCount;
        //    miningData.totalReceiveCount += extendTotalCount;
        //}
        return miningData;
    }

    /// <summary>
    /// 领取赛车挖矿池token积分
    /// </summary>
    /// <param name="i_nServer"></param>
    /// <param name="i_nValue"></param>
    /// <param name="i_nTotalReceiveCount"></param>
    /// <param name="i_bNewReceive"></param>
    /// <returns></returns>
    public long ReceiveCarTokenScorePoolValue(int i_nServer, long i_nValue, int i_nTotalReceiveCount, bool i_bNewReceive)
    {
        bool bChangeData = false;
        lock (this)
        {
            if (m_nCarTokenScorePoolValue != -1)
            {
                if (m_nCarTokenScorePoolValue >= i_nValue)
                {
                    m_nCarTokenScorePoolValue -= i_nValue;
                    bChangeData = true;
                }
                else if (m_nCarTokenScorePoolValue > 0)
                {
                    i_nValue = m_nCarTokenScorePoolValue;
                    m_nCarTokenScorePoolValue = 0;
                    bChangeData = true;
                }
                else
                {
                    i_nValue = 0;
                }
            }
        }
        if (bChangeData)
        {
            OnChangeData();
        }

        if (i_nValue > 0)
        {
            if (m_pServerMiningDatas.TryGetValue(i_nServer, out var miningData))
            {
                if (i_bNewReceive)
                {
                    miningData.totalReceiveCount = i_nTotalReceiveCount + 1;
                }
                else
                {
                    miningData.totalReceiveCount = i_nTotalReceiveCount;
                }
                Dictionary<string, object> changeData = GetSaveMiningData(i_nServer, miningData);
                OnMiningChangeData(SqlHandleEnum.eUpdate, i_nServer, changeData);
            }
        }

        return i_nValue;
    }

    /// <summary>
    /// 领取钻石挖矿池token积分
    /// </summary>
    /// <param name="i_nServer"></param>
    /// <param name="i_nValue"></param>
    /// <param name="i_nTotalReceiveCount"></param>
    /// <param name="i_bNewReceive"></param>
    /// <returns></returns>
    public long ReceiveDiamondTokenScorePoolValue(int i_nServer, long i_nValue, int i_nTotalReceiveCount, bool i_bNewReceive)
    {
        bool bChangeData = false;
        lock (this)
        {
            if (m_nDiamondTokenScorePoolValue != -1)
            {
                if (m_nDiamondTokenScorePoolValue >= i_nValue)
                {
                    m_nDiamondTokenScorePoolValue -= i_nValue;
                    bChangeData = true;
                }
                else if (m_nDiamondTokenScorePoolValue > 0)
                {
                    i_nValue = m_nDiamondTokenScorePoolValue;
                    m_nDiamondTokenScorePoolValue = 0;
                    bChangeData = true;
                }
                else
                {
                    i_nValue = 0;
                }
            }
        }
        if (bChangeData)
        {
            OnChangeData();
        }

        if (i_nValue > 0)
        {
            if (m_pServerMiningDatas.TryGetValue(i_nServer, out var miningData))
            {
                if (i_bNewReceive)
                {
                    miningData.totalReceiveCount = i_nTotalReceiveCount + 1;
                }
                else
                {
                    miningData.totalReceiveCount = i_nTotalReceiveCount;
                }
                Dictionary<string, object> changeData = GetSaveMiningData(i_nServer, miningData);
                OnMiningChangeData(SqlHandleEnum.eUpdate, i_nServer, changeData);
            }
        }

        return i_nValue;
    }

    /// <summary>
    /// 更新公共挖矿服数据
    /// </summary>
    /// <param name="i_nServer"></param>
    /// <param name="i_pReqMsgBodyCommonMiningData"></param>
    public void UpdateCommonMiningData(int i_nServer, ReqMsgBodyCommonMiningData i_pReqMsgBodyCommonMiningData)
    {
        SqlHandleEnum sqlHandleEnum = SqlHandleEnum.eUpdate;
        Dictionary<string, object> changeData = new Dictionary<string, object>();
        m_pServerMiningDatas.AddOrUpdate(i_nServer, (key) =>
        {
            CommonMiningData miningData = new CommonMiningData();
            miningData.totalMiningCount = i_pReqMsgBodyCommonMiningData.TotalMiningCount;
            miningData.totalReceiveCount = i_pReqMsgBodyCommonMiningData.TotalReceiveCount;
            miningData.carTotalMiningCount = i_pReqMsgBodyCommonMiningData.CarTotalMiningCount;
            miningData.carTotalMiningValue = i_pReqMsgBodyCommonMiningData.CarTotalMiningValue;
            miningData.diamondTotalMiningCount = i_pReqMsgBodyCommonMiningData.DiamondTotalMiningCount;
            miningData.diamondTotalMiningValue = i_pReqMsgBodyCommonMiningData.DiamondTotalMiningValue;
            sqlHandleEnum = SqlHandleEnum.eInsert;
            changeData = GetSaveMiningData(i_nServer, miningData);
            return miningData;
        }, (key, miningData) =>
        {
            miningData.totalMiningCount = i_pReqMsgBodyCommonMiningData.TotalMiningCount;
            miningData.totalReceiveCount = i_pReqMsgBodyCommonMiningData.TotalReceiveCount;
            miningData.carTotalMiningCount = i_pReqMsgBodyCommonMiningData.CarTotalMiningCount;
            miningData.carTotalMiningValue = i_pReqMsgBodyCommonMiningData.CarTotalMiningValue;
            miningData.diamondTotalMiningCount = i_pReqMsgBodyCommonMiningData.DiamondTotalMiningCount;
            miningData.diamondTotalMiningValue = i_pReqMsgBodyCommonMiningData.DiamondTotalMiningValue;
            changeData = GetSaveMiningData(i_nServer, miningData);
            return miningData;
        });

        OnMiningChangeData(sqlHandleEnum, i_nServer, changeData);
    }

    /// <summary>
    /// 获取公共挖矿服数据
    /// </summary>
    /// <returns></returns>
    public ResMsgBodyCommonMiningData GetCommonMiningData()
    {
        ResMsgBodyCommonMiningData resMsgBodyCommonMiningData = new ResMsgBodyCommonMiningData();
        resMsgBodyCommonMiningData.CarTokenScorePoolValue = GetCarTokenScorePoolValue();
        resMsgBodyCommonMiningData.DiamondTokenScorePoolValue = GetDiamondTokenScorePoolValue();

        CommonMiningData miningData = GetAllServerTotalMiningData();

        resMsgBodyCommonMiningData.AllServerCarTotalMiningCount = miningData.carTotalMiningCount;
        resMsgBodyCommonMiningData.AllServerDiamondTotalMiningCount = miningData.diamondTotalMiningCount;
        resMsgBodyCommonMiningData.AllServerCarTotalMiningValue = miningData.carTotalMiningValue;
        resMsgBodyCommonMiningData.AllServerDiamondTotalMiningValue = miningData.diamondTotalMiningValue;
        return resMsgBodyCommonMiningData;
    }
}

public class CommonMiningData
{
    public int totalMiningCount = 0;
    public int totalReceiveCount = 0;
    public int carTotalMiningCount = 0;
    public int diamondTotalMiningCount = 0;
    public long carTotalMiningValue = 0;
    public long diamondTotalMiningValue = 0;
}