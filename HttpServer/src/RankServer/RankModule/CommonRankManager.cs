using Proto;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 公共排行榜管理器
/// </summary>
public class CommonRankManager : BaseManager<CommonRankManager>
{
    /// <summary>
    /// 存盘脏位
    /// </summary>
    private ConcurrentDictionary<string, object> m_pSaveCaches = new ConcurrentDictionary<string, object>();

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
    /// 排行榜集合
    /// </summary>
    private Dictionary<RankTypeEnum, IRank> m_pRanks = new Dictionary<RankTypeEnum, IRank>();

    /// <summary>
    /// 当前赛季
    /// </summary>
    private int m_nSeasonId = 0;

    public virtual int UpdateIntervalTime() => 1000;
    public override void Initializer(DataRow i_pGlobalInfo, bool i_bIsFirstOpenServer)
    {
        base.Initializer(i_pGlobalInfo, i_bIsFirstOpenServer);
        if (i_bIsFirstOpenServer)
        {
            ZeroTime = UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing();
            OnChangeData();
            SaveData();
        }
        else
        {
            ZeroTime = Convert.ToInt64(i_pGlobalInfo["zerotime"]);
        }

        foreach (var item in RegisterDefine.RankRegister)
        {
            IRank rank = item.Value.Invoke();
            rank.Initializer();
            m_pRanks.Add(item.Key, rank);
        }

        m_nSeasonId = Convert.ToInt32(i_pGlobalInfo["seasonid"]);
        int seasonId = ServerConfig.GetToInt("season_id");
        if (m_nSeasonId != seasonId)
        {
            StartNewSeason(seasonId);
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

        if (m_pRanks.Count > 0)
        {
            foreach (var item in m_pRanks)
            {
                item.Value.Update(i_nMillisecondDelay);
            }
        }
    }

    public override void SaveData()
    {
        base.SaveData();
        if (m_pSaveCaches.Count > 0)
        {
            Dictionary<string, object> saveCaches = new Dictionary<string, object>();
            lock (this)
            {
                saveCaches = m_pSaveCaches.ToDictionary();
                m_pSaveCaches.Clear();
            }
            foreach (var item in saveCaches)
            {
                Launch.DBServer.UpdateData(ServerTypeEnum.eRankServer, SqlTableName.globalinfo, new Dictionary<string, object>() { { item.Key, item.Value } }, "serverid", ServerConfig.ServerId);
            }
        }

        foreach (var item in m_pRanks)
        {
            item.Value.SaveData();
        }
    }

    public void DayRefresh()
    {
        ZeroTime = UtilityMethod.GetZeroUnixTimeMillisecondsByBeiJing();
        OnChangeData();
    }

    /// <summary>
    /// 数据变化通知
    /// </summary>
    public void OnChangeData()
    {
        m_pSaveCaches.Clear();
        m_pSaveCaches.TryAdd("zerotime", ZeroTime);
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 开始新赛季
    /// </summary>
    public void StartNewSeason(int i_nNewSeasonId)
    {
        m_nSeasonId = i_nNewSeasonId;
        Launch.DBServer.UpdateData(ServerTypeEnum.eRankServer, SqlTableName.globalinfo, new Dictionary<string, object>() { { "seasonid", m_nSeasonId } }, "serverid", ServerConfig.ServerId);

        foreach (var item in m_pRanks)
        {
            item.Value.StartNewSeason(i_nNewSeasonId);
        }
    }

    public IRank GetRank(RankTypeEnum i_eRankTypeEnum)
    {
        m_pRanks.TryGetValue(i_eRankTypeEnum, out IRank rank);
        return rank;
    }

    /// <summary>
    /// 更新排行数据
    /// </summary>
    /// <param name="ReqMsgBodyUpdateRankData"></param>
    public void UpdateRankData(ReqMsgBodyUpdateRankData i_pReqMsgBodyUpdateRankData)
    {
        if (m_pRanks.TryGetValue(i_pReqMsgBodyUpdateRankData.RankTypeEnum, out IRank rank))
        {
            rank.UpdateRankData(i_pReqMsgBodyUpdateRankData.Key, i_pReqMsgBodyUpdateRankData.Values.ToList(), i_pReqMsgBodyUpdateRankData.OtherInfo);
        }
    }

    /// <summary>
    /// 排行榜快照处理
    /// </summary>
    public void RankSnapshot(RankTypeEnum i_eRankTypeEnum)
    {
        if (m_pRanks.TryGetValue(i_eRankTypeEnum, out IRank rank))
        {
            rank.RankSnapshot();
        }
    }

    /// <summary>
    /// 保存排行快照
    /// </summary>
    //public void SaveRankSnapshotData(RankTypeEnum i_eRankTypeEnum)
    //{
    //    if (m_pRanks.TryGetValue(i_eRankTypeEnum, out IRank rank))
    //    {
    //        rank.BackupRankData();
    //    }
    //}

    /// <summary>
    /// 获取排行榜数据
    /// </summary>
    /// <param name="i_pReqMsgBodyGetRankData"></param>
    /// <returns></returns>
    public ResMsgBodyCommonRankManager GetCommonRankData(ReqMsgBodyGetRankData i_pReqMsgBodyGetRankData)
    {
        if (m_pRanks.TryGetValue(i_pReqMsgBodyGetRankData.RankTypeEnum, out IRank rank))
        {
            return rank.GetRankData(i_pReqMsgBodyGetRankData.SelfKey, i_pReqMsgBodyGetRankData.RankStartIndex, i_pReqMsgBodyGetRankData.RankEndIndex);
        }

        return null;
    }

    /// <summary>
    /// 获取排行榜数据
    /// </summary>
    /// <param name="i_pReqMsgBodyGetRankData"></param>
    /// <returns></returns>
    //public ResMsgBodyCommonRankManager GetBackupRankData(ReqMsgBodyGetRankData i_pReqMsgBodyGetRankData)
    //{
    //    if (m_pRanks.TryGetValue(i_pReqMsgBodyGetRankData.RankTypeEnum, out IRank rank))
    //    {
    //        return rank.GetBackupRankData(i_pReqMsgBodyGetRankData.SelfKey, i_pReqMsgBodyGetRankData.RankStartIndex, i_pReqMsgBodyGetRankData.RankEndIndex);
    //    }

    //    return null;
    //}
}